#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

required_files="
.github/workflows/build-unsigned-ipa.yml
OneStateAimTrainer.xcodeproj/project.pbxproj
OneStateAimTrainer.xcodeproj/xcshareddata/xcschemes/OneStateAimTrainer.xcscheme
OneStateAimTrainer/OneStateAimTrainerApp.swift
OneStateAimTrainer/Models.swift
OneStateAimTrainer/AimTrainerEngine.swift
OneStateAimTrainer/HomeView.swift
OneStateAimTrainer/TrainingView.swift
OneStateAimTrainer/Components.swift
OneStateAimTrainer/Info.plist
OneStateAimTrainer/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
OneStateAimTrainerTests/AimTrainerEngineTests.swift
Scripts/security_audit.sh
"

for relative_path in $required_files; do
    if [ ! -f "$root/$relative_path" ]; then
        echo "Missing: $relative_path" >&2
        exit 1
    fi
done

find "$root/OneStateAimTrainer/Assets.xcassets" -name Contents.json -print0 |
    xargs -0 -n 1 jq empty

for swift_file in "$root"/OneStateAimTrainer/*.swift; do
    basename=$(basename "$swift_file")
    if ! grep -q "$basename" "$root/OneStateAimTrainer.xcodeproj/project.pbxproj"; then
        echo "Not referenced by Xcode project: $basename" >&2
        exit 1
    fi
done

if command -v xcodebuild >/dev/null 2>&1; then
    xcodebuild -project "$root/OneStateAimTrainer.xcodeproj" -list >/dev/null
fi

echo "Project structure is valid."
