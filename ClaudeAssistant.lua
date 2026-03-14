-- Claude Assistant Plugin for Roblox Studio
-- Paste this into a Script inside ServerStorage, then save as Plugin

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")

-- ============================================================
-- CONFIG — ganti URL setelah deploy proxy server kamu
-- ============================================================
local PROXY_URL = "https://YOUR-PROXY.railway.app/chat"
-- ============================================================

local toolbar = plugin:CreateToolbar("Claude Assistant")
local toggleButton = toolbar:CreateButton(
    "Claude",
    "Toggle Claude Assistant panel",
    "rbxassetid://14978048280" -- icon robot (bisa diganti)
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    true,  -- enabled by default
    false, -- override previous state
    360,   -- default width
    600,   -- default height
    280,   -- min width
    400    -- min height
)

local widget = plugin:CreateDockWidgetPluginGui("ClaudeAssistant", widgetInfo)
widget.Title = "Claude Assistant"

-- ============================================================
-- UI BUILDER
-- ============================================================
local function makeColor(r, g, b) return Color3.fromRGB(r, g, b) end

local BG        = makeColor(24, 24, 27)
local SURFACE   = makeColor(36, 36, 40)
local BORDER    = makeColor(60, 60, 68)
local ACCENT    = makeColor(139, 92, 246)  -- purple
local TEXT      = makeColor(228, 228, 231)
local MUTED     = makeColor(113, 113, 122)
local USER_BG   = makeColor(49, 46, 74)
local BOT_BG    = makeColor(36, 36, 40)
local CODE_BG   = makeColor(20, 20, 24)

local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = BG
root.BorderSizePixel = 0
root.Parent = widget

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = SURFACE
header.BorderSizePixel = 0
header.Parent = root

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, -1)
headerLine.BackgroundColor3 = BORDER
headerLine.BorderSizePixel = 0
headerLine.Parent = header

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -16, 1, 0)
headerLabel.Position = UDim2.new(0, 16, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "✦ Claude Assistant"
headerLabel.TextColor3 = TEXT
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 14
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = header

-- Model badge
local badge = Instance.new("TextLabel")
badge.Size = UDim2.new(0, 100, 0, 20)
badge.Position = UDim2.new(1, -110, 0.5, -10)
badge.BackgroundColor3 = makeColor(49, 38, 74)
badge.Text = "claude-sonnet-4"
badge.TextColor3 = makeColor(167, 139, 250)
badge.Font = Enum.Font.Gotham
badge.TextSize = 10
badge.TextXAlignment = Enum.TextXAlignment.Center
badge.Parent = header
local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 4)
badgeCorner.Parent = badge

-- Scroll area for messages
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -108)
scrollFrame.Position = UDim2.new(0, 0, 0, 48)
scrollFrame.BackgroundColor3 = BG
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = BORDER
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = root

local messageList = Instance.new("UIListLayout")
messageList.SortOrder = Enum.SortOrder.LayoutOrder
messageList.Padding = UDim.new(0, 0)
messageList.Parent = scrollFrame

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingTop = UDim.new(0, 8)
scrollPad.PaddingBottom = UDim.new(0, 8)
scrollPad.Parent = scrollFrame

-- Input area
local inputArea = Instance.new("Frame")
inputArea.Size = UDim2.new(1, 0, 0, 60)
inputArea.Position = UDim2.new(0, 0, 1, -60)
inputArea.BackgroundColor3 = SURFACE
inputArea.BorderSizePixel = 0
inputArea.Parent = root

local inputTopLine = Instance.new("Frame")
inputTopLine.Size = UDim2.new(1, 0, 0, 1)
inputTopLine.BackgroundColor3 = BORDER
inputTopLine.BorderSizePixel = 0
inputTopLine.Parent = inputArea

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -70, 1, -16)
inputBox.Position = UDim2.new(0, 10, 0, 8)
inputBox.BackgroundColor3 = makeColor(28, 28, 32)
inputBox.TextColor3 = TEXT
inputBox.PlaceholderText = "Ask about Lua, debug code, generate scripts..."
inputBox.PlaceholderColor3 = MUTED
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 13
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.TextYAlignment = Enum.TextYAlignment.Top
inputBox.MultiLine = true
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.Parent = inputArea
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputBox
local inputPad = Instance.new("UIPadding")
inputPad.PaddingLeft = UDim.new(0, 8)
inputPad.PaddingTop = UDim.new(0, 6)
inputPad.Parent = inputBox

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 50, 1, -16)
sendBtn.Position = UDim2.new(1, -58, 0, 8)
sendBtn.BackgroundColor3 = ACCENT
sendBtn.Text = "↑"
sendBtn.TextColor3 = Color3.new(1,1,1)
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 18
sendBtn.BorderSizePixel = 0
sendBtn.Parent = inputArea
local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 6)
sendCorner.Parent = sendBtn

