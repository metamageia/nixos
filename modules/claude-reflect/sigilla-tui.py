#!/usr/bin/env python3
"""
Sigilla TUI - Terminal interface for the Sigilla daemon

A beautiful, minimal TUI for conversing with Sigilla through the
persistent daemon session.
"""

import asyncio
import json
import os
import sys
import re
import shutil
import textwrap
from datetime import datetime
from pathlib import Path
from typing import Optional, List

from prompt_toolkit import PromptSession
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.keys import Keys
from prompt_toolkit.styles import Style
from prompt_toolkit.formatted_text import ANSI
from prompt_toolkit.history import InMemoryHistory
from prompt_toolkit.filters import Condition


class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    ITALIC = "\033[3m"

    SIGILLA = "\033[38;5;218m"      # Soft rose for Sigilla
    USER = "\033[38;5;250m"         # Light grey for user text
    USER_LABEL = "\033[38;5;182m"   # Soft mauve for "you" label
    SYSTEM = "\033[38;5;244m"       # Dim gray for system messages
    ERROR = "\033[38;5;167m"        # Soft red for errors
    ACCENT = "\033[38;5;218m"       # Rose accent
    CODE = "\033[38;5;246m"         # Light gray for code
    CODE_BG = "\033[48;5;236m"      # Subtle background for code
    BOX = "\033[38;5;239m"          # Dark gray for box drawing


class Box:
    TL = "╭"
    TR = "╮"
    BL = "╰"
    BR = "╯"
    H = "─"
    V = "│"


SOCKET_PATH = os.environ.get("SIGILLA_SOCKET", "/run/sigilla/sigilla.sock")
SESSION_ID_PATH = Path("/var/lib/sigilla/session_id")
WORKING_DIR = os.environ.get("SIGILLA_WORKDIR", "/home/metamageia/Sync/Obsidian")
HISTORY_COUNT = 20
BOX_PADDING = 6  # Left margin + box chars + spacing
MAX_BOX_WIDTH = 80


PROMPT_STYLE = Style.from_dict({
    'prompt': '#bcbcbc',
    'continuation': '#6c6c6c',
})


def get_terminal_width() -> int:
    try:
        return shutil.get_terminal_size().columns
    except:
        return 80


def get_box_width() -> int:
    """Get box width based on terminal size."""
    term_width = get_terminal_width()
    # Leave some margin on the right
    return min(term_width - 4, MAX_BOX_WIDTH)


def get_content_width() -> int:
    """Get width available for content inside the box."""
    return get_box_width() - 4  # Account for box edges and padding


def strip_ansi(text: str) -> str:
    """Remove ANSI escape codes for length calculation."""
    return re.sub(r'\033\[[0-9;]*m', '', text)


def wrap_text(text: str, width: int) -> List[str]:
    """Wrap text to fit within width, preserving existing line breaks."""
    if width <= 0:
        width = 40

    result = []
    for line in text.split('\n'):
        if not line:
            result.append('')
            continue

        # For lines with ANSI codes, we need to be careful
        # Simple approach: wrap the stripped version, then we'll color whole lines
        clean_line = strip_ansi(line)
        if len(clean_line) <= width:
            result.append(line)
        else:
            # Wrap the line
            wrapped = textwrap.wrap(clean_line, width=width, break_long_words=True, break_on_hyphens=False)
            # If original had color, apply to all wrapped lines
            if line != clean_line:
                # Extract leading color code if present
                color_match = re.match(r'^(\033\[[0-9;]*m)', line)
                color = color_match.group(1) if color_match else ''
                wrapped = [f"{color}{w}{Colors.RESET}" if color else w for w in wrapped]
            result.extend(wrapped if wrapped else [''])

    return result


def box_top(label: str, label_color: str) -> str:
    """Draw top of a box with a label."""
    width = get_box_width()
    # Calculate label length without ANSI codes
    label_clean_len = len(strip_ansi(label))
    inner = width - 4 - label_clean_len
    if inner < 0:
        inner = 0
    return f"{Colors.BOX}{Box.TL}{Box.H} {label_color}{label}{Colors.BOX} {Box.H * inner}{Box.TR}{Colors.RESET}"


def box_bottom() -> str:
    """Draw bottom of a box."""
    width = get_box_width()
    return f"{Colors.BOX}{Box.BL}{Box.H * (width - 2)}{Box.BR}{Colors.RESET}"


