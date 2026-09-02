-- ========================================================================
-- 🎓 CAMPUS 4 CLASS AUTOMATION FRAMEWORK (V63 + BREAKFAST SEASONAL MENU)
-- Includes: 👗 Auto Outfit | 🍳 Breakfast | 🏀 Basketball | 🔭 Star Gazing | 🧚 Fairy Flight | 💻 Computer | 🏊 Swim Spinner | 🧪 Potionology | 🏹 Archery | 🛒 Shopping | 📚 Homework | 📖 Study Hall | 📝 English | 🤖 API Captcha

-- ========================================================================
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
while not Players.LocalPlayer do task.wait(0.1) end
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 9999)
local makeHttpRequest = request or http_request or (http and http.request) or fluxus or (syn and syn.request)

-- ========================================================================
-- ⚙️ CENTRALIZED CONFIGURATION
-- ========================================================================
if _G.AutoEnableBasketball == nil then _G.AutoEnableBasketball = true end
if _G.AutoEnablePotionologyClass == nil then _G.AutoEnablePotionologyClass = true end
if _G.AutoEnableArchery == nil then _G.AutoEnableArchery = true end
if _G.AutoEnableShopping == nil then _G.AutoEnableShopping = true end
if _G.AutoEnableHomework == nil then _G.AutoEnableHomework = true end
if _G.AutoEnableComputer == nil then _G.AutoEnableComputer = true end
if _G.AutoEnableFairyFlight == nil then _G.AutoEnableFairyFlight = true end
if _G.AutoEnableStarGazing == nil then _G.AutoEnableStarGazing = true end
if _G.AutoEnableBreakfast == nil then _G.AutoEnableBreakfast = true end
if _G.AutoStockCrystalIce == nil then _G.AutoStockCrystalIce = true end
if _G.AutoEnableAutoOutfit == nil then _G.AutoEnableAutoOutfit = true end
if _G.AutoEnableStudyHall == nil then _G.AutoEnableStudyHall = true end
if _G.AutoEnableSwimSpinner == nil then _G.AutoEnableSwimSpinner = true end
if _G.AutoEnableEnglish == nil then _G.AutoEnableEnglish = true end
local Config = { Debug = false, -- true = show detailed class diagnostics
    Basketball = { Enabled = _G.AutoEnableBasketball, Power = 37.0, ArcY = 1.5, Timeouts = { Acquisition = 2.0, Equip = 0.80, Teleport = 1.0, PromptReady = 0.75, Result = 2.50 }, Delays = { RequestRetry = 0.15, Cooldown = 0.35, Failure = 0.05, ReturnGrace = 1.50, FaceStabilize = 0.10 }, Tolerances = { Teleport = 1.5, Position = 2.0, FacingMax = 3.0, FacingCorrection = 0.5 }, MultiInstance = { Slots = 24, SlotSpacing = 0.08, GroupSize = 3, ShotGroupDuration = 1.20, LaneSpacing = 2.75, HoldSpacing = 3.5 } }, Potionology = { Enabled = _G.AutoEnablePotionologyClass, ClickDelay = 0.3, ChangeTimeout = 2.50, PollRate = 0.03 }, Archery = { Enabled = _G.AutoEnableArchery, Delays = { ShotCooldown = 0.42, TargetReuse = 0.52, BlockedRetry = 0.20, IdlePoll = 0.025 }, Timeouts = { Result = 1.40 }, Tolerances = { Endpoint = 6.0 } }, Shopping = { Enabled = _G.AutoEnableShopping, ClickDelay = 0.7, UpdateTimeout = 1.20, IdlePoll = 0.05 }, Computer = { Enabled = _G.AutoEnableComputer,
        -- The client sends one character at a time through
        -- ComputerMinigameRemotes.LetterTyped.
        LetterDelay = 0.045, WordChangeTimeout = 1.50,
        -- Seating / UI readiness
        SeatRetryDelay = 0.20, SeatAttemptTimeout = 1.25, SeatTeleportHeight = 2.6, PollRate = 0.025 }, FairyFlight = { Enabled = _G.AutoEnableFairyFlight, ArenaIntroDelay = 6.0, PollRate = 0.03, MoveSpeed = 85.0, CollectDistance = 2.25, MaxStep = 1.75, TouchWait = 0.45, RingDelay = 0.30, FallbackRetry = 0.60, WallNoclip = true }, StarGazing = { Enabled = _G.AutoEnableStarGazing, PromptRetry = 0.75, PromptTeleportHeight = 2.5, PollRate = 0.05, ClickDelay = 0.40, ButtonRetry = 0.80, UIReadyTimeout = 2.50 }, Breakfast = {
        Enabled = _G.AutoEnableBreakfast,

        -- Food ordering
        OrderDelay = 0.45,
        InitialSlotSpacing = 0.10,
        MaxInitialSlots = 12,
        MenuFetchAttempts = 3,
        MenuFetchRetry = 0.40,

        -- Checkout / tray
        CheckoutDelay = 0.60,
        CheckoutRetry = 0.75,
        CheckoutAttempts = 2, -- retries ONLY when InvokeServer itself errors
        TrayCreateTimeout = 8.00,
        TrayPlaceTimeout = 4.00,
        TrayGuiTimeout = 4.00,
        TrayPlaceDistance = 4.0,

        -- Eating. Tool:Activate() is the same activation path confirmed to
        -- decrement TrayGui BiteNumber through FoodNetworkFolder.TakeBite.
        EquipFoodRetry = 0.35,
        FoodToolTimeout = 2.00,
        BiteDelay = 0.45,
        BiteUpdateTimeout = 1.25,
        MaxBiteRetries = 3,

        -- Remove duplicate/local Tray Tools after the full meal is finished.
        TrayCleanupSweepTime = 3.0,
        TrayCleanupPollRate = 0.10,

        -- CostumeContestVotingRemote:FireServer(targetPlayer)
        MaxVotes = 3,
        VoteDelay = 0.70,
        VoteInitialSlotSpacing = 0.10,
        VoteReadyTimeout = 4.00,
        VoteStartDelay = 2.00,
        VotingRetryDelay = 0.50,

        PollRate = 0.05
    }, Homework = { Enabled = _G.AutoEnableHomework,
        -- The real minigame is a continuously sliding 4-card queue.
        -- Submit ONE current leftmost direction, wait for Progress to
        -- acknowledge it, then read the queue again.
        KeyHold = 0.05, InputDelay = 0.24, PollRate = 0.025, EquipTimeout = 2.50, OpenTimeout = 2.50, ProgressTimeout = 1.25, MaxInputsPerAssignment = 24 }, SwimSpinner = { Enabled = _G.AutoEnableSwimSpinner,
        -- Distance is measured to the ACTUAL surface of each Boop part,
        -- not to the center of the rotating bar.
        TriggerDistance = 6.0, ClearDistance = 8.0, MaxVerticalGap = 6.5, JumpCooldown = 0.65, MinTouchOff = 0.55, MaxTouchOff = 1.60, PollRate = 0.02 }, StudyHall = { Enabled = _G.AutoEnableStudyHall,
        -- Study Hall sometimes does not activate its UI until the character
        -- actually moves after the Auto Schedule teleport. Two separate W taps
        -- are more reliable than one long held key during the spawn transition.
        SpawnMoveKey = Enum.KeyCode.W, SpawnMovePresses = 2, SpawnMovePressDuration = 0.18, SpawnMoveGap = 0.08, IntroDelay = 6.0,       -- Start intro wait AFTER the movement nudge
        KeyDelay = 0.35,        -- Delay between submitted flashcards
        KeyHold = 0.05,         -- How long each number key is held down
        ReadyTimeout = 1.50,    -- Wait for AnswerTime after pressing Enter
        RoundTimeout = 3.00,    -- Wait for next Studying round
        PollRate = 0.03 }, English = { Enabled = _G.AutoEnableEnglish, IntroDelay = 6.0,       -- Same Campus 4 teleport/class intro window
        AnswerDelay = 0.20,     -- Small fixed delay after a new question appears
        PollRate = 0.02 }, CrystalIceStock = {
        Enabled = _G.AutoStockCrystalIce,
        Item = "Crystal Ice",
        Category = "Wings",
        Currency = "Diamonds",
        Target = 15,
        InitialReadyTimeout = 8.0,
        InitialSlotSpacing = 0.12,
        MaxInitialSlots = 12,
        PurchaseDelay = 0.60,
        VerifyTimeout = 3.50,
        PollRate = 0.10
    }, AutoOutfit = {
        Enabled = _G.AutoEnableAutoOutfit,
        StartDelay = 3.0,
        StepDelay = 1.5,
        UiTimeout = 8.0,
        DoneAttempts = 5,
        DoneCloseTimeout = 1.25,
        DoneWatcherPollRate = 0.35,
        PollRate = 0.10
    }, Controller = { FallbackPollRate = 0.25, MouseReleaseTimeout = 0.40 } }

-- ========================================================================
-- ♻️ RUNTIME MANAGER
-- ========================================================================
if _G.Campus4Runtime then
    for _, conn in ipairs(_G.Campus4Runtime.Connections) do pcall(function() conn:Disconnect() end) end
    for _, thread in ipairs(_G.Campus4Runtime.Threads) do pcall(function() task.cancel(thread) end) end
end
_G.Campus4Runtime = { Connections = {}, Threads = {}, CaptchaActive = false }
local Runtime = {}
function Runtime.Connect(signal, callback) local conn = signal:Connect(callback); table.insert(_G.Campus4Runtime.Connections, conn); return conn end
function Runtime.Spawn(func) local thread = task.spawn(func); table.insert(_G.Campus4Runtime.Threads, thread); return thread end

-- ========================================================================
-- 🛠️ UTILITIES, LOGGING & HUMANIZER ENGINE
-- ========================================================================
local Logger = {}
local Utils = {}
-- Central log filtering.
-- This keeps the class modules themselves unchanged, which is safer for
-- executors/obfuscators than rewriting many individual Logger calls.
local QUIET_LOG_PATTERNS = { "[Anti-AFK] Prevented disconnection.", "AUTOMATION ACTIVE", "AUTOMATION STARTED", "[StudyHall] Pressed W", "[StudyHall] Waiting ", "[StudyHall] Round ", "[Basketball] Released control", }
local QUIET_WARN_PATTERNS = { "[Basketball] Prompt fired, but no Basketball Tool appeared", "[Basketball] Mouse remained pressed; ball request skipped.", }
local function messageMatchesAny(message, patterns)
    local textMessage = tostring( message or "" )
    for _, pattern in ipairs( patterns ) do
        if string.find( textMessage, pattern, 1, true ) then
            return true
        end
    end
    return false
end
function Logger.Log(message)
    if not Config.Debug and messageMatchesAny( message, QUIET_LOG_PATTERNS ) then
        return
    end
    print(message)
end
function Logger.Warn(message)
    if not Config.Debug and messageMatchesAny( message, QUIET_WARN_PATTERNS ) then
        return
    end
    warn(message)
end
function Logger.Debug(message)
    if Config.Debug then
        print(message)
    end
end
Logger.Debug( "[Compatibility] getconnections=" .. tostring(type(getconnections) == "function") .. " | fireproximityprompt=" .. tostring(type(fireproximityprompt) == "function") .. " | request=" .. tostring(type(makeHttpRequest) == "function") )

-- ========================================================================
-- 💎 CRYSTAL ICE AUTO-STOCK (DIRECT PURCHASE)
-- ========================================================================
-- Uses the same generic phone-purchase backend confirmed by Cobalt:
--   Network.Functions.Asset.Purchase:InvokeServer("Crystal Ice","Wings","Diamonds",nil)
-- Inventory is verified through Shop.InventoryQuantitiesLocalModule.
-- It never sends the next purchase until the local quantity increases.
do
local function getCrystalIceQuantityModule()
    local shop = PlayerGui:FindFirstChild("Shop") or PlayerGui:WaitForChild("Shop", Config.CrystalIceStock.InitialReadyTimeout)
    local moduleScript = shop and shop:FindFirstChild("InventoryQuantitiesLocalModule")
    if not moduleScript or not moduleScript:IsA("ModuleScript") then return nil end
    local ok, module = pcall(require, moduleScript)
    return ok and module or nil
end

local function getCrystalIcePurchaseRemote()
    local network = ReplicatedStorage:FindFirstChild("Network")
    local functions = network and network:FindFirstChild("Functions")
    local asset = functions and functions:FindFirstChild("Asset")
    local purchase = asset and asset:FindFirstChild("Purchase")
    return purchase and purchase:IsA("RemoteFunction") and purchase or nil
end

local function readCrystalIceCount(quantityModule)
    if not quantityModule or type(quantityModule.GetQuantityData) ~= "function" then return nil, false end
    local ok, data = pcall(function() return quantityModule:GetQuantityData() end)
    if not ok or type(data) ~= "table" then return nil, false end
    return tonumber(data[Config.CrystalIceStock.Item]) or 0, next(data) ~= nil
end

local function waitCrystalIceInventoryReady(quantityModule)
    local started = os.clock()
    while os.clock() - started < Config.CrystalIceStock.InitialReadyTimeout do
        local count, ready = readCrystalIceCount(quantityModule)
        if ready then return count end
        task.wait(Config.CrystalIceStock.PollRate)
    end
    return nil
end

local function waitCrystalIceIncrease(quantityModule, before)
    local started = os.clock()
    while os.clock() - started < Config.CrystalIceStock.VerifyTimeout do
        local count, ready = readCrystalIceCount(quantityModule)
        if ready and count > before then return count end
        task.wait(Config.CrystalIceStock.PollRate)
    end
    return nil
end

local function stockCrystalIceToTarget()
    if not Config.CrystalIceStock.Enabled then return end

    -- Small deterministic startup stagger for multi-instance farms.
    local slots = math.max(1, tonumber(Config.CrystalIceStock.MaxInitialSlots) or 12)
    local spacing = math.max(0, tonumber(Config.CrystalIceStock.InitialSlotSpacing) or 0.12)
    task.wait((math.abs(tonumber(LocalPlayer.UserId) or 0) % slots) * spacing)

    local quantityModule = getCrystalIceQuantityModule()
    local purchaseRemote = getCrystalIcePurchaseRemote()
    if not quantityModule then Logger.Warn("⚠️ [Crystal Ice] InventoryQuantitiesLocalModule unavailable."); return end
    if not purchaseRemote then Logger.Warn("⚠️ [Crystal Ice] Asset.Purchase RemoteFunction unavailable."); return end

    -- Do not guess that an empty quantity table means zero owned. Waiting for
    -- a populated inventory avoids accidentally buying a 16th copy on startup.
    local count = waitCrystalIceInventoryReady(quantityModule)
    if count == nil then
        Logger.Warn("⚠️ [Crystal Ice] Inventory never became ready; auto-stock skipped to protect the 15-item cap.")
        return
    end

    local target = math.max(0, tonumber(Config.CrystalIceStock.Target) or 15)
    Logger.Debug("💎 [Crystal Ice] Owned " .. tostring(count) .. " / target " .. tostring(target))
    if count >= target then return end

    while count < target do
        local before = count
        local ok, result = pcall(function()
            return purchaseRemote:InvokeServer(
                Config.CrystalIceStock.Item,
                Config.CrystalIceStock.Category,
                Config.CrystalIceStock.Currency,
                nil
            )
        end)

        -- Stop on an ambiguous/error result instead of retrying blindly. This
        -- prioritizes never overshooting the requested cap.
        if not ok then
            Logger.Warn("⚠️ [Crystal Ice] Purchase invoke failed; stopping: " .. tostring(result))
            return
        end

        local updated = waitCrystalIceIncrease(quantityModule, before)
        if not updated then
            Logger.Warn("⚠️ [Crystal Ice] Purchase was not reflected in inventory; stopping to avoid duplicate buys.")
            return
        end

        count = updated
        Logger.Debug("💎 [Crystal Ice] " .. tostring(count) .. " / " .. tostring(target))
        if count >= target then break end
        task.wait(Config.CrystalIceStock.PurchaseDelay)
    end

    Logger.Debug("✅ [Crystal Ice] Auto-stock complete at " .. tostring(count) .. ".")
end

Runtime.Spawn(stockCrystalIceToTarget)
end
function Utils.deepWait(parent, timeout, ...)
    local current = parent
    local waitTime = tonumber(timeout)
    for _, name in ipairs({...}) do
        if not current then
            return nil
        end
        -- Roblox WaitForChild requires a timeout > 0 when a timeout
        -- argument is supplied. Several fast UI lookups intentionally call
        -- deepWait(..., 0, ...), so use FindFirstChild for those instead.
        if waitTime and waitTime > 0 then
            current = current:WaitForChild(name, waitTime)
        else
            current = current:FindFirstChild(name)
        end
    end
    return current
end
function Utils.fireClick(button)
    if not button or type(getconnections) ~= "function" then return false end
    local signal = nil
    pcall(function() signal = button.MouseButton1Click or button.Activated end)
    if not signal then return false end
    return pcall(function() for _, conn in ipairs(getconnections(signal)) do conn:Fire() end end)
end
function Utils.hideUI(guiObject)
    if not guiObject then return end
    pcall(function()
        if guiObject:IsA("GuiObject") then guiObject.Visible = false
        elseif guiObject:IsA("LayerCollector") then guiObject.Enabled = false end
    end)
end
function Utils.destroyUI(guiObject)
    if not guiObject then
        return false
    end
    return pcall(function()
        guiObject:Destroy()
    end)
end
function Utils.ensureTicked(checkbox)
    if not checkbox or not checkbox:IsA("TextButton") then return end
    if checkbox.Text == "" or checkbox.TextTransparency >= 0.5 then
        Utils.fireClick(checkbox)
        Logger.Log("[Settings] Box was empty. Ticking ON: " .. tostring(checkbox.Parent and checkbox.Parent.Name or checkbox.Name))
    end
end
-- Humanized Mouse Engine
function Utils.randomGaussian(mean, stdDev) local u1 = math.max(1e-7, math.random()); local u2 = math.random(); local z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2); return mean + z0 * (stdDev or (mean * 0.2)) end
function Utils.humanWait(meanSec, stdDevSec) local delay = math.max(0.015, Utils.randomGaussian(meanSec, stdDevSec)); task.wait(delay) end
function Utils.moveMouseSmooth(targetX, targetY)
    local startPos = UserInputService:GetMouseLocation()
    local startX, startY = startPos.X, startPos.Y
    local distance = math.sqrt((targetX - startX)^2 + (targetY - startY)^2)
    if distance < 2 then
        VirtualInputManager:SendMouseMoveEvent(targetX, targetY, game)
        return
    end
    local steps = math.clamp(math.floor(distance / 10), 6, 22)
    local ctrlX = (startX + targetX) / 2 + math.random(-15, 15)
    local ctrlY = (startY + targetY) / 2 + math.random(-15, 15)
    for i = 1, steps do
        local t = i / steps
        local easedT = 1 - math.pow(1 - t, 2)
        local currX = (1 - easedT)^2 * startX + 2 * (1 - easedT) * easedT * ctrlX + easedT^2 * targetX
        local currY = (1 - easedT)^2 * startY + 2 * (1 - easedT) * easedT * ctrlY + easedT^2 * targetY
        VirtualInputManager:SendMouseMoveEvent(currX, currY, game)
        task.wait(0.006 + math.random() * 0.004)
    end
    VirtualInputManager:SendMouseMoveEvent(targetX, targetY, game)
end
function Utils.humanClickAt(x, y) Utils.moveMouseSmooth(x, y); Utils.humanWait(0.04, 0.01); VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1); Utils.humanWait(0.05, 0.015); VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1) end
function Utils.clickGuiObject(guiObject)
    if not guiObject then return false end
    return pcall(function()
        local absPos, absSize = guiObject.AbsolutePosition, guiObject.AbsoluteSize
        local s, inset = pcall(function() return GuiService:GetGuiInset() end)
        local insetY = s and inset.Y or 0
        local offsetX = Utils.randomGaussian(0, 3)
        local offsetY = Utils.randomGaussian(0, 3)
        local x = absPos.X + (absSize.X / 2) + offsetX
        local y = absPos.Y + (absSize.Y / 2) + insetY + offsetY
        Utils.humanClickAt(x, y)
    end)
end

-- ========================================================================
-- 🤖 API HASH CAPTCHA SOLVER
-- ========================================================================
local CAPTCHA_CONFIG = { POLL_INTERVAL = 0.2, RETRY_DELAY = 1.0, CLICK_COOLDOWN = 0.8, }
local Captcha = { Solving = false, Cache = {}, LastClick = 0 }
local BUTTON_HASHES = { ["40d02d582d76f54881f5f000c9a3712d"] = "1", ["3da8772a1380df0ea9d6e29e584d0dfa"] = "2", ["2ca84bc6e12650e6a29b371030041c71"] = "3", ["5abb9a3e809ddf2abec6bad6c30b9357"] = "4", ["f2183de3439a29ca186a1085a254ee36"] = "5", ["469569cf140da51f1b78fc640eaf6682"] = "6", ["ce4d4f4d3bc8cba41ae0ba9955d052c2"] = "7", ["4dcc9cb4f28e200508ace4b493e8b5b7"] = "8", ["151fa826f05ded1c9903149d0c451a1c"] = "9", ["fda452a0b122c2b4230fc74e5135c3fc"] = "10", ["8b7bec3549554a512cdc2a993ce8f441"] = "11", ["988d2aba9e47d6cafced32dbac0256ab"] = "12", ["6a3723b695d9e6900f8fcc9106b64008"] = "13", ["af300da49b235a2ea90d62f17fcfe8c7"] = "14", ["fd6700a486a6ced004db4d1d5eb8e098"] = "15", }
local function checkFailedToLoad()
    local topCard = PlayerGui:FindFirstChild("CardCaptchaGame")
    if not topCard then return false end
    for _, v in pairs(topCard:GetDescendants()) do
        if v:IsA("TextLabel") and string.find(string.lower(v.Text), "failed to load") then return true end
    end
    return false
end
local function captchaVisible() local captchaGame = Utils.deepWait(PlayerGui, 0, "CardCaptchaGame", "CaptchaGame"); return captchaGame and captchaGame.Visible or false end
local function getTargetId()
    local topCard = PlayerGui:FindFirstChild("CardCaptchaGame")
    if not topCard or (topCard.Enabled == false) then return nil end
    local card = Utils.deepWait(topCard, 0, "CaptchaGame", "Top", "Card")
    if not card then return nil end
    return string.match(card.Image, "id=(%d+)")
end
local function getButtonFromAPI(assetId)
    if not makeHttpRequest then
        warn("[Captcha API] HTTP Request function not available on this executor.")
        return nil
    end
    local apiUrl = "https://thumbnails.roproxy.com/v1/assets?assetIds=" .. assetId .. "&returnPolicy=PlaceHolder&size=420x420&format=Webp"
    local success, response
    for i = 1, 2 do
        success, response = pcall(function() return makeHttpRequest({ Url = apiUrl, Method = "GET" }) end)
        if success and response and response.StatusCode == 200 then break end
        task.wait(0.5)
    end
    if not (success and response and response.StatusCode == 200) then
        warn("[Captcha API] Thumbnail request failed for Asset ID:", assetId)
        return nil
    end
    local dataSuccess, decodedData = pcall(function() return HttpService:JSONDecode(response.Body) end)
    if dataSuccess and decodedData and decodedData.data and #decodedData.data > 0 then
        local imageUrl = decodedData.data[1].imageUrl or ""
        for savedHash, buttonNum in pairs(BUTTON_HASHES) do
            if string.find(imageUrl, savedHash) then
                return buttonNum
            end
        end
    end
    warn("[Captcha API] No matching hash found in local database for Asset ID:", assetId)
    return nil
end
local function getCachedButton(assetId)
    if Captcha.Cache[assetId] then return Captcha.Cache[assetId] end
    local btn = getButtonFromAPI(assetId)
    if btn then Captcha.Cache[assetId] = btn end
    return btn
end
local function clickCaptchaButton(buttonNumber)
    local buttons = Utils.deepWait(PlayerGui, 0, "CardCaptchaGame", "CaptchaGame", "Bottom", "Buttons")
    if not buttons then return false end
    local btn = buttons:FindFirstChild(tostring(buttonNumber))
    if not btn then
        warn("[Captcha Click] Target button element not found in UI:", buttonNumber)
        return false
    end
    return Utils.clickGuiObject(btn)
end
local function startSolveRoutine()
    if Captcha.Solving then return end
    Captcha.Solving = true
    _G.Campus4Runtime.CaptchaActive = true
    Logger.Debug("[Captcha] UI detected! Solver routine started.")
    Runtime.Spawn(function()
        while captchaVisible() do
            if checkFailedToLoad() then
                warn("[Captcha] Detected 'Failed to Load' state. Kicking player...")
                LocalPlayer:Kick("Failed to load captcha.")
                break
            end
            local asset = getTargetId()
            if not asset then
                Utils.humanWait(CAPTCHA_CONFIG.POLL_INTERVAL, 0.05)
                continue
            end
            local now = tick()
            if now - Captcha.LastClick < CAPTCHA_CONFIG.CLICK_COOLDOWN then
                Utils.humanWait(CAPTCHA_CONFIG.POLL_INTERVAL, 0.05)
                continue
            end
            local button = getCachedButton(asset)
            if not button then
                local randomBtn = tostring(math.random(1, 15))
                warn("[Captcha] Image hash missing. Attempting refresh click (" .. randomBtn .. ")...")
                button = randomBtn
            end
            Logger.Debug(string.format("[Captcha] Solving Asset ID: %s -> Button: %s", tostring(asset), tostring(button)))
            clickCaptchaButton(button)
            Captcha.LastClick = tick()
            Utils.humanWait(CAPTCHA_CONFIG.RETRY_DELAY, 0.2)
        end
        Captcha.Solving = false
        _G.Campus4Runtime.CaptchaActive = false
        Logger.Debug("[Captcha] Solved or hidden. Shared solver state reset.")
    end)
end
Runtime.Spawn(function()
    local cardCaptchaUI = PlayerGui:WaitForChild("CardCaptchaGame", 10)
    if cardCaptchaUI then
        local captchaGameFrame = cardCaptchaUI:WaitForChild("CaptchaGame", 10)
        if captchaGameFrame then
            Runtime.Connect(captchaGameFrame:GetPropertyChangedSignal("Visible"), function()
                task.defer(function()
                    if captchaGameFrame.Visible then
                        Utils.humanWait(0.2, 0.05)
                        startSolveRoutine()
                    end
                end)
            end)
        end
    end
    if captchaVisible() then startSolveRoutine() end
end)

-- ========================================================================
-- 🎨 AUTO OUTFIT
-- ========================================================================
-- Integrated ONLY from the user's previous outfit/setup portion.
-- No Art Class canvas, drawing, guessing, webhook, or painting automation is included.
-- Startup-only behavior:
--   • Skip everything if a custom RP name already exists.
--   • Otherwise randomize RP name + profile picture.
--   • Open Dress Up and apply random Outfit, Face and Hair.
--   • Apply Woman body, Stylish walk and skin color #5.
--   • Press Done and leave the normal Campus 4 class controller alone.
--
-- This is intentionally a startup routine rather than a class module because
-- the original Art Class script performed the setup before its Art bot began.
do
local AUTO_OUTFIT_NAMES = {
    "Luna","Angel","Mimi","Yuna","Ari","Lily","Misa","Aiko",
    "Sora","Kira","Nini","Rin","Yuki","Nyla","Ava","Bella",
    "Skye","Ivy","Chloe","Mika","Emi","Noa","Coco","Suki",
    "Nova","Celeste","Mochi","Peach","Daisy","Rosie","Willow","Aurora",
    "Violet","Serenity","Melody","Dream","Cupid","Cherry","Blair","Ophelia",
    "Aster","Nyx","Freya","Evelyn","Elodie","Hazel","Sabrina","Sylvie"
}