-- Context button (attaches selected script)
local ctxBtn = Instance.new("TextButton")
ctxBtn.Size = UDim2.new(1, -20, 0, 24)
ctxBtn.Position = UDim2.new(0, 10, 1, -32)
ctxBtn.BackgroundColor3 = makeColor(36, 36, 40)
ctxBtn.Text = "📎 Attach selected script as context"
ctxBtn.TextColor3 = MUTED
ctxBtn.Font = Enum.Font.Gotham
ctxBtn.TextSize = 11
ctxBtn.BorderSizePixel = 0
ctxBtn.Parent = inputArea
local ctxCorner = Instance.new("UICorner")
ctxCorner.CornerRadius = UDim.new(0, 4)
ctxCorner.Parent = ctxBtn

-- ============================================================
-- STATE
-- ============================================================
local conversationHistory = {}
local attachedScript = nil
local orderIndex = 0

-- ============================================================
-- HELPERS
-- ============================================================
local function newOrder()
    orderIndex += 1
    return orderIndex
end

local function addMessage(role, text)
    local isUser = role == "user"

    local bubble = Instance.new("Frame")
    bubble.Size = UDim2.new(1, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.BackgroundTransparency = 1
    bubble.LayoutOrder = newOrder()
    bubble.Parent = scrollFrame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = bubble

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, 0, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.BackgroundColor3 = isUser and USER_BG or BOT_BG
    inner.BorderSizePixel = 0
    inner.Parent = bubble
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 8)
    innerCorner.Parent = inner

    local innerPad = Instance.new("UIPadding")
    innerPad.PaddingLeft = UDim.new(0, 10)
    innerPad.PaddingRight = UDim.new(0, 10)
    innerPad.PaddingTop = UDim.new(0, 8)
    innerPad.PaddingBottom = UDim.new(0, 8)
    innerPad.Parent = inner

    local who = Instance.new("TextLabel")
    who.Size = UDim2.new(1, 0, 0, 16)
    who.BackgroundTransparency = 1
    who.Text = isUser and "You" or "Claude"
    who.TextColor3 = isUser and makeColor(167, 139, 250) or makeColor(52, 211, 153)
    who.Font = Enum.Font.GothamBold
    who.TextSize = 11
    who.TextXAlignment = Enum.TextXAlignment.Left
    who.Parent = inner

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 0)
    lbl.Position = UDim2.new(0, 0, 0, 20)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.RichText = true
    lbl.Parent = inner

    return bubble
end

local function addTypingIndicator()
    return addMessage("assistant", "<font color='#71717a'>Claude is thinking...</font>")
end

local function scrollToBottom()
    task.wait(0.05)
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
end

local function getSelectedScriptSource()
    local sel = Selection:Get()
    for _, obj in ipairs(sel) do
        if obj:IsA("LuaSourceContainer") then
            return obj.Source, obj.Name
        end
    end
    return nil, nil
end

local function sendToClaude(userMessage)
    table.insert(conversationHistory, { role = "user", content = userMessage })

    local typing = addTypingIndicator()
    scrollToBottom()

    local ok, response = pcall(function()
        local body = HttpService:JSONEncode({ messages = conversationHistory })
        return HttpService:PostAsync(PROXY_URL, body, Enum.HttpContentType.ApplicationJson, false)
    end)

    typing:Destroy()

    if ok then
        local parsed = HttpService:JSONDecode(response)
        local reply = parsed.reply or "No response"
        table.insert(conversationHistory, { role = "assistant", content = reply })
        addMessage("assistant", reply)
    else
        addMessage("assistant", "<font color='#f87171'>Error: " .. tostring(response) .. "\n\nPastikan proxy server kamu sudah running dan URL sudah benar.</font>")
    end

    scrollToBottom()
end

-- ============================================================
-- EVENTS
-- ============================================================
toggleButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

sendBtn.MouseButton1Click:Connect(function()
    local text = inputBox.Text
    if text == "" or text == nil then return end
    inputBox.Text = ""

    local fullMessage = text
    if attachedScript then
        fullMessage = text .. "\n\n```lua\n-- " .. attachedScript.name .. "\n" .. attachedScript.source .. "\n```"
        attachedScript = nil
        ctxBtn.Text = "📎 Attach selected script as context"
        ctxBtn.TextColor3 = MUTED
    end

    addMessage("user", text)
    scrollToBottom()
    task.spawn(sendToClaude, fullMessage)
end)

inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and not inputBox.MultiLine then
        sendBtn.MouseButton1Click:Fire()
    end
end)

ctxBtn.MouseButton1Click:Connect(function()
    local source, name = getSelectedScriptSource()
    if source then
        attachedScript = { source = source, name = name }
        ctxBtn.Text = "✅ Attached: " .. name
        ctxBtn.TextColor3 = makeColor(52, 211, 153)
    else
        attachedScript = nil
        ctxBtn.Text = "📎 Select a Script/LocalScript first"
        ctxBtn.TextColor3 = makeColor(251, 191, 36)
        task.wait(2)
        ctxBtn.Text = "📎 Attach selected script as context"
        ctxBtn.TextColor3 = MUTED
    end
end)

-- Welcome message
addMessage("assistant", "Hi! I'm your Roblox Lua assistant.\n\nI can help you:\n• 🔧 <b>Generate</b> scripts (explain what you need)\n• 🐛 <b>Debug</b> errors (paste your code)\n• 📖 <b>Explain</b> any Lua/Roblox API\n\nTip: Select a Script in Explorer, click <b>📎 Attach</b>, then ask me to explain or fix it!")
