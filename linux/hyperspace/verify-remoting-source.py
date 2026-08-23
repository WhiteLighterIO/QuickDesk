#!/usr/bin/env python3
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent
CONTRACT = ROOT / "remoting-source.contract.json"


def fail(message: str, code: int) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(code)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: verify-remoting-source.py <chromium-remoting-source-root>", 64)

    source = pathlib.Path(sys.argv[1]).resolve()
    if not source.is_dir():
        fail(f"HYPERSPACE_REMOTING_SOURCE_MISSING:{source}", 20)

    contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
    required = contract.get("requiredPaths") or []
    missing = [path for path in required if not (source / path).is_file()]
    if missing:
        for path in missing:
            print(f"missing:{path}", file=sys.stderr)
        fail("HYPERSPACE_REMOTING_SOURCE_CONTRACT_FAILED", 21)

    build_text = (source / "remoting/quickdesk/host/BUILD.gn").read_text(
        encoding="utf-8", errors="replace"
    )
    if "quickdesk_host" not in build_text:
        fail("HYPERSPACE_REMOTING_QUICKDESK_HOST_TARGET_MISSING", 22)

    print(json.dumps({
        "ok": True,
        "source": str(source),
        "requiredPathCount": len(required),
        "quickdeskHostBuild": True,
        "authorizationAuthority": "hyperspace",
    }, separators=(",", ":")))


if __name__ == "__main__":
    main()
