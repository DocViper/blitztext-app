#!/bin/bash
set -euo pipefail

# SprachZuText für Intel-Mac - Build & Run
# Inoffizieller Fork von cmagnussen/blitztext-app, nur für Macs mit Intel-Prozessor.
# Voraussetzungen: Xcode 16.2 oder neuer, xcodegen (brew install xcodegen)

RUN_AFTER=false
INSTALL_APP=false
CLEAN_BUILD=false
BUILD_CONFIGURATION="Release"
BUILD_ARCH="x86_64"

for arg in "$@"; do
    case "$arg" in
        --debug)
            BUILD_CONFIGURATION="Debug"
            ;;
        --run)
            RUN_AFTER=true
            ;;
        --install)
            INSTALL_APP=true
            ;;
        --release)
            BUILD_CONFIGURATION="Release"
            ;;
        --clean)
            CLEAN_BUILD=true
            ;;
        *)
            echo "Unbekannte Option: $arg"
            echo "Verwendung: ./build.sh [--install] [--run] [--release] [--debug] [--clean]"
            exit 1
            ;;
    esac
done

if [ "$(uname -m)" != "x86_64" ]; then
    echo "❌ Dieser Fork ist nur für Macs mit Intel-Prozessor gedacht."
    echo "   Auf Apple Silicon bitte das Original verwenden: https://github.com/cmagnussen/blitztext-app"
    exit 1
fi