local AUTO_OUTFIT_PFPS = {
    "rbxassetid://115029257457567",
    "rbxassetid://88815506216062"
}

local AUTO_OUTFIT_HAIRS = {
    "Avrilla's Chained Tails","Avrilla's Buns","Buzzy Bunz","Chromae's Braid",
    "Cupid's Touch Bantu Knots","Deepsea Radiant Puffs","Fallen Fae's Chopped Braids",
    "Fallen Fae's Longing Braids","Fallen Fae's Messy Bob","Fallen Fae's Reminiscing Braids",
    "Fountain Girl's Blowing Hair","Fountain Girl's Diamond Blowing Hair",
    "Fountain Girl's Diamond Hair","Fountain Girl's Hair","Hibiscus Curls",
    "Hibiscus Waves","Inventor's Top Bun","Inventor's Top Bun Windy"
}

local AUTO_OUTFIT_OUTFITS = {
    "2026July1","2026July2","2026July3","2026July4","2026July5","2026July6",
    "2026July7","2026July8","2026July9","2026July10","2026July11","2026July12",
    "2026July13","2026July14","2026July15","2026July16","2026July17","2026July18",
    "2026July19","2026July20","2026July21","2026July22","2026July23","2026July24",
    "2026July25","2026July26","2026June1","2026June2","2026June3","2026June4",
    "2026June5","2026June6"
}

local AUTO_OUTFIT_FACES = {
    "Winnie","90s Grunge","Animal Nose","Apocalypse Survivor","Apocalypse Survivor v2",
    "Boba Pearls","Cheetah","Daring Diva","Enchanted Eyes","Faye","Fern",
    "Flower Garden","Futuristic Cyborg","Glazed Donut","Huh?","Iris","Jellyfish Dreams",
    "Lipliner","Maeve","Peachy","Petals","Pink Glow","Queen of the Sirens",
    "Royale Queen","Shade","Sunblock V1","Sunblock V2","Sunburn","Sunshine",
    "Tanning Day","Ultra Gloss","Water Goddess"
}

local AUTO_OUTFIT_STATE = {
    Dressing = false,
    HasDressed = false,
    ClosingDone = false
}

local function autoOutfitWait(duration)
    local remaining = math.max(0, tonumber(duration) or 0)

    while remaining > 0 do
        while _G.Campus4Runtime.CaptchaActive or captchaVisible() do
            task.wait(Config.AutoOutfit.PollRate)
        end

        local slice = math.min(remaining, 0.10)
        task.wait(slice)
        remaining -= slice
    end
end

local function autoOutfitGuiInset()
    local ok, inset = pcall(function()
        return GuiService:GetGuiInset()
    end)
    return ok and inset or Vector2.new(0, 0)
end

local function autoOutfitTarget(element)
    if not element then return nil end
    if element:IsA("GuiButton") then return element end
    return element:FindFirstChildWhichIsA("GuiButton", true) or element
end

