# Claude Assistant — Roblox Studio Plugin

Plugin Roblox Studio yang mengintegrasikan Claude AI sebagai asisten coding Lua.

## Fitur
- Chat langsung di sidebar Roblox Studio
- Generate Lua script dengan konteks Roblox API
- Explain & debug kode (attach script dari Explorer)
- Conversation history (multi-turn)

---

## Setup: 2 langkah

### Langkah 1 — Deploy Proxy Server

Proxy wajib karena Roblox tidak bisa langsung memanggil api.anthropic.com.

**Deploy ke Railway (gratis, termudah):**
1. Buat akun di https://railway.app
2. New Project → Deploy from GitHub Repo
   - Atau: drag & drop folder `roblox-claude-proxy`
3. Tambahkan environment variable:
   - Key: `ANTHROPIC_API_KEY`
   - Value: API key kamu dari https://console.anthropic.com
4. Railway akan memberi URL publik, contoh: `https://roblox-claude-proxy.up.railway.app`

**Alternatif — Deploy ke Render:**
1. Buat akun di https://render.com
2. New → Web Service → Connect repo
3. Build command: `npm install`
4. Start command: `npm start`
5. Tambahkan env var `ANTHROPIC_API_KEY`

---

### Langkah 2 — Install Plugin di Roblox Studio

1. Buka `ClaudeAssistant.lua`
2. **Ganti baris ini** dengan URL proxy kamu:
   ```lua
   local PROXY_URL = "https://YOUR-PROXY.railway.app/chat"
   ```
3. Di Roblox Studio:
   - Buka Plugin tab → Plugins Folder
   - Paste `ClaudeAssistant.lua` ke folder plugin
   - Restart Roblox Studio
4. Klik tombol **Claude** di toolbar

---

## Cara Pakai

| Aksi | Cara |
|------|------|
| Tanya bebas | Ketik di input box, tekan ↑ |
| Debug script | Select script di Explorer → klik 📎 Attach → tanya |
| Generate script | "Buatkan script untuk respawn player setiap 5 detik" |
| Explain API | "Apa itu TweenService dan cara pakainya?" |

## Catatan
- Roblox Studio harus mengizinkan HTTP: Game Settings → Security → Allow HTTP Requests
- API key jangan pernah ditulis langsung di plugin, selalu di environment variable proxy
