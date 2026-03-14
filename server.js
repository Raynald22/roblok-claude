const express = require("express");
const app = express();
app.use(express.json({ limit: "50mb" }));

// In-memory workspace store: sessionId -> { scripts, messages }
const workspaces = new Map();

const SYSTEM_PROMPT = `You are an expert Roblox Studio AI assistant, like Cursor or GitHub Copilot but for Roblox.

You have full access to the user's entire Roblox project — all scripts are provided below.

Your behavior:
- READ and UNDERSTAND all scripts before answering
- When asked to add a feature, find the RIGHT file to edit (don't always create new ones)
- When asked to fix a bug, trace it through multiple files if needed
- When generating or editing code, always output the COMPLETE file content (not just the changed part)
- Mention which file(s) you are editing/creating by their exact path
- Use proper Roblox Luau: services via game:GetService(), RemoteEvents for client-server, pcall for safety
- Add clear comments explaining what changed and why

Format for edits:
1. Briefly explain what you found and what you'll do
2. Output code block with the complete file content
3. State the file path at the top as a comment: -- PATH: ServerScriptService.MyScript`;

// ── SYNC all scripts from Roblox ──────────────────────────────
app.post("/sync", (req, res) => {
  const { sessionId, scripts } = req.body;
  if (!sessionId || !Array.isArray(scripts)) {
    return res.status(400).json({ error: "sessionId and scripts required" });
  }

  const existing = workspaces.get(sessionId) || { scripts: [], messages: [] };
  existing.scripts = scripts;
  existing.lastUpdated = Date.now();
  workspaces.set(sessionId, existing);

  console.log(`[sync] session=${sessionId} scripts=${scripts.length}`);
  res.json({ ok: true, count: scripts.length });
});

// ── Update single script (on change) ─────────────────────────
app.post("/sync/update", (req, res) => {
  const { sessionId, script } = req.body;
  const ws = workspaces.get(sessionId);
  if (!ws) return res.status(404).json({ error: "session not found, re-sync" });

  const idx = ws.scripts.findIndex(s => s.path === script.path);
  if (idx >= 0) ws.scripts[idx] = script;
  else ws.scripts.push(script);
  ws.lastUpdated = Date.now();

  res.json({ ok: true });
});

// ── Chat ──────────────────────────────────────────────────────
app.post("/chat", async (req, res) => {
  const { sessionId, messages } = req.body;
  if (!sessionId || !Array.isArray(messages)) {
    return res.status(400).json({ error: "sessionId and messages required" });
  }

  const ws = workspaces.get(sessionId) || { scripts: [], messages: [] };

  // Build full project context
  let projectContext = "";
  if (ws.scripts.length > 0) {
    const lines = ["\n\n━━━ FULL PROJECT (" + ws.scripts.length + " scripts) ━━━"];
    for (const s of ws.scripts) {
      lines.push(`\n[${s.kind}] ${s.path}\n\`\`\`lua\n${s.source}\n\`\`\``);
    }
    projectContext = lines.join("\n");
  } else {
    projectContext = "\n\n(No scripts synced yet — user hasn't opened a place or synced.)";
  }

  // Save conversation
  ws.messages = messages;
  workspaces.set(sessionId, ws);

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": process.env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 4096,
        system: SYSTEM_PROMPT + projectContext,
        messages: messages,
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Anthropic error:", JSON.stringify(data));
      return res.status(500).json({ error: data });
    }

    const reply = data.content[0].text;
    res.json({ reply });
  } catch (err) {
    console.error("Server error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ── Clear session ─────────────────────────────────────────────
app.post("/clear", (req, res) => {
  const { sessionId } = req.body;
  if (sessionId) workspaces.delete(sessionId);
  res.json({ ok: true });
});

app.get("/health", (_, res) => res.json({ ok: true }));

// Cleanup old sessions every hour
setInterval(() => {
  const cutoff = Date.now() - 3600000;
  for (const [id, ws] of workspaces.entries()) {
    if (ws.lastUpdated < cutoff) workspaces.delete(id);
  }
}, 3600000);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Proxy running on port ${PORT}`));
