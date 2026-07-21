#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$root/OneStateAimTrainer"
info_plist="$source_dir/Info.plist"
project_file="$root/OneStateAimTrainer.xcodeproj/project.pbxproj"

fail() {
    echo "Security audit failed: $1" >&2
    exit 1
}

if find "$source_dir" -name '*.swift' -exec grep -En 'URLSession|NSURLConnection|NWConnection|WKWebView|SFSafariViewController|UIApplication\.shared\.open|UIPasteboard|CLLocationManager|PHPhotoLibrary|CNContactStore|AVCapture|HKHealthStore|ATTrackingManager' {} +; then
    fail "networking, external navigation, clipboard, tracking, or protected-data API found"
fi

if grep -En 'NS[A-Za-z]+UsageDescription|NSAppTransportSecurity|UIBackgroundModes' "$info_plist"; then
    fail "privacy-sensitive permission or background capability found"
fi

if grep -En 'PBXShellScriptBuildPhase|XCRemoteSwiftPackageReference|XCSwiftPackageProductDependency|CODE_SIGN_ENTITLEMENTS' "$project_file"; then
    fail "unexpected build script, package dependency, or entitlement found"
fi

if find "$root" \( -name '*.entitlements' -o -name '*.framework' -o -name '*.xcframework' -o -name 'Package.resolved' -o -name 'Podfile' -o -name 'Cartfile' \) -print | grep -q .; then
    fail "entitlement, bundled framework, or third-party dependency manifest found"
fi

if find "$source_dir" -name '*.swift' -exec grep -Ein '(api[_-]?key|client[_-]?secret|access[_-]?token|password)[[:space:]]*[:=]' {} +; then
    fail "possible embedded credential found"
fi

echo "Security audit passed: no network/data APIs, protected permissions, entitlements, third-party dependencies, build scripts, or embedded credentials found."
