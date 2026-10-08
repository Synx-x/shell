pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Per-pane agent state rebuilt from the events written by the Claude Code hook
// caelestia_agent_events.py, keyed by herdr pane id.
Singleton {
    id: root

    // paneId -> {
    //   status: working | blocked | question | idle | "",
    //   ticker, permission, tool, toolDetail,
    //   questions: [{ question, options: [{ label, description }] }] | null,
    //   turnStart, files: [{ name, added, removed }], added, removed,
    //   summary, doneAt
    // }
    property var byPane: ({})

    function get(paneId: string): var {
        return byPane[paneId] ?? null;
    }

    function statusFor(paneId: string): string {
        return byPane[paneId]?.status ?? "";
    }

    function base(file: string): string {
        return file ? file.split("/").pop() : "";
    }

    function describe(e: var): string {
        const file = base(e.file);
        if (["Edit", "Write", "MultiEdit"].includes(e.event))
            return `Edited ${file} +${e.added ?? 0} −${e.removed ?? 0}`;
        if (e.event === "Read")
            return `Reading ${file}`;
        if (e.event === "Bash")
            return `Running ${(e.text || "").split("\n")[0]}`;
        if (e.event === "Prompt")
            return "Thinking";
        return e.tool ? `${e.tool} ${file}`.trim() : "";
    }

    function fresh(): var {
        return {
            status: "",
            ticker: "",
            permission: "",
            tool: "",
            toolDetail: "",
            questions: null,
            turnStart: 0,
            files: [],
            added: 0,
            removed: 0,
            summary: "",
            doneAt: 0
        };
    }

    function startTurn(s: var, ts: real): void {
        s.turnStart = ts;
        s.files = [];
        s.added = 0;
        s.removed = 0;
        s.summary = "";
        s.doneAt = 0;
    }

    function apply(s: var, e: var): void {
        switch (e.event) {
        case "Prompt":
            startTurn(s, e.ts);
            s.status = "working";
            s.ticker = describe(e);
            s.questions = null;
            s.permission = "";
            break;
        case "Question":
            try {
                s.questions = JSON.parse(e.text || "[]");
            } catch (err) {
                s.questions = [];
            }
            s.status = "question";
            s.ticker = "Asked a question";
            break;
        case "Answered":
            s.questions = null;
            s.status = "working";
            break;
        case "Permission":
            s.status = "blocked";
            s.permission = e.text || "";
            break;
        case "Waiting":
            // The idle reminder also fires while a question is open: keep the question
            if (s.status !== "question") {
                s.status = "idle";
                s.permission = "";
            }
            break;
        case "Stop":
            s.status = "idle";
            s.permission = "";
            s.questions = null;
            s.summary = e.text || "";
            s.doneAt = e.ts;
            s.ticker = "Done";
            break;
        default:
            if (s.status === "idle" && s.doneAt)
                startTurn(s, e.ts);
            if (!s.turnStart)
                s.turnStart = e.ts;
            s.status = "working";
            s.permission = "";
            s.tool = e.tool || e.event;
            s.toolDetail = e.text || e.file || "";
            s.ticker = describe(e) || s.ticker;
            if (["Edit", "Write", "MultiEdit"].includes(e.event)) {
                const name = base(e.file);
                const f = s.files.find(x => x.name === name);
                if (f) {
                    f.added += e.added ?? 0;
                    f.removed += e.removed ?? 0;
                } else {
                    s.files.push({
                        name: name,
                        added: e.added ?? 0,
                        removed: e.removed ?? 0
                    });
                }
                s.added += e.added ?? 0;
                s.removed += e.removed ?? 0;
            }
        }
    }

    function parse(text: string): void {
        const map = {};
        for (const line of text.trim().split("\n")) {
            let e;
            try {
                e = JSON.parse(line);
            } catch (err) {
                continue;
            }
            if (!e.pane || !e.event)
                continue;
            apply(map[e.pane] ?? (map[e.pane] = fresh()), e);
        }
        byPane = map;
    }

    FileView {
        path: `${Paths.state}/agents.jsonl`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}
