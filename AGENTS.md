# AGENTS.md

## Cursor Cloud specific instructions

This is a multi-product monorepo. The dependency-refresh update script (Poetry root install,
`aisuite-js` npm install, OpenWorker `platform/.venv` bootstrap, and GUI `npm ci`) runs
automatically on startup, so the notes below focus on non-obvious run/test caveats — not install
steps. Standard commands live in `README.md`, `CONTRIBUTING.md`, `platform/surfaces/gui/README.md`,
and each `package.json`/`pyproject.toml`.

### Components

- `aisuite/` — flagship Python library (Poetry). Chat Completions + Agents API.
- `aisuite-js/` — TypeScript port (npm).
- `platform/` — OpenWorker desktop agent: FastAPI `coworker-server` + React/Tauri GUI.
- `viewer-ui/`, `examples/`, `cli/` — tracing viewer, demos, and a coding CLI (secondary).

### Python (`aisuite` root) — Poetry, non-obvious bits

- Poetry is installed to `~/.local/bin`, which is not on the default non-interactive PATH.
  Invoke it as `python3 -m poetry ...` (this is what the update script uses) or add
  `~/.local/bin` to PATH.
- Deps live in a Poetry venv; run everything through it, e.g.
  `python3 -m poetry run pytest -m "not integration"` (444 unit tests). Tests marked
  `integration` / `llm` / `mcp_server` need real provider keys and/or `npx` and cost money — skip
  them unless keys are provided.
- Lint (matches CI's Black): `black --check aisuite tests`. Black is pinned to `24.4.2`.
  Note: `tests/toolkits/test_files.py` is currently flagged by `24.4.2`; CI's `psf/black@stable`
  uses a newer Black, so `aisuite/` (source) is what must stay clean.

### `aisuite-js` — npm, non-obvious bits

- `jest.config.ts` requires `ts-node`, which is NOT listed in `package.json`. The update script
  installs it with `npm install --no-save ts-node`; without it `npm --prefix aisuite-js test` fails.
- Build: `npm --prefix aisuite-js run build`. Tests: `npm --prefix aisuite-js test` (117 tests).

### OpenWorker `platform` — non-obvious bits

- Bootstrap (`platform/packaging/setup_dev_env.sh`, run by the update script) creates
  `platform/.venv` and drops an `aisuite_src.pth` so `import aisuite` resolves from THIS checkout,
  not PyPI. Server binary: `platform/.venv/bin/coworker-server`. Requires the system package
  `python3.12-venv` (present in the base environment).
- Run the app in browser dev mode (two processes), NOT the Tauri desktop build:
  1. Server: `cd platform && ./.venv/bin/coworker-server --cwd <workspace> --model <model> --port 8765`
  2. GUI: `cd platform/surfaces/gui && npm run dev`
  The Tauri flow (`npm run tauri dev`) needs Rust + Linux webkit2gtk libs and is unnecessary for
  testing.
- The Vite dev server binds to `localhost:1420` on IPv6 (`::1`), so use `http://localhost:1420`
  (curl to `127.0.0.1:1420` fails). `vite.config.ts` pins port 1420 with `strictPort` — the GUI
  README's "5173" is stale.
- Keyless local runs: the `ollama:` model prefix routes to an OpenAI-compatible endpoint at
  `localhost:11434/v1` with no API key. Point it at any local OpenAI-compatible server and launch
  with `--model ollama:<name>` to exercise a real chat turn without a cloud key. Otherwise supply
  `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` (env or Settings ▸ Models).

### GUI unit tests

- Typecheck + unit: `cd platform/surfaces/gui && npx tsc --noEmit && npx vitest run` (63 tests).

### Chrome (browser / computer-use testing)

- Google Chrome is installed as `google-chrome-stable` (Google apt repo). The desktop
  launcher uses `/usr/local/bin/google-chrome` (wrapper around the stable binary).
- To update: `sudo apt-get update && sudo apt-get install -y google-chrome-stable`, then
  `google-chrome-stable --version`.