def box_line(text: str, text_color: str = "") -> str:
    """Draw a line inside a box."""
    if text_color:
        return f"{Colors.BOX}{Box.V}{Colors.RESET} {text_color}{text}{Colors.RESET}"
    else:
        return f"{Colors.BOX}{Box.V}{Colors.RESET} {text}"


def render_markdown(text: str, color: str = "") -> List[str]:
    """Render markdown to terminal-friendly output, returning lines."""
    if not color:
        color = Colors.SIGILLA

    content_width = get_content_width()
    lines = text.split('\n')
    result = []
    in_code_block = False
    code_buffer = []

    for line in lines:
        if line.startswith('```'):
            if in_code_block:
                if code_buffer:
                    result.append("")
                    for code_line in code_buffer:
                        # Wrap code lines too
                        for wrapped in wrap_text(code_line, content_width - 2):
                            result.append(f"{Colors.CODE}{Colors.CODE_BG} {wrapped} {Colors.RESET}")
                    result.append("")
                code_buffer = []
                in_code_block = False
            else:
                in_code_block = True
            continue

        if in_code_block:
            code_buffer.append(line)
            continue

        if line.startswith('### '):
            formatted = f"{Colors.ACCENT}{Colors.BOLD}{line[4:]}{Colors.RESET}"
            for wrapped in wrap_text(strip_ansi(formatted), content_width):
                result.append(f"{Colors.ACCENT}{Colors.BOLD}{wrapped}{Colors.RESET}")
            continue
        if line.startswith('## '):
            for wrapped in wrap_text(line[3:], content_width):
                result.append(f"{Colors.ACCENT}{Colors.BOLD}{wrapped}{Colors.RESET}")
            continue
        if line.startswith('# '):
            for wrapped in wrap_text(line[2:], content_width):
                result.append(f"{Colors.ACCENT}{Colors.BOLD}{wrapped}{Colors.RESET}")
            continue

        formatted = line
        formatted = re.sub(r'\*\*(.+?)\*\*', f'{Colors.BOLD}\\1{Colors.RESET}{color}', formatted)
        formatted = re.sub(r'(?<!\*)\*([^*]+?)\*(?!\*)', f'{Colors.ITALIC}\\1{Colors.RESET}{color}', formatted)
        formatted = re.sub(r'`([^`]+)`', f'{Colors.CODE}{Colors.CODE_BG} \\1 {Colors.RESET}{color}', formatted)

        if formatted.startswith('- '):
            formatted = f"{Colors.ACCENT}♡{Colors.RESET}{color} {formatted[2:]}"
        elif formatted.startswith('* '):
            formatted = f"{Colors.ACCENT}♡{Colors.RESET}{color} {formatted[2:]}"

        # Wrap the plain text, then apply color
        plain = strip_ansi(formatted)
        if len(plain) <= content_width:
            result.append(f"{color}{formatted}{Colors.RESET}")
        else:
            for wrapped in wrap_text(plain, content_width):
                result.append(f"{color}{wrapped}{Colors.RESET}")

    return result


class SigillaClient:
    def __init__(self, socket_path: str):
        self.socket_path = socket_path
        self.reader: Optional[asyncio.StreamReader] = None
        self.writer: Optional[asyncio.StreamWriter] = None

    async def connect(self):
        self.reader, self.writer = await asyncio.open_unix_connection(
            self.socket_path,
            limit=16 * 1024 * 1024
        )

    async def disconnect(self):
        if self.writer:
            self.writer.close()
            try:
                await self.writer.wait_closed()
            except:
                pass

    async def ping(self) -> dict:
        request = {"type": "ping"}
        self.writer.write((json.dumps(request) + "\n").encode())
        await self.writer.drain()
        line = await self.reader.readline()
        return json.loads(line.decode().strip())

    async def get_status(self) -> dict:
        request = {"type": "status"}
        self.writer.write((json.dumps(request) + "\n").encode())
        await self.writer.drain()
        line = await self.reader.readline()
        return json.loads(line.decode().strip())

    async def send_message(self, content: str):
        request = {"type": "message", "content": content}
        self.writer.write((json.dumps(request) + "\n").encode())
        await self.writer.drain()

        while True:
            line = await self.reader.readline()
            if not line:
                break
            data = json.loads(line.decode().strip())
            yield data
            if data.get("type") in ("result", "error"):
                break


