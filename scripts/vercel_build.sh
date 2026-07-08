#!/usr/bin/env bash
set -euo pipefail

if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  flutter build web --release --no-wasm-dry-run
  exit 0
fi

echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter config --enable-web
flutter precache --web
flutter pub get
flutter build web --release --no-wasm-dry-run
