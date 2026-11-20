# aisuite-hipaa remaining surfaces hunt — 2026-11-20

**Verdict: NONE** (no NEW MEDIUM+ with complete E2E chain)

## Scope

Surfaces outside the OpenWorker coworker sidecar HTTP API:

- `aisuite/` Python library (providers, agents, mcp, framework, toolkits)
- `aisuite-js/`
- `cli/py/aisuite-code-cli/`
- `examples/chat-ui/`
- `platform/surfaces/gui` besides already-reported HTML artifact XSS (other iframe/webview sinks, Tauri, file protocol)
- `.github/workflows`
- `viewer-ui/`

Skipped as already reported: chat-ui dotenv base_url credential theft; git config/diff filter/textconv/status filter-clean RCE; github pull hooks smudge; HTML artifact `srcDoc` XSS.

## Result

No new MEDIUM+ findings. High-risk sinks rechecked against prior reports; candidates either duplicate those chains or fail to complete an attacker→impact path on the default product path (e.g. VIEWER_HTML attribute XSS only on non-default fallback UI; Azure `api_version` CRLF rejected by urllib `InvalidURL`).

## Evidence highlights

- Only GUI iframe/srcDoc: `platform/surfaces/gui/src/components/RightRail.tsx:366-370` (already reported)
- Tauri capabilities: pick_folder / autostart / keep-awake / dictation / updater only
- Workflows: no `pull_request_target`; release secrets only on tag/`workflow_dispatch`
- Packaged React viewer present: `aisuite/tracing/static/viewer/index.html` (VIEWER_HTML is fallback)

JSON: `security-reviews/aisuite-hipaa-remaining-surfaces-hunt-2026-11-20---flagged-vulnerabilities.json`
