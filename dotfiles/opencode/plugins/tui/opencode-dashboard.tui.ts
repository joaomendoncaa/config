// V2 TUI plugin: opencode2 discovers this from ~/.config/opencode/plugins/tui/.
// Writes the same schema-1 bridge records as the V1 plugin in plugins/ so
// bin/opencode-agents, bin/opencode-rename-window, and quickshell keep working.

import {
    mkdir,
    readFile,
    readlink,
    rename,
    unlink,
    writeFile,
} from "node:fs/promises";
import { basename, join } from "node:path";

const POLL_INTERVAL = 500;

async function ttyPath() {
    try {
        return await readlink("/proc/self/fd/0");
    } catch {
        return "";
    }
}

async function processStartTicks() {
    try {
        const stat = await readFile("/proc/self/stat", "utf8");
        const fields = stat
            .slice(stat.lastIndexOf(") ") + 2)
            .trim()
            .split(/\s+/);
        return fields[19] || "";
    } catch {
        return "";
    }
}

export default {
    id: "jmmm.opencode-dashboard",
    async setup(ctx) {
        const uid = typeof process.getuid === "function" ? process.getuid() : 0;
        const runtimeBase =
            process.env.XDG_RUNTIME_DIR || `/tmp/opencode-dashboard-${uid}`;
        const runtimeDir = join(runtimeBase, "opencode-dashboard");
        const nonce = crypto.randomUUID();
        const statePath = join(runtimeDir, `tui-${process.pid}-${nonce}.json`);
        const temporaryPath = `${statePath}.tmp`;
        const startedAt = Date.now();
        const tty = await ttyPath();
        const startTicks = await processStartTicks();

        const data = ctx.data;
        const router = ctx.ui.router;
        const runtimeByRoot = new Map();
        const erroredBySession = new Set();
        let disposed = false;
        let pendingRecord = null;
        let writeRunning = false;
        let activeWrite = Promise.resolve();

        await mkdir(runtimeDir, { recursive: true, mode: 0o700 });

        function runtimeState(rootID, session) {
            if (!runtimeByRoot.has(rootID)) {
                runtimeByRoot.set(rootID, {
                    turnStarted: false,
                    error: false,
                    busy: false,
                    state: "idle",
                    activityAt: session?.time?.updated || startedAt,
                });
            }
            return runtimeByRoot.get(rootID);
        }

        function pendingCount(sessionID) {
            const permissions = data.session.permission.list(sessionID);
            const forms = data.session.form.list(sessionID);
            return (permissions?.length ?? 0) + (forms?.length ?? 0);
        }

        function aggregateDiff(family) {
            const files = new Map();
            for (const session of family) {
                for (const diff of session?.revert?.files ?? []) {
                    if (!diff?.file) continue;
                    const previous = files.get(diff.file) || {
                        additions: 0,
                        deletions: 0,
                    };
                    files.set(diff.file, {
                        additions: Math.max(
                            previous.additions,
                            Number(diff.additions) || 0,
                        ),
                        deletions: Math.max(
                            previous.deletions,
                            Number(diff.deletions) || 0,
                        ),
                    });
                }
            }
            return Array.from(files.values()).reduce(
                (total, diff) => ({
                    additions: total.additions + diff.additions,
                    deletions: total.deletions + diff.deletions,
                }),
                { additions: 0, deletions: 0 },
            );
        }

        function deriveState(root, family) {
            const runtime = runtimeState(root.id, root);
            const running = family.some(
                (session) => data.session.status(session.id) === "running",
            );
            if (running && !runtime.busy) runtime.error = false;
            runtime.busy = running;
            if (running) {
                for (const session of family)
                    erroredBySession.delete(session.id);
            }
            const errored = family.some((session) =>
                erroredBySession.has(session.id),
            );
            const blocked =
                errored ||
                family.some((session) => pendingCount(session.id) > 0);
            let nextState = runtime.state;
            if (blocked) {
                runtime.turnStarted = true;
                nextState = "blocked";
            } else if (running) {
                runtime.turnStarted = true;
                runtime.error = false;
                nextState = "running";
            } else {
                nextState = runtime.turnStarted ? "pending" : "idle";
            }
            if (nextState !== runtime.state) {
                runtime.state = nextState;
                runtime.activityAt = Date.now();
            }
            return runtime;
        }

        function queueWrite(record) {
            if (disposed) return;
            pendingRecord = record;
            if (writeRunning) return;
            writeRunning = true;
            activeWrite = (async () => {
                while (pendingRecord && !disposed) {
                    const next = pendingRecord;
                    pendingRecord = null;
                    await writeFile(
                        temporaryPath,
                        `${JSON.stringify(next)}\n`,
                        { mode: 0o600 },
                    );
                    await rename(temporaryPath, statePath);
                }
            })()
                .catch(() => {})
                .finally(() => {
                    writeRunning = false;
                    if (pendingRecord && !disposed) queueWrite(pendingRecord);
                });
        }

        function degradedRecord(route, selectedSessionID) {
            const record = {
                schema: 1,
                pid: process.pid,
                processStartTicks: startTicks,
                nonce,
                startedAt,
                heartbeatAt: Date.now(),
                tty,
                version: ctx.app.version,
                route:
                    route.type === "session" ? "session" : route.type || "home",
            };
            if (selectedSessionID) record.selectedSessionID = selectedSessionID;
            return record;
        }

        function update() {
            if (disposed) return;
            let route;
            try {
                route = router.current() || { type: "home" };
            } catch {
                route = { type: "home" };
            }
            const selectedSessionID =
                route.type === "session" ? route.sessionID : "";
            if (!selectedSessionID) {
                queueWrite(degradedRecord(route));
                return;
            }

            const selected = data.session.get(selectedSessionID);
            if (!selected) {
                void data.session
                    .sync(selectedSessionID, { children: true })
                    .catch(() => {});
                queueWrite(degradedRecord(route, selectedSessionID));
                return;
            }

            const rootID = data.session.root(selectedSessionID);
            const root = data.session.get(rootID) ?? selected;
            const family = data.session
                .family(selectedSessionID)
                .map((sessionID) => data.session.get(sessionID))
                .filter(Boolean);
            if (family.length === 0) {
                void data.session
                    .sync(selectedSessionID, { children: true })
                    .catch(() => {});
                family.push(selected);
            }

            const runtime = deriveState(root, family);
            const diff = aggregateDiff(family);
            const directory = root.location?.directory || "";
            const rawRepo = basename(directory || "");
            const repo = rawRepo.replace(/@[^@]+$/, "");

            let branch = "";
            if (root.location) {
                const vcs = data.location.vcs.info(root.location);
                branch = vcs?.branch?.current ?? "";
                if (!vcs)
                    void data.location.vcs.sync(root.location).catch(() => {});
            }

            queueWrite({
                schema: 1,
                pid: process.pid,
                processStartTicks: startTicks,
                nonce,
                startedAt,
                heartbeatAt: Date.now(),
                tty,
                version: ctx.app.version,
                route: "session",
                selectedSessionID,
                rootSessionID: root.id,
                title: root.title || "New session",
                directory,
                repo,
                branch,
                state: runtime.state,
                additions: diff.additions,
                deletions: diff.deletions,
                activityAt: runtime.activityAt,
                createdAt: root.time?.created || 0,
            });
        }

        function touchSession(sessionID) {
            const rootID = data.session.root(sessionID);
            const runtime = rootID ? runtimeByRoot.get(rootID) : null;
            if (runtime) runtime.activityAt = Date.now();
        }

        const unsubscribes = [
            "session.execution.started",
            "session.execution.failed",
            "session.execution.interrupted",
            "session.step.failed",
            "session.retry.scheduled",
            "permission.asked",
            "permission.replied",
            "form.created",
            "form.replied",
            "form.cancelled",
        ].map((type) =>
            data.on(type, (event) => {
                const sessionID =
                    event?.data?.sessionID || event?.data?.form?.sessionID;
                if (
                    type === "session.execution.failed" ||
                    type === "session.step.failed" ||
                    type === "session.retry.scheduled"
                ) {
                    if (sessionID) erroredBySession.add(sessionID);
                } else if (
                    type === "session.execution.started" ||
                    type === "session.execution.interrupted"
                ) {
                    if (sessionID) erroredBySession.delete(sessionID);
                }
                if (sessionID) touchSession(sessionID);
                update();
            }),
        );

        const interval = setInterval(update, POLL_INTERVAL);
        update();

        return async () => {
            disposed = true;
            clearInterval(interval);
            for (const unsubscribe of unsubscribes) unsubscribe();
            pendingRecord = null;
            await activeWrite;
            await Promise.allSettled([
                unlink(statePath),
                unlink(temporaryPath),
            ]);
        };
    },
};
