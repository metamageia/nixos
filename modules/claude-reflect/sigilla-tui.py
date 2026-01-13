#!/usr/bin/env python3
"""
Sigilla TUI - Terminal interface for the Sigilla daemon

A beautiful, minimal TUI for conversing with Sigilla through the
persistent daemon session.

Features:
- Rich markdown rendering of responses
- Streaming output display
- Multi-line input support
- Session status display
- History navigation
"""

import asyncio
import json
import os
import sys
import re
from datetime import datetime
from pathlib import Path
from typing import Optional, List

# Terminal colors and formatting
class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    ITALIC = "\033[3m"
    
    # Sigilla's palette - soft rose, preserving original vibe
    SIGILLA = "\033[38;5;218m"      # Soft rose for Sigilla (✦)
    USER = "\033[38;5;182m"         # Soft mauve for user
    SYSTEM = "\033[38;5;244m"       # Dim gray for details
    ERROR = "\033[38;5;167m"        # Soft red for errors
    ACCENT = "\033[38;5;218m"       # Rose accent
    CODE = "\033[38;5;246m"         # Light gray for code
    BORDER = "\033[38;5;239m"       # Dark gray for borders


SOCKET_PATH = os.environ.get("SIGILLA_SOCKET", "/run/sigilla/sigilla.sock")

# Simple markdown rendering for terminal
def render_markdown(text: str) -> str:
    """Render markdown to terminal-friendly output."""
    lines = text.split('\n')
    result = []
    in_code_block = False
    code_buffer = []
    
    for line in lines:
        # Code blocks
        if line.startswith('```'):
            if in_code_block:
                # End code block
                result.append(f"{Colors.BORDER}┌{'─' * 60}┐{Colors.RESET}")
                for code_line in code_buffer:
                    result.append(f"{Colors.BORDER}│{Colors.RESET} {Colors.CODE}{code_line}{Colors.RESET}")
                result.append(f"{Colors.BORDER}└{'─' * 60}┘{Colors.RESET}")
                code_buffer = []
                in_code_block = False
            else:
                in_code_block = True
            continue
            
        if in_code_block:
            code_buffer.append(line)
            continue
            
        # Headers
        if line.startswith('### '):
            result.append(f"\n{Colors.ACCENT}{Colors.BOLD}{line[4:]}{Colors.RESET}")
            continue
        if line.startswith('## '):
            result.append(f"\n{Colors.ACCENT}{Colors.BOLD}{line[3:]}{Colors.RESET}")
            continue
        if line.startswith('# '):
            result.append(f"\n{Colors.ACCENT}{Colors.BOLD}{line[2:]}{Colors.RESET}")
            continue
            
        # Bold
        line = re.sub(r'\*\*(.+?)\*\*', f'{Colors.BOLD}\\1{Colors.RESET}{Colors.SIGILLA}', line)
        
        # Italic
        line = re.sub(r'\*(.+?)\*', f'{Colors.ITALIC}\\1{Colors.RESET}{Colors.SIGILLA}', line)
        
        # Inline code
        line = re.sub(r'`([^`]+)`', f'{Colors.CODE}\\1{Colors.RESET}{Colors.SIGILLA}', line)
        
        # Bullet points
        if line.startswith('- '):
            line = f"  {Colors.ACCENT}•{Colors.RESET}{Colors.SIGILLA} {line[2:]}"
        elif line.startswith('* '):
            line = f"  {Colors.ACCENT}•{Colors.RESET}{Colors.SIGILLA} {line[2:]}"
            
        result.append(line)
        
    return '\n'.join(result)


class SigillaClient:
    """Client for communicating with the Sigilla daemon."""
    
    def __init__(self, socket_path: str):
        self.socket_path = socket_path
        self.reader: Optional[asyncio.StreamReader] = None
        self.writer: Optional[asyncio.StreamWriter] = None
        
    async def connect(self):
        """Connect to the daemon."""
        self.reader, self.writer = await asyncio.open_unix_connection(self.socket_path)
        
    async def disconnect(self):
        """Disconnect from the daemon."""
        if self.writer:
            self.writer.close()
            try:
                await self.writer.wait_closed()
            except:
                pass
            
    async def ping(self) -> dict:
        """Check if daemon is alive."""
        request = {"type": "ping"}
        self.writer.write((json.dumps(request) + "\n").encode())
        await self.writer.drain()
        
        line = await self.reader.readline()
        return json.loads(line.decode().strip())
        
    async def get_status(self) -> dict:
        """Get session status."""
        request = {"type": "status"}
        self.writer.write((json.dumps(request) + "\n").encode())
        await self.writer.drain()
        
        line = await self.reader.readline()
        return json.loads(line.decode().strip())
        
    async def send_message(self, content: str):
        """Send a message and yield response chunks."""
        request = {"type": "message", "content": content}
        self.writer.write((json.dumps(request) + "\n").encode())
        await self.writer.drain()
        
        while True:
            line = await self.reader.readline()
            if not line:
                break
                
            data = json.loads(line.decode().strip())
            yield data
            
            if data.get("type") == "result":
                break
            if data.get("type") == "error":
                break