local function autoOutfitVimClick(element)
    local target = autoOutfitTarget(element)

    if not target
        or not target:IsA("GuiObject")
        or target.AbsoluteSize.X <= 0
        or target.AbsoluteSize.Y <= 0
    then
        return false
    end

    return pcall(function()
        local position = target.AbsolutePosition
        local size = target.AbsoluteSize
        local inset = autoOutfitGuiInset()
        local x = position.X + size.X / 2
        local y = position.Y + size.Y / 2 + inset.Y

        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function autoOutfitHybridClick(element)
    local target = autoOutfitTarget(element)
    if not target then return false end

    local fired = false

    if type(firesignal) == "function" then
        local signals = {"MouseButton1Click","Activated","MouseButton1Down","MouseButton1Up"}

        for _, signalName in ipairs(signals) do
            local ok = pcall(function()
                local signal = target[signalName]
                if signal then firesignal(signal) end
            end)

            fired = fired or ok
        end
    end

    if type(getconnections) == "function" then
        local events = {"MouseButton1Click","Activated","MouseButton1Down","InputBegan"}

        for _, eventName in ipairs(events) do
            pcall(function()
                local signal = target[eventName]
                if not signal then return end

                for _, connection in ipairs(getconnections(signal)) do
                    if eventName == "InputBegan" then
                        connection:Fire({
                            UserInputType = Enum.UserInputType.MouseButton1,
                            UserInputState = Enum.UserInputState.Begin
                        })
                        connection:Fire({
                            UserInputType = Enum.UserInputType.Touch,
                            UserInputState = Enum.UserInputState.Begin
                        })
                    else
                        connection:Fire()
                    end
                    fired = true
                end
            end)
        end
    end

    -- Keep the real input fallback from the original setup. It also covers
    -- Volt builds where firesignal/getconnections are unavailable.
    local vimOk = autoOutfitVimClick(target)
    return fired or vimOk
end

local function autoOutfitPath(parent, ...)
    return Utils.deepWait(parent, Config.AutoOutfit.UiTimeout, ...)
end

local function getAutoOutfitDoneRefs()
    local characterCreation = PlayerGui:FindFirstChild("CharacterCreation")
    local main = characterCreation and characterCreation:FindFirstChild("Main")
    local firstSelection = main and main:FindFirstChild("FirstSelection")
    local doneButton = firstSelection and firstSelection:FindFirstChild("Done")
    return characterCreation, main, doneButton
end

local function autoOutfitApplyDoneMoveOut()
    local characterCreation, main, doneButton = getAutoOutfitDoneRefs()
    if not characterCreation then return false end
    if characterCreation.Enabled == false then return true end

    -- Exact behavior from CharacterCreation.Main.FirstSelection.Done.slide:
    --   ApplyColorsForCantRemove()
    --   Magic:Play()
    --   CharacterCreation.Enabled = false
    --   HUD.CharacterCustomizationCamera:Fire(false)
    --   RPName.Recolor.RefreshMatching:FireServer()
    --
    -- The Hair.Set call seen in Cobalt is allowed to occur naturally through
    -- ApplyColorsForCantRemove(), so we do NOT hardcode a hair/color payload.
    local colorsGui = PlayerGui:FindFirstChild("ColorsGui")
    local colorOptions = colorsGui and colorsGui:FindFirstChild("ColorOptions")
    local moduleScript = colorOptions and colorOptions:FindFirstChild("ColorOptionsModule")

    if moduleScript and moduleScript:IsA("ModuleScript") then
        pcall(function()
            local colorModule = require(moduleScript)
            if colorModule and type(colorModule.ApplyColorsForCantRemove) == "function" then
                colorModule:ApplyColorsForCantRemove()
            end
        end)
    end

    if main then
        local magic = main:FindFirstChild("Magic")
        if magic and magic:IsA("Sound") then
            pcall(function()
                magic:Play()
            end)
        end
    end

    characterCreation.Enabled = false

    local hud = PlayerGui:FindFirstChild("HUD")
    local cameraEvent = hud and hud:FindFirstChild("CharacterCustomizationCamera")

    if cameraEvent then
        pcall(function()
            if cameraEvent:IsA("BindableEvent") then
                cameraEvent:Fire(false)
            elseif cameraEvent:IsA("RemoteEvent") then
                cameraEvent:FireServer(false)
            end
        end)
    end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local functions = network and network:FindFirstChild("Functions")
    local gui = functions and functions:FindFirstChild("Gui")
    local rpName = gui and gui:FindFirstChild("RPName")
    local recolor = rpName and rpName:FindFirstChild("Recolor")
    local refreshMatching = recolor and recolor:FindFirstChild("RefreshMatching")

    if refreshMatching and refreshMatching:IsA("RemoteEvent") then
        pcall(function()
            refreshMatching:FireServer()
        end)
    end

    return characterCreation.Enabled == false
end

local function autoOutfitCloseDone()
    if AUTO_OUTFIT_STATE.ClosingDone then return false end

    local characterCreation, _, doneButton = getAutoOutfitDoneRefs()
    if not characterCreation then return false end
    if characterCreation.Enabled == false then return true end

    AUTO_OUTFIT_STATE.ClosingDone = true

    -- Direct MoveOut() first: much more reliable than synthesizing a click.
    local closed = autoOutfitApplyDoneMoveOut()

    -- Retain click fallback in case the game later adds extra click-only logic.
    if not closed and doneButton then
        if type(firesignal) == "function" then
            pcall(function()
                firesignal(doneButton.MouseButton1Down)
            end)
            task.wait(0.05)
        end

        if characterCreation.Enabled then
            autoOutfitVimClick(doneButton)
        end
    end

    local started = os.clock()
    while characterCreation.Parent
        and characterCreation.Enabled
        and os.clock() - started < Config.AutoOutfit.DoneCloseTimeout
    do
        task.wait(0.05)
    end

    closed = characterCreation.Enabled == false
    AUTO_OUTFIT_STATE.ClosingDone = false
    return closed
end

local function startAutoOutfitDoneWatcher()
    if not Config.AutoOutfit.Enabled then return end

    local characterCreation = PlayerGui:FindFirstChild("CharacterCreation")
        or PlayerGui:WaitForChild("CharacterCreation", Config.AutoOutfit.UiTimeout)

    if not characterCreation then
        Logger.Warn("⚠️ [AutoOutfit] CharacterCreation watcher could not start.")
        return
    end

    -- Event-driven path: close immediately whenever the game re-enables the
    -- Dress Up ScreenGui after Auto Outfit has completed.
    Runtime.Connect(characterCreation:GetPropertyChangedSignal("Enabled"), function()
        if characterCreation.Enabled
            and AUTO_OUTFIT_STATE.HasDressed
            and not AUTO_OUTFIT_STATE.Dressing
        then
            task.defer(function()
                task.wait(0.05)
                autoOutfitCloseDone()
            end)
        end
    end)

    local main = characterCreation:FindFirstChild("Main")
    if main and main:IsA("GuiObject") then
        Runtime.Connect(main:GetPropertyChangedSignal("Visible"), function()
            if main.Visible
                and characterCreation.Enabled
                and AUTO_OUTFIT_STATE.HasDressed
                and not AUTO_OUTFIT_STATE.Dressing
            then
                task.defer(function()
                    task.wait(0.05)
                    autoOutfitCloseDone()
                end)
            end
        end)
    end

    -- Low-frequency fallback in case an executor misses a property signal or
    -- the game replaces/re-enables UI state in an unusual order.
    Runtime.Spawn(function()
        while characterCreation.Parent do
            if AUTO_OUTFIT_STATE.HasDressed
                and not AUTO_OUTFIT_STATE.Dressing
                and characterCreation.Enabled
            then
                autoOutfitCloseDone()
            end

            task.wait(Config.AutoOutfit.DoneWatcherPollRate)
        end
    end)

    Logger.Debug("👗 [AutoOutfit] Done watcher armed.")
end

local function runAutoOutfit()
    if not Config.AutoOutfit.Enabled then return end

    -- Match the original script's post-load buffer, then allow the integrated
    -- captcha solver to finish before touching the Dress Up UI.
    autoOutfitWait(Config.AutoOutfit.StartDelay)

    while _G.Campus4Runtime.CaptchaActive or captchaVisible() do
        task.wait(Config.AutoOutfit.PollRate)
    end

    local rpNameBox = autoOutfitPath(PlayerGui, "HUD", "Frame", "Top", "RPName")
    if not rpNameBox then
        Logger.Warn("⚠️ [AutoOutfit] HUD.Frame.Top.RPName was not found.")
        return
    end

    local currentText = tostring(rpNameBox.Text or "")
    local username = tostring(LocalPlayer.Name or "")
    local displayName = tostring(LocalPlayer.DisplayName or "")
    local lowered = string.lower(currentText)

    -- Preserve the original guard: an account that already has a custom RP
    -- name is treated as already configured and is left untouched.
    if currentText ~= ""
        and lowered ~= string.lower(username)
        and lowered ~= string.lower(displayName)
    then
        -- Treat a pre-existing custom RP name as "already configured".
        -- This matters on reinjection because an older Auto Outfit version may
        -- already have dressed the account, but the Done watcher still needs
        -- to remain active for CharacterCreation popups.
        AUTO_OUTFIT_STATE.HasDressed = true
        Logger.Debug("🎨 [AutoOutfit] Existing custom RP name detected; outfit setup skipped, Done watcher kept active.")
        return
    end

    AUTO_OUTFIT_STATE.Dressing = true
    AUTO_OUTFIT_STATE.HasDressed = true
    Logger.Debug("🎨 [AutoOutfit] Starting RP name / PFP / outfit setup.")

    -- 1) RP NAME
    local randomName = AUTO_OUTFIT_NAMES[math.random(1, #AUTO_OUTFIT_NAMES)]

    if rpNameBox:IsA("TextBox") then
        pcall(function()
            rpNameBox:CaptureFocus()
            task.wait(0.05)
            rpNameBox.Text = randomName
            task.wait(0.05)
            rpNameBox:ReleaseFocus(true)
        end)
    else
        pcall(function()
            rpNameBox.Text = randomName
        end)
    end

    Logger.Debug("🎨 [AutoOutfit] RP name -> " .. tostring(randomName))

    -- 2) PROFILE PICTURE
    autoOutfitWait(1.0)

    local pfpRemote = ReplicatedStorage:FindFirstChild("UpdateProfilePicture")
        or ReplicatedStorage:WaitForChild("UpdateProfilePicture", Config.AutoOutfit.UiTimeout)

    if pfpRemote and pfpRemote:IsA("RemoteEvent") then
        local pfp = AUTO_OUTFIT_PFPS[math.random(1, #AUTO_OUTFIT_PFPS)]
        pcall(function()
            pfpRemote:FireServer(pfp)
        end)
        Logger.Debug("🎨 [AutoOutfit] Profile picture -> " .. tostring(pfp))
    end

    -- 3) DRESS-UP MENU
    local dressUpButton = autoOutfitPath(PlayerGui, "HUD", "Frame", "DressUp", "Button")
    local mainUI = autoOutfitPath(PlayerGui, "CharacterCreation", "Main")

    if not dressUpButton or not mainUI then
        Logger.Warn("⚠️ [AutoOutfit] Dress Up / CharacterCreation UI was not ready.")
        return
    end

    autoOutfitVimClick(dressUpButton)
    autoOutfitWait(1.5)

    if not mainUI.Visible then
        pcall(function()
            mainUI.Visible = true
            local first = mainUI:FindFirstChild("FirstSelection")
            if first then first.Visible = true end
        end)
        autoOutfitWait(1.0)
    end

    local firstSelection = mainUI:FindFirstChild("FirstSelection")
    local secondSelection = mainUI:FindFirstChild("SecondSelection")
    local thirdSelection = mainUI:FindFirstChild("ThirdSelection")
    local centralFrame = mainUI:FindFirstChild("CentralFrame")

    if not firstSelection or not secondSelection or not thirdSelection or not centralFrame then
        Logger.Warn("⚠️ [AutoOutfit] CharacterCreation menu structure changed.")
        return
    end

    -- OUTFIT
    local outfitTab = firstSelection:FindFirstChild("Outfit")
    autoOutfitVimClick(outfitTab)
    autoOutfitWait(Config.AutoOutfit.StepDelay)

    local randomOutfit = AUTO_OUTFIT_OUTFITS[math.random(1, #AUTO_OUTFIT_OUTFITS)]
    local clothesFrame = centralFrame:FindFirstChild("ClothesFrame")
    local clothesPage = clothesFrame and clothesFrame:FindFirstChild("ClothesPage")
    local outfitElement = clothesPage and (
        clothesPage:FindFirstChild(randomOutfit)
        or clothesPage:WaitForChild(randomOutfit, Config.AutoOutfit.UiTimeout)
    )

    if outfitElement then
        autoOutfitHybridClick(outfitElement)
        Logger.Debug("🎨 [AutoOutfit] Outfit -> " .. tostring(randomOutfit))
    else
        Logger.Debug("⚠️ [AutoOutfit] Outfit missing: " .. tostring(randomOutfit))
    end

    autoOutfitWait(Config.AutoOutfit.StepDelay)

    -- FACE
    autoOutfitVimClick(firstSelection:FindFirstChild("Face"))
    autoOutfitWait(Config.AutoOutfit.StepDelay)

    local randomFace = AUTO_OUTFIT_FACES[math.random(1, #AUTO_OUTFIT_FACES)]
    local makeupFrame = centralFrame:FindFirstChild("MakeupFrame")
    local fullFaceFrame = makeupFrame and makeupFrame:FindFirstChild("FullFaceFrame")
    local makeupPage = fullFaceFrame and fullFaceFrame:FindFirstChild("MakeupPage")
    local faceElement = makeupPage and (
        makeupPage:FindFirstChild(randomFace)
        or makeupPage:WaitForChild(randomFace, Config.AutoOutfit.UiTimeout)
    )

    if faceElement then
        autoOutfitHybridClick(faceElement)
        Logger.Debug("🎨 [AutoOutfit] Face -> " .. tostring(randomFace))
    else
        Logger.Debug("⚠️ [AutoOutfit] Face missing: " .. tostring(randomFace))
    end

    autoOutfitWait(Config.AutoOutfit.StepDelay)

    -- BODY TYPE / ANIMATION / SKIN
    autoOutfitVimClick(firstSelection:FindFirstChild("Body"))
    autoOutfitWait(Config.AutoOutfit.StepDelay)

    local bodySelection = secondSelection:FindFirstChild("Body")
    if bodySelection then
        autoOutfitVimClick(bodySelection:FindFirstChild("BodyTypes"))
        autoOutfitWait(Config.AutoOutfit.StepDelay)

        local bodyTypesFrame = centralFrame:FindFirstChild("BodyTypesFrame")
        local bodyTypesPage = bodyTypesFrame and bodyTypesFrame:FindFirstChild("ClothesPage")
        local womanBody = bodyTypesPage and bodyTypesPage:FindFirstChild("Woman")

        if womanBody then
            autoOutfitHybridClick(womanBody)
        end

        autoOutfitWait(Config.AutoOutfit.StepDelay)

        autoOutfitVimClick(bodySelection:FindFirstChild("Animations"))
        autoOutfitWait(Config.AutoOutfit.StepDelay)

        local animations = thirdSelection:FindFirstChild("Animations")
        local walkFrame = animations and animations:FindFirstChild("WalkFrame")
        local walks = walkFrame and walkFrame:FindFirstChild("Walks")
        local stylish = walks and walks:FindFirstChild("Stylish")
        local stylishButton = stylish and stylish:FindFirstChild("Button")

        if stylishButton then
            autoOutfitHybridClick(stylishButton)
        end

        autoOutfitWait(Config.AutoOutfit.StepDelay)

        autoOutfitVimClick(bodySelection:FindFirstChild("Skintone"))
        autoOutfitWait(Config.AutoOutfit.StepDelay)

        local skinColors = thirdSelection:FindFirstChild("Skin Colors")
        local colors = skinColors and skinColors:FindFirstChild("Colors")
        local color5 = colors and colors:FindFirstChild("5")

        if color5 then
            autoOutfitHybridClick(color5)
        end

        autoOutfitWait(Config.AutoOutfit.StepDelay)
    end

    -- HAIR
    autoOutfitVimClick(firstSelection:FindFirstChild("Hairstyle"))
    autoOutfitWait(Config.AutoOutfit.StepDelay)

    local randomHair = AUTO_OUTFIT_HAIRS[math.random(1, #AUTO_OUTFIT_HAIRS)]
    local hairFrame = centralFrame:FindFirstChild("HairFrame")
    local hairInner = hairFrame and hairFrame:FindFirstChild("Inner")
    local hairEntry = hairInner and (
        hairInner:FindFirstChild(randomHair)
        or hairInner:WaitForChild(randomHair, Config.AutoOutfit.UiTimeout)
    )
    local hairButton = hairEntry and hairEntry:FindFirstChild("Button")

    if hairButton then
        autoOutfitHybridClick(hairButton)
        Logger.Debug("🎨 [AutoOutfit] Hair -> " .. tostring(randomHair))
    else
        Logger.Debug("⚠️ [AutoOutfit] Hair missing: " .. tostring(randomHair))
    end

    autoOutfitWait(Config.AutoOutfit.StepDelay)

    -- DONE
    -- Done.slide's MoveOut() disables the top-level CharacterCreation
    -- ScreenGui. Checking Main.Visible here was incorrect because Main can
    -- stay Visible=true while CharacterCreation.Enabled=false.
    local attempts = 0
    local characterCreation = PlayerGui:FindFirstChild("CharacterCreation")

    while characterCreation
        and characterCreation.Enabled
        and attempts < Config.AutoOutfit.DoneAttempts
    do
        autoOutfitCloseDone()
        attempts += 1

        if characterCreation.Enabled then
            autoOutfitWait(0.25)
        end
    end

    AUTO_OUTFIT_STATE.Dressing = false

    if characterCreation and characterCreation.Enabled then
        Logger.Warn("⚠️ [AutoOutfit] Dress Up menu stayed enabled after Done retries.")
        return
    end

    Logger.Debug("✅ [AutoOutfit] Auto outfit complete; Done watcher is now active.")
end

startAutoOutfitDoneWatcher()

Runtime.Spawn(function()
    local ok, err = pcall(runAutoOutfit)
    AUTO_OUTFIT_STATE.Dressing = false

    if not ok then
        Logger.Warn("❌ [AutoOutfit] " .. tostring(err))
    end
end)
end

-- ========================================================================
-- ⚙️ INITIAL SETTINGS & UI NUKE
-- ========================================================================
Runtime.Spawn(function()
    local rh4Classes = PlayerGui:WaitForChild("RH4Classes", 5)
    if rh4Classes then
        local onBtn = Utils.deepWait(rh4Classes, 3, "AnnouncementFrame", "ScheduleVisual", "ClassJoinSettings", "On")
        Utils.fireClick(onBtn)
    end
    local ytStudio = PlayerGui:FindFirstChild("YoutubeStudioGui")
    if ytStudio then
        local scrollFrame = Utils.deepWait(ytStudio, 3, "Main", "ScrollPanel", "ScrollingFrame")
        if scrollFrame then
            Utils.ensureTicked(Utils.deepWait(scrollFrame, 2, "NoToolbar", "Checkbox"))
            Utils.ensureTicked(Utils.deepWait(scrollFrame, 2, "NoCoreGui", "Checkbox"))
        end
    end
end)
Runtime.Spawn(function()
    local UI_HANDLERS = { ["WonRoll"] = function(gui) Utils.hideUI(gui) end, ["Reward"] = function(gui) Utils.hideUI(gui) end,
        -- RH4 report cards can appear at different day periods.
        -- Destroy the top-level report card UI immediately when it exists.
        ["ResultsMorning"] = function(gui)
            Utils.destroyUI(gui)
            Logger.Debug("🧹 [UI] Destroyed ResultsMorning report card.")
        end, ["ResultsAfternoon"] = function(gui)
            Utils.destroyUI(gui)
            Logger.Debug("🧹 [UI] Destroyed ResultsAfternoon report card.")
        end, ["ResultsEvening"] = function(gui)
            Utils.destroyUI(gui)
            Logger.Debug("🧹 [UI] Destroyed ResultsEvening report card.")
        end, ["ResultsNight"] = function(gui)
            Utils.destroyUI(gui)
            Logger.Debug("🧹 [UI] Destroyed ResultsNight report card.")
        end, ["DailyRewardsMain"] = function(gui)
            Runtime.Spawn(function()
                local claimBtn = Utils.deepWait(gui, 5, "BottomButtonsFrame", "Claim")
                if claimBtn then Utils.fireClick(claimBtn); task.wait(1.5) end
                Utils.hideUI(gui)
            end)
        end }
    local function processUI(guiObject)
        local handler = UI_HANDLERS[guiObject.Name]
        if handler then handler(guiObject) end
    end
    for _, descendant in ipairs(PlayerGui:GetDescendants()) do processUI(descendant) end
    Runtime.Connect(PlayerGui.DescendantAdded, processUI)
end)
Runtime.Connect(LocalPlayer.Idled, function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0, 0))
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0))
        Logger.Log("[Anti-AFK] Prevented disconnection.")
    end)
end)

-- ========================================================================
-- EXACT CLASS UI
-- ========================================================================
local RH4Classes = PlayerGui:WaitForChild("RH4Classes")
local AnnouncementFrame = RH4Classes:WaitForChild("AnnouncementFrame")
local CurrentClass = AnnouncementFrame:WaitForChild("CurrentClass")
local MinigameFrame = AnnouncementFrame:WaitForChild("AnnouncementSlide") :WaitForChild("Container") :WaitForChild("BottomTab") :WaitForChild("MinigameFrame")
local ClassStartingLabel = MinigameFrame:WaitForChild("ClassStarting")
local PointsLabel = MinigameFrame:WaitForChild("Points")
local TimerLabel = MinigameFrame:WaitForChild("Timer")
local function normalizeClassName(text) text = tostring(text or ""); text = string.gsub(text, "^%s+", ""); text = string.gsub(text, "%s+$", ""); return string.lower(text) end
local function getCurrentClassName() return tostring(CurrentClass.Text) end
local function isCurrentClass(className) return normalizeClassName(getCurrentClassName()) == normalizeClassName(className) end
local function parseClock(text)
    local minutes, seconds = string.match(tostring(text), "(%d+):(%d+)")
    if not minutes or not seconds then return nil end
    return tonumber(minutes) * 60 + tonumber(seconds)
end
local function getClassTimeRemaining() return parseClock(TimerLabel.Text) end
local function isPreClassCountdown() local text = string.lower(tostring(ClassStartingLabel.Text)); local visible = false; pcall(function() visible = ClassStartingLabel.Visible end); return visible and string.find(text, "class in", 1, true) ~= nil end
local function isClassRoundActive() local remaining = getClassTimeRemaining(); return remaining ~= nil and remaining > 1 end
local function getCharacter()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then return nil, nil, nil end
    return character, humanoid, rootPart
end

-- ========================================================================
-- 🎓 SHARED CLASS CONTROLLER
-- ========================================================================
local ClassController = { Modules = {}, ModuleOrder = {}, ActiveName = nil, SessionId = 0 }
function ClassController:Register(module) self.Modules[normalizeClassName(module.ClassName)] = module; table.insert(self.ModuleOrder, module.ClassName) end
function ClassController:IsSessionActive(sessionId, module)
    if self.SessionId ~= sessionId or self.ActiveName ~= module.ClassName or not module:IsEnabled() then return false end
    if module.IsOverride then
        if not module:CheckOverride() then return false end
    else
        if not isCurrentClass(module.ClassName) then return false end
        if module.UseSharedTimer ~= false and not isClassRoundActive() then return false end
    end
    if module.ShouldStayActive then
        local ok, result = pcall(function() return module:ShouldStayActive() end)
        if not ok or result == false then return false end
    end
    return true
end
function ClassController:Wait(sessionId, module, duration)
    local started = os.clock()
    while os.clock() - started < duration do
        -- 🛑 PAUSE AUTOMATION DURING CAPTCHA
        while _G.Campus4Runtime.CaptchaActive do
            task.wait(0.1)
            started += 0.1
        end
        if not self:IsSessionActive(sessionId, module) then return false end
        task.wait(0.015)
    end
    return true
end
function ClassController:Stop(reason)
    if not self.ActiveName then return end
    local previousName = self.ActiveName
    local module = self.Modules[normalizeClassName(previousName)]
    self.SessionId += 1
    self.ActiveName = nil
    if module and module.Stop then pcall(function() module:Stop(reason) end) end
    Logger.Log("🛑 [ClassController] " .. previousName .. " stopped | " .. tostring(reason))
end
function ClassController:Start(module)
    if self.ActiveName or not module:IsEnabled() then return end
    if not module.IsOverride then
        if not isCurrentClass(module.ClassName) then return end
        if module.UseSharedTimer ~= false and not isClassRoundActive() then return end
    end
    if module.CanStart then
        local ok, canStart = pcall(function() return module:CanStart() end)
        if not ok or canStart == false then return end
    end
    self.SessionId += 1
    local mySession = self.SessionId
    self.ActiveName = module.ClassName
    Logger.Log("\n==============================================")
    Logger.Log("▶️ STARTING " .. (module.IsOverride and "OVERRIDE" or "CLASS") .. ": " .. module.ClassName)
    Logger.Log("==============================================")
    Runtime.Spawn(function()
        local success, errorMessage = pcall(function() module:Run(mySession) end)
        if not success then Logger.Warn("❌ [" .. module.ClassName .. "] " .. tostring(errorMessage)) end
        if ClassController.ActiveName == module.ClassName and ClassController.SessionId == mySession then
            ClassController:Stop(success and "round-finished" or "module-error")
        end
    end)
end
function ClassController:Update()
    if _G.Campus4Runtime.CaptchaActive then return end
    -- Check High-Priority Overrides First
    for _, moduleName in ipairs(self.ModuleOrder) do
        local module = self.Modules[normalizeClassName(moduleName)]
        if module and module.IsOverride and module:IsEnabled() and module:CheckOverride() then
            if self.ActiveName ~= moduleName then
                self:Stop("override-triggered")
                self:Start(module)
                return
            elseif self.ActiveName == moduleName then
                return
            end
        end
    end
    local currentName = getCurrentClassName()
    if self.ActiveName then
        local module = self.Modules[normalizeClassName(self.ActiveName)]
        if not module then return self:Stop("module-missing") end
        if not module:IsEnabled() then return self:Stop("global-disabled") end
        if module.IsOverride then
            if not module:CheckOverride() then return self:Stop("override-ended") end
            return
        end
        if not isCurrentClass(module.ClassName) then return self:Stop("class-changed-to-" .. tostring(currentName)) end
        if module.UseSharedTimer ~= false and not isClassRoundActive() then return self:Stop("timer-ended") end
        if module.ShouldStayActive then
            local ok, active = pcall(function() return module:ShouldStayActive() end)
            if not ok or active == false then return self:Stop("module-lifecycle-ended") end
        end
        return
    end
    local module = self.Modules[normalizeClassName(currentName)]
    if not module or not module:IsEnabled() then return end
    if module.UseSharedTimer ~= false and not isClassRoundActive() then return end
    if module.CanStart then
        local ok, canStart = pcall(function() return module:CanStart() end)
        if not ok or canStart == false then return end
    end
    self:Start(module)
end

-- ========================================================================
-- 🍳 BREAKFAST FASHION SHOW MODULE
-- ========================================================================
-- Confirmed game flow:
--   CafeteriaNetwork.OrderFoodItem:FireServer(category, item, nil)
--   CafeteriaNetwork.ProcessPayment:InvokeServer()
--   Tools.PlaceTool:FireServer(tray, cframe, {})
--
-- TrayLocalScript exposes the four current foods in TrayGui:
--   TrayFood.1 = MainSlot
--   TrayFood.2 = SideSlot
--   TrayFood.3 = DrinkSlot
--   TrayFood.4 = DessertSlot
-- Each slot stores FoodId.Value, FoodName.Text and BiteNumber.Text.
--
-- The game's own EquipFood(slot) does:
--   TrayNetworkFolder.EquipFood:InvokeServer(slotFood.Id)
--
-- A selected meal item becomes a real Tool. Tool:Activate() was confirmed
-- to take a bite/sip, and FoodNetworkFolder.TakeBite updates BiteNumber.
--
-- Food phase:
-- ORDER -> CHECKOUT -> PLACE TRAY -> MAIN -> SIDE -> DRINK -> DESSERT
-- -> optional tray pickup -> 3 paced fashion-show votes.
-- ========================================================================
do
local Breakfast = {
    ClassName = "Breakfast Fashion Show",
    UseSharedTimer = false,
    IsOverride = true,
    State = {
        Ordered = false,
        CheckedOut = false,
        PaymentInvoked = false,
        MealFinished = false,
        Tray = nil,
        TrayDataId = nil,
        TrayPlaceRequested = false,
        TrayGuiReady = false,
        VotesCast = 0,
        VotedUserIds = {},
        VotingFinished = false
    }
}

-- V63 fallback refreshed from a live GetFullMenu capture.
-- Seasonal entries are kept separately so fallback behavior follows the same
-- Time/month filtering as the live dynamic menu.
local BREAKFAST_FOOD = {
    { Category = "BreakfastMainCourse", Items = {
        "Fresh Muesli",
        "Rainy Day Warm Oatmeal",
        "Magical Animal Food",
        "Omelette",
        "Avocado Toast"
    }},
    { Category = "BreakfastSideDish", Items = {
        "Side of Brown Rice",
        "Apples and Caramel",
        "Minestrone Soup",
        "Freshly Baked Strawberry Jam Bagel",
        "Caesar Salad"
    }},
    { Category = "BreakfastDrinks", Items = {
        "Cold-Pressed Apple Juice Juicy Box",
        "Iced Green Tea",
        "Iced Tea (Unsweetened)",
        "Raspberry Iced Tea"
    }},
    { Category = "BreakfastDesserts", Items = {
        "Fruit Bowl",
        "Key Lime Pie Yogurt",
        "Chocolate Pudding",
        "Strawberry Fluffy Yogurt",
        "Strawberries and Chocolate"
    }}
}

local BREAKFAST_SEASONAL_FOOD = {
    BreakfastDrinks = {
        {
            Name = "Pumpkin Spice Frappuccino",
            Time = { 9, 10, 11 }
        }
    }
}

local BREAKFAST_SLOT_ORDER = {
    { Index = "1", Slot = "MainSlot", Kind = "Main" },
    { Index = "2", Slot = "SideSlot", Kind = "Side" },
    { Index = "3", Slot = "DrinkSlot", Kind = "Drink" },
    { Index = "4", Slot = "DessertSlot", Kind = "Dessert" }
}

local function breakfastClassMatches()
    local name = normalizeClassName(getCurrentClassName())
    return string.find(name, "breakfast", 1, true) ~= nil
end

local function getBreakfastOrderRemote()
    local network = ReplicatedStorage:FindFirstChild("CafeteriaNetwork")
    local remote = network and network:FindFirstChild("OrderFoodItem")
    return remote and remote:IsA("RemoteEvent") and remote or nil
end

local function getBreakfastFullMenuRemote()
    local network = ReplicatedStorage:FindFirstChild("CafeteriaNetwork")
    local remote = network and network:FindFirstChild("GetFullMenu")
    return remote and remote:IsA("RemoteFunction") and remote or nil
end

local function getBreakfastPaymentRemote()
    local network = ReplicatedStorage:FindFirstChild("CafeteriaNetwork")
    local remote = network and network:FindFirstChild("ProcessPayment")
    return remote and remote:IsA("RemoteFunction") and remote or nil
end

local function getBreakfastEquipFoodRemote()
    local folder = ReplicatedStorage:FindFirstChild("TrayNetworkFolder")
    local remote = folder and folder:FindFirstChild("EquipFood")
    return remote and remote:IsA("RemoteFunction") and remote or nil
end

local function getBreakfastPlaceToolRemote()
    local tools = ReplicatedStorage:FindFirstChild("Tools")
    local remote = tools and tools:FindFirstChild("PlaceTool")
    return remote and remote:IsA("RemoteEvent") and remote or nil
end

local function getBreakfastPickupToolRemote()
    local tools = ReplicatedStorage:FindFirstChild("Tools")
    local remote = tools and tools:FindFirstChild("PickupTool")
    return remote and remote:IsA("RemoteEvent") and remote or nil
end

local function getBreakfastVotingRemote()
    local remote = ReplicatedStorage:FindFirstChild("CostumeContestVotingRemote")
    return remote and remote:IsA("RemoteEvent") and remote or nil
end

local function getCostumeContestUI()
    local classes = PlayerGui:FindFirstChild("RH4Classes")
    return classes and classes:FindFirstChild("CostumeContest") or nil
end

local function getBreakfastTrayGui()
    local gui = PlayerGui:FindFirstChild("TrayGui")
    local frame = gui and gui:FindFirstChild("Frame")
    local trayFood = frame and frame:FindFirstChild("TrayFood")
    return gui, frame, trayFood
end

local function getTrayDataId(tray)
    local value = tray and tray:FindFirstChild("DataId")
    return value and value:IsA("StringValue") and value.Value or nil
end

local function trayHasBreakfastFood(tray)
    if not tray or tray.Name ~= "Tray" then return false end
    local found = 0

    for _, slotName in ipairs({
        "MainSlotFood",
        "SideSlotFood",
        "DrinkSlotFood",
        "DessertSlotFood"
    }) do
        local slot = tray:FindFirstChild(slotName)
        local foodName = slot and slot:FindFirstChild("FoodName")

        if foodName and foodName:IsA("StringValue") and foodName.Value ~= "" then
            found += 1
        end
    end

    return found >= 3
end

local function collectOwnedTrayTools()
    local found = {}

    local function scan(parent)
        if not parent then return end

        for _, object in ipairs(parent:GetChildren()) do
            if object:IsA("Tool") and object.Name == "Tray" then
                found[object] = true
            end
        end
    end

    scan(LocalPlayer.Character)
    scan(LocalPlayer:FindFirstChildOfClass("Backpack"))

    return found
end

local function findNewestBreakfastTray(excluded)
    local best, bestTime = nil, -math.huge

    local function consider(parent)
        if not parent then return end

        for _, object in ipairs(parent:GetChildren()) do
            if object:IsA("Tool")
                and object.Name == "Tray"
                and not (excluded and excluded[object])
                and trayHasBreakfastFood(object)
            then
                local added = tonumber(object:GetAttribute("BackpackAddedTime")) or 0

                if not best or added >= bestTime then
                    best = object
                    bestTime = added
                end
            end
        end
    end

    consider(LocalPlayer.Character)
    consider(LocalPlayer:FindFirstChildOfClass("Backpack"))

    return best
end

local function waitForBreakfastTray(sessionId, excluded)
    local started = os.clock()

    while os.clock() - started < Config.Breakfast.TrayCreateTimeout do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return nil
        end

        local tray = findNewestBreakfastTray(excluded)
        if tray then return tray end

        task.wait(Config.Breakfast.PollRate)
    end

    -- Fallback for servers that reused an existing Tray instance.
    return findNewestBreakfastTray(nil)
end

local function getBreakfastChoice(items, categoryOffset)
    if #items == 0 then return nil end
    local userId = math.abs(tonumber(LocalPlayer.UserId) or 0)
    local index = ((userId + categoryOffset) % #items) + 1
    return items[index]
end

local function getBreakfastCurrentMonth()
    local ok, value = pcall(function()
        local info = os.date("*t")
        return info and tonumber(info.month) or nil
    end)

    if ok and value and value >= 1 and value <= 12 then
        return value
    end

    -- os.date("%m") is a simple fallback for executor/runtime differences.
    local okMonth, monthString = pcall(function()
        return os.date("%m")
    end)

    local month = okMonth and tonumber(monthString) or nil
    return month and math.clamp(month, 1, 12) or 1
end

local function breakfastItemAvailableNow(item, currentMonth)
    if type(item) ~= "table" then
        return true
    end

    local availability = item.Time

    if availability == nil
        or availability == "all"
    then
        return true
    end

    if type(availability) == "number" then
        return tonumber(availability) == currentMonth
    end

    if type(availability) == "table" then
        for _, month in pairs(availability) do
            if tonumber(month) == currentMonth then
                return true
            end
        end

        return false
    end

    -- Unknown future Time formats are allowed instead of breaking Breakfast.
    return true
end

local function normalizeBreakfastMenuItems(rawItems, currentMonth)
    local names = {}
    local seen = {}

    if type(rawItems) ~= "table" then
        return names
    end

    for _, item in pairs(rawItems) do
        local name = nil

        if type(item) == "table" then
            if breakfastItemAvailableNow(item, currentMonth) then
                name = item.Name
            end
        elseif type(item) == "string" then
            name = item
        end

        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    table.sort(names)
    return names
end

local function getBreakfastFallbackMenu(currentMonth)
    local resolved = {}

    for _, entry in ipairs(BREAKFAST_FOOD) do
        local items = {}

        for _, name in ipairs(entry.Items) do
            table.insert(items, name)
        end

        local seasonal =
            BREAKFAST_SEASONAL_FOOD[entry.Category]

        if type(seasonal) == "table" then
            for _, item in ipairs(seasonal) do
                if breakfastItemAvailableNow(item, currentMonth)
                    and type(item.Name) == "string"
                    and item.Name ~= ""
                then
                    table.insert(items, item.Name)
                end
            end
        end

        table.sort(items)

        table.insert(resolved, {
            Category = entry.Category,
            Items = items
        })
    end

    return resolved
end

local function fetchBreakfastMenu(sessionId)
    local currentMonth = getBreakfastCurrentMonth()
    local fallbackMenu = getBreakfastFallbackMenu(currentMonth)
    local remote = getBreakfastFullMenuRemote()

    if not remote then
        Logger.Debug(
            "⚠️ [Breakfast] GetFullMenu unavailable; using V63 fallback menu for month "
            .. tostring(currentMonth)
            .. "."
        )
        return fallbackMenu, "fallback"
    end

    local attempts = math.max(1, tonumber(Config.Breakfast.MenuFetchAttempts) or 3)

    for attempt = 1, attempts do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return nil, "cancelled"
        end

        local ok, result = pcall(function()
            return remote:InvokeServer()
        end)

        if ok and type(result) == "table" and type(result.FoodItems) == "table" then
            local resolved = {}
            local complete = true

            for _, fallbackEntry in ipairs(BREAKFAST_FOOD) do
                local category = fallbackEntry.Category
                local items = normalizeBreakfastMenuItems(result.FoodItems[category], currentMonth)

                if #items == 0 then
                    complete = false
                    Logger.Debug(
                        "⚠️ [Breakfast] GetFullMenu had no items for "
                        .. tostring(category)
                    )
                    break
                end

                table.insert(resolved, {
                    Category = category,
                    Items = items
                })
            end

            if complete and #resolved == #BREAKFAST_FOOD then
                Logger.Debug(
                    "🍳 [Breakfast] Current breakfast menu loaded dynamically for month "
                    .. tostring(currentMonth)
                    .. "."
                )
                return resolved, "dynamic"
            end
        else
            Logger.Debug(
                "⚠️ [Breakfast] GetFullMenu attempt "
                .. tostring(attempt)
                .. "/"
                .. tostring(attempts)
                .. " failed: "
                .. tostring(result)
            )
        end

        if attempt < attempts then
            if not ClassController:Wait(
                sessionId,
                Breakfast,
                Config.Breakfast.MenuFetchRetry
            ) then
                return nil, "cancelled"
            end
        end
    end

    Logger.Debug(
        "⚠️ [Breakfast] Dynamic menu unavailable; using V63 fallback menu for month "
        .. tostring(currentMonth)
        .. "."
    )
    return fallbackMenu, "fallback"
end

local function waitBreakfastInitialSlot(sessionId)
    local maxSlots = math.max(1, tonumber(Config.Breakfast.MaxInitialSlots) or 12)
    local spacing = math.max(0, tonumber(Config.Breakfast.InitialSlotSpacing) or 0.10)
    local slot = math.abs(tonumber(LocalPlayer.UserId) or 0) % maxSlots
    local delay = slot * spacing

    if delay <= 0 then return true end
    return ClassController:Wait(sessionId, Breakfast, delay)
end

local function orderBreakfastMeal(sessionId)
    local remote = getBreakfastOrderRemote()

    if not remote then
        Logger.Warn("⚠️ [Breakfast] CafeteriaNetwork.OrderFoodItem is unavailable.")
        return false
    end

    if not waitBreakfastInitialSlot(sessionId) then return false end

    local menu, source = fetchBreakfastMenu(sessionId)
    if not menu then return false end

    for index, entry in ipairs(menu) do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return false
        end

        local item = getBreakfastChoice(entry.Items, index * 7)

        if not item then
            Logger.Debug(
                "⚠️ [Breakfast] No selectable item for "
                .. tostring(entry.Category)
            )
            return false
        end

        local ok, err = pcall(function()
            remote:FireServer(entry.Category, item, nil)
        end)

        if ok then
            Logger.Debug(
                "🍳 [Breakfast] Ordered "
                .. entry.Category
                .. " -> "
                .. item
                .. " ["
                .. tostring(source)
                .. "]"
            )
        else
            Logger.Warn(
                "⚠️ [Breakfast] Order failed for "
                .. tostring(entry.Category)
                .. ": "
                .. tostring(err)
            )
            return false
        end

        if index < #menu then
            if not ClassController:Wait(
                sessionId,
                Breakfast,
                Config.Breakfast.OrderDelay
            ) then
                return false
            end
        end
    end

    return true
end

local function checkoutBreakfastMeal(sessionId)
    -- If a previous V53 attempt already created a breakfast tray, reuse it
    -- instead of paying again and creating a fourth/fifth tray.
    local existing = findNewestBreakfastTray(nil)
    if existing then
        Breakfast.State.Tray = existing
        Breakfast.State.TrayDataId = getTrayDataId(existing)
        Breakfast.State.PaymentInvoked = true
        Logger.Debug("💳 [Breakfast] Reusing existing breakfast Tray.")
        return true
    end

    local remote = getBreakfastPaymentRemote()
    if not remote then
        Logger.Warn("⚠️ [Breakfast] CafeteriaNetwork.ProcessPayment is unavailable.")
        return false
    end

    -- IMPORTANT: once InvokeServer succeeds locally, do not invoke it again
    -- merely because the resulting Tray has not replicated yet. V53 did that
    -- and could create multiple trays.
    if not Breakfast.State.PaymentInvoked then
        if not ClassController:Wait(sessionId, Breakfast, Config.Breakfast.CheckoutDelay) then
            return false
        end

        local attempts = math.max(1, tonumber(Config.Breakfast.CheckoutAttempts) or 2)

        for attempt = 1, attempts do
            if not ClassController:IsSessionActive(sessionId, Breakfast) then
                return false
            end

            local ok, result = pcall(function()
                return remote:InvokeServer()
            end)

            if ok and result ~= false then
                Breakfast.State.PaymentInvoked = true
                Logger.Debug(
                    "💳 [Breakfast] ProcessPayment invoked"
                    .. (result ~= nil and (" -> " .. tostring(result)) or "")
                )
                break
            end

            if ok and result == false then
                -- Server rejected checkout. Re-fetch/re-order on the next loop
                -- instead of getting stuck forever with PaymentInvoked=true.
                Breakfast.State.Ordered = false
                Breakfast.State.PaymentInvoked = false
                Logger.Debug("⚠️ [Breakfast] ProcessPayment rejected; refreshing breakfast order.")
                return false
            end

            Logger.Debug(
                "⚠️ [Breakfast] ProcessPayment attempt "
                .. tostring(attempt)
                .. "/"
                .. tostring(attempts)
                .. " errored: "
                .. tostring(result)
            )

            if attempt < attempts then
                if not ClassController:Wait(
                    sessionId,
                    Breakfast,
                    Config.Breakfast.CheckoutRetry
                ) then
                    return false
                end
            end
        end
    end

    if not Breakfast.State.PaymentInvoked then
        return false
    end

    -- From this point onward we ONLY wait for/reacquire the resulting tray.
    -- No more ProcessPayment calls are sent.
    local tray = waitForBreakfastTray(sessionId, nil)

    if tray then
        Breakfast.State.Tray = tray
        Breakfast.State.TrayDataId = getTrayDataId(tray)
        Logger.Debug(
            "💳 [Breakfast] Breakfast Tray ready | "
            .. tostring(Breakfast.State.TrayDataId or tray)
        )
        return true
    end

    Logger.Debug("⏳ [Breakfast] Payment sent; waiting for breakfast Tray replication.")
    return false
end

local function getBreakfastPlacementCFrame()
    local character, _, rootPart = getCharacter()
    if not character or not rootPart then return nil end

    local distance = tonumber(Config.Breakfast.TrayPlaceDistance) or 4.0
    local forward = rootPart.CFrame.LookVector
    local flatForward = Vector3.new(forward.X, 0, forward.Z)

    if flatForward.Magnitude < 0.01 then
        flatForward = Vector3.new(0, 0, -1)
    else
        flatForward = flatForward.Unit
    end

    local desired = rootPart.Position + flatForward * distance
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character }

    local result = Workspace:Raycast(
        desired + Vector3.new(0, 5, 0),
        Vector3.new(0, -14, 0),
        rayParams
    )

    local position = result and (result.Position + Vector3.new(0, 0.75, 0))
        or (rootPart.Position + flatForward * distance - Vector3.new(0, 2.25, 0))

    local yaw = math.rad(rootPart.Orientation.Y)
    return CFrame.new(position) * CFrame.Angles(0, yaw, 0)
end

local function breakfastTrayGuiReady()
    local _, frame, trayFood = getBreakfastTrayGui()
    if not frame or not trayFood then return false end

    local ready = 0

    for _, spec in ipairs(BREAKFAST_SLOT_ORDER) do
        local guiSlot = trayFood:FindFirstChild(spec.Index)
        local foodId = guiSlot and guiSlot:FindFirstChild("FoodId")
        local foodName = guiSlot and guiSlot:FindFirstChild("FoodName")
        local biteNumber = guiSlot and guiSlot:FindFirstChild("BiteNumber")

        if guiSlot
            and foodId
            and tostring(foodId.Value) ~= ""
            and foodName
            and tostring(foodName.Text) ~= ""
            and biteNumber
            and tonumber(biteNumber.Text) ~= nil
        then
            ready += 1
        end
    end

    return ready >= 4
end

local function placeBreakfastTray(sessionId)
    if Breakfast.State.TrayGuiReady or breakfastTrayGuiReady() then
        Breakfast.State.TrayGuiReady = true
        return true
    end

    -- Once the placement request has been sent, never place another tray just
    -- because replication/UI took a little longer. V53 re-entered this
    -- function and kept placing additional trays.
    if Breakfast.State.TrayPlaceRequested then
        local started = os.clock()

        while os.clock() - started < Config.Breakfast.TrayGuiTimeout do
            if not ClassController:IsSessionActive(sessionId, Breakfast) then
                return false
            end

            if breakfastTrayGuiReady() then
                Breakfast.State.TrayGuiReady = true
                Logger.Debug("🍽️ [Breakfast] Existing placed TrayGui is ready.")
                return true
            end

            task.wait(Config.Breakfast.PollRate)
        end

        Logger.Debug("⏳ [Breakfast] Tray was already placed; still waiting for TrayGui.")
        return false
    end

    local tray = Breakfast.State.Tray

    if not tray or not tray.Parent then
        tray = findNewestBreakfastTray(nil)
        Breakfast.State.Tray = tray
        Breakfast.State.TrayDataId = getTrayDataId(tray)
    end

    if not tray then
        Logger.Debug("⚠️ [Breakfast] No breakfast Tray available to place.")
        return false
    end

    local remote = getBreakfastPlaceToolRemote()
    if not remote then
        Logger.Warn("⚠️ [Breakfast] ReplicatedStorage.Tools.PlaceTool is unavailable.")
        return false
    end

    local character, humanoid = getCharacter()
    if not character or not humanoid then return false end

    if tray.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(tray)
        end)
        task.wait(0.08)
    end

    local placement = getBreakfastPlacementCFrame()
    if not placement then return false end

    local ok, err = pcall(function()
        remote:FireServer(tray, placement, {})
    end)

    if not ok then
        Logger.Warn("⚠️ [Breakfast] PlaceTool failed: " .. tostring(err))
        return false
    end

    -- Set this immediately after a successful FireServer call. The original
    -- Tray Tool may be consumed/replaced by the server, so its Parent/children
    -- are NOT used to decide whether placement succeeded.
    Breakfast.State.TrayPlaceRequested = true
    Logger.Debug("🍽️ [Breakfast] Tray placement requested once.")

    local started = os.clock()

    while os.clock() - started < Config.Breakfast.TrayGuiTimeout do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return false
        end

        if breakfastTrayGuiReady() then
            Breakfast.State.TrayGuiReady = true
            Logger.Debug("🍽️ [Breakfast] TrayGui food IDs are ready.")
            return true
        end

        task.wait(Config.Breakfast.PollRate)
    end

    Logger.Debug("⏳ [Breakfast] Tray placed; waiting for TrayGui replication.")
    return false
end

local function readBreakfastGuiSlot(index)
    local _, _, trayFood = getBreakfastTrayGui()
    local slot = trayFood and trayFood:FindFirstChild(tostring(index))

    if not slot then return nil end

    local foodId = slot:FindFirstChild("FoodId")
    local foodName = slot:FindFirstChild("FoodName")
    local biteNumber = slot:FindFirstChild("BiteNumber")

    local bites = biteNumber and tonumber(biteNumber.Text) or nil

    return {
        Gui = slot,
        FoodId = foodId and tostring(foodId.Value) or "",
        FoodName = foodName and tostring(foodName.Text) or "",
        Bites = bites,
        BiteLabel = biteNumber
    }
end

local function findBreakfastFoodTool(foodName)
    if not foodName or foodName == "" then return nil end

    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    local function scan(parent)
        if not parent then return nil end

        local exact = parent:FindFirstChild(foodName)
        if exact and exact:IsA("Tool") then return exact end

        for _, object in ipairs(parent:GetChildren()) do
            if object:IsA("Tool")
                and string.lower(object.Name) == string.lower(foodName)
            then
                return object
            end
        end

        return nil
    end

    return scan(character) or scan(backpack)
end

local function waitForBreakfastFoodTool(sessionId, foodName)
    local started = os.clock()

    while os.clock() - started < Config.Breakfast.FoodToolTimeout do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return nil
        end

        local tool = findBreakfastFoodTool(foodName)
        if tool then return tool end

        task.wait(Config.Breakfast.PollRate)
    end

    return findBreakfastFoodTool(foodName)
end

local function equipBreakfastFood(sessionId, slotInfo)
    if not slotInfo
        or slotInfo.FoodId == ""
        or not slotInfo.FoodName
        or slotInfo.FoodName == ""
    then
        return nil
    end

    local remote = getBreakfastEquipFoodRemote()
    if not remote then
        Logger.Warn("⚠️ [Breakfast] TrayNetworkFolder.EquipFood is unavailable.")
        return nil
    end

    local ok, result = pcall(function()
        return remote:InvokeServer(slotInfo.FoodId)
    end)

    if not ok then
        Logger.Debug(
            "⚠️ [Breakfast] EquipFood failed for "
            .. tostring(slotInfo.FoodName)
            .. ": "
            .. tostring(result)
        )
        return nil
    end

    local tool = waitForBreakfastFoodTool(sessionId, slotInfo.FoodName)
    if not tool then
        Logger.Debug("⚠️ [Breakfast] Food Tool did not appear: " .. tostring(slotInfo.FoodName))
        return nil
    end

    local character, humanoid = getCharacter()

    if character and humanoid and tool.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
        task.wait(0.08)
    end

    return tool
end

local function waitForBiteUpdate(sessionId, slotIndex, beforeBites)
    local started = os.clock()

    while os.clock() - started < Config.Breakfast.BiteUpdateTimeout do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return nil
        end

        local info = readBreakfastGuiSlot(slotIndex)

        if not info then
            return 0
        end

        if info.Bites == nil then
            if info.Gui and info.Gui:IsA("GuiObject") and not info.Gui.Visible then
                return 0
            end
        elseif info.Bites < beforeBites then
            return info.Bites
        elseif info.Bites <= 0 then
            return 0
        end

        task.wait(Config.Breakfast.PollRate)
    end

    local info = readBreakfastGuiSlot(slotIndex)
    return info and info.Bites or nil
end

local function eatBreakfastSlot(sessionId, spec)
    local slotInfo = readBreakfastGuiSlot(spec.Index)

    if not slotInfo then
        Logger.Debug("🍽️ [Breakfast] " .. spec.Kind .. " slot is unavailable; skipping.")
        return true
    end

    if slotInfo.Bites ~= nil and slotInfo.Bites <= 0 then
        return true
    end

    local retryCount = 0

    while ClassController:IsSessionActive(sessionId, Breakfast) do
        slotInfo = readBreakfastGuiSlot(spec.Index)

        if not slotInfo then return true end

        if slotInfo.Bites ~= nil and slotInfo.Bites <= 0 then
            Logger.Debug("✅ [Breakfast] " .. spec.Kind .. " finished.")
            return true
        end

        if slotInfo.Gui
            and slotInfo.Gui:IsA("GuiObject")
            and not slotInfo.Gui.Visible
        then
            Logger.Debug("✅ [Breakfast] " .. spec.Kind .. " finished.")
            return true
        end

        local tool = findBreakfastFoodTool(slotInfo.FoodName)

        if not tool then
            tool = equipBreakfastFood(sessionId, slotInfo)

            if not tool then
                retryCount += 1

                if retryCount >= Config.Breakfast.MaxBiteRetries then
                    Logger.Debug(
                        "⚠️ [Breakfast] Could not equip "
                        .. spec.Kind
                        .. " food after retries."
                    )
                    return false
                end

                if not ClassController:Wait(
                    sessionId,
                    Breakfast,
                    Config.Breakfast.EquipFoodRetry
                ) then
                    return false
                end

                continue
            end
        end

        local character, humanoid = getCharacter()

        if character and humanoid and tool.Parent ~= character then
            pcall(function()
                humanoid:EquipTool(tool)
            end)
            task.wait(0.06)
        end

        local beforeBites = tonumber(slotInfo.Bites)

        if not beforeBites then
            return false
        end

        -- CanTakeBite performs a mouse raycast against ToolsStorageFolder.
        -- Move the pointer away from world tools before activating the food.
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(8, 8, game)
        end)

        local activated = pcall(function()
            tool:Activate()
        end)

        if not activated then
            retryCount += 1
        else
            local afterBites = waitForBiteUpdate(
                sessionId,
                spec.Index,
                beforeBites
            )

            if afterBites ~= nil and afterBites < beforeBites then
                retryCount = 0
                Logger.Debug(
                    "🍴 [Breakfast] "
                    .. spec.Kind
                    .. " | "
                    .. tostring(beforeBites)
                    .. " -> "
                    .. tostring(afterBites)
                )
            else
                retryCount += 1
            end
        end

        if retryCount >= Config.Breakfast.MaxBiteRetries then
            -- Re-equip on the next attempt in case the food Tool was replaced.
            local stale = findBreakfastFoodTool(slotInfo.FoodName)
            if stale and stale.Parent then
                pcall(function()
                    if stale.Parent == LocalPlayer.Character then
                        local _, human = getCharacter()
                        if human then human:UnequipTools() end
                    end
                end)
            end

            retryCount = 0

            if not ClassController:Wait(
                sessionId,
                Breakfast,
                Config.Breakfast.EquipFoodRetry
            ) then
                return false
            end
        end

        if not ClassController:Wait(
            sessionId,
            Breakfast,
            Config.Breakfast.BiteDelay
        ) then
            return false
        end
    end

    return false
end

local function findPlacedBreakfastTray()
    local dataId = Breakfast.State.TrayDataId

    local function scan(root)
        if not root then return nil end

        for _, object in ipairs(root:GetDescendants()) do
            if object.Name == "Tray" then
                local objectId = getTrayDataId(object)

                if dataId and objectId == dataId then
                    return object
                end
            end
        end

        return nil
    end

    local storage = Workspace:FindFirstChild("ToolsStorageFolder")
    return scan(storage)
        or scan(Workspace:FindFirstChild("Cafeteria"))
        or (
            Breakfast.State.Tray
            and Breakfast.State.Tray.Parent
            and Breakfast.State.Tray
            or nil
        )
end

local function cleanupBreakfastTrayTools()
    local removed = 0
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    local function cleanParent(parent)
        if not parent then return end

        for _, object in ipairs(parent:GetChildren()) do
            if object:IsA("Tool") and object.Name == "Tray" then
                local destroyed = pcall(function()
                    object.Enabled = false
                    object:Destroy()
                end)

                if destroyed then
                    removed += 1
                end
            end
        end
    end

    cleanParent(character)
    cleanParent(backpack)
    return removed
end

local function scheduleBreakfastTrayCleanupSweep()
    Runtime.Spawn(function()
        local started = os.clock()
        local removedTotal = 0

        while os.clock() - started < Config.Breakfast.TrayCleanupSweepTime do
            removedTotal += cleanupBreakfastTrayTools()
            task.wait(Config.Breakfast.TrayCleanupPollRate)
        end

        if removedTotal > 0 then
            Logger.Debug(
                "🧹 [Breakfast] Cleanup sweep removed "
                .. tostring(removedTotal)
                .. " Tray Tool instance(s)."
            )
        end
    end)
end

local function finishBreakfastMeal(sessionId)
    if not Breakfast.State.TrayGuiReady then
        Breakfast.State.TrayGuiReady = breakfastTrayGuiReady()
    end

    if not Breakfast.State.TrayGuiReady then
        if not placeBreakfastTray(sessionId) then
            return false
        end
    end

    for _, spec in ipairs(BREAKFAST_SLOT_ORDER) do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return false
        end

        if not eatBreakfastSlot(sessionId, spec) then
            Logger.Debug("⚠️ [Breakfast] " .. spec.Kind .. " was not fully consumed; retrying meal flow.")
            return false
        end
    end

    -- Meal is complete. Ask the server to return the placed tray, then remove
    -- every local Tray Tool belonging to this account. A short sweep catches
    -- trays that replicate back into Backpack slightly after PickupTool.
    local pickupRemote = getBreakfastPickupToolRemote()
    local placedTray = findPlacedBreakfastTray()

    if pickupRemote and placedTray then
        pcall(function()
            pickupRemote:FireServer(placedTray)
        end)
    end

    cleanupBreakfastTrayTools()
    scheduleBreakfastTrayCleanupSweep()

    Logger.Debug("✅ [Breakfast] Full breakfast meal consumed; Tray Tools cleaned.")
    return true
end

local function waitForBreakfastVoting(sessionId)
    local started = os.clock()

    while os.clock() - started < Config.Breakfast.VoteReadyTimeout do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return false
        end

        if getBreakfastVotingRemote() then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if character and humanoid and humanoid.Health > 0 then
                        return true
                    end
                end
            end
        end

        task.wait(Config.Breakfast.PollRate)
    end

    return getBreakfastVotingRemote() ~= nil
end

local function getBreakfastVoteCandidates()
    local candidates = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
            and not Breakfast.State.VotedUserIds[player.UserId]
        then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if character and humanoid and humanoid.Health > 0 then
                table.insert(candidates, player)
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.UserId < b.UserId
    end)

    return candidates
