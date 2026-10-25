#!/usr/bin/env bash
set -euo pipefail

CACHE_ROOT="${NETLIFY_CACHE_DIR:-${HOME}/.cache}"
FLUTTER_HOME="${CACHE_ROOT}/flutter-stable"
mkdir -p "$(dirname "$FLUTTER_HOME")"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
else
  git -C "$FLUTTER_HOME" fetch --depth 1 origin stable
  git -C "$FLUTTER_HOME" reset --hard FETCH_HEAD
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter config --enable-web
flutter pub get
flutter build web --release
