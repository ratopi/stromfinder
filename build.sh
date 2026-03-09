#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ELM_DIR="$SCRIPT_DIR/elm"
PUBLIC_DIR="$SCRIPT_DIR/public"

echo "Compiling Elm (optimized)..."
cd "$ELM_DIR"
elm make src/Main.elm --optimize --output="$PUBLIC_DIR/app.js"

echo "Done → $PUBLIC_DIR/app.js"

