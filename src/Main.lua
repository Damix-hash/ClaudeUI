--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                        ClaudeUI                               ║
    ║         Industrial Minimalist Exploit UI SDK for Roblox       ║
    ║   Lead Architect: Claude (Anthropic) × Gemini Collaboration   ║
    ╚═══════════════════════════════════════════════════════════════╝

    PALETTE:
        Base        #1C1C1C   Rail   #262624   Border  #484844
        Accent      #E85D00   Error  #FE7E7C   Text    #FFFFFF
        Dim         #9A9A96   Active #1F1200

    Z-INDEX STACK:
        Base=1  Rail=10  Content=20  Scroll=30  Drawer=40
        Pill=50  CtxMenu=60  Tooltip=70  Toast=80  Error=90
        Watermark=100  System=200
]]

-- ─────────────────────────────────────────────────────────────────
-- 0. SERVICES & ENVIRONMENT DETECTION
-- ─────────────────────────────────────────────────────────────────

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local IS_STUDIO   = RunService:IsStudio()
local ENV_LABEL   = IS_STUDIO and "STUDIO_ENV" or "EXECUTOR_ENV"

-- UNC capability flags (set silently at startup)
local UNC = {
    writefile        = not IS_STUDIO and type(writefile)        == "function",
    readfile         = not IS_STUDIO and type(readfile)         == "function",
    isfile           = not IS_STUDIO and type(isfile)           == "function",
    gethui           = not IS_STUDIO and type(gethui)           == "function",
    setreadonly      = not IS_STUDIO and type(setreadonly)      == "function",
    make_writeable   = not IS_STUDIO and type(make_writeable)   == "function",
    newcclosure      = not IS_STUDIO and type(newcclosure)      == "function",
    cloneref         = not IS_STUDIO and type(cloneref)         == "function",
    getgenv          = not IS_STUDIO and type(getgenv)          == "function",
    getreg           = not IS_STUDIO and type(getreg)           == "function",
    getnetworkowner  = not IS_STUDIO and type(getnetworkowner)  == "function",
    setclipboard     = not IS_STUDIO and type(setclipboard)     == "function",
    checkcaller      = not IS_STUDIO and type(checkcaller)      == "function",
    syn_protect      = not IS_STUDIO and type(syn)              == "table"
                       and type(syn.protect_gui)                == "function",
    hookmetamethod   = not IS_STUDIO and type(hookmetamethod)   == "function",
    debug_setconst   = not IS_STUDIO and type(debug)            == "table"
                       and type(debug.setconstant)              == "function",
}

-- ─────────────────────────────────────────────────────────────────
-- 1. CONSTANTS
-- ─────────────────────────────────────────────────────────────────

local C = {
    -- Colors
    BASE         = Color3.fromHex("1C1C1C"),
    RAIL         = Color3.fromHex("262624"),
    BORDER       = Color3.fromHex("484844"),
    ACCENT       = Color3.fromHex("E85D00"),
    ERROR        = Color3.fromHex("FE7E7C"),
    TEXT         = Color3.fromHex("FFFFFF"),
    DIM          = Color3.fromHex("9A9A96"),
    ACTIVE_BG    = Color3.fromHex("1F1200"),

    -- Fonts
    F_LABEL      = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    F_BOLD       = Font.new("rbxasset://fonts/families/GothamSSm.json",  Enum.FontWeight.Bold),
    F_MEDIUM     = Font.new("rbxasset://fonts/families/GothamSSm.json",  Enum.FontWeight.Medium),
    F_MONO       = Font.new("rbxasset://fonts/families/RobotoMono.json"),

    -- Layout
    RADIUS       = UDim.new(0, 4),
    RADIUS_LG    = UDim.new(0, 8),
    STROKE_W     = 1,

    -- Timing
    T_FAST       = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    T_MED        = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    T_SLOW       = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    T_SETTLE     = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),

    -- Z-Index
    Z_BASE       = 1,
    Z_RAIL       = 10,
    Z_CONTENT    = 20,
    Z_SCROLL     = 30,
    Z_DRAWER     = 40,
    Z_PILL       = 50,
    Z_CTX        = 60,
    Z_TOOLTIP    = 70,
    Z_TOAST      = 80,
    Z_ERROR      = 90,
    Z_WATERMARK  = 100,
    Z_SYSTEM     = 200,

    -- Version & GitHub Sync
    VERSION      = "1.0.6",
    VERSION_URL  = "https://raw.githubusercontent.com/Damix-hash/ClaudeUI/main/versions.txt",
    MAP_URL      = "https://raw.githubusercontent.com/Damix-hash/ClaudeUI/main/spritesheet/spritesheet-map.json",
    REPO_URL     = "https://github.com/Damix-hash/ClaudeUI",

    -- Config
    SCHEMA_VER   = 1,
    MAX_HISTORY  = 10,
    MEMORY_WARN  = 125,   -- MB
    SPAM_LIMIT   = 10,
    SPAM_WINDOW  = 1,    -- seconds
    LOCKOUT_TIME = 2,    -- seconds
}

-- ─────────────────────────────────────────────────────────────────
-- 2. LIBRARY CORE TABLE
-- ─────────────────────────────────────────────────────────────────

local Library = {}
Library.__index = Library

Library.Debug       = false
Library.Version     = C.VERSION
Library._gui        = nil
Library._tweens     = {}
Library._connections= {}
Library._threads    = {}
Library._config     = {}
Library._tabs       = {}
Library._destroyed  = false

-- Tracking helpers
function Library:_trackTween(t)
    table.insert(self._tweens, t); return t
end
function Library:_trackConnection(c)
    table.insert(self._connections, c); return c
end
function Library:_trackThread(t)
    table.insert(self._threads, t); return t
end
-- Add this to your Library table if it's missing or named differently
function Library:Notification(title, content, icon)
    -- This handles the sliding toast notifications you saw in the pill
    local toast = NotificationService.create(title, content, icon)
    toast.Parent = Library._gui
    return toast
end
-- ─────────────────────────────────────────────────────────────────
-- 3. LOGGER
-- ─────────────────────────────────────────────────────────────────

local Logger = {}
local _activeToasts = {}

local function _makeToast(message, color, persistent)
    if not Library._gui then return end
    local gui = Library._gui

    local toast = Instance.new("Frame")
    toast.Name             = "Toast"
    toast.Size             = UDim2.fromOffset(280, 48)
    toast.Position         = UDim2.new(1, -292, 1, 60)
    toast.BackgroundColor3 = C.BASE
    toast.BorderSizePixel  = 0
    toast.ZIndex           = persistent and C.Z_ERROR or C.Z_TOAST
    toast.ClipsDescendants = false
    toast.Parent           = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = C.RADIUS_LG
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = color; stroke.Thickness = 1
    stroke.Parent = toast

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel  = 0
    bar.ZIndex           = C.Z_ERROR + 1
    bar.Parent           = toast

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = C.RADIUS_LG
    barCorner.Parent = bar

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -18, 1, 0)
    lbl.Position         = UDim2.fromOffset(12, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace         = C.F_LABEL
    lbl.TextSize         = 11
    lbl.TextColor3       = C.TEXT
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.TextWrapped      = true
    lbl.ZIndex           = C.Z_ERROR + 1
    lbl.Text             = persistent and (message .. "\n[Click to dismiss]") or message
    lbl.Parent           = toast

    local idx = #_activeToasts + 1
    local yOff = -(56 * idx)
    table.insert(_activeToasts, toast)

    TweenService:Create(toast, C.T_MED, {
        Position = UDim2.new(1, -292, 1, yOff - 8)
    }):Play()

    local function dismiss()
        TweenService:Create(toast, C.T_FAST, {
            Position = UDim2.new(1, 60, toast.Position.Y.Scale, toast.Position.Y.Offset)
        }):Play()
        task.delay(0.15, function()
            local i = table.find(_activeToasts, toast)
            if i then table.remove(_activeToasts, i) end
            if toast and toast.Parent then toast:Destroy() end
        end)
    end

    if persistent then
        toast.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dismiss() end
        end)
    else
        task.delay(3.5, dismiss)
    end
end

function Logger.log(logType, message, debugEnabled)
    warn(string.format("[CLAUDE-UI] [%s] %s", string.upper(logType), message))
    if not debugEnabled then return end
    if logType == "Error" then
        _makeToast(message, C.ERROR, true)
    elseif logType == "Warn" then
        _makeToast(message, C.ACCENT, false)
    elseif logType == "Info" then
        _makeToast(message, C.DIM, false)
    end
end

function Library:Log(logType, message)
    Logger.log(logType, message, self.Debug)
end

function Library:SafeCall(fn, ...)
    if type(fn) ~= "function" then
        self:Log("Error", "SafeCall: expected function, got " .. type(fn))
        return nil
    end
    local args = {...}
    local ok, result = xpcall(
        function() return fn(table.unpack(args)) end,
        function(err) self:Log("Error", "Callback error: " .. tostring(err)) end
    )
    return ok and result or nil
end

-- ─────────────────────────────────────────────────────────────────
-- 4. STATE MANAGER
-- ─────────────────────────────────────────────────────────────────

local StateManager = {}
StateManager._state    = {}
StateManager._watchers = {}

-- History for Undo/Redo
local History = {}
local _histStack   = {}
local _histPointer = 0

local function _histRecord(key, oldVal, newVal)
    while #_histStack > _histPointer do table.remove(_histStack) end
    table.insert(_histStack, {key = key, old = oldVal, new = newVal})
    if #_histStack > C.MAX_HISTORY then table.remove(_histStack, 1) end
    _histPointer = #_histStack
end

function History.undo()
    if _histPointer < 1 then Library:Log("Info", "Nothing to undo."); return end
    local e = _histStack[_histPointer]; _histPointer = _histPointer - 1
    StateManager._set_internal(e.key, e.old)
    Library:Log("Info", "Undo: " .. e.key)
end

function History.redo()
    if _histPointer >= #_histStack then Library:Log("Info", "Nothing to redo."); return end
    _histPointer = _histPointer + 1
    local e = _histStack[_histPointer]
    StateManager._set_internal(e.key, e.new)
    Library:Log("Info", "Redo: " .. e.key)
end

function StateManager._set_internal(key, value)
    StateManager._state[key] = value
    if StateManager._watchers[key] then
        for _, fn in ipairs(StateManager._watchers[key]) do
            task.defer(fn, value)
        end
    end
end

function StateManager.set(key, value)
    if StateManager._state[key] == value then return end
    local old = StateManager._state[key]
    StateManager._set_internal(key, value)
    _histRecord(key, old, value)
end

function StateManager.get(key) return StateManager._state[key] end

function StateManager.watch(key, fn)
    StateManager._watchers[key] = StateManager._watchers[key] or {}
    table.insert(StateManager._watchers[key], fn)
    return function()
        local list = StateManager._watchers[key]
        local idx  = table.find(list, fn)
        if idx then table.remove(list, idx) end
    end
end

