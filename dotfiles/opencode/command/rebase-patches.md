---
description: Rebase jm/patches onto main, resolve conflicts, verify, then rebuild the app
---

Run `clankers-rebase` (it works on `/home/joao/lab/clankers`).

- If it stops on conflicts: read both sides of each conflicted file, keep our fork's intent, `git add` the resolved files, then rerun `clankers-rebase --continue`. Repeat until it finishes.
- If it fails before the rebase starts (dirty tree, fetch, non-fast-forward main), fix the cause and rerun.
- Never call `clankers-rebuild` yourself; `clankers-rebase` runs it only after the rebase succeeds, dependencies are installed, and the built server loads.
- After it finishes, confirm the relaunch in `/home/joao/.local/share/opencode/shell/clankers.log`, run `node apps/server/dist/bin.mjs --version` from the repo, and report the new head SHA.
- Do not push unless asked.