end

local function chooseBreakfastVoteTarget()
    local candidates = getBreakfastVoteCandidates()
    if #candidates == 0 then return nil end

    local userId = math.abs(tonumber(LocalPlayer.UserId) or 0)
    local index = (userId % #candidates) + 1
    return candidates[index]
end

local function waitBreakfastVoteSlot(sessionId)
    local maxSlots = math.max(1, tonumber(Config.Breakfast.MaxInitialSlots) or 12)
    local spacing = math.max(0, tonumber(Config.Breakfast.VoteInitialSlotSpacing) or 0.10)
    local slot = math.abs(tonumber(LocalPlayer.UserId) or 0) % maxSlots
    local delay = slot * spacing

    if delay <= 0 then return true end
    return ClassController:Wait(sessionId, Breakfast, delay)
end

local function castBreakfastVotes(sessionId)
    if Breakfast.State.VotingFinished then return true end

    if not waitForBreakfastVoting(sessionId) then
        Logger.Debug("🌹 [Breakfast] Costume Contest voting remote not ready yet.")
        return false
    end

    if Breakfast.State.VotesCast == 0 then
        if not waitBreakfastVoteSlot(sessionId) then return false end
    end

    local remote = getBreakfastVotingRemote()
    if not remote then return false end

    while Breakfast.State.VotesCast < Config.Breakfast.MaxVotes do
        if not ClassController:IsSessionActive(sessionId, Breakfast) then
            return false
        end

        local target = chooseBreakfastVoteTarget()

        if not target then
            return false
        end

        local ok, err = pcall(function()
            remote:FireServer(target)
        end)

        if ok then
            Breakfast.State.VotedUserIds[target.UserId] = true
            Breakfast.State.VotesCast += 1

            Logger.Debug(
                "🌹 [Breakfast] Vote "
                .. tostring(Breakfast.State.VotesCast)
                .. "/"
                .. tostring(Config.Breakfast.MaxVotes)
                .. " -> "
                .. target.Name
            )
        else
            Logger.Warn(
                "⚠️ [Breakfast] Vote failed for "
                .. tostring(target.Name)
                .. ": "
                .. tostring(err)
            )
        end

        if Breakfast.State.VotesCast < Config.Breakfast.MaxVotes then
            if not ClassController:Wait(
                sessionId,
                Breakfast,
                Config.Breakfast.VoteDelay
            ) then
                return false
            end
        end
    end

    Breakfast.State.VotingFinished = true
    return true
end

function Breakfast:IsEnabled()
    return Config.Breakfast.Enabled
end

function Breakfast:CheckOverride()
    return breakfastClassMatches()
end

function Breakfast:CanStart()
    return breakfastClassMatches()
end

local function runBreakfastVotingWorker(sessionId)
    if Config.Breakfast.VoteStartDelay > 0 then
        if not ClassController:Wait(
            sessionId,
            Breakfast,
            Config.Breakfast.VoteStartDelay
        ) then
            return
        end
    end

    while ClassController:IsSessionActive(sessionId, Breakfast)
        and not Breakfast.State.VotingFinished
    do
        castBreakfastVotes(sessionId)

        if Breakfast.State.VotingFinished then
            break
        end

        if not ClassController:Wait(
            sessionId,
            Breakfast,
            Config.Breakfast.VotingRetryDelay
        ) then
            break
        end
    end
end

function Breakfast:Run(sessionId)
    Logger.Debug("🍳 [Breakfast] Automation active.")

    self.State.Ordered = false
    self.State.CheckedOut = false
    self.State.PaymentInvoked = false
    self.State.MealFinished = false
    self.State.Tray = nil
    self.State.TrayDataId = nil
    self.State.TrayPlaceRequested = false
    self.State.TrayGuiReady = false
    self.State.VotesCast = 0
    self.State.VotedUserIds = {}
    self.State.VotingFinished = false

    -- Voting is intentionally independent from the cafeteria pipeline.
    -- A failed order/tray/eating step can no longer prevent the 3 votes.
    Runtime.Spawn(function()
        local ok, err = pcall(function()
            runBreakfastVotingWorker(sessionId)
        end)

        if not ok then
            Logger.Warn("⚠️ [Breakfast] Voting worker error: " .. tostring(err))
        end
    end)

    -- Food worker remains sequential because checkout/place/eat depend on the
    -- previous state, but it no longer gates voting.
    while ClassController:IsSessionActive(sessionId, self) do
        if not self.State.Ordered then
            self.State.Ordered = orderBreakfastMeal(sessionId)

            if not self.State.Ordered then
                if not ClassController:Wait(sessionId, self, 0.50) then break end
                continue
            end
        end

        if not self.State.CheckedOut then
            self.State.CheckedOut = checkoutBreakfastMeal(sessionId)

            if not self.State.CheckedOut then
                if not ClassController:Wait(
                    sessionId,
                    self,
                    Config.Breakfast.CheckoutRetry
                ) then
                    break
                end
                continue
            end
        end

        if not self.State.MealFinished then
            self.State.MealFinished = finishBreakfastMeal(sessionId)

            if not self.State.MealFinished then
                if not ClassController:Wait(sessionId, self, 0.50) then break end
                continue
            end
        end

        if not ClassController:Wait(
            sessionId,
            self,
            Config.Breakfast.PollRate
        ) then
            break
        end
    end
end

function Breakfast:Stop()
    self.State.Ordered = false
    self.State.CheckedOut = false
    self.State.PaymentInvoked = false
    self.State.MealFinished = false
    self.State.Tray = nil
    self.State.TrayDataId = nil
    self.State.TrayPlaceRequested = false
    self.State.TrayGuiReady = false
    self.State.VotesCast = 0
    self.State.VotedUserIds = {}
    self.State.VotingFinished = false

    local character, humanoid = getCharacter()
    if humanoid then
        pcall(function()
            humanoid:UnequipTools()
        end)
    end

    local contest = getCostumeContestUI()

    if contest then
        pcall(function()
            contest.Visible = false
        end)
    end
end

ClassController:Register(Breakfast)
end -- scope: Breakfast


-- ========================================================================
-- 🔭 STAR GAZING / TELESCOPE MODULE
-- ========================================================================
-- TelescopeGameLocalScript behavior:
--   TelescopePrompter ProximityPrompt -> RequestStart -> TelescopeGameRemote("Start")
--   server "Start" -> Show() -> Telescope UI / camera
--   dynamic BrightStar, ShootingStar, RainbowStar and UFO buttons call
--   TelescopeGameRemote("Get", type) through their normal local handlers.
--
-- We therefore enter through the real telescope prompt, then press the
-- actual spawned GUI buttons instead of blindly spamming the Get remote.
-- ========================================================================
do
local StarGazing = {
    ClassName = "Star Gazing", UseSharedTimer = false, IsOverride = true,
    State = { LastPromptAttempt = 0, ClickedButtons = {}, LastClickAt = 0 }
}

local function starGazingClassMatches()
    local name = normalizeClassName(getCurrentClassName())
    return string.find(name, "star gaz", 1, true) ~= nil
        or string.find(name, "stargaz", 1, true) ~= nil
        or string.find(name, "telescope", 1, true) ~= nil
end

local function getTelescopeGameUI()
    local classes = PlayerGui:FindFirstChild("RH4Classes")
    return classes and classes:FindFirstChild("TelescopeGame") or nil
end

local function getTelescopeResultsUI()
    local classes = PlayerGui:FindFirstChild("RH4Classes")
    return classes and classes:FindFirstChild("TelescopeGameResults") or nil
end

local function isGuiVisible(gui)
    if not gui then return false end
    local ok, visible = pcall(function() return gui.Visible end)
    return ok and visible == true
end

local function getTelescopePrompt()
    local minigame = Workspace:FindFirstChild("TelescopeMinigame")
    local prompter = minigame and minigame:FindFirstChild("TelescopePrompter")
    if not prompter then return nil end

    for _, object in ipairs(prompter:GetDescendants()) do
        if object:IsA("ProximityPrompt") and object.Enabled then return object end
    end
    return nil
end

local function getPromptBasePart(prompt)
    if not prompt then return nil end
    if prompt.Parent and prompt.Parent:IsA("BasePart") then return prompt.Parent end
    return prompt:FindFirstAncestorWhichIsA("BasePart")
end

local function enterTelescopeGame(sessionId)
    local now = os.clock()
    if now - StarGazing.State.LastPromptAttempt < Config.StarGazing.PromptRetry then return false end
    StarGazing.State.LastPromptAttempt = now

    local prompt = getTelescopePrompt()
    if not prompt then
        Logger.Debug("🔭 [StarGazing] Telescope prompt not ready.")
        return false
    end

    local character, humanoid, rootPart = getCharacter()
    if not character or not humanoid or not rootPart then return false end

    local basePart = getPromptBasePart(prompt)
    if basePart then
        pcall(function()
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            character:PivotTo(basePart.CFrame * CFrame.new(0, Config.StarGazing.PromptTeleportHeight, 0))
        end)
        task.wait(0.08)
    end

    if not ClassController:IsSessionActive(sessionId, StarGazing) then return false end
    if type(fireproximityprompt) ~= "function" then
        Logger.Warn("⚠️ [StarGazing] Executor does not expose fireproximityprompt().")
        return false
    end

    local ok, err = pcall(function() fireproximityprompt(prompt) end)
    if not ok then
        Logger.Warn("⚠️ [StarGazing] Telescope prompt failed: " .. tostring(err))
        return false
    end

    local started = os.clock()
    while os.clock() - started < Config.StarGazing.UIReadyTimeout do
        if not ClassController:IsSessionActive(sessionId, StarGazing) then return false end
        if isGuiVisible(getTelescopeGameUI()) then
            Logger.Debug("🔭 [StarGazing] Telescope UI opened.")
            return true
        end
        task.wait(Config.StarGazing.PollRate)
    end

    return isGuiVisible(getTelescopeGameUI())
end

local function getTelescopeSurfaceGui()
    for _, object in ipairs(PlayerGui:GetChildren()) do
        if object:IsA("SurfaceGui")
            and (object:FindFirstChild("BrightStars")
                or object:FindFirstChild("RainbowStarCanvasGroup")
                or object:FindFirstChild("BrightStarTemplate"))
        then
            return object
        end
    end
    return nil
end

local function guiObjectUsable(object)
    if not object or not object:IsA("GuiObject") then return false end
    local current = object
    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and not current.Visible then return false end
        current = current.Parent
    end
    return object.AbsoluteSize.X > 0 and object.AbsoluteSize.Y > 0
end

local function findTelescopeButton(root, objectName, nestedName)
    if not root then return nil end
    local object = root:FindFirstChild(objectName, true)
    if not object then return nil end

    local button = nestedName and object:FindFirstChild(nestedName, true) or nil
    if not button and object:IsA("GuiButton") then button = object end
    if button and button:IsA("GuiButton") and guiObjectUsable(button) then return button end
    return nil
end

local function collectTelescopeButtons()
    local surface = getTelescopeSurfaceGui()
    if not surface then return {} end

    local buttons, seen = {}, {}
    local function add(button, kind)
        if button and not seen[button] and not StarGazing.State.ClickedButtons[button] then
            seen[button] = true
            table.insert(buttons, { Button = button, Kind = kind })
        end
    end

    -- BrightStar instances are placed inside SurfaceGui.BrightStars.
    local brightStars = surface:FindFirstChild("BrightStars")
    if brightStars then
        for _, starFrame in ipairs(brightStars:GetChildren()) do
            if starFrame.Name == "BrightStar" and starFrame:IsA("GuiObject") and starFrame.Visible then
                local starImage = starFrame:FindFirstChild("BrightStar")
                local button = starImage and starImage:FindFirstChild("Button")
                if button and button:IsA("GuiButton") and guiObjectUsable(button) then add(button, "BrightStar") end
            end
        end
    end

    -- One-off server-spawned objects.
    local rainbowGroup = surface:FindFirstChild("RainbowStarCanvasGroup")
    if rainbowGroup and rainbowGroup:IsA("GuiObject") and rainbowGroup.Visible then
        local rainbow = rainbowGroup:FindFirstChild("RainbowStar")
        local button = rainbow and rainbow:FindFirstChild("Button")
        if button and button:IsA("GuiButton") and guiObjectUsable(button) then add(button, "RainbowStar") end
    end

    local shooting = surface:FindFirstChild("ShootingStar")
    if shooting and shooting:IsA("GuiObject") and shooting.Visible then
        local button = shooting:FindFirstChild("Button")
        if button and button:IsA("GuiButton") and guiObjectUsable(button) then add(button, "ShootingStar") end
    end

    local ufo = surface:FindFirstChild("UFO")
    if ufo and ufo:IsA("GuiObject") and ufo.Visible then
        local button = ufo:FindFirstChild("Button")
        if button and button:IsA("GuiButton") and guiObjectUsable(button) then add(button, "UFO") end
    end

    return buttons
end

local function pressTelescopeButton(button)
    if not button or not button.Parent then return false end

    -- The decompiled star/UFO handlers use MouseButton1Down, not Click.
    if type(getconnections) == "function" then
        local fired = false
        local ok = pcall(function()
            for _, connection in ipairs(getconnections(button.MouseButton1Down)) do
                connection:Fire()
                fired = true
            end
        end)
        if ok and fired then return true end
    end

    -- Executor-safe fallback: real pointer click at the live GUI button.
    return Utils.clickGuiObject(button)
end

local function closeTelescopeResults()
    local results = getTelescopeResultsUI()
    if not isGuiVisible(results) then return false end

    -- Confirmed live path:
    -- PlayerGui.RH4Classes.TelescopeGameResults.Close
    local close = results:FindFirstChild("Close")
    if not close or not close:IsA("GuiButton") then
        return false
    end

    local clicked = Utils.fireClick(close)
    if not clicked then
        clicked = Utils.clickGuiObject(close)
    end

    if clicked then
        Logger.Debug("🔭 [StarGazing] Closed TelescopeGameResults.")
    end

    return clicked == true
end

local function closeTelescopeGame()
    local ui = getTelescopeGameUI()
    if not isGuiVisible(ui) then return end

    local exit = ui:FindFirstChild("Exit")
    if exit and exit:IsA("GuiButton") then
        local clicked = Utils.fireClick(exit)
        if not clicked then Utils.clickGuiObject(exit) end
    end
end

function StarGazing:IsEnabled() return Config.StarGazing.Enabled end
function StarGazing:CheckOverride() return starGazingClassMatches() end
function StarGazing:CanStart() return starGazingClassMatches() end

function StarGazing:Run(sessionId)
    Logger.Debug("🔭 [StarGazing] Automation active.")
    self.State.LastPromptAttempt = 0
    self.State.ClickedButtons = {}
    self.State.LastClickAt = 0

    while ClassController:IsSessionActive(sessionId, self) do
        local ui = getTelescopeGameUI()
        local results = getTelescopeResultsUI()

        if isGuiVisible(results) then
            -- V62: results used to block the Star Gazing loop indefinitely.
            -- Close the real results GUI, then let the normal controller continue.
            closeTelescopeResults()
            if not ClassController:Wait(sessionId, self, Config.StarGazing.PollRate) then break end
            continue
        end

        if not isGuiVisible(ui) then
            enterTelescopeGame(sessionId)
            if not ClassController:Wait(sessionId, self, Config.StarGazing.PollRate) then break end
            continue
        end

        local now = os.clock()
        if now - self.State.LastClickAt >= Config.StarGazing.ClickDelay then
            local candidates = collectTelescopeButtons()
            if #candidates > 0 then
                -- Prioritize rare temporary objects over the permanent bright-star loop.
                table.sort(candidates, function(a, b)
                    local priority = { UFO = 1, RainbowStar = 2, ShootingStar = 3, BrightStar = 4 }
                    return (priority[a.Kind] or 9) < (priority[b.Kind] or 9)
                end)

                local target = candidates[1]
                if pressTelescopeButton(target.Button) then
                    self.State.ClickedButtons[target.Button] = os.clock()
                    self.State.LastClickAt = os.clock()
                    Logger.Debug("🔭 [StarGazing] Collected " .. target.Kind)

                    -- Pace successful collections so the game's normal
                    -- MouseButton1Down -> TelescopeGameRemote("Get", type)
                    -- handler is never hammered by rapid replacement spawns.
                    if not ClassController:Wait(
                        sessionId,
                        self,
                        Config.StarGazing.ClickDelay
                    ) then
                        break
                    end
                end
            end
        end

        -- Drop stale button references.
        for button, clickedAt in pairs(self.State.ClickedButtons) do
            if not button or not button.Parent or os.clock() - clickedAt >= Config.StarGazing.ButtonRetry then
                self.State.ClickedButtons[button] = nil
            end
        end

        if not ClassController:Wait(sessionId, self, Config.StarGazing.PollRate) then break end
    end
end

function StarGazing:Stop()
    closeTelescopeResults()
    closeTelescopeGame()
    self.State.LastPromptAttempt = 0
    self.State.ClickedButtons = {}
    self.State.LastClickAt = 0
end

ClassController:Register(StarGazing)
end -- scope: StarGazing


-- ========================================================================
-- 🧚 FAIRY FLIGHT MODULE
-- ========================================================================
-- FlightMinigameLocal behavior:
--   * active rings are chosen from UpdateRings.RandomRings / GotRings
--   * the normal client only calls GetRing AFTER the character touches a ring
--   * the server rejects GetRing when the player is too far away
--
-- This module mirrors that flow: double-Space enables normal flying, the
-- character moves through only the server-selected live ring, waits for the
-- touch/update, and uses GetRing only as an in-range fallback.
-- ========================================================================
do
local FairyFlight = {
    ClassName = "Fairy Flight", UseSharedTimer = false, IsOverride = true,
    State = { RemoteConnection = nil, FlightModel = nil, FlightData = nil, ArenaDetectedAt = nil, FlyingEnabled = false, CurrentTarget = nil, LastFallbackAt = 0, NoclipActive = false, SavedCanCollide = {} }
}

local function fairyFlightClassMatches() local name = normalizeClassName(getCurrentClassName()); return string.find(name, "fairy flight", 1, true) ~= nil end
local function getFairyFlightRemote() local remote = ReplicatedStorage:FindFirstChild("FlightMinigameRemote"); return remote and remote:IsA("RemoteEvent") and remote or nil end

local function tapFairySpace()
    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.055)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
    return ok
end

local function enableFairyFlying()
    if FairyFlight.State.FlyingEnabled then return true end
    if not tapFairySpace() then return false end
    task.wait(0.12)
    if not tapFairySpace() then return false end
    FairyFlight.State.FlyingEnabled = true
    Logger.Debug("🧚 [FairyFlight] Double-Space -> flying ON.")
    return true
end

local function disableFairyFlying()
    if not FairyFlight.State.FlyingEnabled then return true end
    local ok = tapFairySpace()
    FairyFlight.State.FlyingEnabled = false
    Logger.Debug("🧚 [FairyFlight] Single Space -> flying OFF.")
    return ok