-- Ctrl+Z / Ctrl+Y
Library:_trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if input.KeyCode == Enum.KeyCode.Z then History.undo()
        elseif input.KeyCode == Enum.KeyCode.Y then History.redo() end
    end
end))

-- ─────────────────────────────────────────────────────────────────
-- 5. STORAGE PROVIDER & COMPRESSOR
-- ─────────────────────────────────────────────────────────────────

local Compressor = {}

local TOKEN_ENC = {
    ['"enabled":true']  = "~ET", ['"enabled":false'] = "~EF",
    ['"value":']        = "~V:", ['"mode":']          = "~M:",
    ['"default":']      = "~D:", ['"label":']         = "~L:",
}
local TOKEN_DEC = {}
for k, v in pairs(TOKEN_ENC) do TOKEN_DEC[v] = k end

local function _escape(s)
    return s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
end

function Compressor.encode(str)
    for pattern, token in pairs(TOKEN_ENC) do
        str = str:gsub(_escape(pattern), token)
    end
    return str
end

function Compressor.decode(str)
    for token, pattern in pairs(TOKEN_DEC) do
        str = str:gsub(_escape(token), pattern)
    end
    return str
end

local StorageProvider = {}

local SCHEMA_DEFAULTS = {}  -- populated on Library.new()

function StorageProvider.write(filename, data)
    -- checkcaller guard: block game scripts from calling this
    if UNC.checkcaller and not checkcaller() then
        Library:Log("Error", "StorageProvider: blocked external caller.")
        return false
    end
    local ok_enc, encoded = pcall(function()
        return Compressor.encode(HttpService:JSONEncode(data))
    end)
    if not ok_enc then Library:Log("Error", "Storage encode failed."); return false end

    if IS_STUDIO then
        warn(string.format("[CLAUDE-UI] [STORAGE MOCK] %s\n%s", filename, encoded))
        return true
    end
    if UNC.writefile then
        local ok, err = pcall(writefile, filename, encoded)
        if not ok then Library:Log("Error", "writefile: " .. tostring(err)); return false end
        return true
    end
    Library:Log("Warn", "No file I/O available."); return false
end

function StorageProvider.read(filename)
    if IS_STUDIO then return nil end
    if not UNC.readfile or not UNC.isfile then return nil end
    if not isfile(filename) then return nil end
    local ok, raw = pcall(readfile, filename)
    if not ok then return nil end
    local ok2, decoded = pcall(function()
        return HttpService:JSONDecode(Compressor.decode(raw))
    end)
    return ok2 and decoded or nil
end

-- Config sanitization
local function sanitiseConfig(raw, defaults)
    if type(raw) ~= "table" then return defaults end
    if raw._version ~= C.SCHEMA_VER then
        Library:Log("Warn", "Config version mismatch — discarding stale keys.")
    end
    local clean = {}
    for key, defaultVal in pairs(defaults) do
        local saved = raw[key]
        if saved == nil then
            clean[key] = defaultVal
        elseif type(saved) ~= type(defaultVal) then
            Library:Log("Warn", "Config key '" .. key .. "' wrong type, using default.")
            clean[key] = defaultVal
        else
            clean[key] = saved
        end
    end
    clean._version = C.SCHEMA_VER
    return clean
end

function Library:Save(filename)
    StorageProvider.write(filename or "claudeui_config.json", self._config)
end

function Library:Load(filename, defaults)
    local raw = StorageProvider.read(filename or "claudeui_config.json")
    if not raw then return end
    self._config = sanitiseConfig(raw, defaults or self._config)
    Library:Log("Info", "Config loaded from " .. (filename or "claudeui_config.json"))
end

function Library:AutoLoad(defaults)
    local placeId  = game.PlaceId
    local filename = string.format("claudeui_place_%d.json", placeId)
    local raw      = StorageProvider.read(filename)
    self._config   = raw and sanitiseConfig(raw, defaults or {}) or (defaults or {})
    Library:Log("Info", "Auto-loaded profile for PlaceId " .. placeId)
end

function Library:AutoSave()
    local filename = string.format("claudeui_place_%d.json", game.PlaceId)
    StorageProvider.write(filename, self._config)
end

-- ─────────────────────────────────────────────────────────────────
-- 5.5 NOTIFICATION SERVICE
-- ─────────────────────────────────────────────────────────────────
local NotificationService = {}

function NotificationService.create(title, content, iconName)
    local container = Instance.new("Frame")
    container.Name = "CUI_Notification"
    container.Size = UDim2.new(0, 280, 0, 60)
    container.BackgroundColor3 = C.RAIL
    container.BorderSizePixel = 0
    
    -- Positioning (Bottom Right)
    container.Position = UDim2.new(1, -300, 1, -80)
    
    -- Rounded Corners & Stroke
    local corner = Instance.new("UICorner")
    corner.CornerRadius = C.RADIUS
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = C.BORDER
    stroke.Thickness = 1
    stroke.Parent = container

    -- Accent Bar (The Orange strip on the side)
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = C.ACCENT
    accent.BorderSizePixel = 0
    accent.Parent = container
    Instance.new("UICorner", accent).CornerRadius = C.RADIUS

    -- Title text
    local tLabel = Instance.new("TextLabel")
    tLabel.Text = string.upper(title or "SYSTEM")
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 12
    tLabel.TextColor3 = C.ACCENT
    tLabel.Position = UDim2.new(0, 15, 0, 10)
    tLabel.Size = UDim2.new(1, -20, 0, 15)
    tLabel.BackgroundTransparency = 1
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.Parent = container

    -- Content text
    local cLabel = Instance.new("TextLabel")
    cLabel.Text = content or ""
    cLabel.Font = Enum.Font.Gotham
    cLabel.TextSize = 13
    cLabel.TextColor3 = C.TEXT
    cLabel.Position = UDim2.new(0, 15, 0, 28)
    cLabel.Size = UDim2.new(1, -20, 0, 20)
    cLabel.BackgroundTransparency = 1
    cLabel.TextXAlignment = Enum.TextXAlignment.Left
    cLabel.Parent = container

    -- Auto-Destroy after 5 seconds
    task.delay(5, function()
        local tween = game:GetService("TweenService"):Create(container, TweenInfo.new(0.5), {TextTransparency = 1, BackgroundTransparency = 1})
        container:Destroy()
    end)

    return container
end

-- ─────────────────────────────────────────────────────────────────
-- 6. ICON SERVICE
-- ─────────────────────────────────────────────────────────────────

--[[
    IconService for ClaudeUI
    Spritesheet: rbxassetid://97757682409962
    Grid: 9 columns × 10 rows, each cell 32×32px
    Sheet size: 288×320px
    
    HOW TO USE:
        local icon = IconService.get("crosshair")
        icon.Parent = someFrame
    
    HOW TO TEST A SINGLE ICON:
        -- Paste in Studio command bar:
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromOffset(64, 64)
        img.Image = "rbxassetid://97757682409962"
        img.ImageRectSize = Vector2.new(32, 32)
        img.ImageRectOffset = Vector2.new(64, 64)  -- crosshair: col 2, row 2
        img.BackgroundColor3 = Color3.fromHex("1C1C1C")
        img.Parent = game.Players.LocalPlayer.PlayerGui
]]
 
local IconService = {}
 
local ASSET_ID = "rbxassetid://97757682409962"
local CELL     = 32   -- each icon cell is 32×32 pixels
 
--[[
    ICON MAP
    Format: name = {col * CELL, row * CELL}  (0-indexed)
    
    Row 0: arrow-left  arrow-right  arrow-up  arrow-back  badge      bell-off  bell      brain     branch
    Row 1: bug         input        button    calendar    card       check-on  check-off minus     close
    Row 2: code        dot          crosshair file-text   prompt     download  dropdown  edit      external-link
    Row 3: eye-off     eye          file-code file-alt    file       filter    folder-open folder  forward
    Row 4: heart       home         info      card-alt    link       panel     lock      star      menu
    Row 5: message     hyphen       notif-dot notification plus      power     radio-off radio-on  list
    Row 6: redo        refresh      robot     save        search     settings  share     slider-h  sort
    Row 7: star-filled success      terminal  tabs        thinking   time      toggle-off toggle-on message-alt
    Row 8: trash       reload       unlock    upload      user       users     variable  warning   zap
    Row 9: (empty row — sheet ends at row 8 for 9×9=90 icons, last row has 9 icons)
]]
 
