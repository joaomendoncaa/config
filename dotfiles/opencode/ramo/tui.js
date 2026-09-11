// Reports the session on screen in this TUI to the ramo daemon, so the
// picker shows the exact session per tmux pane instead of guessing by
// recency. "" means "no session on screen", and the daemon shows its
// synthetic row for those panes.
//
// The current verdict is resent on a fixed interval because the daemon
// keeps reports in memory: a restart wipes them, and blank reports expire
// after 30s. Without the resend, both cases silently fall back to recency.

import { Plugin } from "@opencode/plugin/tui";
import net from "node:net";
import os from "node:os";
import path from "node:path";

const POLL_MS = 250;
const REPORT_INTERVAL_MS = 2000;

function socketPath() {
    const state =
        process.env.XDG_STATE_HOME && process.env.XDG_STATE_HOME.length > 0
            ? process.env.XDG_STATE_HOME
            : path.join(os.homedir(), ".local", "state");
    return path.join(state, "ramo", "report.sock");
}

function report(paneID, sessionID) {
    const body = Buffer.from(JSON.stringify({ pane_id: paneID, agent_session_id: sessionID }));
    const head = Buffer.alloc(4);
    head.writeUInt32LE(body.length, 0);

    const client = net.createConnection(socketPath(), () => {
        client.write(Buffer.concat([head, body]));
        client.end();
    });

    client.setTimeout(500, () => client.destroy());
    client.on("error", () => client.destroy());
}

function checkAndReport(state) {
    const route = state.router.current();
    const id = route?.type === "session" ? route.sessionID : undefined;
    const verdict = id ?? "";

    const now = Date.now();
    const isNew = verdict !== state.lastReport;
    const isDue = now - state.lastReportAt >= REPORT_INTERVAL_MS;

    if (isNew || isDue) {
        state.lastReport = verdict;
        state.lastReportAt = now;
        report(state.paneID, verdict);
    }
}

export default Plugin.define({
    id: "ramo",
    setup(context) {
        const paneID = process.env.TMUX_PANE;
        if (!paneID) return;

        if (typeof context?.ui?.router?.current !== "function") return;

        const state = { router: context.ui.router, paneID, lastReport: "", lastReportAt: 0 };

        const poll = setInterval(() => checkAndReport(state), POLL_MS);
        return () => clearInterval(poll);
    },
});
