# OpenCode Dashboard v2 Migration

The dashboard consumes a normalized snapshot from `bin/opencode-agents`. QML must
continue to depend on that contract rather than on OpenCode storage or APIs
directly.

## Current Bridge

OpenCode 1.18.12 does not expose attached TUI clients or each client's selected
session through the server API. The configured TUI plugin therefore writes one
ephemeral record per client under `$XDG_RUNTIME_DIR/opencode-dashboard/`.

The collector currently owns:

- live TUI reconciliation and root-session deduplication;
- compatibility fallback through `/proc`, the OpenCode log, and SQLite for TUIs
  started before the plugin was installed;
- terminal and Tmux focus routing;
- the stable JSON snapshot consumed by `Adapters/OpenCodeAgentAdapter.qml`.

The adapter normalizes OpenCode-specific process, session, focus, branding, and
quota details. `AgentService.qml` is the shell-facing facade; bar modules only
depend on its generic agent and optional usage interfaces.

The cloud usage helper is separate. Local OpenCode v2 session APIs do not replace
the authenticated quota source used by `bin/opencode-usage`, which queries
`https://opencode.ai/zen/go/v1/usage` with the API key from
`~/.local/share/opencode/account.json`. The response exposes rolling, weekly, and
monthly usage percentages and reset timestamps only; the API has no account
balance, so the bar does not display one.

## Expected v2 Replacements

| Current responsibility | v2 replacement when stable |
| --- | --- |
| SQLite session metadata | Session list/detail APIs |
| SQLite and TUI diff snapshots | Session diff API and events |
| Status inference fallback | Session status/active APIs |
| Permission, question, retry, and error tracking | Typed snapshots and event stream |
| Git branch polling | VCS/workspace APIs and events |
| Missed durable session events | Session history/cursor APIs |
| Per-TUI backend event bridge | Persistent service SSE adapter |

OpenCode v2 preview APIs still do not identify attached TUI processes or expose
the route selected by each client. Keep the small TUI route bridge, `/proc`
liveness reconciliation, and Tmux focus adapter until an attached-client API
exists.

## Migration Sequence

1. Add a capability-gated v2 adapter behind the collector snapshot schema.
2. Connect to one discovered persistent service and buffer SSE events.
3. Reconcile sessions, active states, pending interactions, diffs, projects,
   workspaces, and VCS data before applying buffered events.
4. Dual-run the v1 and v2 adapters and compare normalized snapshots across idle,
   running, retry, permission, question, error, abort, and restart transitions.
5. Remove SQLite and log fallback first, then Git polling and backend event files.
6. Retain TUI selection records and focus routing until OpenCode exposes equivalent
   client topology.

Treat preview `/api/*`, workspace, durable-history, and plugin-v2 surfaces as
unstable. Version- and capability-check them instead of keying migration solely
to an OpenCode version number.