local ICON_MAP = {
    -- ROW 0
    ["arrow-left"]      = {0*CELL, 0*CELL},
    ["arrow-right"]     = {1*CELL, 0*CELL},
    ["arrow-up"]        = {2*CELL, 0*CELL},
    ["arrow-back"]      = {3*CELL, 0*CELL},
    ["badge"]           = {4*CELL, 0*CELL},
    ["bell-off"]        = {5*CELL, 0*CELL},
    ["bell"]            = {6*CELL, 0*CELL},
    ["brain"]           = {7*CELL, 0*CELL},
    ["branch"]          = {8*CELL, 0*CELL},
 
    -- ROW 1
    ["bug"]             = {0*CELL, 1*CELL},
    ["input"]           = {1*CELL, 1*CELL},
    ["button"]          = {2*CELL, 1*CELL},
    ["calendar"]        = {3*CELL, 1*CELL},
    ["card"]            = {4*CELL, 1*CELL},
    ["checkbox-on"]     = {5*CELL, 1*CELL},
    ["checkbox-off"]    = {6*CELL, 1*CELL},
    -- ROW 1 Fixes
    ["minus"]  = {7*CELL, 1*CELL}, -- The small dash
    ["close"]  = {9*CELL, 1*CELL}, -- The ACTUAL X (Column 10, index 9)
    ["x"]      = {9*CELL, 1*CELL}, -- Alias for X
 
    -- ROW 2
    ["code"]            = {0*CELL, 2*CELL},
    ["dot"]             = {1*CELL, 2*CELL},
    ["crosshair"]       = {2*CELL, 2*CELL},
    ["file-text"]       = {3*CELL, 2*CELL},
    ["prompt"]          = {4*CELL, 2*CELL},
    ["download"]        = {5*CELL, 2*CELL},
    ["dropdown"]        = {6*CELL, 2*CELL},
    ["edit"]            = {7*CELL, 2*CELL},
    ["external-link"]   = {8*CELL, 2*CELL},
 
    -- ROW 3
    ["eye-off"]         = {0*CELL, 3*CELL},
    ["eye"]             = {1*CELL, 3*CELL},
    ["file-code"]       = {2*CELL, 3*CELL},
    ["file-alt"]        = {3*CELL, 3*CELL},
    ["file"]            = {4*CELL, 3*CELL},
    ["filter"]          = {5*CELL, 3*CELL},
    ["folder-open"]     = {6*CELL, 3*CELL},
    ["folder"]          = {7*CELL, 3*CELL},
    ["forward"]         = {8*CELL, 3*CELL},
 
    -- ROW 4
    ["heart"]           = {0*CELL, 4*CELL},
    ["home"]            = {1*CELL, 4*CELL},
    ["info"]            = {2*CELL, 4*CELL},
    ["card-alt"]        = {3*CELL, 4*CELL},
    ["link"]            = {4*CELL, 4*CELL},
    ["panel"]           = {5*CELL, 4*CELL},
    ["lock"]            = {6*CELL, 4*CELL},
    ["star"]            = {7*CELL, 4*CELL},
    ["menu"]            = {8*CELL, 4*CELL},
 
    -- ROW 5
    ["message"]         = {0*CELL, 5*CELL},
    ["hyphen"]          = {1*CELL, 5*CELL},
    ["notif-dot"]       = {2*CELL, 5*CELL},
    ["notification"]    = {3*CELL, 5*CELL},
    ["plus"]            = {4*CELL, 5*CELL},
    ["power"]           = {5*CELL, 5*CELL},
    ["radio-off"]       = {6*CELL, 5*CELL},
    ["radio-on"]        = {7*CELL, 5*CELL},
    ["list"]            = {8*CELL, 5*CELL},
 
    -- ROW 6
    ["redo"]            = {0*CELL, 6*CELL},
    ["refresh"]         = {1*CELL, 6*CELL},
    ["robot"]           = {2*CELL, 6*CELL},
    ["save"]            = {3*CELL, 6*CELL},
    ["search"]          = {4*CELL, 6*CELL},
    ["settings"]        = {5*CELL, 6*CELL},
    ["share"]           = {6*CELL, 6*CELL},
    ["slider-h"]        = {7*CELL, 6*CELL},
    ["sort"]            = {8*CELL, 6*CELL},
 
    -- ROW 7
    ["star-filled"]     = {0*CELL, 7*CELL},
    ["success"]         = {1*CELL, 7*CELL},
    ["terminal"]        = {2*CELL, 7*CELL},
    ["tabs"]            = {3*CELL, 7*CELL},
    ["thinking"]        = {4*CELL, 7*CELL},
    ["time"]            = {5*CELL, 7*CELL},
    ["toggle-off"]      = {6*CELL, 7*CELL},
    ["toggle-on"]       = {7*CELL, 7*CELL},
    ["message-alt"]     = {8*CELL, 7*CELL},
 
    -- ROW 8
    ["trash"]           = {0*CELL, 8*CELL},
    ["reload"]          = {1*CELL, 8*CELL},
    ["unlock"]          = {2*CELL, 8*CELL},
    ["upload"]          = {3*CELL, 8*CELL},
    ["user"]            = {4*CELL, 8*CELL},
    ["users"]           = {5*CELL, 8*CELL},
    ["variable"]        = {6*CELL, 8*CELL},
    ["warning"]         = {7*CELL, 8*CELL},
    ["zap"]             = {8*CELL, 8*CELL},
}
 
-- ── ALIASES ────────────────────────────────────────────────────────
-- Map every old/common name to a real entry above
local ALIASES = {
    -- Combat / targeting
    ["aim"]           = "crosshair",
    ["target"]        = "crosshair",
    ["combat"]        = "crosshair",
    ["aimbot"]        = "crosshair",
 
    -- Visuals / ESP
    ["visuals"]       = "eye",
    ["esp"]           = "eye",
    ["camera"]        = "eye",
    ["visible"]       = "eye",
 
    -- Settings / config
    ["config"]        = "settings",
    ["setup"]         = "settings",
    ["options"]       = "settings",
    ["gear"]          = "settings",
    ["wrench"]        = "settings",
 
    -- Misc / utility
    ["misc"]          = "zap",
    ["lightning"]     = "zap",
    ["utility"]       = "zap",
    ["extra"]         = "zap",
 
    -- Window controls
    ["x"]             = "close",
    ["minimize"]      = "minus",
    ["maximize"]      = "card",
 
    -- Navigation
    ["back"]          = "arrow-back",
    ["return"]        = "arrow-back",
    ["left"]          = "arrow-left",
    ["right"]         = "arrow-right",
    ["up"]            = "arrow-up",
 
    -- File operations
    ["copy"]          = "file-alt",
    ["paste"]         = "file",
    ["load"]          = "upload",
    ["export"]        = "download",
    ["import"]        = "upload",
    ["open"]          = "folder-open",
 
    -- State / feedback
    ["check"]         = "checkbox-on",
    ["checked"]       = "checkbox-on",
    ["unchecked"]     = "checkbox-off",
    ["error"]         = "warning",
    ["alert"]         = "warning",
    ["ok"]            = "success",
    ["done"]          = "success",
 
    -- People / profiles
    ["player"]        = "user",
    ["profile"]       = "user",
    ["account"]       = "user",
    ["players"]       = "users",
 
    -- Technical
    ["debug"]         = "bug",
    ["memory"]        = "brain",
    ["fps"]           = "time",
    ["ping"]          = "zap",
    ["network"]       = "branch",
    ["help"]          = "info",
    ["shield"]        = "lock",
    ["security"]      = "lock",
    ["world"]         = "home",
    ["house"]         = "home",
    ["chip"]          = "brain",
    ["code-alt"]      = "terminal",
    ["plugin"]        = "tabs",
    ["tab"]           = "tabs",
    ["section"]       = "list",
    ["scroll"]        = "sort",
    ["reset"]         = "refresh",
    ["undo"]          = "reload",
    ["notification-bell"] = "bell",
    ["share-alt"]     = "external-link",
    ["slider"]        = "slider-h",
    ["keybind"]       = "input",
    ["key"]           = "input",
    ["panel-alt"]     = "panel",
    ["bookmark"]      = "star",
    ["favourite"]     = "star-filled",
    ["favorite"]      = "star-filled",
}
 
-- Merge aliases into map as direct entries
for alias, target in pairs(ALIASES) do
    if ICON_MAP[target] and not ICON_MAP[alias] then
        ICON_MAP[alias] = ICON_MAP[target]
    end
end
 
-- ── FALLBACK ───────────────────────────────────────────────────────
-- Any unknown icon name falls back to arrow-left (0, 0) — always visible
setmetatable(ICON_MAP, {
    __index = function(_, key)
        warn(string.format("[CLAUDE-UI] IconService: Unknown icon '%s', using fallback.", tostring(key)))
        return {0, 0}
    end
})
 
-- ── PUBLIC API ─────────────────────────────────────────────────────
 
--[[
    IconService.get(name, displaySize?)
    Returns a pre-configured ImageLabel ready to parent.
    
    @param name        string  — icon name from ICON_MAP
    @param displaySize number  — pixel size to display at (default 20)
    @return ImageLabel
]]
function IconService.get(name, displaySize)
    local coords = ICON_MAP[name]   -- always returns something due to __index fallback
    local size   = displaySize or 20
 
    local img = Instance.new("ImageLabel")
    img.Name                = "CUI_Icon"
    img.Size                = UDim2.fromOffset(size, size)
    img.BackgroundTransparency = 1
    img.Image               = ASSET_ID
    img.ImageRectSize       = Vector2.new(CELL, CELL)
    img.ImageRectOffset     = Vector2.new(coords[1], coords[2])
    img.ImageColor3         = Color3.new(1, 1, 1)   -- sheet is already orange; keep white
    img.ScaleType           = Enum.ScaleType.Stretch
    img.ZIndex              = 20
 
    return img
end
 
--[[
    IconService.apply(imageLabel, name)
    Updates an existing ImageLabel to show a different icon.
    Useful for state changes (e.g. toggle-off → toggle-on)
    
    @param imageLabel  ImageLabel
    @param name        string
]]
function IconService.apply(imageLabel, name)
    local coords = ICON_MAP[name]
    imageLabel.Image           = ASSET_ID
    imageLabel.ImageRectSize   = Vector2.new(CELL, CELL)
    imageLabel.ImageRectOffset = Vector2.new(coords[1], coords[2])
end
 
--[[
    IconService.list()
    Prints all available icon names to the console.
    Useful for developers building tabs.
]]
function IconService.list()
    local names = {}
    for k in pairs(ICON_MAP) do
        -- Skip metatable-resolved entries that aren't real keys
        table.insert(names, k)
    end
    table.sort(names)
    warn("[CLAUDE-UI] Available icons (" .. #names .. "):")
    for _, name in ipairs(names) do
        local c = rawget(ICON_MAP, name)
        if c then
            warn(string.format("  %-22s → col %d, row %d  (offset %d, %d)",
                name,
                c[1] / CELL,
                c[2] / CELL,
                c[1], c[2]
            ))
        end
    end
end
 
--[[
    IconService.setTheme()
    Stub — sheet is already orange, no swap needed.
    Kept for API compatibility.
]]
function IconService.setTheme() end

-- ─────────────────────────────────────────────────────────────────
-- 7. LAYOUT MANAGER
-- ─────────────────────────────────────────────────────────────────

local LayoutManager = {}

local PROFILES = {
    Desktop4K   = { minW=2560, winSize=Vector2.new(780,540), iconSize=32, spacing=6,  padding=16, fontSize=13 },
    Desktop1080 = { minW=1280, winSize=Vector2.new(600,420), iconSize=32, spacing=4,  padding=12, fontSize=11 },
    Tablet      = { minW=768,  winSize=Vector2.new(480,360), iconSize=32, spacing=6,  padding=14, fontSize=12 },
    Phone       = { minW=0,    winSize=nil,                  iconSize=32, spacing=8,  padding=16, fontSize=12 },
}

function LayoutManager.getProfile()
    local vp = workspace.CurrentCamera.ViewportSize
    local platform = UserInputService:GetPlatform()
    local isMobile = platform == Enum.Platform.IOS or platform == Enum.Platform.Android

    if isMobile and vp.X < 768 then return PROFILES.Phone, "Phone"
    elseif vp.X >= 2560            then return PROFILES.Desktop4K,   "Desktop4K"
    elseif vp.X >= 1280            then return PROFILES.Desktop1080, "Desktop1080"
    else                                return PROFILES.Tablet,       "Tablet" end
end

function LayoutManager.isPhone()
    local _, name = LayoutManager.getProfile()
    return name == "Phone"
end

function LayoutManager.isWide()
    local vp = workspace.CurrentCamera.ViewportSize
    return vp.X >= 700
end

-- ─────────────────────────────────────────────────────────────────
-- 8. HELPERS (UIFactory)
-- ─────────────────────────────────────────────────────────────────

local function _corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or C.RADIUS
    c.Parent = parent; return c
end

local function _stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thickness or C.STROKE_W
    s.Parent = parent; return s
end

local function _padding(parent, px)
    local p = Instance.new("UIPadding")
    local u = UDim.new(0, px or 10)
    p.PaddingTop = u; p.PaddingBottom = u
    p.PaddingLeft = u; p.PaddingRight = u
    p.Parent = parent; return p
end

local function _listLayout(parent, dir, padding, hAlign, vAlign)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, padding or 4)
    if hAlign then l.HorizontalAlignment = hAlign end
    if vAlign  then l.VerticalAlignment  = vAlign  end
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent; return l
end

