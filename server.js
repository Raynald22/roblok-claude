const express = require("express");
const app = express();
app.use(express.json());

const SYSTEM_PROMPT = `You are an expert Roblox Studio assistant and Lua programmer. You help developers write, debug, and understand Roblox code.

Key rules:
- Always write code for Roblox's Luau (typed Lua) environment
- Use proper Roblox services: game:GetService("Players"), game:GetService("RunService"), etc.
- Distinguish between server-side (Script), client-side (LocalScript), and module scripts (ModuleScript)
- Follow Roblox best practices: use RemoteEvents/RemoteFunctions for client-server communication
- When generating code, always add brief comments explaining what each section does
- For debugging, explain the likely cause and provide a fix
- Common Roblox APIs to use: TweenService, DataStoreService, CollectionService, PhysicsService, UserInputService

When explaining code:
1. Summarize what the code does in 1-2 sentences
2. Point out any bugs or anti-patterns
3. Suggest improvements if relevant

When generating code:
1. Write clean, readable Luau code
2. Include type annotations where helpful
3. Handle errors with pcall where appropriate
4. Add comments for non-obvious logic

Format code blocks with lua syntax.`;

app.post("/chat", async (req, res) => {
  const { messages } = req.body;

  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: "messages array required" });
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
        max_tokens: 2048,
        system: SYSTEM_PROMPT,
        messages: messages,
      }),
    });

    if (!response.ok) {
      const err = await response.json();
      return res.status(response.status).json({ error: err });
    }

    const data = await response.json();
    res.json({ reply: data.content[0].text });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/health", (_, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Proxy running on port ${PORT}`));
