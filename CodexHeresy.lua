-- language: Lua, file: gemini-code-1790871675403_art_monitor.lua, target: Roblox
-- *standalone fusion: art class loop (with live level tracking + afk) running alongside the mass-account trade monitor*
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 9999)

if type(getgenv().Config) ~= "table" then
    getgenv().Config = { AutoArtClass = true, AutoCaptcha = true, AccountMonitor = true }
end

getgenv().IsCaptchaActive = false
local makeHttpRequest = request or http_request or (http and http.request) or fluxus or (syn and syn.request)

local PlayerState = { IsTyping = false, IsDrawing = false, LastInputTime = tick() }

local function safeFind(parent, ...)
    local current = parent
    for _, name in ipairs({...}) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local function moveMouseSmooth(targetX, targetY)
    local startPos = UserInputService:GetMouseLocation()
    local distance = math.sqrt((targetX - startPos.X)^2 + (targetY - startPos.Y)^2)
    if distance < 2 then
        VirtualInputManager:SendMouseMoveEvent(targetX, targetY, game)
        return
    end
    local steps = math.clamp(math.floor(distance / 20), 4, 10) 
    for i = 1, steps do
        local t = i / steps
        local currX = startPos.X + (targetX - startPos.X) * t
        local currY = startPos.Y + (targetY - startPos.Y) * t
        VirtualInputManager:SendMouseMoveEvent(currX, currY, game)
        task.wait(0.005)
    end
    VirtualInputManager:SendMouseMoveEvent(targetX, targetY, game)
end

local function humanClickAt(x, y)
    moveMouseSmooth(x, y)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- CAPTCHA SOLVER
if getgenv().Config.AutoCaptcha then
    task.spawn(function()
        local Captcha = { Solving = false, Cache = {}, LastClick = 0 }
        local BUTTON_HASHES = {
            ["40d02d582d76f54881f5f000c9a3712d"] = "1", ["3da8772a1380df0ea9d6e29e584d0dfa"] = "2",
            ["2ca84bc6e12650e6a29b371030041c71"] = "3", ["5abb9a3e809ddf2abec6bad6c30b9357"] = "4",
            ["f2183de3439a29ca186a1085a254ee36"] = "5", ["469569cf140da51f1b78fc640eaf6682"] = "6",
            ["ce4d4f4d3bc8cba41ae0ba9955d052c2"] = "7", ["4dcc9cb4f28e200508ace4b493e8b5b7"] = "8",
            ["151fa826f05ded1c9903149d0c451a1c"] = "9", ["fda452a0b122c2b4230fc74e5135c3fc"] = "10",
            ["8b7bec3549554a512cdc2a993ce8f441"] = "11", ["988d2aba9e47d6cafced32dbac0256ab"] = "12",
            ["6a3723b695d9e6900f8fcc9106b64008"] = "13", ["af300da49b235a2ea90d62f17fcfe8c7"] = "14",
            ["fd6700a486a6ced004db4d1d5eb8e098"] = "15",
        }

        local function captchaVisible()
            local cg = safeFind(PlayerGui, "CardCaptchaGame", "CaptchaGame")
            return cg and cg.Visible or false
        end

        local function getTargetId()
            local topCard = PlayerGui:FindFirstChild("CardCaptchaGame")
            if not topCard or not topCard.Enabled then return nil end
            local card = safeFind(topCard, "CaptchaGame", "Top", "Card")
            if not card then return nil end
            return string.match(card.Image, "id=(%d+)")
        end

        local function getButtonFromAPI(assetId)
            if not makeHttpRequest then return nil end
            local apiUrl = "https://roblox-captcharoyalehigh.lukekinqz.workers.dev/v1/assets?assetIds=" .. assetId .. "&returnPolicy=PlaceHolder&size=420x420&format=Webp"
            local success, response = pcall(function() return makeHttpRequest({ Url = apiUrl, Method = "GET" }) end)
            if success and response and response.StatusCode == 200 then
                local dSuccess, dec = pcall(function() return HttpService:JSONDecode(response.Body) end)
                if dSuccess and dec and dec.data and #dec.data > 0 then
                    local imgUrl = dec.data[1].imageUrl or ""
                    for hash, btn in pairs(BUTTON_HASHES) do
                        if string.find(imgUrl, hash) then return btn end
                    end
                end
            end
            return nil
        end

        local function clickCaptchaButton(btnNum)
            local btns = safeFind(PlayerGui, "CardCaptchaGame", "CaptchaGame", "Bottom", "Buttons")
            if not btns then return false end
            local btn = btns:FindFirstChild(tostring(btnNum))
            if not btn then return false end
            
            local absPos, absSize = btn.AbsolutePosition, btn.AbsoluteSize
            local s, inset = pcall(function() return GuiService:GetGuiInset() end)
            local insetY = s and inset.Y or 0
            humanClickAt(absPos.X + (absSize.X / 2), absPos.Y + (absSize.Y / 2) + insetY)
            return true
        end

        local function startSolveRoutine()
            if Captcha.Solving then return end
            Captcha.Solving = true; getgenv().IsCaptchaActive = true
            task.spawn(function()
                while captchaVisible() do
                    local asset = getTargetId()
                    if asset and (tick() - Captcha.LastClick > 0.5) then
                        local button = Captcha.Cache[asset] or getButtonFromAPI(asset)
                        Captcha.Cache[asset] = button
                        if button then clickCaptchaButton(button) end
                        Captcha.LastClick = tick()
                    end
                    task.wait(0.2)
                end
                Captcha.Solving = false; getgenv().IsCaptchaActive = false
            end)
        end

        local cardUI = PlayerGui:WaitForChild("CardCaptchaGame", 10)
        if cardUI then
            local gameFrame = cardUI:WaitForChild("CaptchaGame", 10)
            if gameFrame then
                gameFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if gameFrame.Visible then task.wait(0.1); startSolveRoutine() end
                end)
            end
        end
        if captchaVisible() then startSolveRoutine() end

        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.new(0, 0))
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0, 0))
        end)
    end)