local function _label(parent, text, fontFace, size, color, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.FontFace     = fontFace or C.F_LABEL
    l.TextSize     = size     or 11
    l.TextColor3   = color    or C.TEXT
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Text         = text     or ""
    l.Parent       = parent; return l
end

local function _frame(parent, size, pos, color, zIndex)
    local f = Instance.new("Frame")
    f.Size             = size or UDim2.fromScale(1, 1)
    if pos then f.Position = pos end
    f.BackgroundColor3 = color or C.BASE
    f.BorderSizePixel  = 0
    if zIndex then f.ZIndex = zIndex end
    f.Parent           = parent; return f
end

-- Obfuscated name generator
local _CHARSET = "abcdefghijklmnopqrstuvwxyz0123456789"
local function _randName(len)
    local t = {}
    for i = 1, (len or 8) do
        t[i] = _CHARSET:sub(math.random(1, #_CHARSET), math.random(1, #_CHARSET))
    end
    return table.concat(t)
end

-- ─────────────────────────────────────────────────────────────────
-- 9. SAFE GUI PARENTING
-- ─────────────────────────────────────────────────────────────────

local function _getSafeParent()
    if IS_STUDIO then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    if UNC.gethui then
        local ok, result = pcall(gethui)
        if ok then return result end
    end
    if UNC.syn_protect then
        local gui = Instance.new("ScreenGui")
        pcall(syn.protect_gui, gui)
        gui.Parent = game:GetService("CoreGui")
        return game:GetService("CoreGui")
    end
    if UNC.cloneref then
        local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok then return cg end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    return ok and cg or LocalPlayer.PlayerGui
end

-- ─────────────────────────────────────────────────────────────────
-- 10. DEBOUNCE / ANTI-SPAM
-- ─────────────────────────────────────────────────────────────────

local _cooldowns = {}
local function _debounce(id, fn)
    return function(...)
        local now    = tick()
        local rec    = _cooldowns[id] or {count=0, window=now, locked=false}
        if rec.locked then
            if now - (rec.lockedAt or 0) < C.LOCKOUT_TIME then return end
            rec.locked = false; rec.count = 0
        end
        if now - rec.window > C.SPAM_WINDOW then
            rec.count = 0; rec.window = now
        end
        rec.count = rec.count + 1
        if rec.count > C.SPAM_LIMIT then
            rec.locked   = true
            rec.lockedAt = now
            Library:Log("Warn", "[ANTI-SPAM] '" .. id .. "' spammed. Cooldown applied.")
            return
        end
        _cooldowns[id] = rec
        return fn(...)
    end
end

-- ─────────────────────────────────────────────────────────────────
-- 11. DRAG SYSTEM (Magnetic + Topbar-aware)
-- ─────────────────────────────────────────────────────────────────

local function _applyDrag(handle, window)
    local inset     = GuiService:GetGuiInset()
    local TOPBAR_H  = inset.Y
    local MAGNET_R  = 80

    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = window.Position
        end
    end)

    Library:_trackConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local vp    = workspace.CurrentCamera.ViewportSize
        local delta = input.Position - dragStart
        local newX  = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - window.AbsoluteSize.X)
        local newY  = math.clamp(startPos.Y.Offset + delta.Y, TOPBAR_H, vp.Y - window.AbsoluteSize.Y)
        window.Position = UDim2.fromOffset(newX, newY)
    end))

    Library:_trackConnection(UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = false

        local vp   = workspace.CurrentCamera.ViewportSize
        local wSz  = window.AbsoluteSize
        local wPos = window.AbsolutePosition
        local sCX  = vp.X / 2
        local sCY  = vp.Y / 2
        local wCX  = wPos.X + wSz.X / 2
        local wCY  = wPos.Y + wSz.Y / 2
        local dist = math.sqrt((wCX - sCX)^2 + (wCY - sCY)^2)

        if dist < MAGNET_R then
            TweenService:Create(window, C.T_MED, {
                Position = UDim2.fromOffset(sCX - wSz.X/2, sCY - wSz.Y/2)
            }):Play()
        else
            TweenService:Create(window, C.T_SETTLE, {Position = window.Position}):Play()
        end
    end))
end

-- ─────────────────────────────────────────────────────────────────
-- 12. INERTIAL SCROLL
-- ─────────────────────────────────────────────────────────────────

local function _applyInertialScroll(sf)
    local FRICTION   = 0.92
    local MIN_VEL    = 0.5
    local velocity   = 0
    local lastY      = nil
    local dragging   = false
    local physThread = nil

    sf.ScrollingEnabled = false

    local function stopPhys()
        if physThread then task.cancel(physThread); physThread = nil end
    end

    local function startPhys()
        stopPhys()
        physThread = task.spawn(function()
            while math.abs(velocity) > MIN_VEL do
                task.wait()
                velocity = velocity * FRICTION
                local cur = sf.CanvasPosition
                sf.CanvasPosition = Vector2.new(cur.X, math.clamp(
                    cur.Y - velocity, 0,
                    math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y)
                ))
            end
            velocity = 0
        end)
    end

    sf.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; lastY = i.Position.Y; stopPhys(); velocity = 0
        end
    end)

    Library:_trackConnection(UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = lastY - i.Position.Y
        lastY = i.Position.Y
        velocity = delta / 0.4
        local cur = sf.CanvasPosition
        sf.CanvasPosition = Vector2.new(cur.X, math.clamp(
            cur.Y + delta, 0, math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y)
        ))
    end))

    Library:_trackConnection(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false; startPhys()
        end
    end))

    sf.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseWheel then
            stopPhys(); velocity = -i.Position.Z * 24; startPhys()
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- 13. TOOLTIP SYSTEM
-- ─────────────────────────────────────────────────────────────────

local _activeTooltip = nil
local _hoverThread   = nil

local function _destroyTooltip()
    if _hoverThread then task.cancel(_hoverThread); _hoverThread = nil end
    if _activeTooltip and _activeTooltip.Parent then
        TweenService:Create(_activeTooltip, C.T_FAST, {BackgroundTransparency=1}):Play()
        task.delay(0.12, function()
            if _activeTooltip then _activeTooltip:Destroy(); _activeTooltip = nil end
        end)
    end
end

local function _attachTooltip(target, text)
    target.MouseEnter:Connect(function()
        _hoverThread = task.delay(0.5, function()
            _destroyTooltip()
            local mouse = UserInputService:GetMouseLocation()
            local tip = _frame(Library._gui, UDim2.fromOffset(200, 0), UDim2.fromOffset(mouse.X + 12, mouse.Y + 12), C.BASE, C.Z_TOOLTIP)
            tip.AutomaticSize    = Enum.AutomaticSize.Y
            tip.BackgroundTransparency = 1
            _corner(tip, C.RADIUS_LG)
            _stroke(tip, C.ACCENT)
            _padding(tip, 8)

            local lbl = _label(tip, text, C.F_LABEL, 11, C.DIM)
            lbl.Size         = UDim2.new(1, 0, 0, 0)
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.TextWrapped  = true
            lbl.ZIndex       = C.Z_TOOLTIP + 1

            _activeTooltip = tip
            TweenService:Create(tip, C.T_FAST, {BackgroundTransparency = 0}):Play()

            Library:_trackConnection(UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement and _activeTooltip == tip then
                    tip.Position = UDim2.fromOffset(i.Position.X + 12, i.Position.Y + 12)
                end
            end))
        end)
    end)
    target.MouseLeave:Connect(_destroyTooltip)
end

-- ─────────────────────────────────────────────────────────────────
-- 14. CONTEXT MENU
-- ─────────────────────────────────────────────────────────────────

local _activeCtx = nil

local function _closeCtx()
    if _activeCtx and _activeCtx.Parent then
        TweenService:Create(_activeCtx, C.T_FAST, {
            Size = UDim2.fromOffset(_activeCtx.AbsoluteSize.X, 0)
        }):Play()
        task.delay(0.12, function()
            if _activeCtx then _activeCtx:Destroy(); _activeCtx = nil end
        end)
    end
end

local function _attachContextMenu(target, featureId, resetFn)
    local items = {
        { label="Reset to Default", action=function() if resetFn then resetFn() end end },
        { label="Copy Feature ID",  action=function()
            if UNC.setclipboard then pcall(setclipboard, tostring(featureId)) end
            Library:Log("Info", "Copied ID: " .. tostring(featureId))
        end},
    }

    local pressThread = nil

    local function openMenu(x, y)
        _closeCtx()
        local menu = _frame(Library._gui, UDim2.fromOffset(160, 0), UDim2.fromOffset(x, y), C.BASE, C.Z_CTX)
        menu.ClipsDescendants = true
        _corner(menu, C.RADIUS_LG)
        _stroke(menu, C.ACCENT)
        _listLayout(menu, Enum.FillDirection.Vertical, 0)

        local totalH = 0
        for _, item in ipairs(items) do
            local btn = Instance.new("TextButton")
            btn.Size             = UDim2.new(1, 0, 0, 32)
            btn.BackgroundColor3 = C.BASE
            btn.BorderSizePixel  = 0
            btn.FontFace         = C.F_MEDIUM
            btn.TextSize         = 11
            btn.TextColor3       = C.TEXT
            btn.TextXAlignment   = Enum.TextXAlignment.Left
            btn.Text             = "  " .. item.label
            btn.ZIndex           = C.Z_CTX + 1
            btn.Parent           = menu
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, C.T_FAST, {BackgroundColor3 = C.RAIL}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, C.T_FAST, {BackgroundColor3 = C.BASE}):Play()
            end)
            btn.Activated:Connect(function() _closeCtx(); item.action() end)
            totalH = totalH + 32
        end

        _activeCtx = menu
        TweenService:Create(menu, C.T_MED, {Size = UDim2.fromOffset(160, totalH)}):Play()

        Library:_trackConnection(UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                task.defer(_closeCtx)
            end
        end))
    end

    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            openMenu(input.Position.X, input.Position.Y)
        end
        if input.UserInputType == Enum.UserInputType.Touch then
            pressThread = task.delay(0.45, function()
                openMenu(input.Position.X, input.Position.Y)
                pressThread = nil
            end)
        end
    end)
    target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and pressThread then
            task.cancel(pressThread); pressThread = nil
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- 15. SECTION GROUP COMPONENT (Toggles + Sliders, Carved)
-- ─────────────────────────────────────────────────────────────────

local function _applyToggleVisual(stroke, knob, pillBg, active)
    local c   = active and C.ACCENT    or C.BORDER
    local bg  = active and C.ACTIVE_BG or C.BASE
    local kc  = active and C.ACCENT    or C.BORDER
    local kp  = active and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    TweenService:Create(stroke,  C.T_MED,  {Color = c}):Play()
    TweenService:Create(pillBg,  C.T_SLOW, {BackgroundColor3 = bg}):Play()
    TweenService:Create(knob,    C.T_MED,  {BackgroundColor3 = kc, Position = kp}):Play()
end