end

local function enableFairyWallNoclip(character)
    if not Config.FairyFlight.WallNoclip or not character then return end

    if not FairyFlight.State.NoclipActive then
        FairyFlight.State.NoclipActive = true
        FairyFlight.State.SavedCanCollide = {}
        Logger.Debug("🧚 [FairyFlight] Wall noclip ON.")
    end

    -- Only CanCollide is changed. CanTouch stays untouched so the game's
    -- normal ring.Touched -> GetRing path can still fire.
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            if FairyFlight.State.SavedCanCollide[object] == nil then
                FairyFlight.State.SavedCanCollide[object] = object.CanCollide
            end
            pcall(function() object.CanCollide = false end)
        end
    end
end

local function disableFairyWallNoclip()
    if not FairyFlight.State.NoclipActive then return end

    for part, original in pairs(FairyFlight.State.SavedCanCollide) do
        if part and part.Parent then
            pcall(function() part.CanCollide = original end)
        end
    end

    FairyFlight.State.SavedCanCollide = {}
    FairyFlight.State.NoclipActive = false
    Logger.Debug("🧚 [FairyFlight] Wall noclip OFF.")
end

local function disconnectFairyRemote()
    if FairyFlight.State.RemoteConnection then pcall(function() FairyFlight.State.RemoteConnection:Disconnect() end); FairyFlight.State.RemoteConnection = nil end
end

local function getFairyRingContainer()
    local model = FairyFlight.State.FlightModel
    if model and model.Parent then local rings = model:FindFirstChild("FlightClassRings"); if rings then return rings end end
    local fallback = Workspace:FindFirstChild("FlightClassModel")
    return fallback and fallback:FindFirstChild("FlightClassRings") or nil
end

local function setupFairyRemoteListener()
    disconnectFairyRemote()
    local remote = getFairyFlightRemote()
    if not remote then return false end
    FairyFlight.State.RemoteConnection = remote.OnClientEvent:Connect(function(action, a2, a3)
        if action == "Setup" then
            FairyFlight.State.FlightModel = a2; FairyFlight.State.FlightData = nil; FairyFlight.State.ArenaDetectedAt = os.clock(); FairyFlight.State.CurrentTarget = nil
            Logger.Debug("🧚 [FairyFlight] Setup received; starting 6s arena intro.")
        elseif action == "UpdateRings" then
            FairyFlight.State.FlightData = type(a2) == "table" and a2 or nil
        elseif action == "End" then
            FairyFlight.State.FlightModel = nil; FairyFlight.State.FlightData = nil; FairyFlight.State.ArenaDetectedAt = nil; FairyFlight.State.CurrentTarget = nil
        elseif action == "GetRingFailed" then
            Logger.Debug("🧚 [FairyFlight] GetRingFailed: " .. tostring(a2) .. " (" .. tostring(a3) .. ")")
        end
    end)
    return true
end

local function getFairyMaxRingGroup(data)
    if type(data) ~= "table" then return 0 end
    local maxGot = 0
    for key in pairs(data.GotRings or {}) do maxGot = math.max(tonumber(key) or 0, maxGot) end
    return maxGot + (tonumber(data.MaxToSpawn) or 0)
end

local function fairyGroupWasGot(data, groupIndex)
    local got = data and data.GotRings or nil
    if type(got) ~= "table" then return false end
    return got[groupIndex] ~= nil or got[tostring(groupIndex)] ~= nil
end

local function getFairyRandomRingIndex(data, groupIndex)
    local random = data and data.RandomRings or nil
    if type(random) ~= "table" then return nil end
    return random[groupIndex] or random[tostring(groupIndex)]
end

local function getNextFairyRing()
    local data = FairyFlight.State.FlightData
    local container = getFairyRingContainer()
    local _, _, rootPart = getCharacter()

    if type(data) ~= "table" or not container or not rootPart then
        return nil, nil
    end

    local bestRing, bestGroup, bestDistance = nil, nil, math.huge
    local maxGroup = getFairyMaxRingGroup(data)

    -- UpdateRings activates one server-selected RandomRings entry for every
    -- currently available group. The old code returned the LOWEST group
    -- number, which could be across the map. Pick the closest ACTIVE ring
    -- instead.
    for groupIndex = 1, maxGroup do
        local ringIndex = getFairyRandomRingIndex(data, groupIndex)

        if ringIndex and not fairyGroupWasGot(data, groupIndex) then
            local group = container:FindFirstChild(tostring(groupIndex))
            local ring = group and group:FindFirstChild(tostring(ringIndex))

            if ring and ring:IsA("BasePart") then
                local distance = (ring.Position - rootPart.Position).Magnitude

                if distance < bestDistance then
                    bestRing = ring
                    bestGroup = groupIndex
                    bestDistance = distance
                end
            end
        end
    end

    return bestRing, bestGroup
end

local function waitForFairyRingCollected(sessionId, ring, groupIndex, timeout)
    local started = os.clock()
    while os.clock() - started < timeout do
        if not ClassController:IsSessionActive(sessionId, FairyFlight) then return false end
        if not ring or not ring.Parent then return true end
        if fairyGroupWasGot(FairyFlight.State.FlightData, groupIndex) then return true end
        task.wait(Config.FairyFlight.PollRate)
    end
    return fairyGroupWasGot(FairyFlight.State.FlightData, groupIndex)
end

local function flyFairyToRing(sessionId, ring)
    local character, humanoid, rootPart = getCharacter()
    if not character or not humanoid or not rootPart or not ring or not ring.Parent then return false end

    enableFairyWallNoclip(character)

    local speed = math.max(10, tonumber(Config.FairyFlight.MoveSpeed) or 85)
    local collectDistance = math.max(0.5, tonumber(Config.FairyFlight.CollectDistance) or 2.25)
    local maxStep = math.max(0.5, tonumber(Config.FairyFlight.MaxStep) or 1.75)

    while ClassController:IsSessionActive(sessionId, FairyFlight) and ring and ring.Parent do
        character, humanoid, rootPart = getCharacter()
        if not character or not humanoid or not rootPart then return false end

        enableFairyWallNoclip(character)

        local targetPos = ring.Position
        local delta = targetPos - rootPart.Position
        local distance = delta.Magnitude

        if distance <= collectDistance then
            return true
        end

        -- Never jump exactly onto the ring center. V45 could enter a narrow
        -- 2.25-2.55 stud band where math.min(distance, speed*dt) == distance,
        -- making nextPos == ring.Position. CFrame.lookAt(nextPos, ring.Position)
        -- then has identical origin/target points and can create an invalid
        -- orientation that sends the character to nonsense coordinates.
        local dt = Config.FairyFlight.PollRate
        local remainingBeforeRing = math.max(0.05, distance - collectDistance * 0.55)
        local step = math.min(speed * dt, maxStep, remainingBeforeRing)

        if step <= 0.001 or delta.Magnitude <= 0.001 then
            return true
        end

        local nextPos = rootPart.Position + delta.Unit * step

        -- Preserve the current rotation instead of using lookAt against the
        -- ring. This removes the same-point lookAt singularity completely.
        local rotationOnly = rootPart.CFrame - rootPart.Position
        local nextCF = CFrame.new(nextPos) * rotationOnly

        local ok = pcall(function()
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            character:PivotTo(nextCF)
        end)

        if not ok then
            Logger.Warn("⚠️ [FairyFlight] Safe approach PivotTo failed.")
            return false
        end

        task.wait(dt)
    end

    return false
end

function FairyFlight:IsEnabled() return Config.FairyFlight.Enabled end
function FairyFlight:CheckOverride() return fairyFlightClassMatches() end
function FairyFlight:CanStart() return fairyFlightClassMatches() end

function FairyFlight:Run(sessionId)
    Logger.Debug("🧚 [FairyFlight] Automation active.")
    self.State.FlightModel = nil; self.State.FlightData = nil; self.State.ArenaDetectedAt = nil; self.State.FlyingEnabled = false; self.State.CurrentTarget = nil; self.State.LastFallbackAt = 0; self.State.NoclipActive = false; self.State.SavedCanCollide = {}
    setupFairyRemoteListener()

    while ClassController:IsSessionActive(sessionId, self) do
        if not self.State.RemoteConnection then setupFairyRemoteListener() end
        local ringContainer = getFairyRingContainer()
        if ringContainer and not self.State.ArenaDetectedAt then self.State.ArenaDetectedAt = os.clock(); Logger.Debug("🧚 [FairyFlight] Ring arena found; starting 6s arena intro fallback.") end
        local ready = self.State.ArenaDetectedAt and (os.clock() - self.State.ArenaDetectedAt >= Config.FairyFlight.ArenaIntroDelay)

        if not ready or not ringContainer or type(self.State.FlightData) ~= "table" then
            if not ClassController:Wait(sessionId, self, Config.FairyFlight.PollRate) then break end
            continue
        end

        if not enableFairyFlying() then
            Logger.Warn("⚠️ [FairyFlight] Could not enable flying with double-Space.")
            if not ClassController:Wait(sessionId, self, 0.25) then break end
            continue
        end

        local character = LocalPlayer.Character
        if character then enableFairyWallNoclip(character) end

        local ring, groupIndex = getNextFairyRing()
        if not ring then
            if not ClassController:Wait(sessionId, self, Config.FairyFlight.PollRate) then break end
            continue
        end

        self.State.CurrentTarget = ring
        Logger.Debug("🧚 [FairyFlight] Target group " .. tostring(groupIndex) .. " -> " .. ring:GetFullName())

        if flyFairyToRing(sessionId, ring) then
            local collected = waitForFairyRingCollected(sessionId, ring, groupIndex, Config.FairyFlight.TouchWait)
            if not collected and os.clock() - self.State.LastFallbackAt >= Config.FairyFlight.FallbackRetry then
                local remote = getFairyFlightRemote()
                if remote and ring and ring.Parent then
                    self.State.LastFallbackAt = os.clock()
                    local ok, err = pcall(function() remote:FireServer("GetRing", ring) end)
                    if not ok then Logger.Warn("⚠️ [FairyFlight] In-range GetRing fallback failed: " .. tostring(err)) end
                    collected = waitForFairyRingCollected(sessionId, ring, groupIndex, 0.45)
                end
            end

            if collected then
                Logger.Debug("✅ [FairyFlight] Ring group " .. tostring(groupIndex) .. " collected.")
                if not ClassController:Wait(sessionId, self, Config.FairyFlight.RingDelay) then break end
            else
                Logger.Debug("⚠️ [FairyFlight] Ring did not confirm; retrying after short delay.")
                if not ClassController:Wait(sessionId, self, 0.15) then break end
            end
        else
            if not ClassController:Wait(sessionId, self, 0.10) then break end
        end
    end
end

function FairyFlight:Stop()
    disableFairyWallNoclip()
    disableFairyFlying()
    disconnectFairyRemote()

    self.State.FlightModel = nil
    self.State.FlightData = nil
    self.State.ArenaDetectedAt = nil
    self.State.CurrentTarget = nil
    self.State.LastFallbackAt = 0
    self.State.SavedCanCollide = {}
    self.State.NoclipActive = false
end

ClassController:Register(FairyFlight)
end -- scope: FairyFlight

-- ========================================================================
-- 💻 COMPUTER CLASS MODULE
--
-- Decompiled ComputerGameLocalScript shows:
--   ComputerMinigameRemotes.ToggleGameState -> opens/closes ComputerGame
--   ComputerMinigameRemotes.Update          -> CurrentWord / NextWord state
--   ComputerMinigameRemotes.LetterTyped     -> one typed character
--
-- The minigame UI only opens after sitting at a ComputerClass chair, so this
-- module first finds a free Seat under Workspace.ComputerClass.ComputerChairs,
-- sits the local Humanoid, then types the server-provided CurrentWord.

-- ========================================================================
do
local Computer = { ClassName = "Computer", UseSharedTimer = false, IsOverride = true, State = { Remotes = nil, GameUI = nil, Active = false, CurrentWord = nil, NextWord = nil, CorrectWordCount = 0, ToggleConnection = nil, UpdateConnection = nil, LastTypedSignature = nil, LastSeatAttempt = 0 } }
local function computerCurrentClassMatches() local current = normalizeClassName( getCurrentClassName() ); return string.find( current, "computer", 1, true ) ~= nil end
local function getComputerGameUI() local classes = PlayerGui:FindFirstChild( "RH4Classes" ); return classes and classes:FindFirstChild( "ComputerGame" ) or nil end
local function isComputerGameVisible()
    local ui = getComputerGameUI()
    if not ui then
        return false
    end
    local visible = false
    pcall(function()
        visible = ui.Visible
    end)
    return visible
end
local function getComputerRemotes() return ReplicatedStorage: FindFirstChild( "ComputerMinigameRemotes" ) end
local function disconnectComputerRemoteListeners()
    for _, field in ipairs({ "ToggleConnection", "UpdateConnection" }) do
        local connection = Computer.State[field]
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
            Computer.State[field] = nil
        end
    end
end
local function setupComputerRemoteListeners()
    disconnectComputerRemoteListeners()
    local remotes = getComputerRemotes()
    if not remotes then
        return false
    end
    local toggle = remotes:FindFirstChild( "ToggleGameState" )
    local update = remotes:FindFirstChild( "Update" )
    local letterTyped = remotes:FindFirstChild( "LetterTyped" )
    if not toggle or not update or not letterTyped then
        return false
    end
    Computer.State.Remotes = remotes
    Computer.State.GameUI = getComputerGameUI()
    Computer.State.ToggleConnection = toggle.OnClientEvent: Connect(function(active)
                Computer.State.Active = active == true
                if active then
                    Computer.State .LastTypedSignature = nil
                end
            end)
    Computer.State.UpdateConnection = update.OnClientEvent: Connect(function(data)
                if type(data) ~= "table" then
                    return
                end
                Computer.State.CurrentWord = tostring( data.CurrentWord or "" )
                Computer.State.NextWord = tostring( data.NextWord or "" )
                local correctWords = data.CorrectWords
                if type(correctWords) == "table" then
                    Computer.State .CorrectWordCount = #correctWords
                end
            end)
    return true
end
local function getComputerChairContainer() local computerClass = Workspace:FindFirstChild( "ComputerClass" ); return computerClass and computerClass:FindFirstChild( "ComputerChairs" ) or nil end
local function isOurComputerSeat( seat ) local chairs = getComputerChairContainer(); return seat and chairs and seat:IsDescendantOf( chairs ) end
local function getAvailableComputerSeats( rootPart, humanoid )
    local chairs = getComputerChairContainer()
    local seats = {}
    if not chairs then
        return seats
    end
    for _, object in ipairs( chairs:GetDescendants() ) do
        if object:IsA("Seat") or object:IsA("VehicleSeat") then
            local occupant = object.Occupant
            if occupant == nil or occupant == humanoid then
                table.insert( seats, object )
            end
        end
    end
    table.sort( seats, function(a, b)
            return ( a.Position - rootPart.Position ).Magnitude < ( b.Position - rootPart.Position ).Magnitude
        end )
    return seats
end
local function waitForComputerSeatOrUI( sessionId, seat )
    local started = os.clock()
    while os.clock() - started < Config.Computer .SeatAttemptTimeout do
        if ClassController.SessionId ~= sessionId then
            return false
        end
        if isComputerGameVisible() then
            return true
        end
        local character, humanoid = getCharacter()
        if humanoid and humanoid.SeatPart == seat then
            -- Give the game's chair/minigame listener a moment to open the UI.
            task.wait( 0.10 )
            if isComputerGameVisible() then
                return true
            end
        end
        task.wait( Config.Computer.PollRate )
    end
    return isComputerGameVisible()
end
local function tryEnterComputerSeat( sessionId )
    local character, humanoid, rootPart = getCharacter()
    if not character or not humanoid or not rootPart then
        return false
    end
    if humanoid.SeatPart and isOurComputerSeat( humanoid.SeatPart ) then
        return true
    end
    local now = os.clock()
    if now - Computer.State.LastSeatAttempt < Config.Computer .SeatRetryDelay then
        return false
    end
    Computer.State.LastSeatAttempt = now
    local seats = getAvailableComputerSeats( rootPart, humanoid )
    if #seats == 0 then
        Logger.Debug( "⚠️ [Computer] No free Seat found under Workspace.ComputerClass.ComputerChairs." )
        return false
    end
    for _, seat in ipairs( seats ) do
        if ClassController.SessionId ~= sessionId then
            return false
        end
        if seat.Parent and ( seat.Occupant == nil or seat.Occupant == humanoid ) then
            pcall(function()
                character:PivotTo( seat.CFrame * CFrame.new( 0, Config.Computer .SeatTeleportHeight, 0 ) )
            end)
            task.wait( 0.08 )
            pcall(function()
                seat:Sit( humanoid )
            end)
            if waitForComputerSeatOrUI( sessionId, seat ) then
                Logger.Debug( "💺 [Computer] Seated at " .. seat:GetFullName() )
                return true
            end
        end
    end
    return false
end
local function getComputerWordSignature()
    local word = tostring( Computer.State.CurrentWord or "" )
    local nextWord = tostring( Computer.State.NextWord or "" )
    if word == "" then
        return nil
    end
    return word .. "\0" .. nextWord .. "\0" .. tostring( Computer.State .CorrectWordCount )
end
local function sendComputerWord( sessionId, word, signature )
    local remotes = Computer.State.Remotes
    local letterTyped = remotes and remotes:FindFirstChild( "LetterTyped" )
    if not letterTyped or not letterTyped:IsA( "RemoteEvent" ) then
        Logger.Warn( "⚠️ [Computer] LetterTyped RemoteEvent is unavailable." )
        return false
    end
    Logger.Debug( "⌨️ [Computer] Typing: " .. tostring( word ) )
    for index = 1, #word do
        if ClassController.SessionId ~= sessionId or not computerCurrentClassMatches() or not isComputerGameVisible() then
            return false
        end
        -- If the server already advanced to the next word, stop sending
        -- characters from the old word immediately.
        local liveWord = tostring( Computer.State.CurrentWord or "" )
        if liveWord ~= "" and liveWord ~= word then
            break
        end
        local character = string.sub( word, index, index )
        local ok, err = pcall(function()
                letterTyped: FireServer( character )
            end)
        if not ok then
            Logger.Warn( "⚠️ [Computer] LetterTyped failed: " .. tostring( err ) )
            return false
        end
        if not ClassController: Wait( sessionId, Computer, Config.Computer .LetterDelay ) then
            return false
        end
    end
    Computer.State.LastTypedSignature = signature
    -- Wait briefly for Update to rotate CurrentWord -> NextWord before the
    -- outer loop considers another submission.
    local started = os.clock()
    while os.clock() - started < Config.Computer .WordChangeTimeout do
        if ClassController.SessionId ~= sessionId then
            return false
        end
        if not isComputerGameVisible() then
            return true
        end
        local newSignature = getComputerWordSignature()
        if newSignature and newSignature ~= signature then
            return true
        end
        task.wait( Config.Computer.PollRate )
    end
    return true
end
function Computer:IsEnabled() return Config.Computer.Enabled end
function Computer:CheckOverride() return computerCurrentClassMatches() end
function Computer:CanStart() return computerCurrentClassMatches() end
function Computer:Run( sessionId )
    Logger.Debug( "💻 [Computer] Automation active." )
    self.State.Active = isComputerGameVisible()
    self.State.CurrentWord = nil
    self.State.NextWord = nil
    self.State.CorrectWordCount = 0
    self.State.LastTypedSignature = nil
    self.State.LastSeatAttempt = 0
    if not setupComputerRemoteListeners() then
        Logger.Warn( "⚠️ [Computer] ComputerMinigameRemotes are not ready yet." )
    end
    while ClassController: IsSessionActive( sessionId, self ) do
        if not self.State.Remotes or not self.State.Remotes.Parent then
            setupComputerRemoteListeners()
        end
        if not isComputerGameVisible() then
            tryEnterComputerSeat( sessionId )
            if not ClassController: Wait( sessionId, self, Config.Computer .PollRate ) then
                break
            end
            continue
        end
        local word = tostring( self.State.CurrentWord or "" )
        local signature = getComputerWordSignature()
        if word ~= "" and signature and signature ~= self.State .LastTypedSignature then
            sendComputerWord( sessionId, word, signature )
        else
            if not ClassController: Wait( sessionId, self, Config.Computer .PollRate ) then
                break
            end
        end
    end
end
function Computer:Stop()
    disconnectComputerRemoteListeners()
    self.State.Active = false
    self.State.CurrentWord = nil
    self.State.NextWord = nil
    self.State.CorrectWordCount = 0
    self.State.LastTypedSignature = nil
    self.State.Remotes = nil
    self.State.GameUI = nil
    -- Release the computer chair cleanly when the class changes.
    local _, humanoid = getCharacter()
    if humanoid and humanoid.SeatPart and isOurComputerSeat( humanoid.SeatPart ) then
        pcall(function()
            humanoid.Sit = false
            humanoid:ChangeState( Enum.HumanoidStateType.GettingUp )
        end)
    end
end
ClassController:Register( Computer )
end -- scope: Computer

-- ========================================================================
-- 📚 HOMEWORK MODULE (REBUILT FROM RH4HomeworkLocalScript)
-- ========================================================================
do
local Homework = { ClassName = "Homework", UseSharedTimer = false, IsOverride = true, State = { ActiveTool = nil, ActiveHomeworkId = nil } }
local HOMEWORK_DIRECTION_KEY = { Up = Enum.KeyCode.W, Left = Enum.KeyCode.A, Down = Enum.KeyCode.S, Right = Enum.KeyCode.D }
local function getHomeworkGui()
    local hw = PlayerGui:FindFirstChild( "RH4Homework" )
    if not hw then
        return nil
    end
    local withQuest = hw:FindFirstChild( "WithQuest" )
    local doHomework = hw:FindFirstChild( "DoHomeworkButton" )
    return hw, withQuest, doHomework
end
local function isHomeworkTool( object )
    if not object or not object:IsA("Tool") then
        return false
    end
    -- HomeworkId is the authoritative marker used by RH4HomeworkLocalScript.
    return object:GetAttribute( "HomeworkId" ) ~= nil
end
local function isHomeworkComplete( tool ) return tool and tool:GetAttribute("Done") == true end
local function findIncompleteHomeworkTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer: FindFirstChildOfClass( "Backpack" )
    -- Prefer an already-equipped homework assignment.
    if character then
        for _, object in ipairs( character:GetChildren() ) do
            if isHomeworkTool(object) and not isHomeworkComplete( object ) then
                return object
            end
        end
    end
    if backpack then
        for _, object in ipairs( backpack:GetChildren() ) do
            if isHomeworkTool(object) and not isHomeworkComplete( object ) then
                return object
            end
        end
    end
    return nil
end
local function getHomeworkProgress( withQuest )
    if not withQuest then
        return nil, nil
    end
    local decorative = withQuest:FindFirstChild( "decorativethings" )
    local progress = decorative and decorative:FindFirstChild( "Progress" )
    if not progress then
        return nil, nil
    end
    local current, total = string.match( tostring( progress.Text or "" ), "(%d+)%s*/%s*(%d+)" )
    return tonumber(current), tonumber(total)
end
local function getCurrentHomeworkDirection( withQuest )
    if not withQuest then
        return nil
    end
    local recipe = withQuest:FindFirstChild( "recipe" )
    if not recipe then
        return nil
    end
    local visible = {}
    for _, object in ipairs( recipe:GetChildren() ) do
        if object:IsA("GuiObject") and object.Visible and HOMEWORK_DIRECTION_KEY[ object.Name ] then
            table.insert( visible, object )
        end
    end
    if #visible == 0 then
        return nil
    end
    -- CreateIcon() positions queue slots from left -> right.
    -- The game's press() checks only tbl_upv_1[1], so the leftmost
    -- visible recipe card is the ONLY direction that should be submitted.
    table.sort( visible, function(a, b)
            local ax = a.AbsolutePosition.X
            local bx = b.AbsolutePosition.X
            if math.abs(ax - bx) > 1 then
                return ax < bx
            end
            return a.AbsolutePosition.Y < b.AbsolutePosition.Y
        end )
    return visible[1].Name, visible[1]
end
local function sendHomeworkDirection( direction )
    local key = HOMEWORK_DIRECTION_KEY[ direction ]
    if not key then
        return false
    end
    local ok = pcall(function()
            VirtualInputManager: SendKeyEvent( true, key, false, game )
            task.wait( Config.Homework.KeyHold )
            VirtualInputManager: SendKeyEvent( false, key, false, game )
        end)
    return ok
end
local function equipHomeworkTool( tool )
    if not tool or not tool.Parent then
        return false
    end
    local character, humanoid = getCharacter()
    if not character or not humanoid then
        return false
    end
    if tool.Parent == character then
        return true
    end
    local backpack = LocalPlayer: FindFirstChildOfClass( "Backpack" )
    if tool.Parent ~= backpack then
        return false
    end
    local ok = pcall(function()
            humanoid:EquipTool( tool )
        end)
    if not ok then
        return false
    end
    local started = os.clock()
    while os.clock() - started < Config.Homework.EquipTimeout do
        if not tool.Parent then
            return false
        end
        if tool.Parent == character then
            return true
        end
        task.wait( Config.Homework.PollRate )
    end
    return tool.Parent == character
end
local function waitForHomeworkGuiReady( sessionId, tool )
    local started = os.clock()
    while os.clock() - started < Config.Homework.OpenTimeout do
        if ClassController.SessionId ~= sessionId then
            return false
        end
        if not tool or not tool.Parent or isHomeworkComplete( tool ) then
            return false
        end
        local _, withQuest, doHomework = getHomeworkGui()
        if withQuest and withQuest.Visible then
            return true
        end
        if doHomework and doHomework.Visible then
            return true
        end
        task.wait( Config.Homework.PollRate )
    end
    return false
end
local function openHomeworkMinigame( sessionId, tool )
    local _, withQuest, doHomework = getHomeworkGui()
    if withQuest and withQuest.Visible then
        return true
    end
    if not waitForHomeworkGuiReady( sessionId, tool ) then
        return false
    end
    _, withQuest, doHomework = getHomeworkGui()
    if withQuest and withQuest.Visible then
        return true
    end
    local button = doHomework and doHomework:FindFirstChild( "Button" )
    if not button or not button:IsA( "GuiButton" ) then
        Logger.Warn( "⚠️ [Homework] DoHomeworkButton.Button not found." )
        return false
    end
    -- RH4HomeworkLocalScript connects THIS exact TextButton to
    -- OpenGuiButton(). Firing the connection preserves its local u1
    -- assignment/state and lets the game's own MinigameStarted call run.
    local clicked = Utils.fireClick( button )
    -- Executor/obfuscator compatibility:
    -- some environments do not expose getconnections() reliably.
    -- If the direct connection-fire route fails, use the existing
    -- VirtualInputManager GUI click path instead.
    if not clicked then
        Logger.Debug( "📚 [Homework] getconnections click unavailable; trying GUI click fallback." )
        clicked = Utils.clickGuiObject( button )
    end
    if not clicked then
        Logger.Warn( "⚠️ [Homework] Could not activate Do Homework button using either click method." )
        return false
    end
    local openedAt = os.clock()
    while os.clock() - openedAt < Config.Homework.OpenTimeout do
        if ClassController.SessionId ~= sessionId then
            return false
        end
        if not tool or not tool.Parent or isHomeworkComplete( tool ) then
            return false
        end
        _, withQuest = getHomeworkGui()
        if withQuest and withQuest.Visible then
            return true
        end
        task.wait( Config.Homework.PollRate )
    end
    return false
