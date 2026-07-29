"""Kokoro-82M TTS CLI (onnxruntime), invoked by hermes as a `type: command` TTS provider."""

import argparse
import sys
from pathlib import Path

import soundfile as sf
from kokoro_onnx import Kokoro


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--voices", required=True)
    parser.add_argument("--voice", default="af_bella")
    parser.add_argument("--speed", default="")
    parser.add_argument("--lang", default="en-us")
    args = parser.parse_args()

    text = Path(args.text_file).read_text(encoding="utf-8").strip()
    if not text:
        print("empty input text", file=sys.stderr)
        return 1

    kokoro = Kokoro(args.model, args.voices)
    samples, sample_rate = kokoro.create(
        text,
        voice=args.voice,
        speed=float(args.speed) if args.speed else 1.0,
        lang=args.lang,
    )

    sf.write(args.output, samples, sample_rate)
    return 0


if __name__ == "__main__":
    sys.exit(main())
