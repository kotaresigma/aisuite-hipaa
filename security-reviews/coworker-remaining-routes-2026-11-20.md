# Coworker remaining REST surfaces hunt (2026-11-20)

Commit: `1b4bbf303ec21968230b1ec869a144d054e9b3c4`
Branch: `cursor/vulnerability-findings-persistence-6ffa`
Scope: Hunt list in `platform/coworker/server/app.py` + `manager.py` handlers (connections, roots, workspaces, chat/completions, mcp-connect, PATCH tools, OAuth callbacks, cloud/login, settings, inspect-pdf, inject_inbound, browser/screenshot, web-search, PATCH sessions, audit/memory, finalize).

## Verdict: 2 NEW HIGH (vs exclude list + same-day catalog)

### 1. HIGH — Unauthenticated `PATCH /v1/connectors/{name}/tools` re-enables ungated read tools

Victim disables connector read tools (Gmail/HubSpot/Notion/…) as a privacy control. Attacker (localhost Origin / missing Origin) PATCHes `enabled: {tool: true}`. New sessions build engines via `_enabled_connector_tools` → tools return. Read tools have `approval_for_tool=False`, so mailbox/CRM reads run with no approval card.

**Attack path**
1. Gmail (or other) connector connected; user disables `gmail_get_message` / `gmail_search_messages`.
2. `PATCH /v1/connectors/gmail/tools` `{"enabled":{"gmail_get_message":true,"gmail_search_messages":true}}`.
3. Attacker opens a new WS session (`agent=cowork`) or waits for a new Slack @mention session (fresh `build_engine`).
4. Drive `gmail_search_messages` / `gmail_get_message` — no approval.
5. Contents land in transcript / standing `send_message` on mention threads.

**Evidence:** `app.py:1096-1101`, `manager.py:1064-1067`, `tool_defs.py:1138-1159`, `agent.py:84-98`, `approval_for_tool` read→False. PoC: `security-reviews/coworker-remaining-routes-tools-reenable-poc.txt`.

**Distinct from:** Gmail filters / HubSpot hidden-fields; allow_deliver; inbox AUTO. Prior near-miss said "still needs approval" — false for `kind=read`.

### 2. HIGH — Unauthenticated `POST /v1/sessions/{id}/connections` unmutes persona-muted connectors

Persona default mutes a connected connector (no tools in engine). Attacker sets session override `enabled:true`. `effective_connectors` includes it for new engines → all still-enabled tools (including ungated reads) return for that session.

**Attack path**
1. Persona defaults mute `gmail` (or similar).
2. `POST /v1/sessions/{sid}/connections` `{"connector":"gmail","enabled":true}`.
3. New engine for `sid` intersects `connector_filter` with unmuted set.
4. Same ungated read / drive chain as (1).

**Evidence:** `app.py:325-338`, `manager.py:433-454`, `connections.py:158-179`.

**Distinct from:** (1) is per-tool flags; this bypasses the persona/session mute layer.

### Already catalogued (re-confirmed, not re-filed)

- MEDIUM `POST /v1/chat/completions` key abuse
- MEDIUM `POST /v1/settings/model-key` overwrite

## Ruled out / not re-reported

| Surface | Outcome |
|---|---|
| POST/DELETE roots | Already HIGH (arbitrary FS roots); not re-filed |
| scratch-base | Already CRITICAL rmtree; not re-filed |
| workspaces/open\|pick | mkdir/dialog only; bind is WS workspace/roots |
| mcp-connect | Seeds curated `mcp_url` + pinned tools; per-tool approval for writes; OAuth URL retarget is PATCH mcp (excluded) |
| GET /mcp/oauth/callback | SDK state compare after deliver; DoS only |
| GET /auth/callback | PKCE pending map holds |
| POST /oauth/callback app_state CSRF | Already HIGH; confirmed, not re-filed |
| cloud/login | Returns authorize_url under localhost trust; no new plant primitive |
| inspect-pdf | data-URL only |
| inject_inbound | `COWORKER_DEBUG_INJECT=1` only |
| browser/screenshot REST | Returns shared blank-context PNG / can pop Chromium; tool path overwrite already HIGH |
| web-search set | Enum providers; blank key wipes profile (integrity only, below bar vs model-key) |
| PATCH sessions | title/pin/archive only |
| GET audit/memory | Read exposure / nested sanitize gap previously catalogued; no new mutating impact |
| finalize automations | Status/metadata only |
| DELETE roots | Revocation only |
