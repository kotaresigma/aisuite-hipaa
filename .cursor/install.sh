#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the aisuite monorepo.
# Prepares: the aisuite Python library, the aisuite-js TypeScript SDK,
# and the React/Vite tracing viewer UI.
set -euo pipefail

# pip --user installs land here; make sure poetry is on PATH.
export PATH="$HOME/.local/bin:$PATH"

cd "$(dirname "$0")/.."

# --- Poetry (matches the version validated for this environment) ---
if ! command -v poetry >/dev/null 2>&1; then
  python3 -m pip install --user "poetry==2.4.1"
fi

# --- aisuite Python library: all provider extras + dev & test groups ---
# Mirrors CONTRIBUTING.md ("poetry install --with dev,test") plus every
# optional provider so the full test suite and examples are runnable.
poetry install --all-extras --with dev,test

# --- aisuite-js TypeScript SDK ---
# jest.config.ts requires ts-node, which the package.json does not declare,
# so install it explicitly (no-save) to keep `npm test` working.
(
  cd aisuite-js
  npm install
  npm install --no-save ts-node
)

# --- Tracing viewer UI (React/Vite) ---
# `npm run build` emits the bundle into aisuite/tracing/static/viewer, which
# the Python tracing viewer server serves.
(
  cd viewer-ui
  npm install
  npm run build
)

echo "aisuite dev environment ready."