end
local function waitForHomeworkProgress( sessionId, tool, previousProgress )
    local started = os.clock()
    while os.clock() - started < Config.Homework.ProgressTimeout do
        -- Do not use IsSessionActive() here after the final 18th press:
        -- the server may mark the tool Done immediately, which correctly
        -- makes CheckOverride() false before this local loop finishes.
        if ClassController.SessionId ~= sessionId then
            return false, previousProgress, false
        end
        if tool and isHomeworkComplete( tool ) then
            return true, 18, true
        end
        local _, withQuest = getHomeworkGui()
        if not withQuest or not withQuest.Visible then
            -- RH4HomeworkLocalScript hides WithQuest after the 18th correct
            -- input and fires Finished + MinigameStarted(false).
            return true, previousProgress, true
        end
        local current = getHomeworkProgress( withQuest )
        if current and current > previousProgress then
            return true, current, false
        end
        task.wait( Config.Homework.PollRate )
    end
    return false, previousProgress, false
end
function Homework:IsEnabled() return Config.Homework.Enabled end
function Homework:CheckOverride()
    local _, withQuest, doHomework = getHomeworkGui()
    if withQuest and withQuest.Visible then
        return true
    end
    -- DoHomeworkButton can remain as UI state; only treat it as an override
    -- while an actual unfinished HomeworkId Tool exists.
    local incomplete = findIncompleteHomeworkTool()
    if incomplete then
        return true
    end
    return false
end
function Homework:CanStart() return findIncompleteHomeworkTool() ~= nil or ( select( 2, getHomeworkGui() ) and select( 2, getHomeworkGui() ).Visible ) end
function Homework:Run( sessionId )
    Logger.Log( "\n==============================================" .. "\n📚 HOMEWORK AUTOMATION ACTIVE (REBUILT)" .. "\n==============================================" )
    while ClassController.SessionId == sessionId do
        local tool = findIncompleteHomeworkTool()
        if not tool then
            break
        end
        self.State.ActiveTool = tool
        self.State.ActiveHomeworkId = tool:GetAttribute( "HomeworkId" )
        Logger.Log( "📚 [Homework] Assignment: " .. tostring( tool.Name ) .. " | HomeworkId=" .. tostring( self.State.ActiveHomeworkId ) )
        -- ================================================================
        -- 1. EQUIP THE REAL HOMEWORK TOOL
        -- ================================================================
        if not equipHomeworkTool( tool ) then
            Logger.Warn( "⚠️ [Homework] Could not equip " .. tostring( tool.Name ) )
            break
        end
        -- ================================================================
        -- 2. OPEN DoHomeworkButton.Button
        -- ================================================================
        if not openHomeworkMinigame( sessionId, tool ) then
            Logger.Warn( "⚠️ [Homework] Homework minigame did not open." )
            break
        end
        local _, withQuest = getHomeworkGui()
        if not withQuest or not withQuest.Visible then
            break
        end
        local progress, total = getHomeworkProgress( withQuest )
        progress = progress or 0
        total = total or 18
        Logger.Log( "📝 [Homework] Minigame opened | " .. tostring(progress) .. "/" .. tostring(total) )
        -- ================================================================
        -- 3. FOLLOW THE SLIDING QUEUE ONE INPUT AT A TIME
        --
        -- RH4HomeworkLocalScript:
        --   press(direction)
        --      compares direction to tbl_upv_1[1]
        --      increments u3
        --      Progress:FireServer(...)
        --      Slide(...)
        --
        -- Therefore we DO NOT capture all four directions and blast them.
        -- We read ONLY the current leftmost card, submit it, wait for the
        -- game's Progress UI to acknowledge it, and then read the new queue.
        -- ================================================================
        local submitted = 0
        local failures = 0
        while ClassController.SessionId == sessionId and submitted < Config.Homework .MaxInputsPerAssignment do
            if isHomeworkComplete( tool ) then
                break
            end
            _, withQuest = getHomeworkGui()
            if not withQuest or not withQuest.Visible then
                break
            end
            progress, total = getHomeworkProgress( withQuest )
            progress = progress or 0
            total = total or 18
            if progress >= total then
                break
            end
            local direction = getCurrentHomeworkDirection( withQuest )
            if not direction then
                if not ClassController: Wait( sessionId, self, Config.Homework.PollRate ) then
                    break
                end
                continue
            end
            local before = progress
            Logger.Debug( "📚 [Homework] " .. tostring(before) .. "/" .. tostring(total) .. " -> " .. tostring(direction) )
            if not sendHomeworkDirection( direction ) then
                Logger.Warn( "⚠️ [Homework] Failed to send " .. tostring(direction) )
                break
            end
            submitted += 1
            local advanced, newProgress, finished = waitForHomeworkProgress( sessionId, tool, before )
            if finished then
                break
            end
            if advanced then
                failures = 0
                progress = newProgress
            else
                failures += 1
                Logger.Warn( "⚠️ [Homework] Progress did not advance after " .. tostring(direction) .. " | " .. tostring(before) .. "/" .. tostring(total) )
                if failures >= 3 then
                    Logger.Warn( "❌ [Homework] Stopping after 3 unacknowledged inputs." )
                    break
                end
            end
            -- The game's SlideTweenInfo is 0.2 seconds. This fixed gap keeps
            -- us from sampling the old card while it is still sliding out.
            if ClassController.SessionId ~= sessionId then
                break
            end
            task.wait( Config.Homework.InputDelay )
        end
        local finalProgress = 0
        _, withQuest = getHomeworkGui()
        if withQuest then
            finalProgress = select( 1, getHomeworkProgress( withQuest ) ) or 0
        end
        if isHomeworkComplete(tool) or not ( withQuest and withQuest.Visible ) or finalProgress >= 18 then
            Logger.Log( "✅ [Homework] Completed " .. tostring( tool.Name ) )
        else
            Logger.Warn( "⚠️ [Homework] Assignment stopped at " .. tostring( finalProgress ) .. "/18" )
            break
        end
        -- Give the server a moment to set Done / move UI state before looking
        -- for another unfinished HomeworkId tool.
        task.wait(0.20)
    end
    self.State.ActiveTool = nil
    self.State.ActiveHomeworkId = nil
end
function Homework:Stop() self.State.ActiveTool = nil; self.State.ActiveHomeworkId = nil end
ClassController:Register( Homework )
end -- scope: Homework

-- ========================================================================
-- 📖 STUDY HALL MODULE
-- ========================================================================
do
local StudyHall = { ClassName = "Study Hall", UseSharedTimer = false, State = { IntroReadyAt = nil, SpawnMoveDone = false, Round = 0 } }
-- Exact card mapping from StudyHallLocal.
local STUDY_CARD_BY_ASSET = { ["135883583522799"] = { Name = "Backpack", Key = Enum.KeyCode.One }, ["127574325227693"] = { Name = "Unisus", Key = Enum.KeyCode.Two }, ["111192420346715"] = { Name = "Pen", Key = Enum.KeyCode.Three }, ["102150609356863"] = { Name = "Flower", Key = Enum.KeyCode.Four }, ["128066095795130"] = { Name = "Puppy", Key = Enum.KeyCode.Five } }
local function getStudyHallUI()
    local session = RH4Classes:FindFirstChild( "StudyHallCramSession" )
    if not session then
        return nil
    end
    local studying = session:FindFirstChild( "Studying" )
    local answerTime = session:FindFirstChild( "AnswerTime" )
    local timer = session:FindFirstChild( "Timer" )
    return session, studying, answerTime, timer
end
local function isGuiVisible(gui)
    if not gui then
        return false
    end
    local visible = false
    pcall(function()
        visible = gui.Visible
    end)
    return visible
end
local function getStudyHallTimeRemaining()
    local _, _, _, timer = getStudyHallUI()
    if not timer then
        return nil
    end
    local seconds = string.match( tostring( timer.Text or "" ), "(%d+)%s*s" )
    return seconds and tonumber(seconds) or nil
end
local function readStudyHallSequence()
    local _, studying = getStudyHallUI()
    local sequence = {}
    if not studying then
        return sequence
    end
    local flashcards = studying:FindFirstChild( "FlashcardsToMemorize" )
    if not flashcards then
        return sequence
    end
    for index = 1, 8 do
        local slot = flashcards:FindFirstChild( tostring(index) )
        if slot and isGuiVisible(slot) then
            local icon = slot:FindFirstChild( "Icon" )
            if icon then
                local assetId = string.match( tostring( icon.Image or "" ), "(%d+)" )
                local mapped = assetId and STUDY_CARD_BY_ASSET[ assetId ] or nil
                if mapped then
                    table.insert( sequence, { Name = mapped.Name, Key = mapped.Key, Asset = assetId } )
                end
            end
        end
    end
    return sequence
end
local function sequenceToText( sequence )
    local names = {}
    for _, card in ipairs( sequence ) do
        table.insert( names, card.Name )
    end
    return table.concat( names, " > " )
end
local function sendStudyHallKey( keyCode ) local ok = pcall(function() VirtualInputManager: SendKeyEvent( true, keyCode, false, game ); task.wait( Config.StudyHall.KeyHold ); VirtualInputManager: SendKeyEvent( false, keyCode, false, game ); end); return ok end
local function waitForStudyHallState( sessionId, predicate, timeout )
    local started = os.clock()
    while os.clock() - started < timeout do
        if not ClassController: IsSessionActive( sessionId, StudyHall ) then
            return false
        end
        local ok, result = pcall( predicate )
        if ok and result then
            return true
        end
        task.wait( Config.StudyHall.PollRate )
    end
    return false
end
local function doStudyHallSpawnMove()
    local key = Config.StudyHall.SpawnMoveKey or Enum.KeyCode.W
    local presses = Config.StudyHall.SpawnMovePresses or 2
    local pressDuration = Config.StudyHall.SpawnMovePressDuration or 0.18
    local gap = Config.StudyHall.SpawnMoveGap or 0.08
    local ok = pcall(function()
            for index = 1, presses do
                VirtualInputManager: SendKeyEvent( true, key, false, game )
                task.wait( pressDuration )
                VirtualInputManager: SendKeyEvent( false, key, false, game )
                if index < presses then
                    task.wait( gap )
                end
            end
        end)
    -- Always make sure W is released even if the input sequence errors.
    pcall(function()
        VirtualInputManager: SendKeyEvent( false, key, false, game )
    end)
    if ok then
        Logger.Log( "🚶 [StudyHall] Pressed W " .. tostring(presses) .. "x after teleport to trigger the class zone/UI." )
    else
        Logger.Warn( "⚠️ [StudyHall] Could not perform post-teleport W movement." )
    end
    return ok
end
function StudyHall:IsEnabled() return Config.StudyHall.Enabled end
function StudyHall:CanStart()
    -- ClassController only reaches this module while CurrentClass matches
    -- "Study Hall". Immediately perform one real forward movement after the
    -- schedule teleport, before requiring StudyHallCramSession to be active.
    if not self.State.SpawnMoveDone then
        self.State.SpawnMoveDone = true
        doStudyHallSpawnMove()
        self.State.IntroReadyAt = os.clock() + Config.StudyHall.IntroDelay
        Logger.Log( "⏳ [StudyHall] Waiting " .. tostring( Config.StudyHall.IntroDelay ) .. "s after movement for class intro..." )
        return false
    end
    if not self.State.IntroReadyAt then
        self.State.IntroReadyAt = os.clock() + Config.StudyHall.IntroDelay
        return false
    end
    if os.clock() < self.State.IntroReadyAt then
        return false
    end
    local session, studying, answerTime = getStudyHallUI()
    if not session or not studying or not answerTime then
        -- Keep waiting. Do NOT reset SpawnMoveDone/IntroReadyAt here,
        -- otherwise the script would repeatedly press W if the UI is late.
        return false
    end
    return isGuiVisible( session )
end
function StudyHall:ShouldStayActive()
    local session = getStudyHallUI()
    if not session then
        return false
    end
    local remaining = getStudyHallTimeRemaining()
    if remaining and remaining <= 0 then
        return false
    end
    return true
end
function StudyHall:Run( sessionId )
    Logger.Log( "\n==============================================" .. "\n📖 STUDY HALL AUTOMATION ACTIVE" .. "\n==============================================" )
    self.State.Round = 0
    while ClassController: IsSessionActive( sessionId, self ) do
        local session, studying, answerTime = getStudyHallUI()
        if not session or not studying or not answerTime then
            if not ClassController: Wait( sessionId, self, Config.StudyHall.PollRate ) then
                break
            end
            continue
        end
        -- ================================================================
        -- STUDYING PHASE
        -- ================================================================
        if isGuiVisible( studying ) then
            local sequence = readStudyHallSequence()
            -- SetupNewRound() can make Studying visible a frame before every
            -- FlashcardsToMemorize slot has received its image.
            if #sequence == 0 then
                if not ClassController: Wait( sessionId, self, Config.StudyHall.PollRate ) then
                    break
                end
                continue
            end
            self.State.Round += 1
            Logger.Log( "🧠 [StudyHall] Round " .. tostring( self.State.Round ) .. " | " .. sequenceToText( sequence ) )
            -- The decompiled StudyHallLocal binds Enter/Return to Ready().
            sendStudyHallKey( Enum.KeyCode.Return )
            local enteredAnswerMode = waitForStudyHallState( sessionId, function()
                        local _, _, answer = getStudyHallUI()
                        return answer and isGuiVisible( answer )
                    end, Config.StudyHall.ReadyTimeout )
            -- Fallback: if the keyboard binding wasn't ready yet, invoke the
            -- same local Ready button the game connects to Ready().
            if not enteredAnswerMode then
                local ready = studying: FindFirstChild( "Ready" )
                local button = ready and ready:FindFirstChild( "Button" )
                if button then
                    Utils.fireClick( button )
                end
                enteredAnswerMode = waitForStudyHallState( sessionId, function()
                            local _, _, answer = getStudyHallUI()
                            return answer and isGuiVisible( answer )
                        end, Config.StudyHall.ReadyTimeout )
            end
            if not enteredAnswerMode then
                Logger.Warn( "⚠️ [StudyHall] AnswerTime did not open." )
                if not ClassController: Wait( sessionId, self, Config.StudyHall.PollRate ) then
                    break
                end
                continue
            end
            -- ============================================================
            -- ANSWERING PHASE
            --
            -- StudyHallLocal maps:
            --   1 = Backpack
            --   2 = Unisus
            --   3 = Pen
            --   4 = Flower
            --   5 = Puppy
            --
            -- Sending the normal number keys lets the game's own Input()
            -- and CheckAnswer() functions validate the sequence and send
            -- "Right"/"Wrong" to StudyHallRemote itself.
            -- ============================================================
            for _, card in ipairs( sequence ) do
                if not ClassController: IsSessionActive( sessionId, self ) then
                    return
                end
                sendStudyHallKey( card.Key )
                if not ClassController: Wait( sessionId, self, Config.StudyHall.KeyDelay ) then
                    return
                end
            end
            -- CheckAnswer() waits 0.5s on a correct result and then
            -- SetupNewRound() returns to Studying. Wait for that transition
            -- instead of blindly assuming a fixed round duration.
            waitForStudyHallState( sessionId, function()
                    local _, study = getStudyHallUI()
                    return study and isGuiVisible( study )
                end, Config.StudyHall.RoundTimeout )
        -- ================================================================
        -- ANSWER MODE ALREADY OPEN
        --
        -- Normally this state is only entered after we have saved a sequence.
        -- If the module happens to attach mid-round, wait for the game to
        -- return to Studying rather than guessing an unknown answer.
        -- ================================================================
        elseif isGuiVisible( answerTime ) then
            if not ClassController: Wait( sessionId, self, Config.StudyHall.PollRate ) then
                break
            end
        else
            if not ClassController: Wait( sessionId, self, Config.StudyHall.PollRate ) then
                break
            end
        end
    end
end
function StudyHall:Stop()
    self.State.IntroReadyAt = nil
    self.State.SpawnMoveDone = false
    self.State.Round = 0
    -- Safety release in case the class changed during the movement nudge.
    pcall(function()
        VirtualInputManager: SendKeyEvent( false, Config.StudyHall.SpawnMoveKey or Enum.KeyCode.W, false, game )
    end)
end
ClassController:Register( StudyHall )
end -- scope: StudyHall

-- ========================================================================
-- 🏊 SWIM SPINNER MODULE
--
-- SpinnerLocal marks every dangerous spinner BasePart with the "Boop"
-- attribute and uses that part's Touched event to knock the local character
-- away.  This module therefore does NOT disable CanCollide (we still need
-- the pillar to support the player).  Instead it temporarily disables
-- CanTouch on the character's direct BaseParts while jumping.

-- ========================================================================
do
local SwimSpinner = { ClassName = "Swim Spinner",
    -- Start from CurrentClass itself. The Spinner model is created dynamically
    -- later, so the module can safely wait through the intro without relying
    -- on the shared class timer.
    UseSharedTimer = false, State = { Spinner = nil, BoopParts = {}, DescendantAddedConnection = nil, TouchShieldActive = false, TouchShieldStartedAt = 0, SavedCanTouch = {}, Armed = true, LastJumpAt = -math.huge } }
local function getSwimSpinnerModel() local minigame = Workspace:FindFirstChild( "JumpingPoolMinigame" ); return minigame and minigame:FindFirstChild( "Spinner" ) or nil end
local function isBoopPart(object) return object and object:IsA("BasePart") and object:GetAttribute("Boop") ~= nil end
local function addSwimBoopPart(object)
    if not isBoopPart(object) then
        return
    end
    SwimSpinner.State.BoopParts[object] = true
    Logger.Debug( "🏊 [SwimSpinner] Tracking Boop part: " .. object:GetFullName() )
end
local function disconnectSwimSpinnerWatcher()
    local connection = SwimSpinner.State .DescendantAddedConnection
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
    SwimSpinner.State .DescendantAddedConnection = nil
end
local function attachSwimSpinner(spinner)
    if SwimSpinner.State.Spinner == spinner then
        return
    end
    disconnectSwimSpinnerWatcher()
    SwimSpinner.State.Spinner = spinner
    SwimSpinner.State.BoopParts = {}
    if not spinner then
        return
    end
    for _, object in ipairs( spinner:GetDescendants() ) do
        addSwimBoopPart( object )
    end
    SwimSpinner.State .DescendantAddedConnection = spinner.DescendantAdded: Connect(function(object)
                addSwimBoopPart( object )
            end)
    Logger.Debug( "🏊 [SwimSpinner] Spinner attached with " .. tostring( (function()
                local count = 0
                for _ in pairs( SwimSpinner.State.BoopParts ) do
                    count += 1
                end
                return count
            end)() ) .. " Boop part(s)." )
end
local function getPointToPartSurfaceDistance( worldPosition, part )
    if not part or not part.Parent then
        return math.huge, math.huge
    end
    local localPoint = part.CFrame: PointToObjectSpace( worldPosition )
    local half = part.Size * 0.5
    local closestLocal = Vector3.new( math.clamp( localPoint.X, -half.X, half.X ), math.clamp( localPoint.Y, -half.Y, half.Y ), math.clamp( localPoint.Z, -half.Z, half.Z ) )
    local closestWorld = part.CFrame: PointToWorldSpace( closestLocal )
    local offset = worldPosition - closestWorld
    return offset.Magnitude, math.abs( offset.Y )
end
local function getClosestSwimThreat( rootPart )
    local closestPart = nil
    local closestDistance = math.huge
    local closestVerticalGap = math.huge
    for part in pairs( SwimSpinner.State.BoopParts ) do
        if not isBoopPart(part) or not part:IsDescendantOf( Workspace ) then
            SwimSpinner.State .BoopParts[part] = nil
            continue
        end
        local distance, verticalGap = getPointToPartSurfaceDistance( rootPart.Position, part )
        if distance < closestDistance then
            closestPart = part
            closestDistance = distance
            closestVerticalGap = verticalGap
        end
    end
    return closestPart, closestDistance, closestVerticalGap
end
local function applySwimTouchShield( character )
    if not character then
        return
    end
    for _, object in ipairs( character:GetChildren() ) do
        if object:IsA("BasePart") then
            if SwimSpinner.State .SavedCanTouch[object] == nil then
                SwimSpinner.State .SavedCanTouch[object] = object.CanTouch
            end
            pcall(function()
                object.CanTouch = false
            end)
        end
    end
end
local function enableSwimTouchShield( character )
    if not SwimSpinner.State .TouchShieldActive then
        SwimSpinner.State .SavedCanTouch = {}
        SwimSpinner.State .TouchShieldStartedAt = os.clock()
        SwimSpinner.State .TouchShieldActive = true
        Logger.Debug( "🛡️ [SwimSpinner] Touch shield ON." )
    end
    -- Reapply every poll so any character BasePart that appears while the
    -- shield is active is also protected.
    applySwimTouchShield( character )
end
local function disableSwimTouchShield()
    if not SwimSpinner.State .TouchShieldActive then
        return
    end
    for part, originalCanTouch in pairs( SwimSpinner.State .SavedCanTouch ) do
        if part and part.Parent then
            pcall(function()
                part.CanTouch = originalCanTouch
            end)
        end
    end
    SwimSpinner.State .SavedCanTouch = {}
    SwimSpinner.State .TouchShieldActive = false
    SwimSpinner.State .TouchShieldStartedAt = 0
    Logger.Debug( "🛡️ [SwimSpinner] Touch shield OFF." )
end
local function isSwimGrounded( humanoid )
    if not humanoid then
        return false
    end
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown then
        return false
    end
    return humanoid.FloorMaterial ~= Enum.Material.Air
end
local function performSwimJump( humanoid, character )
    enableSwimTouchShield( character )
    SwimSpinner.State.Armed = false
    SwimSpinner.State.LastJumpAt = os.clock()
    local ok = pcall(function()
            humanoid.Jump = true
            humanoid:ChangeState( Enum.HumanoidStateType.Jumping )
        end)
    if ok then
        Logger.Debug( "🏊 [SwimSpinner] Threat close -> jump." )
    else
        Logger.Warn( "⚠️ [SwimSpinner] Failed to trigger jump." )
    end
    return ok
end
function SwimSpinner:IsEnabled() return Config.SwimSpinner.Enabled end
function SwimSpinner:CanStart() return true end
function SwimSpinner:Run( sessionId )
    Logger.Debug( "🏊 [SwimSpinner] Automation active." )
    self.State.Armed = true
    self.State.LastJumpAt = -math.huge
    while ClassController: IsSessionActive( sessionId, self ) do
        local character, humanoid, rootPart = getCharacter()
        if not character or not humanoid or not rootPart then
            if not ClassController: Wait( sessionId, self, Config.SwimSpinner .PollRate ) then
                break
            end
            continue
        end
        local spinner = getSwimSpinnerModel()
        if spinner ~= self.State.Spinner then
            attachSwimSpinner( spinner )
        end
        if self.State .TouchShieldActive then
            enableSwimTouchShield( character )
        end
        local threatPart, threatDistance, verticalGap = getClosestSwimThreat( rootPart )
        local now = os.clock()
        -- Restore touch as soon as the dangerous bar has moved away, while
        -- keeping a short minimum protected window around the actual jump.
        if self.State .TouchShieldActive then
            local protectedFor = now - self.State .TouchShieldStartedAt
            local threatClear = not threatPart or threatDistance >= Config.SwimSpinner .ClearDistance
            if protectedFor >= Config.SwimSpinner .MinTouchOff and threatClear then
                disableSwimTouchShield()
            elseif protectedFor >= Config.SwimSpinner .MaxTouchOff then
                -- Failsafe: never leave CanTouch disabled indefinitely.
                disableSwimTouchShield()
            end
        end
        -- Rearm only after the previous bar has clearly passed.
        if not self.State.Armed and not self.State .TouchShieldActive then
            local clear = not threatPart or threatDistance >= Config.SwimSpinner .ClearDistance
            if clear and now - self.State.LastJumpAt >= Config.SwimSpinner .JumpCooldown then
                self.State.Armed = true
            end
        end
        local threatClose = threatPart and threatDistance <= Config.SwimSpinner .TriggerDistance and verticalGap <= Config.SwimSpinner .MaxVerticalGap
        if self.State.Armed and threatClose and isSwimGrounded( humanoid ) and now - self.State.LastJumpAt >= Config.SwimSpinner .JumpCooldown then
            Logger.Debug( "🏊 [SwimSpinner] " .. threatPart.Name .. " | surface=" .. string.format( "%.2f", threatDistance ) .. " | vertical=" .. string.format( "%.2f", verticalGap ) )
            performSwimJump( humanoid, character )
        end
        if not ClassController: Wait( sessionId, self, Config.SwimSpinner.PollRate ) then
            break
        end
    end
end
function SwimSpinner:Stop() disableSwimTouchShield(); disconnectSwimSpinnerWatcher(); self.State.Spinner = nil; self.State.BoopParts = {}; self.State.Armed = true; self.State.LastJumpAt = -math.huge end
ClassController:Register( SwimSpinner )
end -- scope: SwimSpinner

