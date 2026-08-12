#!/bin/bash
# Runs every suite against an available iOS Simulator.
#
# The suites use Quick and Nimble, which need a simulator host, so this is
# `xcodebuild test` rather than `swift test`. CI runs this same file.
#
# Set TEST_DESTINATION to override the auto-picked simulator, e.g.
#   TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' Scripts/test.sh
# Any further arguments are passed through to xcodebuild.
set -euo pipefail

cd "$(dirname "$0")/.."

DESTINATION="${TEST_DESTINATION:-}"

if [ -z "$DESTINATION" ]; then
  # Newest installed iOS runtime, first available iPhone on it. Picking by
  # UDID rather than by name keeps this working as Xcode's device set changes.
  UDID="$(xcrun simctl list devices available --json | python3 -c '
import json, sys

best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if ".SimRuntime.iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in runtime.rsplit("iOS-", 1)[1].split("-"))
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            if best is None or version > best[0]:
                best = (version, device["udid"])
            break
print(best[1] if best else "")
')"

  if [ -z "$UDID" ]; then
    echo "No available iOS simulator. Install one from Xcode > Settings > Components." >&2
    exit 1
  fi

  DESTINATION="platform=iOS Simulator,id=$UDID"
fi

echo "Test destination: $DESTINATION"

xcodebuild test \
  -scheme ModaalFoundationCore-Package \
  -destination "$DESTINATION" \
  "$@"