end

local function isCaptchaOnScreen()
    local cg = safeFind(PlayerGui, "CardCaptchaGame", "CaptchaGame")
    return (cg and cg.Visible) or getgenv().IsCaptchaActive
end

while isCaptchaOnScreen() do task.wait(0.5) end
task.wait(0.5)

-- UI NUKE
task.spawn(function()
    local TARGET_UIS = { ["DailyRewardsMain"] = true, ["WonRoll"] = true, ["Reward"] = true }
    local function nukeElement(g)
        if TARGET_UIS[g.Name] then pcall(function() g.Visible = false; g.Enabled = false end) end
    end
    for _, d in ipairs(PlayerGui:GetDescendants()) do nukeElement(d) end
    PlayerGui.DescendantAdded:Connect(nukeElement)
end)

-- AUTO-SETUP
local function clickUI(target)
    if target and target:IsA("GuiObject") then
        local pos, size = target.AbsolutePosition, target.AbsoluteSize
        local s, inset = pcall(function() return GuiService:GetGuiInset() end)
        humanClickAt(pos.X + (size.X / 2), pos.Y + (size.Y / 2) + (s and inset.Y or 0))
    end
end

local safeEgirlNames = {"Luna", "Angel", "Mimi", "Yuna", "Ari"}
local pcallSuccess, rpNameBox = pcall(function() return PlayerGui:WaitForChild("HUD"):WaitForChild("Frame"):WaitForChild("Top"):WaitForChild("RPName") end)