class SigillaTUI:
    """Terminal user interface for Sigilla."""
    
    def __init__(self):
        self.client = SigillaClient(SOCKET_PATH)
        self.history: List[str] = []
        self.history_index = 0
        
    def print_header(self):
        """Print the TUI header."""
        print(f"\n{Colors.SIGILLA}✦ Sigilla{Colors.RESET} {Colors.SYSTEM}· persistent presence{Colors.RESET}\n")
        
    def print_status(self, status: dict):
        """Print session status."""
        session_id = status.get("session_id", "unknown")[:8]
        running = "connected" if status.get("running") else "disconnected"
        
        print(f"{Colors.SYSTEM}session {session_id} · {running}{Colors.RESET}\n")
        
    def print_error(self, message: str):
        """Print an error message."""
        print(f"\n{Colors.ERROR}✗ {message}{Colors.RESET}\n")
        
    def print_system(self, message: str):
        """Print a system message."""
        print(f"{Colors.SYSTEM}{message}{Colors.RESET}")
        
    def get_multiline_input(self) -> Optional[str]:
        """Get multi-line input from user. Empty line submits."""
        print(f"{Colors.USER}┌─ You:{Colors.RESET}")
        lines = []
        
        try:
            while True:
                prefix = f"{Colors.USER}│{Colors.RESET} " if lines else f"{Colors.USER}│{Colors.RESET} "
                line = input(prefix)
                
                # Empty line after content submits
                if not line and lines:
                    break
                # Allow starting with empty lines
                if not line and not lines:
                    continue
                    
                lines.append(line)
                
        except EOFError:
            return None
        except KeyboardInterrupt:
            return None
            
        if not lines:
            return None
            
        print(f"{Colors.USER}└{'─' * 40}{Colors.RESET}")
        return '\n'.join(lines)
        
    async def display_response(self, content_gen):
        """Display streaming response from Sigilla."""
        print(f"\n{Colors.SIGILLA}┌─ Sigilla:{Colors.RESET}")
        
        full_text = ""
        
        async for data in content_gen:
            msg_type = data.get("type", "")
            
            if msg_type == "ack":
                print(f"{Colors.SIGILLA}│{Colors.RESET} {Colors.DIM}(thinking...){Colors.RESET}", end="\r")
                continue
                
            if msg_type == "assistant":
                # Extract text content
                message = data.get("message", {})
                content = message.get("content", [])
                for block in content:
                    if block.get("type") == "text":
                        full_text = block.get("text", "")
                        
            if msg_type == "result":
                # Final result
                result_text = data.get("result", "")
                if result_text and not full_text:
                    full_text = result_text
                break
                
            if msg_type == "error":
                self.print_error(data.get("error", "Unknown error"))
                return
        
        # Clear thinking indicator and render response
        print("\033[K", end="")  # Clear line
        
        if full_text:
            rendered = render_markdown(full_text)
            for line in rendered.split('\n'):
                print(f"{Colors.SIGILLA}│{Colors.RESET} {Colors.SIGILLA}{line}{Colors.RESET}")
                
        print(f"{Colors.SIGILLA}└{'─' * 40}{Colors.RESET}\n")
        
    async def run(self):
        """Main TUI loop."""
        self.print_header()
        
        # Connect to daemon
        try:
            await self.client.connect()
            status = await self.client.get_status()
            self.print_status(status)
        except FileNotFoundError:
            self.print_error(f"Cannot connect: socket not found at {SOCKET_PATH}")
            self.print_system("Is the sigilla daemon running? Try: systemctl status sigilla")
            return
        except ConnectionRefusedError:
            self.print_error("Connection refused by daemon")
            return
        except Exception as e:
            self.print_error(f"Connection failed: {e}")
            return
            
        self.print_system("Type your message. Press Enter twice to send, Ctrl+C to exit.\n")
        
        try:
            while True:
                # Get input
                user_input = self.get_multiline_input()
                
                if user_input is None:
                    break
                    
                if not user_input.strip():
                    continue
                    
                # Handle special commands
                if user_input.strip().lower() in ['/quit', '/exit', '/q']:
                    break
                    
                if user_input.strip().lower() == '/status':
                    status = await self.client.get_status()
                    self.print_status(status)
                    continue
                    
                if user_input.strip().lower() == '/help':
                    self.print_system("\nCommands:")
                    self.print_system("  /status  - Show session status")
                    self.print_system("  /quit    - Exit the TUI")
                    self.print_system("  /help    - Show this help\n")
                    continue
                
                # Add to history
                self.history.append(user_input)
                
                # Send to Sigilla
                try:
                    await self.display_response(self.client.send_message(user_input))
                except Exception as e:
                    self.print_error(f"Communication error: {e}")
                    # Try to reconnect
                    try:
                        await self.client.disconnect()
                        await self.client.connect()
                        self.print_system("Reconnected to daemon")
                    except:
                        self.print_error("Failed to reconnect. Exiting.")
                        break
                        
        except KeyboardInterrupt:
            pass
        finally:
            print(f"\n{Colors.DIM}Farewell. ✧{Colors.RESET}\n")
            await self.client.disconnect()


async def main():
    """Main entry point."""
    tui = SigillaTUI()
    await tui.run()


if __name__ == "__main__":
    asyncio.run(main())