local function _makeToggle(parent, cfg)
    local key     = cfg._key or cfg.label
    local state   = cfg.default or false
    StateManager._state[key] = state

    local row = _frame(parent, UDim2.new(1, 0, 0, cfg.subLabel and 48 or 36), nil, C.RAIL)
    _corner(row); local rowStroke = _stroke(row)
    _padding(row, 10)

    local lbl = _label(row, cfg.label, C.F_MEDIUM, 11, C.TEXT)
    lbl.Size = UDim2.new(0.65, 0, 0, 14)

    if cfg.subLabel then
        local sub = _label(row, cfg.subLabel, C.F_MONO, 10, C.DIM)
        sub.Size     = UDim2.new(0.65, 0, 0, 12)
        sub.Position = UDim2.fromOffset(0, 18)
    end

    -- Pill
    local pillBg = _frame(row, UDim2.fromOffset(36, 18), nil, state and C.ACTIVE_BG or C.BASE)
    pillBg.AnchorPoint = Vector2.new(1, 0.5)
    pillBg.Position    = UDim2.new(1, 0, 0.5, 0)
    _corner(pillBg, UDim.new(1, 0))
    local pillStroke = _stroke(pillBg, state and C.ACCENT or C.BORDER)

    local knob = _frame(pillBg, UDim2.fromOffset(12, 12), nil, state and C.ACCENT or C.BORDER)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position    = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    _corner(knob, UDim.new(1, 0))

    local function toggle()
        state = not state
        StateManager.set(key, state)
        _applyToggleVisual(pillStroke, knob, pillBg, state)
        _applyToggleVisual(rowStroke,  knob, pillBg, state)
        if cfg.onChange then Library:SafeCall(cfg.onChange, state) end
    end

    row.InputBegan:Connect(_debounce("toggle_" .. key, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then toggle() end
    end))

    StateManager.watch(key, function(v)
        if v ~= state then
            state = v
            _applyToggleVisual(pillStroke, knob, pillBg, state)
            _applyToggleVisual(rowStroke,  knob, pillBg, state)
        end
    end)

    if cfg.tooltip then _attachTooltip(row, cfg.tooltip) end
    if cfg.featureId then
        _attachContextMenu(row, cfg.featureId, function()
            state = cfg.default or false
            StateManager.set(key, state)
            _applyToggleVisual(pillStroke, knob, pillBg, state)
        end)
    end

    return row
end

local function _makeSlider(parent, cfg)
    local key   = cfg._key or cfg.label
    local value = cfg.default or cfg.min or 0
    StateManager._state[key] = value

    local row = _frame(parent, UDim2.new(1, 0, 0, cfg.subLabel and 52 or 42), nil, C.RAIL)
    _corner(row); local rowStroke = _stroke(row)
    _padding(row, 10)

    local lbl = _label(row, cfg.label, C.F_MEDIUM, 11, C.TEXT)
    lbl.Size = UDim2.new(0.7, 0, 0, 14)

    if cfg.subLabel then
        local sub = _label(row, cfg.subLabel, C.F_MONO, 10, C.DIM)
        sub.Size     = UDim2.new(0.7, 0, 0, 12)
        sub.Position = UDim2.fromOffset(0, 18)
    end

    local readout = _label(row, tostring(value) .. (cfg.suffix or ""), C.F_MONO, 11, C.ACCENT)
    readout.AnchorPoint    = Vector2.new(1, 0)
    readout.Size           = UDim2.new(0.28, 0, 0, 14)
    readout.Position       = UDim2.new(1, 0, 0, 0)
    readout.TextXAlignment = Enum.TextXAlignment.Right

    local trackY = cfg.subLabel and 34 or 28
    local track = _frame(row, UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, trackY), C.BORDER)

    local fill = _frame(track, UDim2.fromScale(
        (value - (cfg.min or 0)) / math.max((cfg.max or 100) - (cfg.min or 0), 1), 1
    ), nil, C.ACCENT)

    local dragging = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)

    Library:_trackConnection(UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local newVal = math.floor(cfg.min + pct * (cfg.max - cfg.min))
        value = newVal
        fill.Size     = UDim2.fromScale(pct, 1)
        readout.Text  = tostring(newVal) .. (cfg.suffix or "")
        StateManager.set(key, newVal)
        if cfg.onChange then Library:SafeCall(cfg.onChange, newVal) end
    end))

    Library:_trackConnection(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    if cfg.tooltip  then _attachTooltip(row, cfg.tooltip) end
    return row
end

local function _makeKeybind(parent, cfg)
    local currentKey = cfg.key or Enum.KeyCode.F
    local state      = cfg.mode == "AlwaysOn"
    local binding    = false

    local row = _frame(parent, UDim2.new(1, 0, 0, 36), nil, C.RAIL)
    _corner(row); local rowStroke = _stroke(row)
    _padding(row, 10)

    _label(row, cfg.label, C.F_MEDIUM, 11, C.TEXT).Size = UDim2.new(0.45, 0, 1, 0)

    local rightFrame = _frame(row, UDim2.new(0.55, 0, 1, 0), nil, C.RAIL)
    rightFrame.BackgroundTransparency = 1
    rightFrame.AnchorPoint = Vector2.new(1, 0)
    rightFrame.Position    = UDim2.new(1, 0, 0, 0)
    _listLayout(rightFrame, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local modeMap = {Hold="HLD", Toggle="TGL", AlwaysOn="AON"}

    local modeBadge = _frame(rightFrame, UDim2.fromOffset(32, 18), nil, C.BASE)
    _corner(modeBadge, UDim.new(0, 3)); _stroke(modeBadge, C.BORDER)
    local mbl = _label(modeBadge, modeMap[cfg.mode] or "TGL", C.F_MONO, 9, C.ACCENT)
    mbl.Size = UDim2.fromScale(1, 1); mbl.TextXAlignment = Enum.TextXAlignment.Center

    local keyDisplay = _frame(rightFrame, UDim2.fromOffset(52, 18), nil, C.BASE)
    _corner(keyDisplay, UDim.new(0, 3)); local keyStroke = _stroke(keyDisplay, C.BORDER)
    local kdl = _label(keyDisplay, currentKey.Name, C.F_MONO, 10, C.TEXT)
    kdl.Size = UDim2.fromScale(1, 1); kdl.TextXAlignment = Enum.TextXAlignment.Center

    local function setState(active)
        if cfg.mode == "AlwaysOn" then return end
        state = active
        local col = active and C.ACCENT or C.BORDER
        TweenService:Create(rowStroke,  C.T_MED, {Color = col}):Play()
        TweenService:Create(keyStroke,  C.T_MED, {Color = col}):Play()
        if cfg.onChange then Library:SafeCall(cfg.onChange, active) end
    end

    keyDisplay.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        binding = true; kdl.Text = "..."; kdl.TextColor3 = C.ACCENT
    end)

    Library:_trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey      = input.KeyCode
                kdl.Text        = currentKey.Name
                kdl.TextColor3  = C.TEXT
                binding         = false
            end
            return
        end
        if processed or input.KeyCode ~= currentKey then return end
        if cfg.mode == "Toggle" then setState(not state)
        elseif cfg.mode == "Hold" then setState(true) end
    end))

    Library:_trackConnection(UserInputService.InputEnded:Connect(function(input)
        if cfg.mode == "Hold" and input.KeyCode == currentKey then setState(false) end
    end))

    if cfg.mode == "AlwaysOn" then setState(true) end
    return row
end

-- Validator
local _VALID_RULES = {
    toggle  = { label="string", default="boolean", onChange="function" },
    slider  = { label="string", min="number", max="number", default="number", onChange="function" },
    keybind = { label="string", mode="string", onChange="function" },
}

local function _validateItem(item)
    local rules = _VALID_RULES[item.type]
    if not rules then Library:Log("Error", "Unknown item type: " .. tostring(item.type)); return nil end
    local clean = { type = item.type }
    for field, expectedType in pairs(rules) do
        local v = item[field]
        if v ~= nil and type(v) ~= expectedType then
            Library:Log("Error", string.format("Field '%s' expected %s got %s. Reverting.", field, expectedType, type(v)))
            -- skip invalid, use raw item's field anyway (fallback)
        else
            clean[field] = v
        end
    end
    -- Copy all other fields
    for k, v in pairs(item) do
        if clean[k] == nil then clean[k] = v end
    end
    return clean
end

function Library:AddSection(parent, title, items)
    local group = _frame(parent, UDim2.new(1, 0, 0, 0), nil, C.BASE)
    group.AutomaticSize    = Enum.AutomaticSize.Y
    group.BackgroundTransparency = 1
    group.Name             = "SectionGroup_" .. title
    _listLayout(group, Enum.FillDirection.Vertical, 4)

    -- Section header: orange, uppercase, 11px bold
    local header = _label(group, string.upper(title), C.F_BOLD, 11, C.ACCENT)
    header.Size = UDim2.new(1, 0, 0, 16)
    local hp = Instance.new("UIPadding")
    hp.PaddingLeft = UDim.new(0, 2); hp.Parent = header

    for _, item in ipairs(items or {}) do
        local clean = _validateItem(item)
        if clean then
            if clean.type == "toggle"  then _makeToggle(group, clean)
            elseif clean.type == "slider"  then _makeSlider(group, clean)
            elseif clean.type == "keybind" then _makeKeybind(group, clean)
            end
        end
    end

    return group
end

-- ─────────────────────────────────────────────────────────────────
-- 16. BREADCRUMB BAR
-- ─────────────────────────────────────────────────────────────────

local BreadcrumbBar = {}
local _bcContainer  = nil
local _bcPath       = {}
local _bcWatchers   = {}

local function _rebuildBreadcrumb()
    if not _bcContainer then return end
    for _, child in ipairs(_bcContainer:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
    for i, crumb in ipairs(_bcPath) do
        local isLast = i == #_bcPath
        local lbl = _label(_bcContainer, string.upper(crumb), C.F_BOLD, 11,
            isLast and C.TEXT or C.DIM)
        lbl.AutomaticSize = Enum.AutomaticSize.XY
        lbl.Size = UDim2.fromOffset(0, 0)

        if not isLast then
            lbl.MouseEnter:Connect(function()
                TweenService:Create(lbl, C.T_FAST, {TextColor3 = C.ACCENT}):Play()
            end)
            lbl.MouseLeave:Connect(function()
                TweenService:Create(lbl, C.T_FAST, {TextColor3 = C.DIM}):Play()
            end)

            local div = _label(_bcContainer, "/", C.F_BOLD, 11, C.BORDER)
            div.AutomaticSize = Enum.AutomaticSize.XY
            div.Size = UDim2.fromOffset(0, 0)
        end
    end
end

function BreadcrumbBar.init(container)
    _bcContainer = container
    _listLayout(container, Enum.FillDirection.Horizontal, 6, nil, Enum.VerticalAlignment.Center)
end

function BreadcrumbBar.push(tabName, sectionName)
    _bcPath = sectionName and {tabName, sectionName} or {tabName}
    _rebuildBreadcrumb()
end

function BreadcrumbBar.watch(tabContainer, sectionMap)
    for _, conn in ipairs(_bcWatchers) do conn:Disconnect() end
    _bcWatchers = {}

    for _, tabFrame in ipairs(tabContainer:GetChildren()) do
        if not tabFrame:IsA("Frame") then continue end
        local conn = Library:_trackConnection(
            tabFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                if not tabFrame.Visible then return end
                local sectionName = nil
                local sf = sectionMap and sectionMap[tabFrame.Name]
                if sf then
                    for _, sec in ipairs(sf:GetChildren()) do
                        if sec:IsA("Frame") and sec.Visible then
                            sectionName = sec.Name:gsub("SectionGroup_", ""); break
                        end
                    end
                end
                BreadcrumbBar.push(tabFrame.Name, sectionName)
            end)
        )
        table.insert(_bcWatchers, conn)
    end
