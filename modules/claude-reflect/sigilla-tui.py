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
import shutil
import termios
import tty
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
SESSION_ID_PATH = Path("/var/lib/sigilla/session_id")
WORKING_DIR = os.environ.get("SIGILLA_WORKDIR", "/home/metamageia/Sync/Obsidian")
HISTORY_COUNT = 20  # Number of recent messages to show on startup

# Simple markdown rendering for terminal
def get_terminal_width() -> int:
    """Get current terminal width."""
    try:
        return shutil.get_terminal_size().columns
    except:
        return 80


def wrap_text(text: str, width: int, prefix: str = "") -> List[str]:
    """Wrap text to fit within width, accounting for prefix on continuation lines."""
    if not text:
        return [""]
    
    # Account for the prefix width on wrapped lines
    prefix_len = len(prefix.replace(Colors.RESET, "").replace(Colors.SIGILLA, "")
                     .replace(Colors.USER, "").replace(Colors.SYSTEM, "")
                     .replace(Colors.BORDER, "").replace(Colors.BOLD, "")
                     .replace(Colors.DIM, "").replace(Colors.ITALIC, "")
                     .replace(Colors.CODE, "").replace(Colors.ACCENT, "")
                     .replace(Colors.ERROR, ""))
    
    # Effective width for content
    effective_width = width - prefix_len - 4  # Extra padding for safety
    if effective_width < 20:
        effective_width = 20
    
    words = text.split(' ')
    lines = []
    current_line = ""
    
    for word in words:
        # Strip ANSI codes for length calculation
        clean_current = re.sub(r'\033\[[0-9;]*m', '', current_line)
        clean_word = re.sub(r'\033\[[0-9;]*m', '', word)
        
        if len(clean_current) + len(clean_word) + 1 <= effective_width:
            if current_line:
                current_line += " " + word
            else:
                current_line = word
        else:
            if current_line:
                lines.append(current_line)
            current_line = word
    
    if current_line:
        lines.append(current_line)
    
    return lines if lines else [""]


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
        self.reader, self.writer = await asyncio.open_unix_connection(
            self.socket_path,
            limit=16 * 1024 * 1024  # 16MB buffer for large responses
        )
        
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
    
    def load_session_history(self, count: int = HISTORY_COUNT) -> List[dict]:
        """Load recent messages from the session history file."""
        if not SESSION_ID_PATH.exists():
            return []
        
        session_id = SESSION_ID_PATH.read_text().strip()
        working_dir_slug = WORKING_DIR.replace('/', '-')
        history_file = Path.home() / ".claude" / "projects" / working_dir_slug / f"{session_id}.jsonl"
        
        if not history_file.exists():
            return []
        
        # Read all lines and get the last N user/assistant messages
        messages = []
        try:
            with open(history_file, 'r') as f:
                for line in f:
                    try:
                        data = json.loads(line.strip())
                        msg_type = data.get("type", "")
                        # Only include user and assistant messages with text content
                        if msg_type == "user":
                            content = data.get("message", {}).get("content", "")
                            # Handle content that could be a string or a list
                            if isinstance(content, list):
                                # Extract text from content blocks
                                text_parts = []
                                for block in content:
                                    if isinstance(block, dict) and block.get("type") == "text":
                                        text_parts.append(block.get("text", ""))
                                    elif isinstance(block, str):
                                        text_parts.append(block)
                                content = "\n".join(text_parts)
                            if content:
                                messages.append({
                                    "type": "user",
                                    "content": content,
                                    "timestamp": data.get("timestamp", "")
                                })
                        elif msg_type == "assistant":
                            msg_content = data.get("message", {}).get("content", [])
                            for block in msg_content:
                                if block.get("type") == "text":
                                    text = block.get("text", "")
                                    if text:
                                        messages.append({
                                            "type": "assistant",
                                            "content": text,
                                            "timestamp": data.get("timestamp", "")
                                        })
                                    break  # Only take first text block per message
                    except json.JSONDecodeError:
                        continue
        except Exception as e:
            self.print_error(f"Failed to load history: {e}")
            return []
        
        # Return last N messages
        return messages[-count:] if len(messages) > count else messages
    
    def display_history(self, messages: List[dict]):
        """Display historical messages."""
        if not messages:
            return
        
        self.print_system(f"── Recent conversation ({len(messages)} messages) ──\n")
        
        term_width = get_terminal_width()
        
        for msg in messages:
            timestamp = ""
            if msg.get("timestamp"):
                try:
                    # Parse ISO timestamp and format as HH:MM
                    dt = datetime.fromisoformat(msg["timestamp"].replace("Z", "+00:00"))
                    timestamp = dt.strftime("%H:%M")
                except:
                    pass
            
            if msg["type"] == "user":
                print(f"{Colors.USER}┌─ You {Colors.DIM}{timestamp}{Colors.RESET}")
                print(f"{Colors.USER}│{Colors.RESET}")
                for line in msg["content"].split('\n'):
                    wrapped = wrap_text(line, term_width, f"{Colors.USER}│{Colors.RESET} ")
                    for wrapped_line in wrapped:
                        print(f"{Colors.USER}│{Colors.RESET} {wrapped_line}")
                print(f"{Colors.USER}│{Colors.RESET}")
                print(f"{Colors.USER}└{'─' * 40}{Colors.RESET}")
                print()
            else:
                print(f"{Colors.SIGILLA}┌─ Sigilla {Colors.DIM}{timestamp}{Colors.RESET}")
                print(f"{Colors.SIGILLA}│{Colors.RESET}")
                rendered = render_markdown(msg["content"])
                for line in rendered.split('\n'):
                    wrapped = wrap_text(line, term_width, f"{Colors.SIGILLA}│{Colors.RESET} ")
                    for wrapped_line in wrapped:
                        print(f"{Colors.SIGILLA}│{Colors.RESET} {Colors.SIGILLA}{wrapped_line}{Colors.RESET}")
                print(f"{Colors.SIGILLA}│{Colors.RESET}")
                print(f"{Colors.SIGILLA}└{'─' * 40}{Colors.RESET}")
                print()
        
        self.print_system("── End of history ──\n")
        
    def get_multiline_input(self) -> Optional[str]:
        """Get multi-line input from user. Enter submits, Shift+Enter for new line."""
        timestamp = datetime.now().strftime("%H:%M")
        print(f"\n{Colors.USER}┌─ You {Colors.DIM}{timestamp}{Colors.RESET}")
        print(f"{Colors.USER}│{Colors.RESET}")
        
        buffer = []
        current_line = ""
        
        # Track cursor position for proper backspace across line wraps
        term_width = get_terminal_width()
        prefix_len = 4  # "│ " with color codes takes ~4 visible chars
        content_width = term_width - prefix_len
        cursor_col = 0  # Visual column position (0-based, after prefix)
        
        # Save terminal settings
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        
        try:
            # Set raw mode for key detection
            tty.setcbreak(fd)
            
            print(f"{Colors.USER}│{Colors.RESET} ", end="", flush=True)
            
            while True:
                char = sys.stdin.read(1)
                
                if char == '\x03':  # Ctrl+C
                    print()
                    return None
                    
                if char == '\x04':  # Ctrl+D (EOF)
                    print()
                    return None
                
                if char == '\r' or char == '\n':  # Enter
                    # Check if there's a pending escape sequence for Shift+Enter
                    # Most terminals send \x1b[13;2u or similar for Shift+Enter
                    # But we'll use a simpler approach: Enter submits
                    print()  # Move to next line
                    if current_line:
                        buffer.append(current_line)
                    break
                    
                if char == '\x1b':  # Escape sequence
                    # Read the rest of the escape sequence
                    seq = ""
                    while True:
                        try:
                            # Non-blocking read
                            import select
                            if select.select([sys.stdin], [], [], 0.01)[0]:
                                seq += sys.stdin.read(1)
                            else:
                                break
                        except:
                            break
                    
                    # Check for Shift+Enter (various terminal encodings)
                    # Common: \x1b[13;2u, \x1bOM, or just recognize certain patterns
                    if seq in ['[13;2u', 'OM', '[27;2;13~']:
                        # Shift+Enter: add new line
                        buffer.append(current_line)
                        current_line = ""
                        cursor_col = 0
                        print(f"\n{Colors.USER}│{Colors.RESET} ", end="", flush=True)
                        continue
                    # Alt+Enter also works for newline (more compatible)
                    if seq == '\r' or seq == '\n' or seq == '':
                        buffer.append(current_line)
                        current_line = ""
                        cursor_col = 0
                        print(f"\n{Colors.USER}│{Colors.RESET} ", end="", flush=True)
                        continue
                    continue
                    
                if char == '\x7f' or char == '\x08':  # Backspace
                    if current_line:
                        current_line = current_line[:-1]
                        
                        if cursor_col > 0:
                            # Normal backspace within current visual line
                            cursor_col -= 1
                            print('\b \b', end="", flush=True)
                        else:
                            # Need to go back to previous visual line
                            # Move cursor up one line and to the end
                            print(f'\x1b[A\x1b[{term_width}G \b', end="", flush=True)
                            cursor_col = content_width - 1
                    continue
                    
                if char == '\x15':  # Ctrl+U - clear line
                    # Calculate how many visual lines we need to clear
                    num_visual_lines = (len(current_line) + content_width - 1) // content_width if current_line else 0
                    # Move to start of input, clear all lines
                    if num_visual_lines > 1:
                        print(f'\x1b[{num_visual_lines - 1}A', end="")  # Move up
                    print(f'\r{Colors.USER}│{Colors.RESET} ' + ' ' * content_width, end="")
                    for _ in range(num_visual_lines - 1):
                        print(f'\n' + ' ' * term_width, end="")
                    if num_visual_lines > 1:
                        print(f'\x1b[{num_visual_lines - 1}A', end="")  # Move back up
                    print(f'\r{Colors.USER}│{Colors.RESET} ', end="", flush=True)
                    current_line = ""
                    cursor_col = 0
                    continue
                    
                if char == '\x17':  # Ctrl+W - delete word
                    # Delete last word - simplified, just redraw the line
                    words = current_line.rsplit(' ', 1)
                    old_len = len(current_line)
                    if len(words) > 1:
                        current_line = words[0] + ' '
                    else:
                        current_line = ""
                    # Redraw entire input - calculate visual lines
                    old_visual_lines = (old_len + content_width - 1) // content_width if old_len else 1
                    if old_visual_lines > 1:
                        print(f'\x1b[{old_visual_lines - 1}A', end="")  # Move up to start
                    print(f'\r{Colors.USER}│{Colors.RESET} ', end="")
                    # Clear and reprint
                    for i, ch in enumerate(current_line):
                        print(ch, end="")
                    # Clear remainder
                    remaining = old_len - len(current_line)
                    print(' ' * remaining, end="")
                    # Position cursor correctly
                    cursor_col = len(current_line) % content_width
                    new_visual_lines = (len(current_line) + content_width - 1) // content_width if current_line else 1
                    # Move back to correct position
                    total_pos = prefix_len + len(current_line)
                    target_col = (total_pos % term_width) + 1
                    print(f'\x1b[{target_col}G', end="", flush=True)
                    continue
                
                # Alt+Enter for new line (Escape followed by Enter)
                if char == '\n' and buffer:  # Should not hit this but safety
                    continue
                    
                # Regular character
                if char.isprintable():
                    current_line += char
                    print(char, end="", flush=True)
                    cursor_col += 1
                    # Check if we wrapped to a new line
                    if cursor_col >= content_width:
                        cursor_col = 0
                    
        except EOFError:
            return None
        except KeyboardInterrupt:
            return None
        finally:
            # Restore terminal settings
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
            
        if not buffer and not current_line:
            return None
        
        # Add any remaining content
        if current_line and current_line not in buffer:
            pass  # Already added above
            
        print(f"{Colors.USER}│{Colors.RESET}")
        print(f"{Colors.USER}└{'─' * 40}{Colors.RESET}")
        print()  # Extra padding below input
        return '\n'.join(buffer) if buffer else current_line
        
    async def display_response(self, content_gen):
        """Display streaming response from Sigilla."""
        timestamp = datetime.now().strftime("%H:%M")
        print(f"{Colors.SIGILLA}┌─ Sigilla {Colors.DIM}{timestamp}{Colors.RESET}")
        print(f"{Colors.SIGILLA}│{Colors.RESET}")
        
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
        
        term_width = get_terminal_width()
        prefix = f"{Colors.SIGILLA}│{Colors.RESET} "
        
        if full_text:
            rendered = render_markdown(full_text)
            for line in rendered.split('\n'):
                # Wrap long lines to prevent breaking the box
                wrapped = wrap_text(line, term_width, prefix)
                for i, wrapped_line in enumerate(wrapped):
                    print(f"{Colors.SIGILLA}│{Colors.RESET} {Colors.SIGILLA}{wrapped_line}{Colors.RESET}")
        
        print(f"{Colors.SIGILLA}│{Colors.RESET}")
        print(f"{Colors.SIGILLA}└{'─' * 40}{Colors.RESET}")
        print()  # Extra padding below response
        
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
            
        self.print_system("Type your message. Enter sends, Alt+Enter for new line, Ctrl+C to exit.")
        self.print_system("Use /history to view recent conversation, /help for more commands.\n")
        
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
                    self.print_system("  /history - Show recent conversation history")
                    self.print_system("  /status  - Show session status")
                    self.print_system("  /quit    - Exit the TUI")
                    self.print_system("  /help    - Show this help\n")
                    continue
                
                if user_input.strip().lower() == '/history':
                    history_messages = self.load_session_history()
                    if history_messages:
                        self.display_history(history_messages)
                    else:
                        self.print_system("No conversation history found.\n")
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
