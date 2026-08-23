#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str, code: int = 2):
    print(message, file=sys.stderr)
    raise SystemExit(code)


def text(value):
    return value.strip() if isinstance(value, str) else ""


def main():
    if len(sys.argv) != 2:
        fail("usage: validate-host-config.py <config.json>")

    path = Path(sys.argv[1])
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"HOST_CONFIG_PARSE_FAILED:{exc}")

    if not isinstance(data, dict):
        fail("HOST_CONFIG_OBJECT_REQUIRED")

    if data.get("version") != 1:
        fail("HOST_CONFIG_VERSION_UNSUPPORTED")

    for key in ("orgId", "machineId", "agentId", "sessionId", "displayId"):
        if not text(data.get(key)):
            fail(f"HOST_CONFIG_IDENTITY_REQUIRED:{key}")

    displays = data.get("displays")
    if not isinstance(displays, list) or not displays:
        fail("HOST_CONFIG_DISPLAYS_REQUIRED")

    ids = set()
    primary_ids = []
    for index, display in enumerate(displays):
        if not isinstance(display, dict):
            fail(f"HOST_CONFIG_DISPLAY_OBJECT_REQUIRED:{index}")
        display_id = text(display.get("id"))
        if not display_id:
            fail(f"HOST_CONFIG_DISPLAY_ID_REQUIRED:{index}")
        if display_id in ids:
            fail(f"HOST_CONFIG_DISPLAY_DUPLICATE:{display_id}")
        ids.add(display_id)

        width = display.get("width")
        height = display.get("height")
        if not isinstance(width, int) or isinstance(width, bool) or width <= 0:
            fail(f"HOST_CONFIG_DISPLAY_WIDTH_INVALID:{display_id}")
        if not isinstance(height, int) or isinstance(height, bool) or height <= 0:
            fail(f"HOST_CONFIG_DISPLAY_HEIGHT_INVALID:{display_id}")
        if not isinstance(display.get("primary"), bool):
            fail(f"HOST_CONFIG_DISPLAY_PRIMARY_INVALID:{display_id}")
        if display["primary"]:
            primary_ids.append(display_id)

    if len(primary_ids) != 1:
        fail(f"HOST_CONFIG_PRIMARY_COUNT_INVALID:{len(primary_ids)}")

    selected = text(data.get("displayId"))
    if selected not in ids:
        fail(f"HOST_CONFIG_SELECTED_DISPLAY_NOT_FOUND:{selected}")

    selected_display = next(item for item in displays if text(item.get("id")) == selected)
    print(json.dumps({
        "ok": True,
        "orgId": data["orgId"],
        "machineId": data["machineId"],
        "agentId": data["agentId"],
        "sessionId": data["sessionId"],
        "displayId": selected,
        "primaryDisplayId": primary_ids[0],
        "width": selected_display["width"],
        "height": selected_display["height"],
        "displayCount": len(displays),
    }, separators=(",", ":")))


if __name__ == "__main__":
    main()
