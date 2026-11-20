# OpenWorker tools/connectors hunt — 2026-11-20

Scope: agent tools (`git/files/shell/search/directories/subagent`), `email_tools` remaining sinks, `integration_tools` ID traversal for connectors **not** in prior batches, `web/fetch` distinct SSRF, `mcp/client`, `browser_automation`, `memory/tools`, `automation/tools`, `skills`, plus `ToolRegistry.execute` / `approval_for_tool` / `risk.classify` / `PermissionEngine`.

## Verdict: 1 NEW HIGH

### HIGH — Ungated `email_search` IMAP SEARCH-criteria CR/LF injection

**Attacker:** Anyone who can cause the agent to call `email_search` with attacker-influenced string args (Slack/email/web prompt injection into a session that has the email connector connected).

**Controls:** `from_address`, `to_address`, `subject`, and/or `text` tool arguments (model-chosen; no approval card).

**Path to sink:**
1. `email_search` is `kind=read` in `tool_defs.py` → `approval_for_tool` → `requires_approval=False`.
2. `risk.classify` → `RiskClass.READ` (no base override; metadata not requiring approval).
3. `PermissionEngine.evaluate` returns allow/`low risk` with `needs_user=False` in INTERACTIVE/PLAN.
4. `build_search_criteria` builds `FROM/TO/SUBJECT/TEXT {_quote(value)}`.
5. `_quote` escapes `\` and `"` only — **preserves CR/LF** inside the quoted string.
6. `imap.uid("SEARCH", criteria)` → `imaplib` concatenates args and `send`s with a trailing CRLF, so an embedded CRLF starts a **new IMAP command** on the wire.

**Impact:** Mailbox mutation while posing as a read-only search: `UID STORE` (delete flags), `CREATE`, `EXPUNGE`, etc., against the victim’s connected IMAP account — no write-tool approval.

**Evidence (file:line):**
- `platform/coworker/connectors/email_tools.py:214-215` `_quote`
- `platform/coworker/connectors/email_tools.py:232-264` `build_search_criteria`
- `platform/coworker/connectors/email_tools.py:450` `imap.uid("SEARCH", criteria)`
- `platform/coworker/connectors/tool_defs.py:165-170` `email_search` kind=`read`
- `platform/coworker/risk.py:39-53` `classify` → READ when `requires_approval` false
- `platform/coworker/permissions.py:131-133` non-consequential always allowed
- Wire PoC: `/opt/cursor/artifacts/imap-search-criteria-crlf-injection-evidence.txt`

**Distinctness:** Not IMAP **UID** CR/LF (`email_read`/`_fetch_message` uid arg). Not IMAP **folder** `_quote` on `SELECT`. New sink is SEARCH criteria fields on the ungated `email_search` tool.

---

## Shared mechanism note (not a new host finding)

`ToolRegistry.execute` (`tools/registry.py:62-66`) does `spec.func(**arguments)` with **no type coercion/validation**. Annotations like `issue_number: int` do not stop string `../` values. That is the root enabler for prior ID-traversal batches; no **new** host/token/object triple outside the excluded list was found (Linear uses GraphQL variables; Stripe/Apollo/Mixpanel/Amplitude use query/JSON params; Salesforce/Intercom tools absent; Hunter paths fixed; PostHog `project_id`/`base_url` from profile).

## Checked — no NEW MEDIUM+ in this pass

| Area | Result |
|------|--------|
| `git_log` / `files` / `search` / `directories` / `subagent` | Path scoping OK for files/grep; git argv + `--`; explore forced PLAN; no new RCE beyond prior git-filter / shell-allowlist classes |
| Shell allowlist (`find`/`python`/`cat`/`echo`) | Already reported — not re-reported |
| `browser_screenshot` kind=read overwrite | Already reported |
| `browser_upload_file` missing roots check | Previously noted (write-gated); not re-reported |
| `web_fetch` / `browser_read_url` SSRF | `file://` / `http+unix` rejected by httpx; classic localhost/metadata stays prior SSRF class |
| MCP `client.py` | No new command injection beyond stdio plant / mcp.json class |
| Memory WRITE-as-READ | Already reported |
| Automation standing grants / `update_scheduled_task` | No new complete chain beyond prior standing-rule findings |
| Skills | `load_skill` dict lookup only; `allowed_tools` unused |
| Integration ID `../` for new hosts | None outside excluded batches |
| Email SMTP header CRLF | `EmailMessage` rejects CR/LF in headers |
| Self-wake missing metadata | Ungated suspend/resume with note re-injection — impact below MEDIUM+ as standalone (PI persistence only) |