end

-- ─────────────────────────────────────────────────────────────────
-- 17. MINIMIZED PILL
-- ─────────────────────────────────────────────────────────────────

local MinimizedPill = {}
local _pill         = nil
local _pillTicker   = nil
local _pillThread   = nil

function MinimizedPill.build(parent)
    local PILL_H   = 40
    local PILL_W   = 180

    local frame = _frame(parent, UDim2.fromOffset(PILL_H, PILL_H), nil, C.RAIL, C.Z_PILL)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position    = UDim2.new(0.5, 0, 1, PILL_H + 8)
    frame.Visible     = false
    frame.ClipsDescendants = true
    _corner(frame, C.RADIUS_LG)
    _stroke(frame)

    _listLayout(frame, Enum.FillDirection.Horizontal, 0, nil, Enum.VerticalAlignment.Center)

    -- Icon container
    local iconBox = _frame(frame, UDim2.fromOffset(PILL_H, PILL_H), nil, C.RAIL)
    iconBox.BackgroundTransparency = 1
    local icon = IconService.get("zap")
    icon.Name        = "CUI_PillIcon"
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position    = UDim2.fromScale(0.5, 0.5)
    icon.Parent      = iconBox

    -- Divider
    local div = _frame(frame, UDim2.new(0, 1, 0, 20), nil, C.BORDER)

    -- Ticker label
    local ticker = _label(frame, "IDLE", C.F_MONO, 10, C.DIM)
    ticker.Name = "Ticker"
    ticker.Size = UDim2.new(1, -(PILL_H + 1), 1, 0)
    ticker.TextXAlignment  = Enum.TextXAlignment.Left
    ticker.TextTruncate    = Enum.TextTruncate.AtEnd
    local tp = Instance.new("UIPadding")
    tp.PaddingLeft = UDim.new(0, 8); tp.Parent = ticker

    _pill = frame
    _pillTicker = ticker

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            MinimizedPill.restore()
        end
    end)

    return frame
end

function MinimizedPill.show(mainWindow)
    if not _pill then return end
    TweenService:Create(mainWindow, C.T_FAST, {
        Size = UDim2.fromOffset(mainWindow.AbsoluteSize.X, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.18, function()
        mainWindow.Visible = false
        _pill.Visible      = true
        TweenService:Create(_pill, C.T_MED, {
            Size = UDim2.fromOffset(180, 40)
        }):Play()
    end)
end

function MinimizedPill.setTicker(texts, interval)
    if _pillThread then task.cancel(_pillThread); _pillThread = nil end
    if not _pillTicker then return end
    local idx = 1
    _pillTicker.Text = string.upper(texts[1] or "IDLE")
    _pillThread = Library:_trackThread(task.spawn(function()
        while true do
            task.wait(interval or 2.5)
            idx = (idx % #texts) + 1
            TweenService:Create(_pillTicker, C.T_FAST, {TextTransparency=1}):Play()
            task.wait(0.1)
            _pillTicker.Text = string.upper(texts[idx])
            TweenService:Create(_pillTicker, C.T_FAST, {TextTransparency=0}):Play()
        end
    end))
end

function MinimizedPill.restore()
    -- Override this from Library.new()
end

-- ─────────────────────────────────────────────────────────────────
-- 18. DEBUG WATERMARK + PERF MONITOR
-- ─────────────────────────────────────────────────────────────────

local PerfMonitor = {}
local _fps = 0; local _ping = 0

-- FPS off-thread
Library:_trackThread(task.spawn(function()
    local frames, elapsed = 0, 0
    Library:_trackConnection(RunService.Heartbeat:Connect(function(dt)
        frames  = frames + 1
        elapsed = elapsed + dt
        if elapsed >= 1 then _fps = frames; frames = 0; elapsed = 0 end
    end))
end))

-- Ping off-thread
Library:_trackThread(task.spawn(function()
    while true do
        task.wait(2)
        local ok, result = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        _ping = ok and math.floor(result) or 0
    end
end))

function PerfMonitor.getFPS()  return _fps  end
function PerfMonitor.getPing() return _ping end

local _watermarkLabel = nil
local _watermarkFrame = nil

local function _buildWatermark(parent)
    local frame = _frame(parent, UDim2.fromOffset(240, 24), nil, C.BASE, C.Z_WATERMARK)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.Position    = UDim2.new(1, -8, 1, -8)
    frame.BackgroundTransparency = 1
    frame.Visible     = false
    frame.Name        = "CUI_Watermark"

    local lbl = _label(frame, "", C.F_MONO, 10, C.BORDER)
    lbl.Size             = UDim2.fromScale(1, 1)
    lbl.TextXAlignment   = Enum.TextXAlignment.Right
    lbl.TextYAlignment   = Enum.TextYAlignment.Bottom
    lbl.ZIndex           = C.Z_WATERMARK

    _watermarkFrame = frame
    _watermarkLabel = lbl

    Library:_trackThread(task.spawn(function()
        while true do
            task.wait(2)
            if _watermarkFrame and _watermarkFrame.Visible then
                local mem = math.floor(gcinfo() / 1024 * 100) / 100
                _watermarkLabel.Text = string.format(
                    "%s · %dFPS · %dMS · %.2fMB",
                    ENV_LABEL, _fps, _ping, mem
                )
                -- Memory warning
                if mem > C.MEMORY_WARN then
                    Library:Log("Warn", string.format("Memory high: %.1fMB (>%dMB)", mem, C.MEMORY_WARN))
                end
            end
        end
    end))

    return frame
end

function Library:SetDebug(enabled)
    self.Debug = enabled
    if _watermarkFrame then _watermarkFrame.Visible = enabled end
end

-- ─────────────────────────────────────────────────────────────────
-- 19. BOTTOM DRAWER (Mobile)
-- ─────────────────────────────────────────────────────────────────

local BottomDrawer = {}
local _drawer      = nil
local _drawerOpen  = false

local function _buildDrawer(parent, sidebarContent)
    local HANDLE_H   = 20
    local DRAW_PCT   = 0.72
    local vp         = workspace.CurrentCamera.ViewportSize

    local frame = _frame(parent, UDim2.new(1, 0, DRAW_PCT, 0), nil, C.BASE, C.Z_DRAWER)
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Position    = UDim2.new(0, 0, 1, HANDLE_H)
    _corner(frame, C.RADIUS_LG)
    _stroke(frame)

    local handle = _frame(frame, UDim2.new(1, 0, 0, HANDLE_H), nil, C.BASE)
    handle.BackgroundTransparency = 1

    local pill = _frame(handle, UDim2.fromOffset(36, 4), nil, C.BORDER)
    pill.AnchorPoint = Vector2.new(0.5, 0.5)
    pill.Position    = UDim2.fromScale(0.5, 0.5)
    _corner(pill, UDim.new(1, 0))

    sidebarContent.Parent   = frame
    sidebarContent.Position = UDim2.fromOffset(0, HANDLE_H)
    sidebarContent.Size     = UDim2.new(1, 0, 1, -HANDLE_H)

    local OPEN_POS  = UDim2.new(0, 0, 1 - DRAW_PCT, -HANDLE_H)
    local CLOSE_POS = UDim2.new(0, 0, 1, HANDLE_H)
    local tweenInfo = C.T_MED
    local dragStart, totalDelta = nil, 0

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragStart  = input.Position.Y
            totalDelta = 0
        end
    end)

    Library:_trackConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragStart then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        totalDelta = input.Position.Y - dragStart
        local newScale = (1 - DRAW_PCT) + (totalDelta / vp.Y)
        frame.Position = UDim2.new(0, 0, math.clamp(newScale, 1 - DRAW_PCT, 1), 0)
    end))

    Library:_trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch or not dragStart then return end
        if totalDelta < -80 then
            TweenService:Create(frame, tweenInfo, {Position = OPEN_POS}):Play(); _drawerOpen = true
        elseif totalDelta > 80 then
            TweenService:Create(frame, tweenInfo, {Position = CLOSE_POS}):Play(); _drawerOpen = false
        else
            TweenService:Create(frame, tweenInfo, {Position = _drawerOpen and OPEN_POS or CLOSE_POS}):Play()
        end
        dragStart = nil
    end))

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and math.abs(totalDelta) < 8 then
            _drawerOpen = not _drawerOpen
            TweenService:Create(frame, tweenInfo, {Position = _drawerOpen and OPEN_POS or CLOSE_POS}):Play()
        end
    end)

    _drawer = frame
    return frame
end

-- ─────────────────────────────────────────────────────────────────
-- 20. PROTECTION & OBFUSCATION
-- ─────────────────────────────────────────────────────────────────

local Protection = {}

function Protection.lockTable(t)
    if UNC.setreadonly then pcall(setreadonly, t, true) end
    return t
end

function Protection.unlockTable(t)
    if UNC.make_writeable then pcall(make_writeable, t)
    elseif UNC.setreadonly then pcall(setreadonly, t, false) end
    return t
end

function Protection.wrapFunction(fn)
    if UNC.newcclosure then
        local ok, wrapped = pcall(newcclosure, fn)
        if ok then return wrapped end
    end
    return fn
end

function Protection.maskStrings(fn, target, replacement)
    if not UNC.debug_setconst then return end
    local i = 0
    while true do
        i = i + 1
        local ok, val = pcall(debug.getconstant, fn, i)
        if not ok then break end
        if val == target then pcall(debug.setconstant, fn, i, replacement) end
    end
end

function Protection.obfuscateGui(gui)
    for _, inst in ipairs(gui:GetDescendants()) do
        pcall(function() inst.Name = _randName(10) end)
        if UNC.cloneref then pcall(cloneref, inst) end
    end
    pcall(function() gui.Name = _randName(12) end)
end

function Protection.startObfuscateCycle(gui, interval)
    Library:_trackThread(task.spawn(function()
        while true do
            task.wait(interval or 30)
            Protection.obfuscateGui(gui)
        end
    end))
end

function Protection.exposeGlobal()
    if not UNC.getgenv then return end
    local proxy = {}
    setmetatable(proxy, {
        __index    = function(_, key) return StateManager._state[key] end,
        __newindex = function(_, key, _)
            Library:Log("Warn", "getgenv().ClaudeUI." .. tostring(key) .. " is read-only.")
        end,
        __metatable = "locked",
    })
    local ok, env = pcall(getgenv)
    if ok then env.ClaudeUI = proxy end