if pcallSuccess and rpNameBox then
    if rpNameBox.Text == "" or rpNameBox.Text:lower() == LocalPlayer.Name:lower() then
        local randomName = safeEgirlNames[math.random(1, #safeEgirlNames)]
        if rpNameBox:IsA("TextBox") then
            rpNameBox:CaptureFocus()
            rpNameBox.Text = randomName
            rpNameBox:ReleaseFocus(true)
        else
            rpNameBox.Text = randomName
        end
        
        task.wait(0.5)
        local updatePfpEvent = ReplicatedStorage:FindFirstChild("UpdateProfilePicture")
        if updatePfpEvent then pcall(function() updatePfpEvent:FireServer("rbxassetid://115029257457567") end) end
        
        local MainUI = PlayerGui:WaitForChild("CharacterCreation"):WaitForChild("Main")
        local dressUpBtn = PlayerGui:WaitForChild("HUD"):WaitForChild("Frame"):WaitForChild("DressUp"):WaitForChild("Button")
        clickUI(dressUpBtn)
        task.wait(1)
        
        if MainUI.Visible then
            local doneBtn = MainUI:FindFirstChild("FirstSelection") and MainUI.FirstSelection:FindFirstChild("Done")
            if doneBtn then
                local attempts = 0
                while MainUI.Visible and attempts < 3 do
                    clickUI(doneBtn)
                    task.wait(1)
                    attempts = attempts + 1
                end
            end
        end
    end
end

-- ACCOUNT MONITOR (Standalone Integration)
if getgenv().Config.AccountMonitor then
    task.spawn(function()
        local Monitor = {
            Gui = nil, Panel = nil, NameLabel = nil, DiamondLabel = nil, TradeLabel = nil, ClassLabel = nil, LevelLabel = nil, DiamondAmountLabel = nil, CurrentClassLabel = nil,
            LastLevel = nil, TradeCheckedForLevel75 = false, TradeChecking = false, NextTradeCheckAt = 0, LastTradeTargetLevel = nil,
            TradeBanStrikes = 0, TradeBanMaxStrikes = 5, TradeAccountBanned = false, TradeStatus = "Loading...", TradeStatusKind = "unknown",
            Connections = {}
        }

        local PROFILE_SHOW = ReplicatedStorage:FindFirstChild("Profile") and ReplicatedStorage.Profile:FindFirstChild("Show")

        local function monitorNormalize(value)
            value = string.lower(tostring(value or ""))
            value = string.gsub(value, "%s+", " ")
            value = string.gsub(value, "^%s+", "")
            value = string.gsub(value, "%s+$", "")
            return value
        end

        local function formatWholeNumber(value)
            local number = math.floor(tonumber(value) or 0)
            local sign = number < 0 and "-" or ""
            local digits = tostring(math.abs(number))
            while true do
                local updated, count = string.gsub(digits, "^(-?%d+)(%d%d%d)", "%1,%2")
                digits = updated
                if count == 0 then break end
            end
            return sign .. digits
        end

        local function parseLooseNumber(value)
            local textValue = tostring(value or "")
            local compact = string.gsub(textValue, ",", "")
            compact = string.gsub(compact, "%s", "")
            local number = string.match(compact, "%-?%d+%.?%d*")
            return tonumber(number)
        end

        local function parseLevelText(value)
            local textValue = string.lower(tostring(value or ""))
            textValue = string.gsub(textValue, ",", "")
            return tonumber(string.match(textValue, "level%s*[:%-]?%s*(%d+)") or string.match(textValue, "lvl%s*[:%-]?%s*(%d+)") or string.match(textValue, "lv%.?%s*[:%-]?%s*(%d+)") or string.match(textValue, "(%d+)"))
        end

        local function parseDiamondText(value)
            local textValue = tostring(value or "")
            local compact = string.gsub(textValue, ",", "")
            return tonumber(string.match(compact, "%$%s*(%d+)") or string.match(string.lower(compact), "(%d+)%s*diamonds?") or string.match(compact, "(%d+)"))
        end

        local function resolveMonitorHudLabels()
            local hud = PlayerGui:FindFirstChild("HUD")
            if not hud then return false end
            local frame = hud:FindFirstChild("Frame")
            if not frame then return false end

            local xpStuff = frame:FindFirstChild("XPStuff")
            if xpStuff and xpStuff:FindFirstChild("Level") then Monitor.LevelLabel = xpStuff.Level end

            local middle = frame:FindFirstChild("Middle")
            local diamondsFrame = middle and middle:FindFirstChild("DiamondsFrame")
            if diamondsFrame and diamondsFrame:FindFirstChild("DiamondAmount") then Monitor.DiamondAmountLabel = diamondsFrame.DiamondAmount end

            local classes = PlayerGui:FindFirstChild("RH4Classes")
            local announcement = classes and classes:FindFirstChild("AnnouncementFrame")
            if announcement and announcement:FindFirstChild("CurrentClass") then Monitor.CurrentClassLabel = announcement.CurrentClass end

            return Monitor.LevelLabel ~= nil and Monitor.DiamondAmountLabel ~= nil
        end

        local function readLevel()
            local label = Monitor.LevelLabel
            if not label or not label.Parent then resolveMonitorHudLabels(); label = Monitor.LevelLabel end
            if not label then return nil end
            local ok, value = pcall(function() return label.Text end)
            if not ok then return nil end
            local level = parseLevelText(value)
            return level and math.max(0, math.floor(level)) or nil
        end

        local function readDiamonds()
            local label = Monitor.DiamondAmountLabel
            if not label or not label.Parent then resolveMonitorHudLabels(); label = Monitor.DiamondAmountLabel end
            if not label then return nil end
            local ok, value = pcall(function() return label.Text end)
            if not ok then return nil end
            local diamonds = parseDiamondText(value)
            return diamonds and math.max(0, math.floor(diamonds)) or nil
        end

        local function readCurrentClassText()
            local label = Monitor.CurrentClassLabel
            if not label or not label.Parent then return "Waiting" end
            local ok, value = pcall(function()
                local content = label.ContentText
                if content and content ~= "" then return content end
                return label.Text
            end)
            if not ok then return "Waiting" end
            local classText = tostring(value or "")
            classText = string.gsub(classText, "^%s+", "")
            classText = string.gsub(classText, "%s+$", "")
            if classText == "" then return "Waiting" end
            return classText
        end

        local function makeMonitorLabel(parent, name, yScale, heightScale, color, minTextSize, maxTextSize)
            local label = Instance.new("TextLabel")
            label.Name = name; label.BackgroundTransparency = 1; label.BorderSizePixel = 0
            label.Position = UDim2.fromScale(0.015, yScale); label.Size = UDim2.fromScale(0.97, heightScale)
            label.Font = Enum.Font.GothamBold; label.Text = ""; label.TextColor3 = color
            label.TextScaled = true; label.TextWrapped = false; label.RichText = true
            label.TextStrokeColor3 = Color3.new(0, 0, 0); label.TextStrokeTransparency = 0.08
            label.TextXAlignment = Enum.TextXAlignment.Center; label.TextYAlignment = Enum.TextYAlignment.Center
            label.ZIndex = 1002; label.Active = false; label.Selectable = false; label.Parent = parent

            local constraint = Instance.new("UITextSizeConstraint")
            constraint.MinTextSize = minTextSize; constraint.MaxTextSize = maxTextSize; constraint.Parent = label
            return label
        end

        local function createMonitorGui()
            local old = PlayerGui:FindFirstChild("Campus4AccountMonitor")
            if old then pcall(function() old:Destroy() end) end

            local gui = Instance.new("ScreenGui")
            gui.Name = "Campus4AccountMonitor"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
            gui.DisplayOrder = 1000000; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = PlayerGui

            local panel = Instance.new("Frame")
            panel.Name = "Background"; panel.AnchorPoint = Vector2.new(0, 0)
            panel.Position = UDim2.fromScale(0, 0); panel.Size = UDim2.fromScale(1, 1)
            panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0); panel.BackgroundTransparency = 0.12
            panel.BorderSizePixel = 0; panel.ZIndex = 1000; panel.Active = false; panel.Parent = gui

            Monitor.NameLabel = makeMonitorLabel(panel, "AccountLevel", 0.05, 0.20, Color3.fromRGB(255, 105, 180), 8, 180)
            Monitor.DiamondLabel = makeMonitorLabel(panel, "Diamonds", 0.30, 0.20, Color3.fromRGB(69, 220, 255), 8, 150)
            Monitor.TradeLabel = makeMonitorLabel(panel, "TradeStatus", 0.55, 0.20, Color3.fromRGB(190, 190, 190), 8, 130)
            Monitor.ClassLabel = makeMonitorLabel(panel, "CurrentClass", 0.80, 0.20, Color3.fromRGB(194, 154, 255), 8, 125)

            Monitor.Gui = gui; Monitor.Panel = panel
        end

        local function setTradeStatus(textValue, kind)
            Monitor.TradeStatus = tostring(textValue or "Unknown"); Monitor.TradeStatusKind = kind or "unknown"
            if not Monitor.TradeLabel or not Monitor.TradeLabel.Parent then return end
            Monitor.TradeLabel.Text = "Trade Status: " .. Monitor.TradeStatus

            if kind == "available" then Monitor.TradeLabel.TextColor3 = Color3.fromRGB(127, 255, 108)
            elseif kind == "locked" then Monitor.TradeLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
            elseif kind == "underlevel" then Monitor.TradeLabel.TextColor3 = Color3.fromRGB(195, 195, 195)
            elseif kind == "checking" then Monitor.TradeLabel.TextColor3 = Color3.fromRGB(255, 205, 88)
            else Monitor.TradeLabel.TextColor3 = Color3.fromRGB(195, 195, 195) end
        end

        local function profileGuiVisible(object)
            if not object or not object:IsA("GuiObject") then return false end
            local ok, visible = pcall(function() return object.Visible and object.AbsoluteSize.X > 0 and object.AbsoluteSize.Y > 0 end)
            if not ok or not visible then return false end
            local current = object.Parent
            while current and current ~= PlayerGui do
                if current:IsA("GuiObject") and current.Visible == false then return false end
                if current:IsA("LayerCollector") and current.Enabled == false then return false end
                current = current.Parent
            end
            return true
        end

        local function getDirectProfilePreview()
            local profileGui = PlayerGui:FindFirstChild("ProfilePreviewGui")
            return profileGui and profileGui:FindFirstChild("ProfilePreview")
        end

        local function closeDirectProfile(profilePreview)
            if not profilePreview or not profilePreview.Parent then return end
            local best = nil
            for _, object in ipairs(profilePreview:GetDescendants()) do
                if object:IsA("GuiButton") and profileGuiVisible(object) then
                    local name = monitorNormalize(object.Name)
                    local textValue = monitorNormalize((object:IsA("TextButton") and object.Text) or "")
                    if name == "close" or string.find(name, "closebutton", 1, true) or textValue == "close" or textValue == "x" or textValue == "×" then
                        best = object; break
                    end
                end
            end
            if best then clickUI(best) end
        end

        local function enoughPlayersForTradeCheck() return #Players:GetPlayers() >= 5 end
        local function getProfileTargets()
            local targets = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Parent == Players and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(targets, player)
                end
            end
            return targets
        end

        local function resetTradeBanEvidence()
            Monitor.TradeBanStrikes = 0; Monitor.TradeAccountBanned = false; Monitor.TradeCheckedForLevel75 = false
        end

        local function setWaitingForPlayerCount()
            if Monitor.TradeAccountBanned then return end
            setTradeStatus("Waiting for 5+ Players", "unknown")
            Monitor.TradeCheckedForLevel75 = false; Monitor.NextTradeCheckAt = math.huge
        end

        local function checkTradeIconStatus()
            if Monitor.TradeChecking or Monitor.TradeAccountBanned then return end
            if not enoughPlayersForTradeCheck() then setWaitingForPlayerCount(); return end
            if os.clock() < (Monitor.NextTradeCheckAt or 0) then return end
            if not PROFILE_SHOW or not PROFILE_SHOW:IsA("RemoteEvent") then
                setTradeStatus("Unknown (Profile remote unavailable)", "unknown")
                Monitor.NextTradeCheckAt = os.clock() + 3600; return
            end

            Monitor.TradeChecking = true
            setTradeStatus("Scanning...", "checking")

            task.spawn(function()
                while getgenv().IsCaptchaActive do task.wait(0.5) end

                if not enoughPlayersForTradeCheck() then setWaitingForPlayerCount(); Monitor.TradeChecking = false; return end

                local ignoredPlayers = {}; local qualifiedMissingCount = 0; local scanned = 0
                resetTradeBanEvidence()

                while scanned < #Players:GetPlayers() and qualifiedMissingCount < Monitor.TradeBanMaxStrikes and not Monitor.TradeAccountBanned do
                    if not enoughPlayersForTradeCheck() then setWaitingForPlayerCount(); Monitor.TradeChecking = false; return end

                    local targetPlayer = nil
                    for _, player in ipairs(getProfileTargets()) do
                        if not ignoredPlayers[player] then targetPlayer = player; break end
                    end

                    if not targetPlayer then
                        if next(ignoredPlayers) ~= nil then ignoredPlayers = {}; scanned = 0; continue end
                        setTradeStatus("No Players Found", "checking")
                        Monitor.TradeChecking = false; Monitor.NextTradeCheckAt = os.clock() + 3600; return
                    end

                    ignoredPlayers[targetPlayer] = true; scanned += 1

                    local stalePreview = getDirectProfilePreview()
                    if stalePreview and profileGuiVisible(stalePreview) then closeDirectProfile(stalePreview); task.wait(0.10) end

                    local opened = pcall(function() PROFILE_SHOW:FireServer(targetPlayer, "Preview") end)
                    if not opened then continue end

                    task.wait(2.40) -- Config.AccountMonitor.TradeProfileOpenWait

                    if not enoughPlayersForTradeCheck() then
                        local preview = getDirectProfilePreview()
                        if preview then closeDirectProfile(preview) end
                        setWaitingForPlayerCount(); Monitor.TradeChecking = false; return
                    end

                    local profilePreview = getDirectProfilePreview()
                    local tradeBtn = profilePreview and profilePreview:FindFirstChild("Trade")
                    local lvlLabel = profilePreview and profilePreview:FindFirstChild("Level")

                    if not profilePreview or not profileGuiVisible(profilePreview) then continue end

                    local targetLevel = 0
                    if lvlLabel and lvlLabel:IsA("TextLabel") then
                        local ok, rawText = pcall(function() return lvlLabel.Text end)
                        if ok then targetLevel = parseLevelText(rawText) or 0 end
                    end

                    if tradeBtn and tradeBtn:IsA("GuiObject") and tradeBtn.Visible then
                        resetTradeBanEvidence(); closeDirectProfile(profilePreview); setTradeStatus("Unlocked", "available")
                        Monitor.TradeCheckedForLevel75 = true; Monitor.TradeChecking = false; Monitor.NextTradeCheckAt = math.huge; return
                    end

                    if targetLevel >= 75 then
                        qualifiedMissingCount += 1
                        Monitor.TradeBanStrikes = qualifiedMissingCount
                        if qualifiedMissingCount >= Monitor.TradeBanMaxStrikes then
                            Monitor.TradeAccountBanned = true; Monitor.TradeCheckedForLevel75 = true; Monitor.TradeChecking = false
                            Monitor.NextTradeCheckAt = math.huge; closeDirectProfile(profilePreview); setTradeStatus("BANNED", "locked"); return
                        end
                    end
                    closeDirectProfile(profilePreview); task.wait(0.10)
                end

                if not Monitor.TradeAccountBanned then
                    if qualifiedMissingCount > 0 then setTradeStatus("Checking... " .. tostring(qualifiedMissingCount) .. "/" .. tostring(Monitor.TradeBanMaxStrikes), "checking")
                    else setTradeStatus("No Lv75+ Targets Found", "unknown") end
                    Monitor.TradeCheckedForLevel75 = false; Monitor.TradeChecking = false; Monitor.NextTradeCheckAt = os.clock() + 3600
                end
            end)
        end

        local function updateMonitorValues()
            if not Monitor.Gui or not Monitor.Gui.Parent then createMonitorGui() end
            local level = readLevel()
            local diamonds = readDiamonds()

            local levelText = level ~= nil and ("Lv" .. formatWholeNumber(level)) or "Lv?"
            local shortName = string.sub(tostring(LocalPlayer.Name), 1, 5)

            Monitor.NameLabel.Text = shortName .. ' <font color="#FFD84D">| ' .. levelText .. "</font>"
            Monitor.DiamondLabel.Text = diamonds ~= nil and ("$" .. formatWholeNumber(diamonds)) or "$?"
            if Monitor.ClassLabel and Monitor.ClassLabel.Parent then Monitor.ClassLabel.Text = "Class: " .. readCurrentClassText() end

            if level == nil then setTradeStatus("Waiting for level", "unknown")
            elseif level < 75 then
                if not Monitor.TradeAccountBanned then setTradeStatus("Locked (< 75)", "underlevel") end
                Monitor.TradeCheckedForLevel75 = false
            elseif Monitor.TradeAccountBanned then setTradeStatus("BANNED", "locked")
            else
                if Monitor.LastLevel and Monitor.LastLevel < 75 then resetTradeBanEvidence(); Monitor.NextTradeCheckAt = 0 end
                if not enoughPlayersForTradeCheck() then if not Monitor.TradeCheckedForLevel75 then setWaitingForPlayerCount() end
                elseif not Monitor.TradeCheckedForLevel75 and not Monitor.TradeChecking and os.clock() >= (Monitor.NextTradeCheckAt or 0) then
                    checkTradeIconStatus()
                end
            end
            Monitor.LastLevel = level
        end

        local function bindMonitorHudEvents()
            for i = 1, #Monitor.Connections do Monitor.Connections[i]:Disconnect() end
            table.clear(Monitor.Connections)

            if not resolveMonitorHudLabels() then return false end

            table.insert(Monitor.Connections, Monitor.LevelLabel:GetPropertyChangedSignal("Text"):Connect(updateMonitorValues))
            table.insert(Monitor.Connections, Monitor.DiamondAmountLabel:GetPropertyChangedSignal("Text"):Connect(updateMonitorValues))
            if Monitor.CurrentClassLabel then
                table.insert(Monitor.Connections, Monitor.CurrentClassLabel:GetPropertyChangedSignal("Text"):Connect(updateMonitorValues))
                pcall(function() table.insert(Monitor.Connections, Monitor.CurrentClassLabel:GetPropertyChangedSignal("ContentText"):Connect(updateMonitorValues)) end)
            end
            return true
        end

        createMonitorGui(); setTradeStatus("Loading...", "unknown")
        bindMonitorHudEvents(); updateMonitorValues()

        Players.PlayerAdded:Connect(function()
            if (Monitor.LastLevel or 0) >= 75 and not Monitor.TradeAccountBanned and not Monitor.TradeCheckedForLevel75 and enoughPlayersForTradeCheck() then
                Monitor.NextTradeCheckAt = 0; task.spawn(checkTradeIconStatus)
            end
        end)

        Players.PlayerRemoving:Connect(function()
            if (Monitor.LastLevel or 0) < 75 or Monitor.TradeAccountBanned or Monitor.TradeCheckedForLevel75 then return end
            if (#Players:GetPlayers() - 1) < 5 then setWaitingForPlayerCount() end
        end)

        task.spawn(function()
            while true do
                if not Monitor.LevelLabel or not Monitor.LevelLabel.Parent or not Monitor.DiamondAmountLabel or not Monitor.DiamondAmountLabel.Parent then bindMonitorHudEvents() end
                updateMonitorValues(); task.wait(1.0)
            end
        end)
    end)
end

-- ART CLASS BOT (Live Level Tracking + AFK)
if getgenv().Config.AutoArtClass then
    task.spawn(function()
        local SERVER_ID = game.JobId == "" and "LocalServer" or game.JobId
        local MY_API_URL = "https://api.sharafaithcenabreflores.dev/api/word"
        local artClassGui = PlayerGui:WaitForChild("ArtClass", 15)
        if not artClassGui then return end
        
        local guessingGame = artClassGui:WaitForChild("GuessingGame", 10)
        local chooseAWord = guessingGame:WaitForChild("ChooseAWord", 10)
        local midGameArtist = guessingGame:WaitForChild("Mid-GameArtist", 10)
        local artistsWordLabel = midGameArtist:WaitForChild("ArtistsWord", 10)
        local lastSentWord = ""

        local function cleanWord(str)
            local s = string.gsub(str, "Your Drawing Subject:", "")
            return string.match(string.gsub(s, "[\n\r]", ""), "^%s*(.-)%s*$")
        end

        local function sendData(word)
            if makeHttpRequest then
                task.spawn(function()
                    pcall(function()
                        makeHttpRequest({ Url = MY_API_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode({ server_id = SERVER_ID, answer = word }) })
                    end)
                end)
            end
        end

        local function getCanvasBounds()
            local cf = safeFind(guessingGame, "Canvas") or safeFind(guessingGame, "CanvasFrame") or safeFind(guessingGame, "Easel")
            if cf and cf:IsA("GuiObject") then
                local s, i = pcall(function() return GuiService:GetGuiInset() end)
                return { MinX = cf.AbsolutePosition.X + 10, MaxX = cf.AbsolutePosition.X + cf.AbsoluteSize.X - 10, MinY = cf.AbsolutePosition.Y + (s and i.Y or 0) + 10, MaxY = cf.AbsolutePosition.Y + cf.AbsoluteSize.Y + (s and i.Y or 0) - 10, Width = cf.AbsoluteSize.X - 20, Height = cf.AbsoluteSize.Y - 20 }
            end
            local vp = workspace.CurrentCamera.ViewportSize
            return { MinX = vp.X * 0.2, MaxX = vp.X * 0.8, MinY = vp.Y * 0.2, MaxY = vp.Y * 0.7, Width = vp.X * 0.6, Height = vp.Y * 0.5 }
        end

        local function drawLineOnCanvas(startX, startY, endX, endY)
            while getgenv().IsCaptchaActive do task.wait(0.2) end
            VirtualInputManager:SendMouseMoveEvent(startX, startY, game)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(startX, startY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseMoveEvent(endX, endY, game)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(endX, endY, 0, false, game, 1)
            task.wait(0.02)
        end

        local function drawChar(char, x, y, s)
            local b = getCanvasBounds()
            local cX, cY = function(v) return math.clamp(v, b.MinX, b.MaxX) end, function(v) return math.clamp(v, b.MinY, b.MaxY) end
            char = string.upper(char)
            if char == "A" then drawLineOnCanvas(cX(x), cY(y+s), cX(x+s/2), cY(y)); drawLineOnCanvas(cX(x+s/2), cY(y), cX(x+s), cY(y+s)); drawLineOnCanvas(cX(x+s*0.25), cY(y+s*0.5), cX(x+s*0.75), cY(y+s*0.5))
            elseif char == "B" then drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)); drawLineOnCanvas(cX(x), cY(y), cX(x+s*0.8), cY(y+s*0.25)); drawLineOnCanvas(cX(x+s*0.8), cY(y+s*0.25), cX(x), cY(y+s*0.5)); drawLineOnCanvas(cX(x), cY(y+s*0.5), cX(x+s*0.8), cY(y+s*0.75)); drawLineOnCanvas(cX(x+s*0.8), cY(y+s*0.75), cX(x), cY(y+s))
            elseif char == "C" then drawLineOnCanvas(cX(x+s), cY(y), cX(x), cY(y)); drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)); drawLineOnCanvas(cX(x), cY(y+s), cX(x+s), cY(y+s))
            elseif char == "D" then drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)); drawLineOnCanvas(cX(x), cY(y), cX(x+s*0.8), cY(y+s*0.5)); drawLineOnCanvas(cX(x+s*0.8), cY(y+s*0.5), cX(x), cY(y+s))
            elseif char == "E" then drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)); drawLineOnCanvas(cX(x), cY(y), cX(x+s), cY(y)); drawLineOnCanvas(cX(x), cY(y+s*0.5), cX(x+s*0.8), cY(y+s*0.5)); drawLineOnCanvas(cX(x), cY(y+s), cX(x+s), cY(y+s))
            end
        end

        local function startWritingWord(wordToDraw)
            if PlayerState.IsDrawing then return end
            PlayerState.IsDrawing = true
            task.spawn(function()
                task.wait(1)
                local b = getCanvasBounds()
                local sX, sY, sz = b.MinX + (b.Width * 0.1), b.MinY + (b.Height * 0.3), math.clamp(b.Height * 0.3, 25, 45)
                for i = 1, #wordToDraw do
                    if not midGameArtist.Visible then break end
                    while getgenv().IsCaptchaActive do task.wait(0.2) end
                    drawChar(string.sub(wordToDraw, i, i), sX + ((i - 1) * sz * 1.2), sY, sz)
                end
                PlayerState.IsDrawing = false
            end)
        end

        chooseAWord:GetPropertyChangedSignal("Visible"):Connect(function()
            task.defer(function()
                if chooseAWord.Visible then
                    while getgenv().IsCaptchaActive do task.wait(0.2) end
                    task.wait(0.5)
                    local op1 = chooseAWord:FindFirstChild("Option1")
                    if op1 then clickUI(op1) end
                end
            end)
        end)

        artistsWordLabel:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                task.wait(0.1)
                if not midGameArtist.Visible then return end
                local cleanText = cleanWord(artistsWordLabel.ContentText)
                if cleanText ~= "" and cleanText ~= lastSentWord then
                    lastSentWord = cleanText
                    sendData(cleanText)
                    startWritingWord(cleanText)
                end
            end)
        end)

        local function typeAnswer(text)
            local tb = guessingGame:FindFirstChildWhichIsA("TextBox", true)
            if not tb then return end
            PlayerState.IsTyping = true
            
            tb:CaptureFocus(); tb.Text = text; task.wait(0.05)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game); task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            PlayerState.IsTyping = false
        end

        local isProcessing = false
        local attempted = {}
        local nextAnswerTick = 0
        local currentLevel = nil

        local function parseLevelText(value)
            local textValue = string.lower(tostring(value or ""))
            textValue = string.gsub(textValue, ",", "")
            return tonumber(string.match(textValue, "level%s*[:%-]?%s*(%d+)") or string.match(textValue, "lvl%s*[:%-]?%s*(%d+)") or string.match(textValue, "lv%.?%s*[:%-]?%s*(%d+)") or string.match(textValue, "(%d+)"))
        end

        task.spawn(function()
            local hud = PlayerGui:WaitForChild("HUD", 9999)
            local levelLabel = safeFind(hud, "Frame", "XPStuff", "Level")
            
            local function handleLevelChange()
                if not levelLabel then return end
                local ok, txt = pcall(function() return levelLabel.Text end)
                if not ok then return end
                
                local newLevel = parseLevelText(txt)
                if not newLevel then return end

                if currentLevel and newLevel > currentLevel then
                    local afkTime = tick() + math.random(300, 420)
                    if afkTime > nextAnswerTick then nextAnswerTick = afkTime end
                end
                currentLevel = newLevel
            end

            if levelLabel then
                levelLabel:GetPropertyChangedSignal("Text"):Connect(handleLevelChange)
                handleLevelChange()
            end
        end)

        midGameArtist:GetPropertyChangedSignal("Visible"):Connect(function()
            if midGameArtist.Visible then PlayerState.IsDrawing = false; attempted = {} end
        end)

        task.spawn(function()
            while task.wait(1.5) do
                if midGameArtist.Visible or isProcessing then continue end
                if tick() < nextAnswerTick then continue end

                if makeHttpRequest then
                    local s, r = pcall(function() return makeHttpRequest({Url = MY_API_URL .. "?server_id=" .. SERVER_ID, Method = "GET"}) end)
                    if s and r and r.StatusCode == 200 then
                        local ds, dec = pcall(function() return HttpService:JSONDecode(r.Body) end)
                        if ds and dec and dec.answer and dec.answer ~= "" then
                            local finalAns = cleanWord(dec.answer)
                            if finalAns ~= "" and not attempted[finalAns] then
                                attempted[finalAns] = true; isProcessing = true
                                task.spawn(function()
                                    local injectJitter = math.random(5, 12)
                                    task.wait(injectJitter)
                                    
                                    while getgenv().IsCaptchaActive do task.wait(0.2) end
                                    if guessingGame.Visible and not midGameArtist.Visible then
                                        pcall(function() typeAnswer(finalAns) end)
                                        nextAnswerTick = tick() + math.random(35, 50)
                                    end
                                    isProcessing = false
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- IDLE MOVEMENT
task.spawn(function()
    while true do
        task.wait(math.random(15, 30))
        if not PlayerState.IsTyping and not PlayerState.IsDrawing and not getgenv().IsCaptchaActive then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end
end)