verify_x86_64_app() {
    local app_path="$1"
    local app_name
    local binary_path
    local archs

    app_name="$(basename "$app_path" .app)"
    binary_path="$app_path/Contents/MacOS/$app_name"

    if [ ! -f "$binary_path" ]; then
        echo "❌ Konnte App-Binary nicht finden: $binary_path"
        exit 1
    fi

    archs="$(lipo -archs "$binary_path" 2>/dev/null || true)"

    if [[ " $archs " != *" x86_64 "* ]]; then
        echo "❌ Build enthält keinen x86_64-Teil. Gefunden: ${archs:-nichts}"
        file "$binary_path" 2>/dev/null || true
        exit 1
    fi

    echo "✅ Intel-Build verifiziert: $archs"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/BlitztextMac"
PROJECT_FILE="$PROJECT_DIR/BlitztextMac.xcodeproj"
WHISPERKIT_PATCH="$SCRIPT_DIR/patches/whisperkit-intel.patch"
# Keep DerivedData outside iCloud-synced folders (Desktop/Documents): the file
# provider adds com.apple.FinderInfo xattrs to bundles, which breaks codesign with
# "resource fork, Finder information, or similar detritus not allowed".
# (cmagnussen/blitztext-app PR #5)
DERIVED_DATA_PATH="$HOME/Library/Caches/blitztext-build/derivedData"
SOURCE_PACKAGES_PATH="$DERIVED_DATA_PATH/SourcePackages"
cd "$PROJECT_DIR"

if command -v xcodegen &> /dev/null; then
    echo "⚙️  Generiere Xcode-Projekt ..."
    xcodegen generate 2>&1
elif [ -d "$PROJECT_FILE" ]; then
    echo "⚠️  xcodegen nicht gefunden – nutze vorhandenes Xcode-Projekt."
elif command -v brew &> /dev/null; then
    echo "📦 Installiere xcodegen ..."
    brew install xcodegen
    echo "⚙️  Generiere Xcode-Projekt ..."
    xcodegen generate 2>&1
else
    echo "❌ xcodegen fehlt und Homebrew ist nicht installiert."
    echo "   Installiere xcodegen oder stelle sicher, dass $PROJECT_FILE vorhanden ist."
    exit 1
fi

# Swift-Pakete laden, damit WhisperKit für Intel gepatcht werden kann.
echo "📦 Lade Swift-Pakete ..."
xcodebuild -resolvePackageDependencies \
    -project BlitztextMac.xcodeproj \
    -scheme BlitztextMac \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" 2>&1 | tail -n 3

# WhisperKit rechnet auf Intel-Macs mit Float statt Float16 und stürzt sonst beim
# Diktieren ab. Der Patch korrigiert die Speicherzugriffe (patches/whisperkit-intel.patch).
WHISPERKIT_CHECKOUT="$SOURCE_PACKAGES_PATH/checkouts/argmax-oss-swift"
if [ ! -d "$WHISPERKIT_CHECKOUT" ]; then
    echo "❌ WhisperKit wurde nicht gefunden: $WHISPERKIT_CHECKOUT"
    exit 1
fi
if git -C "$WHISPERKIT_CHECKOUT" apply --reverse --check "$WHISPERKIT_PATCH" 2>/dev/null; then
    echo "✅ WhisperKit-Intel-Patch ist bereits angewendet."
elif git -C "$WHISPERKIT_CHECKOUT" apply --check "$WHISPERKIT_PATCH" 2>/dev/null; then
    chmod -R u+w "$WHISPERKIT_CHECKOUT"
    git -C "$WHISPERKIT_CHECKOUT" apply "$WHISPERKIT_PATCH"
    echo "✅ WhisperKit-Intel-Patch angewendet."
else
    echo "❌ Der WhisperKit-Patch passt nicht zur geladenen Version."
    echo "   Erwartet ist Version 0.18.0 (siehe BlitztextMac/project.yml)."
    exit 1
fi

# Bauen
BUILD_ACTIONS=(build)
if [ "$CLEAN_BUILD" = true ]; then
    BUILD_ACTIONS=(clean build)
fi

echo "🔨 Baue SprachZuText ..."
xcodebuild \
    -project BlitztextMac.xcodeproj \
    -scheme BlitztextMac \
    -destination 'platform=macOS' \
    -configuration "$BUILD_CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" \
    ONLY_ACTIVE_ARCH=YES \
    ARCHS="$BUILD_ARCH" \
    "${BUILD_ACTIONS[@]}"

# App finden
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$BUILD_CONFIGURATION/SprachZuText.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build fehlgeschlagen – keine App gefunden."
    exit 1
fi

verify_x86_64_app "$APP_PATH"

# Resources manuell ins Bundle kopieren (xcodegen kopiert sie nicht automatisch)
echo "📋 Kopiere Resources ..."
RESOURCES_DIR="$APP_PATH/Contents/Resources"
mkdir -p "$RESOURCES_DIR"
cp -f "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/" 2>/dev/null || true
cp -f "$PROJECT_DIR/Resources/menubar_icon.png" "$RESOURCES_DIR/" 2>/dev/null || true
cp -f "$PROJECT_DIR/Resources/menubar_icon@2x.png" "$RESOURCES_DIR/" 2>/dev/null || true

# Ziel vorab bestimmen: nur einmal kopieren, signieren und pruefen, ohne zweite Kopie
# im Projektordner (cmagnussen/blitztext-app PR #16).
if [ "$INSTALL_APP" = true ]; then
    APPS_DIR="/Applications"
    DEST="$APPS_DIR/SprachZuText.app"
    if [ ! -w "$APPS_DIR" ]; then
        echo "❌ /Applications ist nicht beschreibbar."
        echo "   Fuehre den Befehl mit passenden Rechten erneut aus oder ziehe die App manuell nach /Applications."
        exit 1
    fi
else
    DEST="$SCRIPT_DIR/SprachZuText.app"
fi

rm -rf "$DEST"
cp -R "$APP_PATH" "$DEST"
# iCloud or the file provider may have added xattrs again; codesign refuses them.
xattr -cr "$DEST" 2>/dev/null || true
codesign --force --deep --sign - "$DEST" 2>&1
verify_x86_64_app "$DEST"

RUN_TARGET="$DEST"

echo ""
echo "✅ Fertig! App liegt unter:"
echo "   $DEST"
echo ""
echo "Build-Typ: $BUILD_CONFIGURATION"
echo "Architektur: $BUILD_ARCH (Intel-Macs, macOS 14+)"
echo ""
echo "Naechste Schritte:"
echo "1. App starten"
echo "2. Mikrofon erlauben"
echo "3. Fuer direktes Einfuegen zusaetzlich Bedienungshilfen erlauben"
echo "   (nach jedem Neubau den alten Eintrag entfernen und die neue App hinzufuegen)"
echo "4. Lokales Whisper-Modell laden, optional einen Modell-Anbieter mit API-Key eintragen"
echo ""

# Optional: direkt starten
if [ "$RUN_AFTER" = true ]; then
    echo "🚀 Starte SprachZuText ..."
    open "$RUN_TARGET"
fi