end

-- ─────────────────────────────────────────────────────────────────
-- 21. PLUGIN SYSTEM
-- ─────────────────────────────────────────────────────────────────

local PluginSystem = {}
local _plugins     = {}

function PluginSystem.register(plugin)
    assert(type(plugin.name)   == "string",   "Plugin.name must be string")
    assert(type(plugin.onLoad) == "function", "Plugin.onLoad must be function")
    for _, p in ipairs(_plugins) do
        if p.name == plugin.name then
            Library:Log("Warn", "Plugin '" .. plugin.name .. "' already registered."); return
        end
    end
    table.insert(_plugins, plugin)
    Library:Log("Info", "Plugin registered: " .. plugin.name)
end

function PluginSystem.loadAll()
    for _, plugin in ipairs(_plugins) do
        local ok, err = pcall(plugin.onLoad, Library)
        if not ok then Library:Log("Error", "Plugin '" .. plugin.name .. "' failed: " .. tostring(err))
        else Library:Log("Info", "Plugin loaded: " .. plugin.name) end
    end
end

-- ─────────────────────────────────────────────────────────────────
-- 22. VERSION CHECK
-- ─────────────────────────────────────────────────────────────────

local function _checkVersion()
    Library:_trackThread(task.spawn(function()
        local ok, result = pcall(function()
            return HttpService:GetAsync(C.VERSION_URL, true)
        end)
        if not ok then Library:Log("Warn", "Version check failed."); return end
        local latest = result:match("^%s*(.-)%s*$")
        if latest ~= C.VERSION then
            Library:Log("Warn", string.format("Update available: v%s → v%s", C.VERSION, latest))
        else
            Library:Log("Info", "ClaudeUI is up to date (v" .. C.VERSION .. ")")
        end
    end))
end

-- ─────────────────────────────────────────────────────────────────
-- 23. DEPENDENCY AUDIT
-- ─────────────────────────────────────────────────────────────────

local function _auditDependencies()
    -- HttpService
    if not HttpService.HttpEnabled and IS_STUDIO then
        Library:Log("Warn", "HttpService disabled in Studio. Version check won't work.")
    end
    -- File I/O
    if not IS_STUDIO and not UNC.writefile then
        Library:Log("Warn", "writefile() unavailable. Config saving disabled.")
    end
    -- Optional UNC
    local missing = {}
    for fnName, available in pairs(UNC) do
        if not available then table.insert(missing, fnName) end
    end
    if #missing > 0 then
        Library:Log("Info", "Optional UNC missing: " .. table.concat(missing, ", "))
    end
end

-- ─────────────────────────────────────────────────────────────────
-- 24. TAB SYSTEM + MAIN WINDOW BUILDER
-- ─────────────────────────────────────────────────────────────────

function Library:AddTab(name, iconName)
    -- Returns a content frame for that tab
    local tab = {
        name    = name,
        icon    = iconName,
        frame   = nil,   -- set in _buildWindow
        button  = nil,
    }
    table.insert(self._tabs, tab)
    return tab
end

local function _buildWindow(self, config)
    -- config: { title, subtitle, width, height }
    local profile = LayoutManager.getProfile()
    local isPhone = LayoutManager.isPhone()

    -- Root ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name                  = "ClaudeUI"
    screenGui.ResetOnSpawn          = false
    screenGui.ZIndexBehavior        = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder          = 999
    screenGui.IgnoreGuiInset        = false
    screenGui.Parent                = _getSafeParent()
    self._gui = screenGui

    -- Watermark + toasts live here
    _buildWatermark(screenGui)
    MinimizedPill.build(screenGui)

    if isPhone then
        -- Phone: full-screen approach handled by BottomDrawer
        -- Main content pane fills screen
        local mainFrame = _frame(screenGui, UDim2.fromScale(1, 1), nil, C.BASE, C.Z_BASE)
        mainFrame.Name = "CUI_Main"

        -- Breadcrumb
        local bc = _frame(mainFrame, UDim2.new(1, 0, 0, 32), nil, C.RAIL, C.Z_RAIL)
        bc.Position = UDim2.fromOffset(0, 0)
        _padding(bc, 8)
        BreadcrumbBar.init(bc)

        -- Content scroll area
        local contentScroll = Instance.new("ScrollingFrame")
        contentScroll.Size             = UDim2.new(1, 0, 1, -32)
        contentScroll.Position         = UDim2.fromOffset(0, 32)
        contentScroll.BackgroundColor3 = C.BASE
        contentScroll.BorderSizePixel  = 0
        contentScroll.ScrollBarThickness = 0
        contentScroll.CanvasSize       = UDim2.fromOffset(0, 0)
        contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentScroll.ZIndex           = C.Z_CONTENT
        contentScroll.Parent           = mainFrame
        _applyInertialScroll(contentScroll)

        -- Sidebar as BottomDrawer
        local sidebarFrame = _frame(screenGui, UDim2.fromScale(1, 1), nil, C.RAIL)
        sidebarFrame.Visible = false
        _buildDrawer(screenGui, sidebarFrame)

        self._contentFrame = contentScroll
        self._mainFrame    = mainFrame
        return screenGui
    end

    -- Desktop/Tablet window
    local winW = config.width  or profile.winSize and profile.winSize.X or 600
    local winH = config.height or profile.winSize and profile.winSize.Y or 420

    -- Center on screen
    local vp     = workspace.CurrentCamera.ViewportSize
    local startX = math.max(0, (vp.X - winW) / 2)
    local startY = math.max(GuiService:GetGuiInset().Y, (vp.Y - winH) / 2)

    local window = _frame(screenGui,
        UDim2.fromOffset(winW, winH),
        UDim2.fromOffset(startX, startY),
        C.BASE, C.Z_BASE)
    window.Name           = "CUI_Window"
    window.ClipsDescendants = false
    _corner(window)
    _stroke(window)

    -- Title bar
    local titleBar = _frame(window, UDim2.new(1, 0, 0, 34), nil, C.RAIL, C.Z_RAIL)
    _stroke(titleBar, C.BORDER)

    -- Logo/title area
    local titleLbl = _label(titleBar, config.title or "ClaudeUI", C.F_BOLD, 12, C.TEXT)
    titleLbl.Size     = UDim2.new(0.5, 0, 1, 0)
    titleLbl.Position = UDim2.fromOffset(12, 0)

    -- Breadcrumb
    local bcFrame = _frame(titleBar, UDim2.new(0.35, 0, 1, 0), nil, C.RAIL, C.Z_RAIL)
    bcFrame.Position         = UDim2.fromScale(0.32, 0)
    bcFrame.BackgroundTransparency = 1
    BreadcrumbBar.init(bcFrame)

    -- Window controls
    local ctrlFrame = _frame(titleBar, UDim2.fromOffset(72, 34), nil, C.RAIL, C.Z_RAIL)
    ctrlFrame.AnchorPoint    = Vector2.new(1, 0)
    ctrlFrame.Position       = UDim2.new(1, 0, 0, 0)
    ctrlFrame.BackgroundTransparency = 1
    _listLayout(ctrlFrame, Enum.FillDirection.Horizontal, 2, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local cp = Instance.new("UIPadding")
    cp.PaddingRight = UDim.new(0, 8); cp.Parent = ctrlFrame

    local function _ctrlBtn(icon, zIndex)
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.fromOffset(20, 20)
        btn.BackgroundColor3 = C.RAIL
        btn.BorderSizePixel  = 0
        btn.Text             = ""
        btn.ZIndex           = zIndex or C.Z_SYSTEM
        btn.Parent           = ctrlFrame
        _corner(btn, UDim.new(1, 0))
        local ico = IconService.get(icon)
        ico.Size         = UDim2.fromOffset(12, 12)
        ico.AnchorPoint  = Vector2.new(0.5, 0.5)
        ico.Position     = UDim2.fromScale(0.5, 0.5)
        ico.ZIndex       = (zIndex or C.Z_SYSTEM) + 1
        ico.Parent       = btn
        return btn
    end

    local btnMin   = _ctrlBtn("minimize")
    local btnResize = _ctrlBtn("maximize")
    local btnClose  = _ctrlBtn("close")

    -- Close gets red hover
    btnClose.MouseEnter:Connect(function()
        TweenService:Create(btnClose, C.T_FAST, {BackgroundColor3 = C.ERROR}):Play()
    end)
    btnClose.MouseLeave:Connect(function()
        TweenService:Create(btnClose, C.T_FAST, {BackgroundColor3 = C.RAIL}):Play()
    end)
    btnClose.Activated:Connect(function()
        TweenService:Create(window, C.T_FAST, {
            Size = UDim2.fromOffset(winW, 0),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.15, function() self:Destroy() end)
    end)

    btnMin.Activated:Connect(function()
        MinimizedPill.show(window)
    end)
    MinimizedPill.restore = function()
        window.Visible = true
        TweenService:Create(window, C.T_MED, {
            Size = UDim2.fromOffset(winW, winH),
            BackgroundTransparency = 0
        }):Play()
    end

    local _maximized = false
    btnResize.Activated:Connect(function()
        _maximized = not _maximized
        local vp2 = workspace.CurrentCamera.ViewportSize
        TweenService:Create(window, C.T_MED, {
            Size = _maximized
                and UDim2.fromOffset(vp2.X * 0.85, vp2.Y * 0.85)
                or  UDim2.fromOffset(winW, winH),
            Position = _maximized
                and UDim2.fromOffset(vp2.X * 0.075, vp2.Y * 0.075)
                or  UDim2.fromOffset(startX, startY)
        }):Play()
    end)

    _applyDrag(titleBar, window)

    -- Body: sidebar + content
    local body = _frame(window, UDim2.new(1, 0, 1, -34), UDim2.fromOffset(0, 34), C.BASE, C.Z_BASE)
    _listLayout(body, Enum.FillDirection.Horizontal, 0)

    -- Command Rail (sidebar)
    local rail = _frame(body, UDim2.new(0, 140, 1, 0), nil, C.RAIL, C.Z_RAIL)
    _stroke(rail, C.BORDER)
    _listLayout(rail, Enum.FillDirection.Vertical, 2)
    _padding(rail, 8)

    -- Content area with scroll
    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Size                = UDim2.new(1, -140, 1, 0)
    contentScroll.BackgroundColor3    = C.BASE
    contentScroll.BorderSizePixel     = 0
    contentScroll.ScrollBarThickness  = 0
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.CanvasSize          = UDim2.fromOffset(0, 0)
    contentScroll.ZIndex              = C.Z_CONTENT
    contentScroll.Parent              = body
    _applyInertialScroll(contentScroll)

    local contentPad = _padding(contentScroll, 12)

    local contentLayout = _listLayout(contentScroll, Enum.FillDirection.Vertical, 12)

    self._window       = window
    self._rail         = rail
    self._contentFrame = contentScroll
    self._mainFrame    = window

    -- Build tab buttons and content frames
    local _tabFrames = {}
    local function _activateTab(tab)
        for _, t in ipairs(self._tabs) do
            if t.frame then t.frame.Visible = (t == tab) end
            if t.button then
                TweenService:Create(t.button, C.T_MED, {
                    BackgroundColor3 = (t == tab) and C.ACTIVE_BG or C.RAIL
                }):Play()
                local bs = t.button:FindFirstChildOfClass("UIStroke")
                if bs then
                    TweenService:Create(bs, C.T_MED, {
                        Color = (t == tab) and C.ACCENT or C.BORDER
                    }):Play()
                end
            end
        end
        BreadcrumbBar.push(tab.name)
    end

    for _, tab in ipairs(self._tabs) do
        -- Tab button in rail
        local tabBtn = _frame(rail, UDim2.new(1, 0, 0, 36), nil, C.RAIL, C.Z_RAIL)
        _corner(tabBtn); _stroke(tabBtn)
        local tbLabel = _label(tabBtn, tab.name, C.F_MEDIUM, 11, C.TEXT)
        tbLabel.Size = UDim2.new(1, -8, 1, 0)
        tbLabel.Position = UDim2.fromOffset(8, 0)

        -- Tab content frame inside scroll
        local tabContent = _frame(contentScroll, UDim2.new(1, 0, 0, 0), nil, C.BASE, C.Z_CONTENT)
        tabContent.AutomaticSize    = Enum.AutomaticSize.Y
        tabContent.BackgroundTransparency = 1
        tabContent.Visible          = false
        tabContent.Name             = "TabContent_" .. tab.name
        _listLayout(tabContent, Enum.FillDirection.Vertical, 12)

        -- Two-column auto layout
        Library:_trackConnection(tabContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local isWide = tabContent.AbsoluteSize.X >= 700
            for _, child in ipairs(tabContent:GetChildren()) do
                if child:IsA("UIGridLayout") or child:IsA("UIListLayout") then child:Destroy() end
            end
            if isWide then
                local grid = Instance.new("UIGridLayout")
                grid.CellSize      = UDim2.new(0.5, -6, 0, 0)
                grid.CellPaddingHorizontal = UDim.new(0, 12)
                grid.CellPaddingVertical   = UDim.new(0, 4)
                grid.FillDirection = Enum.FillDirection.Horizontal
                grid.Parent        = tabContent
            else
                _listLayout(tabContent, Enum.FillDirection.Vertical, 12)
            end
        end))

        tab.button = tabBtn
        tab.frame  = tabContent

        tabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                _activateTab(tab)
            end
        end)
    end

    -- Activate first tab
    if self._tabs[1] then _activateTab(self._tabs[1]) end

    -- Resize viewport watcher
    Library:_trackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local newProfile = LayoutManager.getProfile()
    end))

    return screenGui
