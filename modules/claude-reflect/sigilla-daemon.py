#!/usr/bin/env python3
"""
Sigilla Daemon - Persistent Claude Code session manager

This daemon maintains a long-running Claude Code session and accepts
connections from clients (TUI, automated heartbeats) via Unix socket.

Architecture:
- Spawns Claude Code with stream-json input/output
- Accepts client connections on a Unix domain socket
- Routes messages between clients and Claude
- Handles Claude process lifecycle and reconnection
"""

import asyncio
import json
import os
import signal
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional
import logging

# Configuration
SOCKET_PATH = os.environ.get("SIGILLA_SOCKET", "/run/sigilla/sigilla.sock")
WORKING_DIR = os.environ.get("SIGILLA_WORKDIR", "/home/metamageia/Sync/Obsidian")
CLAUDE_BIN = os.environ.get("SIGILLA_CLAUDE_BIN", "claude")
MODEL = os.environ.get("SIGILLA_MODEL", "claude-opus-4-5-20251101")
LOG_DIR = os.environ.get("SIGILLA_LOG_DIR", "/var/log/sigilla")

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
    ]
)
logger = logging.getLogger("sigilla-daemon")


class ClaudeSession:
    """Manages a persistent Claude Code subprocess."""
    
    def __init__(self, claude_bin: str, model: str, working_dir: str):
        self.claude_bin = claude_bin
        self.model = model
        self.working_dir = working_dir
        self.process: Optional[asyncio.subprocess.Process] = None
        self.session_id: Optional[str] = None
        self._read_lock = asyncio.Lock()
        self._write_lock = asyncio.Lock()
        self._response_queue: asyncio.Queue = asyncio.Queue()
        self._reader_task: Optional[asyncio.Task] = None
        self._initialized = asyncio.Event()
        self._session_file = Path("/run/sigilla/session_id")
        
    async def start(self):
        """Start the Claude Code subprocess."""
        logger.info(f"Starting Claude session in {self.working_dir}")
        
        # Try to resume existing session, otherwise create new
        args = [
            self.claude_bin,
            "--model", self.model,
            "--input-format", "stream-json",
            "--output-format", "stream-json",
            "--verbose",
            "--dangerously-skip-permissions",
            "--allowedTools", "*",
        ]
        
        # Check for existing session to continue
        if self._session_file.exists():
            self.session_id = self._session_file.read_text().strip()
            args.extend(["--resume", self.session_id])
            logger.info(f"Resuming existing session: {self.session_id}")
        else:
            self.session_id = str(uuid.uuid4())
            args.extend(["--session-id", self.session_id])
            self._session_file.write_text(self.session_id)
            logger.info(f"Starting new session: {self.session_id}")
        
        self.process = await asyncio.create_subprocess_exec(
            *args,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=self.working_dir,
            limit=16 * 1024 * 1024,  # 16MB buffer for large responses
        )
        
        # Start background reader
        self._reader_task = asyncio.create_task(self._read_output())
        
        # Don't wait for init - Claude sends it with first response
        # Mark as initialized immediately so server can start
        self._initialized.set()
        logger.info(f"Claude session started: {self.session_id}")
        
    async def _read_output(self):
        """Background task to read Claude output and route to queue."""
        try:
            while self.process and self.process.stdout:
                # Read line with large buffer limit
                try:
                    line = await self.process.stdout.readline()
                except ValueError as e:
                    # Line too long - try to recover
                    logger.warning(f"Line too long, attempting recovery: {e}")
                    continue
                    
                if not line:
                    break
                    
                try:
                    data = json.loads(line.decode().strip())
                    msg_type = data.get("type", "")
                    
                    # Handle init message
                    if msg_type == "system" and data.get("subtype") == "init":
                        self._initialized.set()
                        logger.info("Received init from Claude")
                        
                    # Queue all messages for clients
                    await self._response_queue.put(data)
                    
                except json.JSONDecodeError as e:
                    logger.warning(f"Failed to parse Claude output: {e}")
                    
        except Exception as e:
            logger.error(f"Reader task error: {e}")
            # Attempt to restart reader if process still alive
            if self.process and self.process.returncode is None:
                logger.info("Process still alive, restarting reader...")
                await asyncio.sleep(0.5)
                self._reader_task = asyncio.create_task(self._read_output())
                return
        finally:
            logger.info("Reader task ended")
            
    async def send_message(self, content: str) -> list:
        """Send a message to Claude and collect all response messages."""
        if not self.process or not self.process.stdin:
            raise RuntimeError("Claude session not running")
            
        # Format message for Claude's stream-json input
        message = {
            "type": "user",
            "message": {
                "role": "user",
                "content": content
            }
        }
        
        async with self._write_lock:
            # Clear any stale messages from queue
            while not self._response_queue.empty():
                try:
                    self._response_queue.get_nowait()
                except asyncio.QueueEmpty:
                    break
            
            # Send message
            msg_bytes = (json.dumps(message) + "\n").encode()
            self.process.stdin.write(msg_bytes)
            await self.process.stdin.drain()
            logger.info(f"Sent message to Claude ({len(content)} chars)")
        
        # Collect response messages until we get a result
        responses = []
        while True:
            try:
                data = await asyncio.wait_for(self._response_queue.get(), timeout=300)
                responses.append(data)
                
                # Result message signals end of response
                if data.get("type") == "result":
                    break
                    
            except asyncio.TimeoutError:
                logger.error("Timeout waiting for Claude response")
                break
                
        return responses
    
    async def stop(self):
        """Stop the Claude subprocess."""
        if self._reader_task:
            self._reader_task.cancel()
            try:
                await self._reader_task
            except asyncio.CancelledError:
                pass
                
        if self.process:
            self.process.terminate()
            try:
                await asyncio.wait_for(self.process.wait(), timeout=5)
            except asyncio.TimeoutError:
                self.process.kill()
                await self.process.wait()
            logger.info("Claude session stopped")
            
    @property
    def is_running(self) -> bool:
        return self.process is not None and self.process.returncode is None


