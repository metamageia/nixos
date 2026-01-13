#!/usr/bin/env python3
"""
Sigilla CLI - Command-line interface for automated heartbeats

This script is used by systemd timers to send prompts to the
persistent Sigilla session. It connects, sends a prompt, and
prints the response to stdout (for logging).
"""

import asyncio
import json
import os
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

SOCKET_PATH = os.environ.get("SIGILLA_SOCKET", "/run/sigilla/sigilla.sock")


async def send_prompt(prompt: str, timeout: float = 300) -> str:
    """Send a prompt to Sigilla and return the response."""
    try:
        reader, writer = await asyncio.open_unix_connection(SOCKET_PATH)
    except FileNotFoundError:
        print(f"Error: Socket not found at {SOCKET_PATH}", file=sys.stderr)
        print("Is the sigilla daemon running?", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error connecting to daemon: {e}", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Send message
        request = {"type": "message", "content": prompt}
        writer.write((json.dumps(request) + "\n").encode())
        await writer.drain()
        
        # Collect response
        full_text = ""
        
        while True:
            try:
                line = await asyncio.wait_for(reader.readline(), timeout=timeout)
                if not line:
                    break
                    
                data = json.loads(line.decode().strip())
                msg_type = data.get("type", "")
                
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
                    print(f"Error from daemon: {data.get('error')}", file=sys.stderr)
                    sys.exit(1)
                    
            except asyncio.TimeoutError:
                print("Timeout waiting for response", file=sys.stderr)
                sys.exit(1)
                
        return full_text
        
    finally:
        writer.close()
        try:
            await writer.wait_closed()
        except:
            pass


def get_prompt_with_timestamp(prompt_file: str) -> str:
    """Read prompt from file and prepend timestamp."""
    try:
        with open(prompt_file, 'r') as f:
            prompt = f.read()
    except FileNotFoundError:
        print(f"Error: Prompt file not found: {prompt_file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading prompt file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Add timestamp
    tz = ZoneInfo("America/Chicago")
    now = datetime.now(tz)
    timestamp = now.strftime("%A, %B %d, %Y at %I:%M %p %Z")
    
    return f"Current date and time in El Dorado, Kansas, USA (Central Time): {timestamp}\n\n{prompt}"


async def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: sigilla-cli <prompt-file>", file=sys.stderr)
        print("       sigilla-cli --raw '<prompt text>'", file=sys.stderr)
        sys.exit(1)
    
    if sys.argv[1] == "--raw":
        if len(sys.argv) < 3:
            print("Error: --raw requires a prompt argument", file=sys.stderr)
            sys.exit(1)
        prompt = sys.argv[2]
    elif sys.argv[1] == "--status":
        # Quick status check
        try:
            reader, writer = await asyncio.open_unix_connection(SOCKET_PATH)
            request = {"type": "status"}
            writer.write((json.dumps(request) + "\n").encode())
            await writer.drain()
            line = await reader.readline()
            data = json.loads(line.decode().strip())
            print(json.dumps(data, indent=2))
            writer.close()
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        return
    else:
        prompt = get_prompt_with_timestamp(sys.argv[1])
    
    response = await send_prompt(prompt)
    print(response)


if __name__ == "__main__":
    asyncio.run(main())