end

-- ─────────────────────────────────────────────────────────────────
-- 25. LIBRARY.HELP
-- ─────────────────────────────────────────────────────────────────

function Library:Help(filter)
    local API = {
        {"Library.new(config)",               "Create a new ClaudeUI window"},
        {"Library:AddTab(name, icon?)",        "Create a navigation tab, returns tab object"},
        {"Library:AddSection(tab, title, items)", "Add a SectionGroup to a tab frame"},
        {"Library:Log(type, message)",         "Console warn + optional toast (if Debug=true)"},
        {"Library:SafeCall(fn, ...)",          "xpcall wrapper for user callbacks"},
        {"Library:Save(filename?)",            "Write config to disk"},
        {"Library:Load(filename?, defaults?)", "Load and sanitize config from disk"},
        {"Library:AutoLoad(defaults?)",        "Load profile for current game.PlaceId"},
        {"Library:AutoSave()",                 "Save profile for current game.PlaceId"},
        {"Library:SetDebug(bool)",             "Toggle watermark + error toasts"},
        {"Library:Destroy()",                  "Full teardown: tweens, connections, blur"},
        {"Library:Help(filter?)",              "Print this API reference"},
        {"StateManager.set(key, value)",       "Update state, fires all watchers"},
        {"StateManager.get(key)",              "Read current state value"},
        {"StateManager.watch(key, fn)",        "Subscribe to state changes, returns unsubscribe fn"},
        {"History.undo()",                     "Revert last state change (Ctrl+Z)"},
        {"History.redo()",                     "Re-apply undone change (Ctrl+Y)"},
        {"IconService.get(name, theme?)",      "Get ImageLabel from spritesheet"},
        {"PluginSystem.register(plugin)",      "Register a custom tab plugin"},
        {"PluginSystem.loadAll()",             "Execute all registered plugins"},
        {"BreadcrumbBar.push(tab, section?)", "Manually update breadcrumb path"},
        {"MinimizedPill.setTicker(texts, interval?)", "Set pill status ticker strings"},
        {"Protection.lockTable(t)",            "setreadonly on a table"},
        {"Protection.exposeGlobal()",          "Expose read-only state to getgenv().ClaudeUI"},
    }

    local LINE = string.rep("─", 64)
    warn("[CLAUDE-UI] ═══ API REFERENCE v" .. C.VERSION .. " ═══")
    warn(LINE)
    for _, entry in ipairs(API) do
        if not filter or entry[1]:lower():find(filter:lower(), 1, true) then
            warn(string.format("  %-45s %s", entry[1], entry[2]))
        end
    end
    warn(LINE)
    warn(string.format("  %d methods. Usage: Library:Help('keyword')", #API))
end

-- ─────────────────────────────────────────────────────────────────
-- 26. LIBRARY:DESTROY — CLEAN EXIT
-- ─────────────────────────────────────────────────────────────────

function Library:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- Auto-save before exit
    pcall(function() self:AutoSave() end)

    -- Cancel all tweens
    for _, tween in ipairs(self._tweens) do
        pcall(function() tween:Cancel() end)
    end
    self._tweens = {}

    -- Disconnect all connections
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}

    -- Cancel threads
    for _, thread in ipairs(self._threads) do
        pcall(task.cancel, thread)
    end
    self._threads = {}

    -- Cancel pill ticker
    if _pillThread then pcall(task.cancel, _pillThread); _pillThread = nil end

    -- Disconnect breadcrumb watchers
    for _, conn in ipairs(_bcWatchers) do pcall(function() conn:Disconnect() end) end
    _bcWatchers = {}

    -- Remove BlurEffect
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("BlurEffect") and child.Name == "CUI_Blur" then
            child:Destroy()
        end
    end

    -- Destroy GUI
    if self._gui and self._gui.Parent then
        pcall(function() self._gui:Destroy() end)
        self._gui = nil
    end

    -- Null library via metamethod so further calls error clearly
    setmetatable(self, {
        __index = function(_, key)
            error("[CLAUDE-UI] Library has been destroyed. Accessed: " .. tostring(key), 2)
        end,
        __newindex = function()
            error("[CLAUDE-UI] Library has been destroyed.", 2)
        end,
    })

    warn("[CLAUDE-UI] [INFO] Library destroyed cleanly.")
end

-- ─────────────────────────────────────────────────────────────────
-- 27. LIBRARY.NEW — ENTRY POINT
-- ─────────────────────────────────────────────────────────────────

function Library.new(config)
    config = config or {}

    -- Run startup checks silently
    _auditDependencies()

    -- Build window (tabs must be added before calling new,
    -- or use Library:AddTab after and call Library:Rebuild())
    local gui = _buildWindow(Library, config)

    -- Protection
    if not IS_STUDIO then
        Protection.obfuscateGui(gui)
        Protection.startObfuscateCycle(gui, 30)
        Protection.exposeGlobal()
    end

    -- Load plugins
    PluginSystem.loadAll()

    -- Version check (async)
    _checkVersion()

    -- Debug mode from config
    if config.debug then Library:SetDebug(true) end

    -- Apply blur if configured
    if config.blur then
        local blur = Instance.new("BlurEffect")
        blur.Name   = "CUI_Blur"
        blur.Size   = 8
        blur.Parent = Lighting
    end

    warn(string.format("[CLAUDE-UI] v%s initialised. ENV: %s | UNC: writefile=%s gethui=%s getreg=%s",
        C.VERSION, ENV_LABEL,
        tostring(UNC.writefile), tostring(UNC.gethui), tostring(UNC.getreg)
    ))

    return Library
end

-- ─────────────────────────────────────────────────────────────────
-- 28. PUBLIC API SURFACE
-- ─────────────────────────────────────────────────────────────────

-- Expose sub-systems for advanced use
Library.State        = StateManager
Library.History      = History
Library.Icons        = IconService
Library.Layout       = LayoutManager
Library.Storage      = StorageProvider
Library.Plugins      = PluginSystem
Library.Breadcrumb   = BreadcrumbBar
Library.Pill         = MinimizedPill
Library.Protect      = Protection
Library.UNC          = UNC           -- capability flags (read-only intent)

-- Lock the public table in executor environments
if not IS_STUDIO then
    pcall(Protection.lockTable, Library)
end

return Library

--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 USAGE EXAMPLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ClaudeUI = loadstring(game:HttpGet("..."))()

-- 1. Create tabs before building window
local combatTab  = ClaudeUI:AddTab("Combat",  "crosshair")
local visualsTab = ClaudeUI:AddTab("Visuals", "eye")
local miscTab    = ClaudeUI:AddTab("Misc",    "settings")

-- 2. Init window
ClaudeUI.new({
    title  = "ClaudeUI",
    debug  = false,
    blur   = false,
})

-- 3. Add sections
ClaudeUI:AddSection(combatTab.frame, "Aimbot", {
    {
        type     = "toggle",
        label    = "Enabled",
        subLabel = "Master aimbot switch",
        default  = false,
        tooltip  = "Enables aim assistance. Use responsibly.",
        featureId = "aimbot_enabled",
        onChange  = function(v) print("Aimbot:", v) end,
    },
    {
        type    = "slider",
        label   = "FOV",
        subLabel = "Detection radius",
        min     = 10, max = 360, default = 120,
        suffix  = "°",
        onChange = function(v) print("FOV:", v) end,
    },
    {
        type  = "keybind",
        label = "Toggle Key",
        key   = Enum.KeyCode.X,
        mode  = "Toggle",
        onChange = function(v) print("Keybind active:", v) end,
    },
})

-- 4. Live pill ticker
ClaudeUI.Pill.setTicker({"AIMBOT: OFF", "FOV: 120", "v1.0.0"}, 2.5)

-- 5. Debug mode
ClaudeUI:SetDebug(true)

-- 6. Plugin example
ClaudeUI.Plugins.register({
    name    = "MyPlugin",
    version = "1.0",
    onLoad  = function(lib)
        local myTab = lib:AddTab("Plugin", "plugin")
        lib:AddSection(myTab.frame, "Custom", {
            { type="toggle", label="My Feature", default=false }
        })
    end,
})

-- 7. Cleanup
ClaudeUI:Destroy()
]]
