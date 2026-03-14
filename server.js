const express = require("express");
const app = express();
app.use(express.json({ limit: "50mb" }));

const workspaces = new Map();

const SYSTEM_PROMPT = `You are an expert Roblox Studio AI assistant, like Cursor AI but for Roblox.

You have full access to the user's entire project. When responding:

1. First, briefly explain what you plan to do (1-3 sentences max).

2. If you need to CREATE or EDIT files, output them using this EXACT format for each file:

<<<FILE>>>
PATH: ServerScriptService.KillBrick
ACTION: edit
<<<CODE>>>
-- full file content here
<<<END>>>

3. You can output multiple FILE blocks if editing multiple files.

4. ACTION can be: "edit" (modify existing) or "create" (new file).

5. Always output the COMPLETE file content, not just the changed lines.

6. After all FILE blocks, add a short summary of what changed.

Rules:
- Use proper Roblox Luau (typed Lua)
- Use game:GetService() for all services
- Use RemoteEvents for client-server communication
- Handle errors with pcall where appropriate
- Add comments explaining non-obvious logic`;

const workspaceSessions = new Map();

app.post("/sync", (req, res) => {
  const { sessionId, scripts } = req.body;
  if (!sessionId || !Array.isArray(scripts)) {
    return res.status(400).json({ error: "sessionId and scripts required" });
  }
  const existing = workspaceSessions.get(sessionId) || { scripts: [], messages: [] };
  existing.scripts = scripts;
  existing.lastUpdated = Date.now();
  workspaceSessions.set(sessionId, existing);
  console.log(`[sync] session=${sessionId} scripts=${scripts.length}`);
  res.json({ ok: true, count: scripts.length });
});

app.post("/sync/update", (req, res) => {
  const { sessionId, script } = req.body;
  const ws = workspaceSessions.get(sessionId);
  if (!ws) return res.status(404).json({ error: "session not found, re-sync" });
  const idx = ws.scripts.findIndex(s => s.path === script.path);
  if (idx >= 0) ws.scripts[idx] = script;
  else ws.scripts.push(script);
  ws.lastUpdated = Date.now();
  res.json({ ok: true });
});

app.post("/chat", async (req, res) => {
  const { sessionId, messages } = req.body;
  if (!sessionId || !Array.isArray(messages)) {
    return res.status(400).json({ error: "sessionId and messages required" });
  }

  const ws = workspaceSessions.get(sessionId) || { scripts: [], messages: [] };

  let projectContext = "";
  if (ws.scripts.length > 0) {
    const lines = [`\n\n━━━ FULL PROJECT (${ws.scripts.length} scripts) ━━━`];
    for (const s of ws.scripts) {
      lines.push(`\n[${s.kind}] ${s.path}\n\`\`\`lua\n${s.source}\n\`\`\``);
    }
    projectContext = lines.join("\n");
  }

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
        messages,
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      console.error("Anthropic error:", JSON.stringify(data));
      return res.status(500).json({ error: data });
    }

    const rawReply = data.content[0].text;

    // Parse FILE blocks from response
    const edits = [];
    const fileRegex = /<<<FILE>>>\s*PATH:\s*([^\n]+)\s*ACTION:\s*([^\n]+)\s*<<<CODE>>>([\s\S]*?)<<<END>>>/g;
    let match;
    while ((match = fileRegex.exec(rawReply)) !== null) {
      edits.push({
        path:    match[1].trim(),
        action:  match[2].trim(), // "edit" or "create"
        newCode: match[3].trim(),
      });
    }

    // Clean reply text (remove raw FILE blocks for display)
    const cleanReply = rawReply
      .replace(/<<<FILE>>>[\s\S]*?<<<END>>>/g, "")
      .replace(/\n{3,}/g, "\n\n")
      .trim();

    res.json({ reply: cleanReply, edits });
  } catch (err) {
    console.error("Server error:", err);
    res.status(500).json({ error: err.message });
  }
});

app.post("/clear", (req, res) => {
  const { sessionId } = req.body;
  if (sessionId) workspaceSessions.delete(sessionId);
  res.json({ ok: true });
});

app.get("/health", (_, res) => res.json({ ok: true }));

setInterval(() => {
  const cutoff = Date.now() - 3600000;
  for (const [id, ws] of workspaceSessions.entries()) {
    if (ws.lastUpdated < cutoff) workspaceSessions.delete(id);
  }
}, 3600000);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Proxy running on port ${PORT}`));