-- ========================================================================
-- 📝 ENGLISH CLASS MODULE
-- ========================================================================
do
local English = { ClassName = "English", UseSharedTimer = false, State = { IntroReadyAt = nil, AnsweredSignature = nil, LastUnknownQuestion = nil } }
local EnglishClassRemote = ReplicatedStorage:WaitForChild( "EnglishClassRemote", 10 )
local EnglishCorrectByQuestion = {}
local EnglishCorrectAnswerSet = {}
local ENGLISH_EXTRA_QUESTIONS = {
    {"The diligent student always showed great ___________ in her studies.", "Perseverance"},
    {"The engineer's precise ___________ ensured the bridge was safe for everyone.", "Calculations"},
    {"I didn't give up ______ I learned how to spell the word.", "Until"},
    {"It was an _______ mistake.", "Amateur"},
    {"I'm going to win this ________!", "Argument"},
    {"I'm going to study in the _______.", "Library"},
    {"Valentines day is on ________ 14th.", "February"},
    {"A good host knows how to ___________ their guests.", "Accommodate"},
    {"It was so ____________.", "Embarrassing"},
    {"I wanted another piece of cake, because I love _______.", "Dessert"},
    {"I accidently bit my ______.", "Tongue"},
    {"That is ______ being crazy for one day.", "Enough"},
    {"_________ comes after Tuesday.", "Wednesday"},
    {"The sky is _________ today.", "Beautiful"},
    {"We'll have to wait _____ tomorrow.", "Until"},
    {"The chameleon went into __________ to protect itself.", "Camouflage"},
    {"I had drank ____ of soda at the party.", "a lot"},
    {"It's _________ that my kitten loves to chase her own tail.", "Apparent"},
    {"The ___________ is everything around us, like the air, trees, and animals.", "Environment"},
    {"The _______ of noise in the early morning was calming, as if the world was taking a deep, peaceful breath.", "Absence"},
    {"I was _________ finished with my homework when my dog jumped on the desk and knocked everything over!", "Basically"},
    {"She is __________ the happiest when she's surrounded by her friends and family.", "Definitely"},
    {"We're going to the beach ________.", "Tomorrow"},
    {"I marked the entire month on my ________ with smiley faces, because every day feels like a fun new adventure!", "Calendar"},
    {"The _________ in her eyes was contagious, inspiring everyone around her.", "Curiosity"},
    {"The fairy flew into the room wearing a _________ sparkling dress.", "Glamorous"},
    {"I'm so ________ for my friends who always make me laugh.", "Grateful"},
    {"I still can't believe what ________ when the puppy found the pile of pillows and decided it was his new bed!", "Happened"},
    {"They got an ________ medal for being a good helper.", "Honorary"},
    {"The two puppies are _______ in size and color.", "Similar"},
    {"The artist's _____ painting made everyone smile because it was so unique and fun.", "Weird"},
    {"It took her by ________.", "Surprise"},
    {"They had a __________ shopping trip.", "Successful"},
    {"Oracas are very ___________ animals.", "Intelligent"},
    {"I got my drivers _______ today!", "License"},
    {"An interesting thought ________ to her.", "Occurred"},
    {"His ________ joke made everyone giggle.", "Humorous"},
    {"The students left the room __________ after the bell rang.", "Immediately"},
    {"Please don't _________ during the movie.", "Interrupt"},
    {"The nature fairy has a lot of _________ about animals.", "Knowledge"},
    {"The __________ lit up the sky during the storm.", "Lightning"},
    {"Her bright pink dress was very __________ at the party.", "Noticeable"},
    {"We celebrated the special ________ with a big party.", "Occasion"},
    {"Her __________ efforts finally paid off when she won the race.", "Persistent"},
    {"He gave me a _____ of pie.", "Piece"},
    {"Always ________ to finish all of your school work.", "Remember"},
    {"She will _______ many gifts for her birthday.", "Receive"},
    {"Ice fairies show great __________ to the cold weather.", "Resistance"},
    {"We need to ________ the recycling from the trash.", "Separate"},
    {"He has a ________ to be late for class.", "Tendency"},
    {"We wanted to go to the park, but ____________, it started raining.", "Unfortunately"},
    {"Her explanation finally made _____ to me.", "Sense"},
    {"The dog gave a _______ bark at the stranger.", "Vicious"},
    {"I will follow you ________ you go.", "Wherever"},
    {"My dog stood _____ at the door when he heard a knock.", "Guard"},
    {"The princess invited her best ______ to the royale ball.", "Friend"},
    {"The place felt ________ as soon as I walked in.", "Familiar"},
    {"The mermaid's _________ was a secret, known only to skip the wait.", "Existence"},
    {"The rain will _________ by afternoon.", "Disappear"},
    {"She __________ forgot about the homework assignment.", "Completely"},
    {"He placed the books in the correct ________.", "Category"},
    {"The _________ of the story was full of magic and wonder.", "Beginning"},
    {"Her __________ changed after the makeover.", "Appearance"},
    {"Please help me _______ all of my goals this year.", "Achieve"},
    {"The dancer moved with a perfect ________ that captivated the audience.", "Rhythm"},
    {"Her desk was cluttered with _________ items, making it hard to find anything.", "Miscellaneous"},
    {"He made a ________ effort to help his friend in need.", "Valiant"},
    {"The young musician's ___________ performance left the audience in awe.", "Mesmerizing"},
}
local function normalizeEnglishQuestion(text) text = tostring( text or "" ); text = string.gsub( text, "^%s+", "" ); text = string.gsub( text, "%s+$", "" ); text = string.gsub( text, "%s+", " " ); return string.lower( text ) end
local function normalizeEnglishAnswer(text) text = tostring( text or "" ); text = string.gsub( text, "^%s+", "" ); text = string.gsub( text, "%s+$", "" ); return text end
local function buildEnglishAnswerDatabase()
    table.clear(EnglishCorrectByQuestion)
    table.clear(EnglishCorrectAnswerSet)

    local count = 0

    local function addRows(rows)
        if type(rows) ~= "table" then return end

        for _, row in ipairs(rows) do
            if type(row) == "table"
                and type(row[1]) == "string"
                and type(row[2]) == "string"
            then
                local questionKey = normalizeEnglishQuestion(row[1])
                local correctAnswer = normalizeEnglishAnswer(row[2])

                if questionKey ~= "" and correctAnswer ~= "" then
                    if EnglishCorrectByQuestion[questionKey] == nil then
                        count += 1
                    end

                    EnglishCorrectByQuestion[questionKey] = correctAnswer
                    EnglishCorrectAnswerSet[correctAnswer] = true
                end
            end
        end
    end

    -- Load the game's older built-in bank when available.
    local englishGui = RH4Classes:FindFirstChild("EnglishClass")
    local moduleScript = englishGui and englishGui:FindFirstChild("OLD_EnglishQuestions")

    if moduleScript and moduleScript:IsA("ModuleScript") then
        local ok, questions = pcall(require, moduleScript)

        if ok and type(questions) == "table" then
            addRows(questions)
        else
            Logger.Debug("⚠️ [English] Could not require OLD_EnglishQuestions; using extra bank.")
        end
    else
        Logger.Debug("⚠️ [English] OLD_EnglishQuestions module not found; using extra bank.")
    end

    -- User-supplied August 2026 additions. Added LAST so exact updated
    -- question text/answers take precedence over any older duplicate.
    addRows(ENGLISH_EXTRA_QUESTIONS)

    Logger.Debug(
        "📝 [English] Loaded "
        .. tostring(count)
        .. " unique question answers (including "
        .. tostring(#ENGLISH_EXTRA_QUESTIONS)
        .. " supplied additions)."
    )

    return count > 0
end

local function getEnglishUI()
    local englishGui = RH4Classes:FindFirstChild( "EnglishClass" )
    if not englishGui then
        return nil
    end
    local frame = englishGui:FindFirstChild( "Frame" )
    return englishGui, frame
end
local function isEnglishGuiEnabled( englishGui )
    if not englishGui then
        return false
    end
    local active = false
    pcall(function()
        if englishGui:IsA( "LayerCollector" ) then
            active = englishGui.Enabled
        elseif englishGui:IsA( "GuiObject" ) then
            active = englishGui.Visible
        else
            -- SurfaceGui / BillboardGui are LayerCollectors, but keep a
            -- generic fallback in case Royale High changes the container.
            active = englishGui.Enabled ~= false
        end
    end)
    return active
end
local function getEnglishChoices( frame )
    local choices = {}
    if not frame then
        return choices
    end
    for _, letter in ipairs({ "A", "B", "C", "D" }) do
        local button = frame:FindFirstChild( letter )
        local answerValue = button and button:FindFirstChild( "Answer" )
        if answerValue and answerValue:IsA( "StringValue" ) then
            table.insert( choices, { Letter = letter, Button = button, Answer = normalizeEnglishAnswer( answerValue.Value ) } )
        end
    end
    return choices
end
local function getEnglishQuestionState()
    local englishGui, frame = getEnglishUI()
    if not englishGui or not frame then
        return nil
    end
    local questionLabel = frame:FindFirstChild( "question" )
    local welcomeLabel = frame:FindFirstChild( "welcome" )
    local questionText = questionLabel and tostring( questionLabel.Text or "" ) or ""
    local welcomeText = welcomeLabel and tostring( welcomeLabel.Text or "" ) or ""
    local choices = getEnglishChoices( frame )
    if questionText == "" or #choices == 0 then
        return { Gui = englishGui, Frame = frame, Question = questionText, Welcome = welcomeText, Choices = choices, Active = false }
    end
    -- run_timer() changes welcome to:
    -- "Choose the correctly spelled answer within (N) seconds."
    local active = string.find( string.lower( welcomeText ), "choose the correctly spelled answer", 1, true ) ~= nil
    return { Gui = englishGui, Frame = frame, Question = questionText, Welcome = welcomeText, Choices = choices, Active = active }
end
local function getEnglishQuestionSignature( state )
    if not state then
        return nil
    end
    local parts = { normalizeEnglishQuestion( state.Question ) }
    for _, choice in ipairs( state.Choices or {} ) do
        table.insert( parts, choice.Letter .. "=" .. choice.Answer )
    end
    return table.concat( parts, "|" )
end
local function solveEnglishQuestion( state )
    if not state then
        return nil, nil
    end
    local questionKey = normalizeEnglishQuestion( state.Question )
    -- Preferred path: exact question -> correct answer from the game's own
    -- OLD_EnglishQuestions ModuleScript.
    local correct = EnglishCorrectByQuestion[ questionKey ]
    if correct then
        for _, choice in ipairs( state.Choices ) do
            if choice.Answer == correct then
                return correct, choice.Letter
            end
        end
    end
    -- Conservative fallback for updated text:
    -- only answer if EXACTLY ONE displayed choice is in the known set of
    -- correct spellings. If there is ambiguity, do not guess.
    local candidate = nil
    local candidateLetter = nil
    local matches = 0
    for _, choice in ipairs( state.Choices ) do
        if EnglishCorrectAnswerSet[ choice.Answer ] then
            matches += 1
            candidate = choice.Answer
            candidateLetter = choice.Letter
        end
    end
    if matches == 1 then
        return candidate, candidateLetter
    end
    return nil, nil
end
function English:IsEnabled() return Config.English.Enabled end
function English:CanStart()
    local englishGui, frame = getEnglishUI()
    if not englishGui or not frame then
        self.State.IntroReadyAt = nil
        return false
    end
    -- Campus 4 teleports into English first, then runs its intro/countdown.
    -- Start only after the same six-second gate used for the other classes.
    if not self.State.IntroReadyAt then
        self.State.IntroReadyAt = os.clock() + Config.English.IntroDelay
        Logger.Log( "⏳ [English] Waiting " .. tostring( Config.English.IntroDelay ) .. "s for class intro..." )
        return false
    end
    if os.clock() < self.State.IntroReadyAt then
        return false
    end
    return isEnglishGuiEnabled( englishGui )
end
function English:ShouldStayActive() local englishGui = getEnglishUI(); return englishGui ~= nil end
function English:Run( sessionId )
    Logger.Log( "\n==============================================" .. "\n📝 ENGLISH AUTOMATION ACTIVE" .. "\n==============================================" )
    if not EnglishClassRemote then
        Logger.Warn( "❌ [English] EnglishClassRemote missing." )
        return
    end
    if next( EnglishCorrectByQuestion ) == nil then
        buildEnglishAnswerDatabase()
    end
    self.State.AnsweredSignature = nil
    self.State.LastUnknownQuestion = nil
    while ClassController: IsSessionActive( sessionId, self ) do
        local state = getEnglishQuestionState()
        if not state or not state.Active then
            -- A non-active interval separates Result/ClassEnd/new Start.
            -- Clear this so the same exact question can be answered again
            -- later if Royale High happens to repeat it.
            self.State.AnsweredSignature = nil
            if not ClassController: Wait( sessionId, self, Config.English.PollRate ) then
                break
            end
            continue
        end
        local signature = getEnglishQuestionSignature( state )
        if signature and signature ~= self.State.AnsweredSignature then
            local answer, letter = solveEnglishQuestion( state )
            if answer then
                -- Do not fire on the exact frame the question appears.
                if not ClassController: Wait( sessionId, self, Config.English.AnswerDelay ) then
                    break
                end
                -- Re-read immediately before submitting in case Start changed.
                local freshState = getEnglishQuestionState()
                local freshSignature = getEnglishQuestionSignature( freshState )
                if freshState and freshState.Active and freshSignature == signature then
                    local freshAnswer, freshLetter = solveEnglishQuestion( freshState )
                    if freshAnswer == answer then
                        local ok, err = pcall(function()
                                EnglishClassRemote: FireServer( answer )
                            end)
                        if ok then
                            self.State.AnsweredSignature = signature
                            Logger.Log( "✅ [English] " .. tostring( freshLetter or letter ) .. ". " .. tostring( answer ) )
                        else
                            Logger.Warn( "❌ [English] FireServer failed: " .. tostring(err) )
                        end
                    end
                end
            elseif self.State.LastUnknownQuestion ~= state.Question then
                self.State.LastUnknownQuestion = state.Question
                Logger.Debug("⚠️ [English] No unambiguous answer found for: " .. tostring( state.Question ) )
            end
        end
        if not ClassController: Wait( sessionId, self, Config.English.PollRate ) then
            break
        end
    end
end
function English:Stop() self.State.IntroReadyAt = nil; self.State.AnsweredSignature = nil; self.State.LastUnknownQuestion = nil end
-- Build once up front if the module already exists.
buildEnglishAnswerDatabase()
ClassController:Register( English )
end -- scope: English

-- ========================================================================
-- 🛒 STUDENT STORE RUSH MODULE
-- ========================================================================
local ShoppingRush = { ClassName = "Student Store Rush!", UseSharedTimer = false }
ShoppingRush.State = { ActiveHeader = nil, WaitingForFreshList = false, PreviousListSignature = nil, ItemAttempts = {}, PendingCursor = 1 }
local ShoppingCache = { Objects = {}, Remotes = {}, ClickParts = {} }
local function normalizeShoppingName(text) text = tostring(text or ""); text = string.lower(text); text = string.gsub(text, "<.->", ""); text = string.gsub(text, "&", "and"); text = string.gsub(text, "[^%w]", ""); return text end
local function getShoppingUI()
    local minigame = RH4Classes:FindFirstChild("ShoppingMinigame")
    if not minigame then return nil end
    local list = minigame:FindFirstChild("List")
    local container = list and list:FindFirstChild("ShoppingContainer")
    local headerLabel = list and list:FindFirstChild("ShoppingHeader")
    return minigame, list, container, headerLabel
end
local function getShoppingHeaderText()
    local _, _, _, header = getShoppingUI()
    if not header then return "" end
    return string.gsub(string.gsub(tostring(header.Text or ""), "^%s+", ""), "%s+$", "")
end
local function parseShoppingCellText(rawText)
    local text = string.gsub(string.gsub(string.gsub(tostring(rawText or ""), "<.->", ""), "^%s+", ""), "%s+$", "")
    if text == "" then return nil end
    local got = tonumber(string.match(text, "%((%d+)%)%s*$")) or 0
    text = string.gsub(text, "%s*%(%d+%)%s*$", "")
    local need = tonumber(string.match(text, "%s+[xX](%d+)%s*$")) or 1
    local itemName = string.gsub(string.gsub(text, "%s+[xX]%d+%s*$", ""), "^%s+", ""); itemName = string.gsub(itemName, "%s+$", "")
    return { Item = itemName, Need = need, Got = got, Remaining = math.max(need - got, 0) }
end
local function readShoppingList()
    local _, _, container = getShoppingUI()
    local entries = {}
    if not container then return entries end
    for _, child in ipairs(container:GetChildren()) do
        local index = tonumber(string.match(child.Name, "^cell(%d+)$"))
        if index then
            local objectLabel, checkmark = child:FindFirstChild("ShoppingObject"), child:FindFirstChild("Checkmark")
            if objectLabel and objectLabel:IsA("TextLabel") then
                local parsed = parseShoppingCellText(objectLabel.Text)
                if parsed then
                    local completed = (checkmark and checkmark.Visible) or string.find(tostring(objectLabel.Text), "<s>", 1, true)
                    parsed.CellIndex = index; parsed.Cell = child; parsed.Completed = completed
                    if completed then parsed.Remaining = 0 end
                    table.insert(entries, parsed)
                end
            end
        end
    end
    table.sort(entries, function(a, b) return a.CellIndex < b.CellIndex end)
    return entries
end
local function getShoppingListSignature(entries)
    local parts = {}
    for _, entry in ipairs(entries or {}) do table.insert(parts, entry.CellIndex .. "|" .. entry.Item .. "|" .. entry.Remaining) end
    return table.concat(parts, "||")
end
local function findShoppingObject(itemName)
    local norm = normalizeShoppingName(itemName)
    if ShoppingCache.Objects[norm] then return ShoppingCache.Objects[norm] end
    local folder = Workspace:FindFirstChild("ShoppingClass") and Workspace.ShoppingClass:FindFirstChild("ShoppingObjects")
    if not folder then return nil end
    for _, child in ipairs(folder:GetDescendants()) do
        if normalizeShoppingName(child.Name) == norm then ShoppingCache.Objects[norm] = child return child end
    end
    return nil
end
local function findShoppingRemote(itemName)
    local norm = normalizeShoppingName(itemName)
    if ShoppingCache.Remotes[norm] then return ShoppingCache.Remotes[norm] end
    local parentRefs = ReplicatedStorage:FindFirstChild("FakeClickDetector") and ReplicatedStorage.FakeClickDetector:FindFirstChild("ParentRefs")
    if not parentRefs then return nil end
    for _, child in ipairs(parentRefs:GetChildren()) do
        if normalizeShoppingName(child.Name) == norm then
            local clicked = child:FindFirstChild("FakeClickDetector") and child.FakeClickDetector:FindFirstChild("Clicked")
            if clicked and (clicked:IsA("RemoteEvent") or clicked:IsA("UnreliableRemoteEvent")) then ShoppingCache.Remotes[norm] = clicked return clicked end
        end
    end
    return nil
end
local function getShoppingClickPart(shoppingObject)
    local id = shoppingObject:GetDebugId()
    if ShoppingCache.ClickParts[id] then return ShoppingCache.ClickParts[id] end
    local bestPart = shoppingObject:IsA("BasePart") and shoppingObject or (shoppingObject:IsA("Model") and shoppingObject.PrimaryPart)
    if not bestPart then
        local bestScore = -math.huge
        for _, descendant in ipairs(shoppingObject:GetDescendants()) do
            if descendant:IsA("BasePart") then
                local score = descendant.Size.Magnitude
                if descendant.Transparency < 0.98 then score += 1000 end
                if descendant.Name == shoppingObject.Name then score += 2000 end
                if score > bestScore then bestScore = score; bestPart = descendant end
            end
        end
    end
    if bestPart then ShoppingCache.ClickParts[id] = bestPart end
    return bestPart
end
local function fireShoppingObjectRemote(itemName, shoppingObject)
    local clicked = findShoppingRemote(itemName)
    if not clicked then return false, "remote-not-found" end
    local clickPart = getShoppingClickPart(shoppingObject)
    if not clickPart then return false, "part-not-found" end
    local ok, err = pcall(function() clicked:FireServer(clickPart.Position) end)
    if not ok then return false, err end
    Logger.Debug("📡 [Shopping] Clicked -> " .. itemName)
    return true
end
local function waitForShoppingProgress(sessionId, entry, previousHeader)
    local started = os.clock()
    local objectLabel, checkmark = entry.Cell:FindFirstChild("ShoppingObject"), entry.Cell:FindFirstChild("Checkmark")
    while os.clock() - started < Config.Shopping.UpdateTimeout do
        if not ClassController:IsSessionActive(sessionId, ShoppingRush) then return false end
        local currentHeader = getShoppingHeaderText()
        if previousHeader and currentHeader ~= previousHeader then return true end
        if checkmark and checkmark.Visible then return true end
        if objectLabel and string.find(tostring(objectLabel.Text), "<s>", 1, true) then return true end
        local parsed = parseShoppingCellText(objectLabel and objectLabel.Text or "")
        if parsed and (parsed.Got > entry.Got or parsed.Remaining < entry.Remaining) then return true end
        task.wait(0.025)
    end
    return false
end
function ShoppingRush:IsEnabled() return Config.Shopping.Enabled end
function ShoppingRush:CanStart()
    local minigame, list, container = getShoppingUI()
    if not minigame or not list or not container then return false end
    local visible = false
    pcall(function() visible = minigame.Visible and list.Visible end)
    return visible and #readShoppingList() > 0
end
function ShoppingRush:ShouldStayActive() return true end
function ShoppingRush:Run(sessionId)
    table.clear(ShoppingCache.Objects); table.clear(ShoppingCache.Remotes); table.clear(ShoppingCache.ClickParts)
    local initialHeader = getShoppingHeaderText()
    self.State = { ActiveHeader = initialHeader, ActiveListSignature = getShoppingListSignature(readShoppingList()), WaitingForFreshList = false, ItemAttempts = {}, PendingCursor = 1 }
    while ClassController:IsSessionActive(sessionId, self) do
        local currentHeader = getShoppingHeaderText()
        local currentEntries = readShoppingList()
        local currentSignature = getShoppingListSignature(currentEntries)
        if currentHeader ~= "" and currentHeader ~= self.State.ActiveHeader then
            self.State.ActiveHeader = currentHeader
            self.State.PreviousListSignature = self.State.ActiveListSignature
            self.State.WaitingForFreshList = self.State.PreviousListSignature ~= nil and currentSignature == self.State.PreviousListSignature
            self.State.ActiveListSignature = currentSignature
        end
        if self.State.WaitingForFreshList then
            if #currentEntries > 0 and currentSignature ~= self.State.PreviousListSignature then
                self.State.WaitingForFreshList = false; self.State.ActiveListSignature = currentSignature; Logger.Debug("✅ [Shopping] Fresh cells loaded for " .. currentHeader)
            else
                if not ClassController:Wait(sessionId, self, Config.Shopping.IdlePoll) then break end
                continue
            end
        end
        local pending = {}
        for _, entry in ipairs(currentEntries) do if not entry.Completed and entry.Remaining > 0 then table.insert(pending, entry) end end
        if #pending == 0 then
            if not ClassController:Wait(sessionId, self, Config.Shopping.IdlePoll) then break end
            continue
        end
        if self.State.PendingCursor > #pending then self.State.PendingCursor = 1 end
        local entry = pending[self.State.PendingCursor]
        local shoppingObject = findShoppingObject(entry.Item)
        local madeAttempt = false
        if shoppingObject then
            local attemptKey = entry.CellIndex .. "|" .. entry.Item
            local success = fireShoppingObjectRemote(entry.Item, shoppingObject)
            if success then
                madeAttempt = true
                if waitForShoppingProgress(sessionId, entry, self.State.ActiveHeader) then
                    self.State.ItemAttempts[attemptKey] = nil; self.State.PendingCursor = 1
                else
                    self.State.ItemAttempts[attemptKey] = (self.State.ItemAttempts[attemptKey] or 0) + 1; self.State.PendingCursor += 1
                end
            else
                self.State.PendingCursor += 1
            end
        else
            self.State.PendingCursor += 1
        end
        local delay = madeAttempt and Config.Shopping.ClickDelay or Config.Shopping.IdlePoll
        if not ClassController:Wait(sessionId, self, delay) then break end
    end
end
function ShoppingRush:Stop(reason) end
ClassController:Register(ShoppingRush)

-- ========================================================================
-- 🧪 POTIONOLOGY MODULE
-- ========================================================================
do
local Potionology = { ClassName = "Potionology", UseSharedTimer = false }
local IngredientKeys = { ["8972758809"] = Enum.KeyCode.One, ["8972759801"] = Enum.KeyCode.Two, ["8972759468"] = Enum.KeyCode.Three, ["8972760388"] = Enum.KeyCode.Four }
function Potionology:IsEnabled() return Config.Potionology.Enabled end
function Potionology:CanStart() return true end
local function readPotionRecipe()
    local slots, PotionologyGame = {}, RH4Classes:FindFirstChild("PotionologyGame")
    local RecipeFrame = PotionologyGame and PotionologyGame:FindFirstChild("recipe")
    if not RecipeFrame then return slots end
    for i = 1, 10 do
        local btn = RecipeFrame:FindFirstChild("Button" .. i)
        if btn and btn.Visible then
            local asset = string.match(tostring(btn.Image or ""), "rbxassetid://(%d+)") or string.match(tostring(btn.Image or ""), "(%d+)")
            if asset and IngredientKeys[asset] then table.insert(slots, { Key = IngredientKeys[asset], Asset = asset }) end
        end
    end
    return slots
end
local function getRecipeSignature(recipe)
    local s = ""
    for _, slot in ipairs(recipe) do s = s .. slot.Asset end
    return s
end
function Potionology:Run(sessionId)
    Logger.Log("\n==============================================\n🧪 POTIONOLOGY AUTOMATION STARTED\n==============================================")
    local lastSignature = nil
    while ClassController:IsSessionActive(sessionId, self) do
        local recipe = readPotionRecipe()
        if #recipe == 0 then
            if not ClassController:Wait(sessionId, self, Config.Potionology.PollRate) then break end
            continue
        end
        local signature = getRecipeSignature(recipe)
        if signature ~= lastSignature then
            lastSignature = signature
            for _, slot in ipairs(recipe) do
                if not ClassController:IsSessionActive(sessionId, self) then return end
                pcall(function() VirtualInputManager:SendKeyEvent(true, slot.Key, false, game); task.wait(0.05); VirtualInputManager:SendKeyEvent(false, slot.Key, false, game) end)
                if not ClassController:Wait(sessionId, self, Config.Potionology.ClickDelay) then return end
            end
            local started = os.clock()
            while os.clock() - started < Config.Potionology.ChangeTimeout do
                if not ClassController:IsSessionActive(sessionId, self) then return end
                local cur = readPotionRecipe()
                if #cur == 0 or getRecipeSignature(cur) ~= signature then break end
                task.wait(Config.Potionology.PollRate)
            end
        else
            if not ClassController:Wait(sessionId, self, Config.Potionology.PollRate) then break end
        end
    end
end
function Potionology:Stop() end
ClassController:Register(Potionology)
end -- scope: Potionology

-- ========================================================================
-- 🏹 ARCHERY MODULE (Optimized Raycasts)
-- ========================================================================
do
local Archery = { ClassName = "Archery", UseSharedTimer = false }
local ArcheryRemote = ReplicatedStorage:WaitForChild("ArcheryRemote", 10)
local FireArrowRemote = ArcheryRemote and ArcheryRemote:WaitForChild("FireArrow", 10)
local ARCHERY_TAG = "ArcheryRaycastInclude"
local ArcheryTargets = {}
Runtime.Connect(CollectionService:GetInstanceAddedSignal(ARCHERY_TAG), function(inst) ArcheryTargets[inst] = true end)
Runtime.Connect(CollectionService:GetInstanceRemovedSignal(ARCHERY_TAG), function(inst) ArcheryTargets[inst] = nil end)
for _, inst in ipairs(CollectionService:GetTagged(ARCHERY_TAG)) do ArcheryTargets[inst] = true end
local SharedRaycastParams = RaycastParams.new()
SharedRaycastParams.FilterType = Enum.RaycastFilterType.Include
SharedRaycastParams.IgnoreWater = true
Archery.State = { LastFiredAt = {}, LastBlockedAt = {} }
function Archery:IsEnabled() return Config.Archery.Enabled end
function Archery:CanStart() return LocalPlayer:GetAttribute("BowEnabled") == true end
function Archery:ShouldStayActive() return LocalPlayer:GetAttribute("BowEnabled") == true end
local function resolveArcheryTarget(target)
    if not target or not target.Parent then return nil, nil end
    if target:IsA("BasePart") and target.Name == "Apple" and target:GetAttribute("TargetActive") then return target.Position, "APPLE" end
    if target:IsA("Model") and target.Name == "BalloonforArchery" then
        local balloon = target:FindFirstChild("Balloon")
        if balloon and balloon:GetAttribute("TargetActive") then return balloon.Position, "BALLOON" end
    end
    if target:IsA("Model") and target.Name == "Target" and target:GetAttribute("TargetActive") then
        local bullseye = target:FindFirstChild("layer5", true)
        if bullseye then return bullseye.Position, "BULLSEYE" end
        pcall(function() return target:GetPivot().Position, "TARGET" end)
    end
    return nil, nil
end
local function hasArcheryLineOfSight(target, targetPosition)
    local camera = Workspace.CurrentCamera
    if not camera or not targetPosition then return false end
    local origin = camera.CFrame.Position
    local direction = targetPosition - origin
    if direction.Magnitude <= 0.01 then return false end
    local filter = { Workspace.Terrain }
    for tgt in pairs(ArcheryTargets) do table.insert(filter, tgt) end
    SharedRaycastParams.FilterDescendantsInstances = filter
    local result = Workspace:Raycast(origin, direction, SharedRaycastParams)
    if not result then return true end
    local hit = result.Instance
    if hit == Workspace.Terrain then
        if (targetPosition - result.Position).Magnitude <= Config.Archery.Tolerances.Endpoint then return true end
        return false
    end
    if hit == target or (target:IsA("Model") and hit:IsDescendantOf(target)) then return true end
    if (targetPosition - result.Position).Magnitude <= Config.Archery.Tolerances.Endpoint then return true end
    return false
end
function Archery:Run(sessionId)
    Logger.Log("\n==============================================\n🏹 ARCHERY AUTOMATION ACTIVE\n==============================================")
    if not FireArrowRemote then return end
    table.clear(self.State.LastFiredAt)
    table.clear(self.State.LastBlockedAt)
    local function E(w) local h=#w/2; local v1,v2=string.sub(w,0,h),string.sub(w,h+1,#w); local l=string.reverse(string.sub(v1,0,#v1/2))..string.reverse(string.sub(v1,#v1/2+1,#v1)); local c=string.reverse(string.sub(v2,0,#v2/2))..string.reverse(string.sub(v2,#v2/2+1,#v2))..l.."/"; local o=""; for i=1,#c do local char=string.sub(c,i,i); o=o..string.sub(string.rep("&",255),0,255-string.byte(char))..string.rep("%",string.byte(char)) end; return o end
    local token = E("BarbieIsTheQueen")
    while ClassController:IsSessionActive(sessionId, self) do
        local now = os.clock()
        local bestTarget, bestPos = nil, nil
        local bestPriority, bestLast = -math.huge, math.huge
        for target in pairs(ArcheryTargets) do
            local pos, tType = resolveArcheryTarget(target)
            if pos then
                local lastF = self.State.LastFiredAt[target] or -math.huge
                local lastB = self.State.LastBlockedAt[target] or -math.huge
                if now - lastF >= Config.Archery.Delays.TargetReuse and now - lastB >= Config.Archery.Delays.BlockedRetry then
                    if hasArcheryLineOfSight(target, pos) then
                        local prio = (tType == "BULLSEYE" and 4) or (tType == "BALLOON" and 3) or (tType == "APPLE" and 2) or 1
                        if lastF < bestLast or (lastF == bestLast and prio > bestPriority) then
                            bestTarget, bestPos, bestPriority, bestLast = target, pos, prio, lastF
                        end
                    else
                        self.State.LastBlockedAt[target] = now
                    end
                end
            end
        end
        if bestTarget and bestPos then
            self.State.LastFiredAt[bestTarget] = os.clock()
            pcall(function() FireArrowRemote:FireServer(CFrame.new(bestPos), token) end)
            if not ClassController:Wait(sessionId, self, Config.Archery.Delays.ShotCooldown) then break end
        else
            if not ClassController:Wait(sessionId, self, Config.Archery.Delays.IdlePoll) then break end
        end
    end
end
function Archery:Stop() end
ClassController:Register(Archery)
end -- scope: Archery

-- ========================================================================
-- 🏀 BASKETBALL MODULE (LEFT ONLY)
-- ========================================================================
do
local Basketball = { ClassName = "Basketball", UseSharedTimer = true }
local ShootRemote = ReplicatedStorage:WaitForChild("BasketballClass", 10) and ReplicatedStorage.BasketballClass:WaitForChild("ShootBasketball", 10)
local TP_BIN = CFrame.new(-4533, -2, 1959)
local LEFT_STATION = { CFrame = CFrame.new(-4516, -2, 1915), Hoop = Vector3.new(-4490.087, 12.5, 1915.069) }
Basketball.State = { StopAimLock = nil, ReturnGraceUntil = 0, OwnedBall = nil, TouchShieldActive = false, SavedCanTouch = {}, ShotSlotIndex = 1, ShotSlotCount = 1, ShotGroupIndex = 1, ShotGroupCount = 1, LaneMember = 1 }

function Basketball:IsEnabled() return Config.Basketball.Enabled end
function Basketball:CanStart() return (getClassTimeRemaining() or 0) > 5 end

local function isBallTool(obj)
    if not obj or not obj:IsA("Tool") then return false end
    local name = string.lower(obj.Name)
    return string.find(name, "basketball", 1, true) ~= nil or string.find(name, "ball", 1, true) ~= nil
end

local function getBallHandle(tool)
    if not tool then return nil end
    local handle = tool:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle end
    return tool:FindFirstChildWhichIsA("BasePart", true)
end

local function getBasketballRefs() local character, humanoid, rootPart = getCharacter(); local backpack = LocalPlayer:FindFirstChildOfClass("Backpack"); return character, humanoid, rootPart, backpack end

local function isLiveBallTool(tool, character, backpack)
    if not isBallTool(tool) then return false end
    local parent = tool.Parent
    return parent ~= nil and (parent == character or parent == backpack)
end

local function findLiveBall(character, backpack, excluded)
    if character then
        for _, obj in ipairs(character:GetChildren()) do
            if isLiveBallTool(obj, character, backpack) and not (excluded and excluded[obj]) then return obj end
        end
    end
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if isLiveBallTool(obj, character, backpack) and not (excluded and excluded[obj]) then return obj end
        end
    end
    return nil
end

local function snapshotBasketballTools(character, backpack)
    local snapshot = {}
    if character then for _, obj in ipairs(character:GetChildren()) do if isBallTool(obj) then snapshot[obj] = true end end end
    if backpack then for _, obj in ipairs(backpack:GetChildren()) do if isBallTool(obj) then snapshot[obj] = true end end end
    return snapshot
end

local function clearUnownedBasketballs(character, backpack)
    local owned = Basketball.State.OwnedBall
    local function clean(parent)
        if not parent then return end
        for _, obj in ipairs(parent:GetChildren()) do
            if isBallTool(obj) and obj ~= owned then pcall(function() obj.Enabled = false; obj:Destroy() end) end
        end
    end
    clean(character); clean(backpack)
end

local function enableBasketballTouchShield(character)
    if not character then return end
    if not Basketball.State.TouchShieldActive then Basketball.State.SavedCanTouch = {}; Basketball.State.TouchShieldActive = true end
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("BasePart") then
            if Basketball.State.SavedCanTouch[obj] == nil then Basketball.State.SavedCanTouch[obj] = obj.CanTouch end
            pcall(function() obj.CanTouch = false end)
        end
    end
end

local function disableBasketballTouchShield()
    if not Basketball.State.TouchShieldActive then return end
    for part, original in pairs(Basketball.State.SavedCanTouch) do
        if part and part.Parent then pcall(function() part.CanTouch = original end) end
    end
    Basketball.State.SavedCanTouch = {}
    Basketball.State.TouchShieldActive = false
end

local function basketballServerTime()
    local ok, value = pcall(function() return Workspace:GetServerTimeNow() end)
    if ok and type(value) == "number" then return value end
    return tick()
end

local function waitForBasketballRequestSlot(sessionId)
    local cfg = Config.Basketball.MultiInstance
    local slots = math.max(1, tonumber(cfg and cfg.Slots) or 24)
    local spacing = math.max(0.01, tonumber(cfg and cfg.SlotSpacing) or 0.08)
    local cycle = slots * spacing
    local slot = math.abs(tonumber(LocalPlayer.UserId) or 0) % slots
    local target = slot * spacing
    local phase = basketballServerTime() % cycle
    local waitTime = (target - phase) % cycle
    if waitTime > 0.005 then return ClassController:Wait(sessionId, Basketball, waitTime) end
    return ClassController:IsSessionActive(sessionId, Basketball)
end

local function initializeBasketballShotSlot()
    local roster = Players:GetPlayers()
    table.sort(roster, function(a, b) return a.UserId < b.UserId end)

    local index = 1
    for i, player in ipairs(roster) do
        if player == LocalPlayer then index = i; break end
    end

    local groupSize = math.max(1, tonumber(Config.Basketball.MultiInstance.GroupSize) or 3)
    local groupIndex = math.floor((index - 1) / groupSize) + 1
    local groupCount = math.max(1, math.ceil(#roster / groupSize))
    local laneMember = ((index - 1) % groupSize) + 1

    Basketball.State.ShotSlotIndex = index
    Basketball.State.ShotSlotCount = math.max(1, #roster)
    Basketball.State.ShotGroupIndex = groupIndex
    Basketball.State.ShotGroupCount = groupCount
    Basketball.State.LaneMember = laneMember

    Logger.Debug("🏀 [Basketball] Player " .. tostring(index) .. "/" .. tostring(#roster)
        .. " | group " .. tostring(groupIndex) .. "/" .. tostring(groupCount)
        .. " | lane member " .. tostring(laneMember) .. "/" .. tostring(groupSize))
end

local function getBasketballHoldingCFrame()
    local index = math.max(1, Basketball.State.ShotSlotIndex or 1)
    local spacing = tonumber(Config.Basketball.MultiInstance.HoldSpacing) or 3.5
    local col = (index - 1) % 5
    local row = math.floor((index - 1) / 5)
    local xOffset = (col - 2) * spacing
    local zOffset = 6 + row * spacing
    return TP_BIN * CFrame.new(xOffset, 0, zOffset)
end

local function getBasketballShotCFrame()
    local groupSize = math.max(1, tonumber(Config.Basketball.MultiInstance.GroupSize) or 3)
    local member = math.clamp(Basketball.State.LaneMember or 1, 1, groupSize)
    local spacing = tonumber(Config.Basketball.MultiInstance.LaneSpacing) or 2.75
    local centeredIndex = member - ((groupSize + 1) / 2)
    local zOffset = centeredIndex * spacing
    return LEFT_STATION.CFrame * CFrame.new(0, 0, zOffset)
end

local function moveBasketballToHoldingArea()
    local character, _, rootPart = getCharacter()
    if not character or not rootPart then return false end
    local hold = getBasketballHoldingCFrame()
    pcall(function()
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(hold)
    end)
    return true
end

local function waitForBasketballShotSlot(sessionId)
    local duration = math.max(0.75, tonumber(Config.Basketball.MultiInstance.ShotGroupDuration) or 1.20)
    local groupCount = math.max(1, Basketball.State.ShotGroupCount or 1)
    local groupIndex = math.clamp(Basketball.State.ShotGroupIndex or 1, 1, groupCount)
    local cycle = duration * groupCount
    local targetStart = (groupIndex - 1) * duration

    while ClassController:IsSessionActive(sessionId, Basketball) do
        moveBasketballToHoldingArea()
        local phase = basketballServerTime() % cycle
        local intoGroup = phase - targetStart

        -- All 3 members of the current group are released together.
        if intoGroup >= 0 and intoGroup < duration * 0.55 then return true end
        task.wait(0.03)
    end
    return false
end

local function waitForMouse(sessionId)
    local started = os.clock()
    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and os.clock() - started < Config.Controller.MouseReleaseTimeout do
        if not ClassController:IsSessionActive(sessionId, Basketball) then return false end
        task.wait(0.01)
    end
    return not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

local function forceFaceStation(humanoid, rootPart)
    if not humanoid or not rootPart or not rootPart.Parent then return end
    humanoid.AutoRotate = false
    rootPart.AssemblyAngularVelocity = Vector3.zero
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(LEFT_STATION.Hoop.X, rootPart.Position.Y, LEFT_STATION.Hoop.Z))
end

local function getFacingErrorDegrees(rootPart)
    local desired = Vector3.new(LEFT_STATION.Hoop.X - rootPart.Position.X, 0, LEFT_STATION.Hoop.Z - rootPart.Position.Z)
    if desired.Magnitude <= 0.001 then return 0 end
    desired = desired.Unit
    local actual = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
    if actual.Magnitude <= 0.001 then return 180 end
    actual = actual.Unit
    return math.deg(math.acos(math.clamp(actual:Dot(desired), -1, 1)))
end

local function stopBasketballAimLock()
    if Basketball.State.StopAimLock then Basketball.State.StopAimLock(); Basketball.State.StopAimLock = nil end
end

local function waitForNewBallFromGiver(sessionId, before)
    local started = os.clock()
    while os.clock() - started < Config.Basketball.Timeouts.Acquisition do
        if not ClassController:IsSessionActive(sessionId, Basketball) then return nil end
        local character, _, _, backpack = getBasketballRefs()
        local ball = findLiveBall(character, backpack, before)
        if ball then return ball end
        task.wait(0.015)
    end
    return nil
end

local function getOrRequestBall(sessionId)
    local character, humanoid, rootPart, backpack = getBasketballRefs()
    if not character or not humanoid or not rootPart then return nil end

    local owned = Basketball.State.OwnedBall
    if isLiveBallTool(owned, character, backpack) then enableBasketballTouchShield(character); return owned end
    Basketball.State.OwnedBall = nil

    -- While our touch shield is active after a shot, any new live ball that
    -- appears in Character/Backpack is expected to be the game's returned
    -- replacement, because loose court balls cannot touch the character.
    if os.clock() < Basketball.State.ReturnGraceUntil then
        enableBasketballTouchShield(character)
        local returned = findLiveBall(character, backpack)
        if returned then Basketball.State.OwnedBall = returned; return returned end
        return nil
    end

    -- We need a fresh giver request. Keep the touch shield ON for the entire
    -- Basketball class so this account cannot physically collect another
    -- player's travelling shot while it waits near the giver.
    enableBasketballTouchShield(character)
    clearUnownedBasketballs(character, backpack)
    if not waitForBasketballRequestSlot(sessionId) then return nil end

    character, humanoid, rootPart, backpack = getBasketballRefs()
    if not character or not humanoid or not rootPart then return nil end
    clearUnownedBasketballs(character, backpack)
    local before = snapshotBasketballTools(character, backpack)

    character:PivotTo(TP_BIN)
    enableBasketballTouchShield(character)
    local basketballFolder = Workspace:FindFirstChild("Basketball")
    local giver = basketballFolder and basketballFolder:FindFirstChild("BallGiver")
    local prompt = giver and giver:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then Logger.Warn("⚠️ [Basketball] BallGiver ProximityPrompt not found."); return nil end
    if not waitForMouse(sessionId) then Logger.Warn("⚠️ [Basketball] Mouse remained pressed; ball request skipped."); return nil end
    if type(fireproximityprompt) ~= "function" then Logger.Warn("❌ [Basketball] Executor does not expose fireproximityprompt()."); return nil end

    local promptOK, promptErr = pcall(function() fireproximityprompt(prompt) end)
    if not promptOK then Logger.Warn("❌ [Basketball] fireproximityprompt failed: " .. tostring(promptErr)); return nil end

    local ball = waitForNewBallFromGiver(sessionId, before)
    if not ball then Logger.Debug("⚠️ [Basketball] Prompt fired, but no NEW Basketball Tool appeared within " .. tostring(Config.Basketball.Timeouts.Acquisition) .. "s."); return nil end

    Basketball.State.OwnedBall = ball
    enableBasketballTouchShield(character)
    Logger.Debug("🏀 [Basketball] Acquired own ball in request slot " .. tostring((math.abs(tonumber(LocalPlayer.UserId) or 0) % math.max(1, Config.Basketball.MultiInstance.Slots))))
    return ball
end

function Basketball:Run(sessionId)
    Logger.Log("\n==============================================\n🏀 BASKETBALL AUTOMATION ACTIVE (LEFT ONLY)\n==============================================")
    if not ShootRemote then return end
    self.State.ReturnGraceUntil = 0
    self.State.OwnedBall = nil
    initializeBasketballShotSlot()
    local startCharacter = LocalPlayer.Character
    if startCharacter then enableBasketballTouchShield(startCharacter) end
    moveBasketballToHoldingArea()

    while ClassController:IsSessionActive(sessionId, self) do
        local ballTool = getOrRequestBall(sessionId)
        if not ballTool then
            local delay = os.clock() < self.State.ReturnGraceUntil and 0.05 or Config.Basketball.Delays.RequestRetry
            if not ClassController:Wait(sessionId, self, delay) then break end
            continue
        end

        local character, humanoid, rootPart, backpack = getBasketballRefs()
        if not character or not humanoid or not rootPart or not isLiveBallTool(ballTool, character, backpack) then
            self.State.OwnedBall = nil
            self.State.ReturnGraceUntil = math.max(self.State.ReturnGraceUntil, os.clock() + 0.35)
            if not ClassController:Wait(sessionId, self, Config.Basketball.Delays.Failure) then break end
            continue
        end

        enableBasketballTouchShield(character)
        clearUnownedBasketballs(character, backpack)

        -- Serialize the ACTUAL shot in groups of 3. Waiting accounts stay in
        -- the giver/holding area; only the active 3-account group enters the
        -- shooting lane during its shared server-time window.
        if not waitForBasketballShotSlot(sessionId) then break end

        character, humanoid, rootPart, backpack = getBasketballRefs()
        if not character or not humanoid or not rootPart or not isLiveBallTool(ballTool, character, backpack) then
            self.State.OwnedBall = nil
            continue
        end

        enableBasketballTouchShield(character)
        clearUnownedBasketballs(character, backpack)
        pcall(function() ballTool.ManualActivationOnly = true; ballTool.Enabled = false end)
        local shotCFrame = getBasketballShotCFrame()
        character:PivotTo(shotCFrame)

        local originalAutoRotate = humanoid.AutoRotate
        local active = true
        self.State.StopAimLock = function()
            if not active then return end
            active = false
            pcall(function() RunService:UnbindFromRenderStep("BBAim") end)
            if humanoid and humanoid.Parent then humanoid.AutoRotate = originalAutoRotate end
        end

        RunService:BindToRenderStep("BBAim", Enum.RenderPriority.Character.Value + 50, function()
            if not active or not ClassController:IsSessionActive(sessionId, self) then return end
            if humanoid.Parent and rootPart.Parent and getFacingErrorDegrees(rootPart) > Config.Basketball.Tolerances.FacingCorrection then forceFaceStation(humanoid, rootPart) end
        end)

        if not ClassController:Wait(sessionId, self, 0.5) then stopBasketballAimLock(); break end

        character, humanoid, rootPart, backpack = getBasketballRefs()
        if not character or not humanoid or not rootPart or not isLiveBallTool(ballTool, character, backpack) then
            stopBasketballAimLock()
            self.State.OwnedBall = nil
            self.State.ReturnGraceUntil = math.max(self.State.ReturnGraceUntil, os.clock() + 0.35)
            Logger.Debug("♻️ [Basketball] Old ball reference expired; waiting for returned replacement.")
            if not ClassController:Wait(sessionId, self, Config.Basketball.Delays.Failure) then break end
            continue
        end

        local fired = false
        if (rootPart.Position - shotCFrame.Position).Magnitude <= Config.Basketball.Tolerances.Position and waitForMouse(sessionId) then
            pcall(function() ballTool.Enabled = true; ballTool.ManualActivationOnly = true end)
            local equippedOK = true
            if ballTool.Parent == backpack then equippedOK = pcall(function() humanoid:EquipTool(ballTool) end) elseif ballTool.Parent ~= character then equippedOK = false end

            if not equippedOK then
                stopBasketballAimLock()
                self.State.OwnedBall = nil
                self.State.ReturnGraceUntil = math.max(self.State.ReturnGraceUntil, os.clock() + 0.35)
                Logger.Debug("♻️ [Basketball] Ball expired during EquipTool; waiting for replacement.")
                if not ClassController:Wait(sessionId, self, Config.Basketball.Delays.Failure) then break end
                continue
            end

            local equipStarted = os.clock()
            local genuinelyEquipped = false
            while os.clock() - equipStarted < Config.Basketball.Timeouts.Equip do
                if not ClassController:IsSessionActive(sessionId, self) then break end
                character, humanoid, rootPart, backpack = getBasketballRefs()
                if not character or not humanoid or not rootPart or not isLiveBallTool(ballTool, character, backpack) then break end
                if ballTool.Parent == character and getBallHandle(ballTool) then genuinelyEquipped = true; break end
                task.wait(0.015)
            end

            if genuinelyEquipped and ClassController:Wait(sessionId, self, Config.Basketball.Delays.FaceStabilize) then
                forceFaceStation(humanoid, rootPart)
                local handle = getBallHandle(ballTool)
                if handle and getFacingErrorDegrees(rootPart) <= Config.Basketball.Tolerances.FacingMax then
                    local delta = LEFT_STATION.Hoop + Vector3.new(0, Config.Basketball.ArcY, 0) - handle.Position
                    if delta.Magnitude > 0.001 then
                        local ok = pcall(function() ShootRemote:FireServer(delta.Unit, Config.Basketball.Power) end)
                        if ok then
                            fired = true
                            self.State.ReturnGraceUntil = os.clock() + Config.Basketball.Delays.ReturnGrace
                            Logger.Debug("🏀 [SHOT] LEFT | " .. tostring(Config.Basketball.Power) .. " / " .. tostring(Config.Basketball.ArcY))
                        end
                    end
                end
            end
        end

        stopBasketballAimLock()

        -- Vacate the shooting lane immediately. The fired ball continues on
        -- its own, while this character returns beside the BallGiver so the
        -- next account's shot has a clear path to the hoop.
        moveBasketballToHoldingArea()
        character = LocalPlayer.Character
        if character then enableBasketballTouchShield(character) end

        local delay = fired and Config.Basketball.Delays.Cooldown or Config.Basketball.Delays.Failure
        if not ClassController:Wait(sessionId, self, delay) then break end
    end
end

local function cleanupBasketballTools()
    local removed = 0
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local function cleanParent(parent)
        if not parent then return end
        for _, object in ipairs(parent:GetChildren()) do
            if isBallTool(object) then
                local destroyed = pcall(function() object.Enabled = false; object:Destroy() end)
                if destroyed then removed += 1 end
            end
        end
    end
    cleanParent(character); cleanParent(backpack)
    return removed
end

local function scheduleBasketballCleanupSweep()
    Runtime.Spawn(function()
        local started = os.clock()
        local removedTotal = 0
        while os.clock() - started < 3.0 do removedTotal += cleanupBasketballTools(); task.wait(0.10) end
        if removedTotal > 0 then Logger.Debug("🧹 [Basketball] Cleanup sweep removed " .. tostring(removedTotal) .. " Basketball Tool instance(s).") end
    end)
end

function Basketball:Stop(reason)
    stopBasketballAimLock()
    self.State.ReturnGraceUntil = 0
    self.State.OwnedBall = nil
    disableBasketballTouchShield()
    cleanupBasketballTools()
    scheduleBasketballCleanupSweep()
    Logger.Log("⏹️ [Basketball] Released control | " .. tostring(reason))
end

ClassController:Register(Basketball)
end -- scope: Basketball

-- ========================================================================
-- CONTROLLER EVENT UPDATE & WATCHERS
-- ========================================================================
local updateQueued = false
local function requestControllerUpdate()
    if updateQueued then return end
    updateQueued = true
    task.defer(function() updateQueued = false ClassController:Update() end)
end
Runtime.Connect(CurrentClass:GetPropertyChangedSignal("Text"), requestControllerUpdate)
Runtime.Connect(TimerLabel:GetPropertyChangedSignal("Text"), requestControllerUpdate)
Runtime.Connect(ClassStartingLabel:GetPropertyChangedSignal("Text"), requestControllerUpdate)
Runtime.Connect(ClassStartingLabel:GetPropertyChangedSignal("Visible"), requestControllerUpdate)
Runtime.Connect(LocalPlayer:GetAttributeChangedSignal("BowEnabled"), requestControllerUpdate)
Runtime.Spawn(function()
    local hwWatcher = nil
    local function checkHW()
        local hw = PlayerGui:FindFirstChild("RH4Homework")
        if hw and hw ~= hwWatcher then
            hwWatcher = hw
            Runtime.Connect(hw.DescendantAdded, function(d)
                if d.Name == "WithQuest" or d.Name == "DoHomeworkButton" then requestControllerUpdate() end
            end)
        end
    end
    local connectedTimer, timerConnection = nil, nil
    while true do
        local frame = RH4Classes:FindFirstChild("Archery")
        local archeryTimer = frame and frame:FindFirstChild("MidGame") and frame.MidGame:FindFirstChild("Timer")
        if archeryTimer and archeryTimer ~= connectedTimer then
            if timerConnection then timerConnection:Disconnect() end
            connectedTimer = archeryTimer
            timerConnection = archeryTimer:GetPropertyChangedSignal("Text"):Connect(requestControllerUpdate)
        end
        if connectedTimer and not connectedTimer:IsDescendantOf(game) then
            connectedTimer = nil
            if timerConnection then timerConnection:Disconnect(); timerConnection = nil end
        end
        checkHW()
        task.wait(0.25)
    end
end)
Runtime.Spawn(function()
    local connectedHeader, headerConnection = nil, nil
    local connectedTimer, shoppingTimerConnection = nil, nil
    local connectedList, listVisibleConnection = nil, nil
    while true do
        local _, list, _, timer, header = getShoppingUI()
        if header and header ~= connectedHeader then
            if headerConnection then headerConnection:Disconnect() end
            connectedHeader = header
            headerConnection = header:GetPropertyChangedSignal("Text"):Connect(requestControllerUpdate)
        end
        if timer and timer ~= connectedTimer then
            if shoppingTimerConnection then shoppingTimerConnection:Disconnect() end
            connectedTimer = timer
            shoppingTimerConnection = timer:GetPropertyChangedSignal("Text"):Connect(requestControllerUpdate)
        end
        if list and list ~= connectedList then
            if listVisibleConnection then listVisibleConnection:Disconnect() end
            connectedList = list
            listVisibleConnection = list:GetPropertyChangedSignal("Visible"):Connect(requestControllerUpdate)
        end
        if connectedHeader and not connectedHeader:IsDescendantOf(game) then connectedHeader = nil; if headerConnection then headerConnection:Disconnect(); headerConnection = nil end end
        if connectedTimer and not connectedTimer:IsDescendantOf(game) then connectedTimer = nil; if shoppingTimerConnection then shoppingTimerConnection:Disconnect(); shoppingTimerConnection = nil end end
        if connectedList and not connectedList:IsDescendantOf(game) then connectedList = nil; if listVisibleConnection then listVisibleConnection:Disconnect(); listVisibleConnection = nil end end
        task.wait(0.25)
    end
end)

-- ========================================================================
-- MAIN FALLBACK WATCHER
-- ========================================================================
Runtime.Spawn(function()
    Logger.Log("\n==============================================")
    Logger.Log("🎓 CAMPUS 4 CLASS CONTROLLER READY")
    Logger.Log("==============================================")
    while true do
        ClassController:Update()
        task.wait(Config.Controller.FallbackPollRate)
    end
end)