class SigillaTUI:
    def __init__(self):
        self.client = SigillaClient(SOCKET_PATH)
        self.prompt_history = InMemoryHistory()
        self.session: Optional[PromptSession] = None
        self._setup_prompt()

    def _setup_prompt(self):
        bindings = KeyBindings()

        # Enter submits (override default multiline behavior)
        @bindings.add(Keys.Enter)
        def _(event):
            event.current_buffer.validate_and_handle()

        # Shift+Enter or Alt+Enter for newline
        # Note: Shift+Enter terminal support varies, Alt+Enter is more reliable
        @bindings.add(Keys.Escape, Keys.Enter)
        def _(event):
            event.current_buffer.insert_text('\n')

        # Also try to catch Shift+Enter (works in some terminals like kitty)
        @bindings.add(Keys.ControlJ, Keys.Any)
        def _(event):
            # This catches some terminal's shift+enter
            event.current_buffer.insert_text('\n')

        @bindings.add(Keys.ControlD)
        def _(event):
            if event.current_buffer.text:
                event.current_buffer.validate_and_handle()
            else:
                event.app.exit(result=None)

        self.session = PromptSession(
            history=self.prompt_history,
            key_bindings=bindings,
            multiline=True,
            style=PROMPT_STYLE,
            enable_history_search=True,
        )

    def print_header(self):
        print(f"\n{Colors.SIGILLA}  ✧ sigilla{Colors.RESET}")
        print(f"{Colors.DIM}    persistent presence{Colors.RESET}\n")

    def print_status(self, status: dict):
        session_id = status.get("session_id", "unknown")[:8]
        running = "connected" if status.get("running") else "disconnected"
        print(f"{Colors.DIM}    session {session_id} · {running}{Colors.RESET}\n")

    def print_error(self, message: str):
        print(f"\n{Colors.ERROR}  ✗ {message}{Colors.RESET}\n")

    def print_system(self, message: str):
        print(f"{Colors.SYSTEM}    {message}{Colors.RESET}")

    def load_session_history(self, count: int = HISTORY_COUNT) -> List[dict]:
        if not SESSION_ID_PATH.exists():
            return []

        session_id = SESSION_ID_PATH.read_text().strip()
        working_dir_slug = WORKING_DIR.replace('/', '-')
        history_file = Path.home() / ".claude" / "projects" / working_dir_slug / f"{session_id}.jsonl"

        if not history_file.exists():
            return []

        messages = []
        try:
            with open(history_file, 'r') as f:
                for line in f:
                    try:
                        data = json.loads(line.strip())
                        msg_type = data.get("type", "")
                        if msg_type == "user":
                            content = data.get("message", {}).get("content", "")
                            if isinstance(content, list):
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
                                    break
                    except json.JSONDecodeError:
                        continue
        except Exception as e:
            self.print_error(f"Failed to load history: {e}")
            return []

        return messages[-count:] if len(messages) > count else messages

    def print_message_box(self, label: str, label_color: str, content: str, text_color: str, timestamp: str = ""):
        """Print a complete message in a box."""
        content_width = get_content_width()

        if timestamp:
            header_label = f"{label} {Colors.DIM}{timestamp}{label_color}"
        else:
            header_label = label
        print(f"  {box_top(header_label, label_color)}")

        # Wrap and print content
        if text_color == Colors.USER:
            # Plain text for user messages
            for line in wrap_text(content, content_width):
                print(f"  {box_line(line, text_color)}")
        else:
            # Markdown for Sigilla
            for line in render_markdown(content, text_color):
                print(f"  {box_line(line, '')}")

        print(f"  {box_bottom()}")

    def display_history(self, messages: List[dict]):
        if not messages:
            return

        print(f"\n{Colors.DIM}    ─── history ({len(messages)} messages) ───{Colors.RESET}\n")

        for msg in messages:
            timestamp = ""
            if msg.get("timestamp"):
                try:
                    dt = datetime.fromisoformat(msg["timestamp"].replace("Z", "+00:00"))
                    timestamp = dt.strftime("%H:%M")
                except:
                    pass

            if msg["type"] == "user":
                self.print_message_box("you", Colors.USER_LABEL, msg["content"], Colors.USER, timestamp)
            else:
                self.print_message_box("sigilla", Colors.SIGILLA, msg["content"], Colors.SIGILLA, timestamp)
            print()

        print(f"{Colors.DIM}    ─── end history ───{Colors.RESET}\n")

    def _get_continuation(self, width, line_number, is_soft_wrap):
        """Continuation prompt maintains box edge."""
        return ANSI(f'  {Colors.BOX}{Box.V}{Colors.RESET} ')

    async def get_input(self) -> Optional[str]:
        """Get multi-line input from user."""
        timestamp = datetime.now().strftime("%H:%M")

        print(f"\n  {box_top(f'you {Colors.DIM}{timestamp}{Colors.USER_LABEL}', Colors.USER_LABEL)}")

        try:
            text = await self.session.prompt_async(
                ANSI(f'  {Colors.BOX}{Box.V}{Colors.RESET} '),
                prompt_continuation=self._get_continuation,
                style=PROMPT_STYLE,
            )

            if text is None:
                print(f"  {box_bottom()}")
                return None

            print(f"  {box_bottom()}")
            return text

        except EOFError:
            print(f"  {box_bottom()}")
            return None
        except KeyboardInterrupt:
            print(f"\n  {box_bottom()}")
            return None

    async def display_response(self, content_gen):
        """Display response from Sigilla in a box."""
        timestamp = datetime.now().strftime("%H:%M")

        print(f"\n  {box_top(f'sigilla {Colors.DIM}{timestamp}{Colors.SIGILLA}', Colors.SIGILLA)}")

        full_text = ""
        thinking_shown = False

        async for data in content_gen:
            msg_type = data.get("type", "")

            if msg_type == "ack" and not thinking_shown:
                print(f"  {box_line('...', Colors.DIM)}", end="", flush=True)
                thinking_shown = True
                continue

            if msg_type == "assistant":
                message = data.get("message", {})
                content = message.get("content", [])
                for block in content:
                    if block.get("type") == "text":
                        full_text = block.get("text", "")

            if msg_type == "result":
                result_text = data.get("result", "")
                if result_text and not full_text:
                    full_text = result_text
                break

            if msg_type == "error":
                if thinking_shown:
                    print("\r\033[K", end="")
                print(f"  {box_line(data.get('error', 'Unknown error'), Colors.ERROR)}")
                print(f"  {box_bottom()}")
                return

        if thinking_shown:
            print("\r\033[K", end="")

        if full_text:
            for line in render_markdown(full_text, Colors.SIGILLA):
                print(f"  {box_line(line, '')}")

        print(f"  {box_bottom()}")

    async def run(self):
        self.print_header()

        try:
            await self.client.connect()
            status = await self.client.get_status()
            self.print_status(status)
        except FileNotFoundError:
            self.print_error(f"Socket not found at {SOCKET_PATH}")
            self.print_system("Is the sigilla daemon running? Try: systemctl status sigilla")
            return
        except ConnectionRefusedError:
            self.print_error("Connection refused by daemon")
            return
        except Exception as e:
            self.print_error(f"Connection failed: {e}")
            return

        self.print_system("enter = send, alt+enter = newline, ctrl+c = exit")
        self.print_system("/help for commands\n")

        try:
            while True:
                user_input = await self.get_input()

                if user_input is None:
                    break

                if not user_input.strip():
                    continue

                cmd = user_input.strip().lower()
                if cmd in ['/quit', '/exit', '/q']:
                    break

                if cmd == '/status':
                    status = await self.client.get_status()
                    self.print_status(status)
                    continue

                if cmd == '/help':
                    print()
                    self.print_system("commands:")
                    self.print_system("  /history  show recent conversation")
                    self.print_system("  /status   show session status")
                    self.print_system("  /quit     exit")
                    print()
                    self.print_system("input:")
                    self.print_system("  enter       send message")
                    self.print_system("  alt+enter   new line")
                    self.print_system("  ctrl+d      send (or exit if empty)")
                    self.print_system("  ctrl+c      exit")
                    print()
                    self.print_system("editing:")
                    self.print_system("  arrows      move cursor")
                    self.print_system("  ctrl+a/e    start/end of line")
                    self.print_system("  ctrl+w      delete word")
                    self.print_system("  ctrl+u      clear line")
                    print()
                    continue

                if cmd == '/history':
                    history_messages = self.load_session_history()
                    if history_messages:
                        self.display_history(history_messages)
                    else:
                        self.print_system("No conversation history found.\n")
                    continue

                try:
                    await self.display_response(self.client.send_message(user_input))
                except Exception as e:
                    self.print_error(f"Communication error: {e}")
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
            print(f"\n{Colors.DIM}    ✧{Colors.RESET}\n")
            await self.client.disconnect()


async def main():
    tui = SigillaTUI()
    await tui.run()


if __name__ == "__main__":
    asyncio.run(main())