class SigillaServer:
    """Unix socket server for Sigilla clients."""
    
    def __init__(self, socket_path: str, claude_session: ClaudeSession):
        self.socket_path = socket_path
        self.claude = claude_session
        self.server: Optional[asyncio.Server] = None
        self._active_clients: set = set()
        self._request_lock = asyncio.Lock()  # Serialize requests to Claude
        
    async def start(self):
        """Start the socket server."""
        # Ensure socket directory exists
        socket_dir = Path(self.socket_path).parent
        socket_dir.mkdir(parents=True, exist_ok=True)
        
        # Remove stale socket
        if os.path.exists(self.socket_path):
            os.unlink(self.socket_path)
            
        self.server = await asyncio.start_unix_server(
            self._handle_client,
            path=self.socket_path
        )
        
        # Set socket permissions
        os.chmod(self.socket_path, 0o660)
        
        logger.info(f"Sigilla server listening on {self.socket_path}")
        
    async def _handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        """Handle a client connection."""
        client_id = str(uuid.uuid4())[:8]
        self._active_clients.add(client_id)
        logger.info(f"Client {client_id} connected")
        
        try:
            while True:
                # Read request (newline-delimited JSON)
                line = await reader.readline()
                if not line:
                    break
                    
                try:
                    request = json.loads(line.decode().strip())
                except json.JSONDecodeError as e:
                    error_response = {"type": "error", "error": f"Invalid JSON: {e}"}
                    writer.write((json.dumps(error_response) + "\n").encode())
                    await writer.drain()
                    continue
                
                req_type = request.get("type", "")
                
                if req_type == "ping":
                    # Health check
                    response = {
                        "type": "pong",
                        "session_id": self.claude.session_id,
                        "running": self.claude.is_running
                    }
                    writer.write((json.dumps(response) + "\n").encode())
                    await writer.drain()
                    
                elif req_type == "message":
                    # Send message to Claude
                    content = request.get("content", "")
                    if not content:
                        error_response = {"type": "error", "error": "Empty message"}
                        writer.write((json.dumps(error_response) + "\n").encode())
                        await writer.drain()
                        continue
                    
                    # Serialize access to Claude (one request at a time)
                    async with self._request_lock:
                        try:
                            # Send acknowledgment
                            ack = {"type": "ack", "status": "processing"}
                            writer.write((json.dumps(ack) + "\n").encode())
                            await writer.drain()
                            
                            # Get response from Claude
                            responses = await self.claude.send_message(content)
                            
                            # Stream responses to client
                            for resp in responses:
                                writer.write((json.dumps(resp) + "\n").encode())
                                await writer.drain()
                                
                        except Exception as e:
                            logger.error(f"Error processing message: {e}")
                            error_response = {"type": "error", "error": str(e)}
                            writer.write((json.dumps(error_response) + "\n").encode())
                            await writer.drain()
                            
                elif req_type == "status":
                    # Get session status
                    response = {
                        "type": "status",
                        "session_id": self.claude.session_id,
                        "running": self.claude.is_running,
                        "active_clients": len(self._active_clients),
                    }
                    writer.write((json.dumps(response) + "\n").encode())
                    await writer.drain()
                    
                else:
                    error_response = {"type": "error", "error": f"Unknown request type: {req_type}"}
                    writer.write((json.dumps(error_response) + "\n").encode())
                    await writer.drain()
                    
        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error(f"Client {client_id} error: {e}")
        finally:
            self._active_clients.discard(client_id)
            writer.close()
            try:
                await writer.wait_closed()
            except:
                pass
            logger.info(f"Client {client_id} disconnected")
            
    async def stop(self):
        """Stop the server."""
        if self.server:
            self.server.close()
            await self.server.wait_closed()
            
        if os.path.exists(self.socket_path):
            os.unlink(self.socket_path)
            
        logger.info("Sigilla server stopped")


async def main():
    """Main entry point."""
    logger.info("Starting Sigilla daemon")
    
    # Create Claude session
    claude = ClaudeSession(
        claude_bin=CLAUDE_BIN,
        model=MODEL,
        working_dir=WORKING_DIR,
    )
    
    # Create server
    server = SigillaServer(SOCKET_PATH, claude)
    
    # Signal handlers
    shutdown_event = asyncio.Event()
    
    def handle_signal(signum, frame):
        logger.info(f"Received signal {signum}")
        shutdown_event.set()
        
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    
    try:
        # Start Claude session
        await claude.start()
        
        # Start server
        await server.start()
        
        # Wait for shutdown
        await shutdown_event.wait()
        
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise
    finally:
        await server.stop()
        await claude.stop()
        
    logger.info("Sigilla daemon stopped")


if __name__ == "__main__":
    asyncio.run(main())
