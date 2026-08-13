-- ========================================================================
-- ⏳ WAIT FOR GAME TO FULLY LOAD (ANTI-STUCK)
-- ========================================================================
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(3)

-- ========================================================================
-- SERVICES & GLOBAL SETUP
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 9999)

-- Default Config Fallback
if type(getgenv().Config) ~= "table" then
    getgenv().Config = { AutoArtClass = true, AutoCaptcha = true }
end

-- Global Variables & State Tracking
getgenv().IsCaptchaActive = false
local makeHttpRequest = request or http_request or (http and http.request) or fluxus or (syn and syn.request)

local PlayerState = {
    IsTyping = false,
    IsDrawing = false,
    LastInputTime = tick()
}

-- Generic Safe Traversal Function
local function safeFind(parent, ...)
    local current = parent
    for _, name in ipairs({...}) do
        current = current and current:FindFirstChild(name)
        if not current then
            return nil
        end
    end
    return current
end

-- ========================================================================
-- 🧠 ADVANCED HUMANIZER & MOUSE TRAJECTORY ENGINE
-- ========================================================================
local function randomGaussian(mean, stdDev)
    local u1 = math.max(1e-7, math.random())
    local u2 = math.random()
    local z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
    return mean + z0 * (stdDev or (mean * 0.2))
end

local function humanWait(meanSec, stdDevSec)
    local delay = math.max(0.015, randomGaussian(meanSec, stdDevSec))
    task.wait(delay)
end

local function moveMouseSmooth(targetX, targetY)
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
        local easedT = 1 - math.pow(1 - t, 2) -- Ease-out deceleration
        
        local currX = (1 - easedT)^2 * startX + 2 * (1 - easedT) * easedT * ctrlX + easedT^2 * targetX
        local currY = (1 - easedT)^2 * startY + 2 * (1 - easedT) * easedT * ctrlY + easedT^2 * targetY
        
        VirtualInputManager:SendMouseMoveEvent(currX, currY, game)
        task.wait(0.006 + math.random() * 0.004)
    end
    VirtualInputManager:SendMouseMoveEvent(targetX, targetY, game)
end

local function humanClickAt(x, y)
    moveMouseSmooth(x, y)
    humanWait(0.04, 0.01)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    humanWait(0.05, 0.015)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ========================================================================
-- 🛡️ PART 0: AUTO-CAPTCHA (OPTIMIZED EVENT-BASED SOLVER)
-- ========================================================================
if getgenv().Config.AutoCaptcha then
    task.spawn(function()
        local CAPTCHA_CONFIG = {
            POLL_INTERVAL = 0.2,
            RETRY_DELAY = 1.0,
            CLICK_COOLDOWN = 0.8,
        }

        local Captcha = {
            Solving = false,
            Cache = {},
            LastClick = 0
        }

        local BUTTON_HASHES = {
            ["40d02d582d76f54881f5f000c9a3712d"] = "1",
            ["3da8772a1380df0ea9d6e29e584d0dfa"] = "2",
            ["2ca84bc6e12650e6a29b371030041c71"] = "3",
            ["5abb9a3e809ddf2abec6bad6c30b9357"] = "4",
            ["f2183de3439a29ca186a1085a254ee36"] = "5",
            ["469569cf140da51f1b78fc640eaf6682"] = "6",
            ["ce4d4f4d3bc8cba41ae0ba9955d052c2"] = "7",
            ["4dcc9cb4f28e200508ace4b493e8b5b7"] = "8",
            ["151fa826f05ded1c9903149d0c451a1c"] = "9",
            ["fda452a0b122c2b4230fc74e5135c3fc"] = "10",
            ["8b7bec3549554a512cdc2a993ce8f441"] = "11",
            ["988d2aba9e47d6cafced32dbac0256ab"] = "12",
            ["6a3723b695d9e6900f8fcc9106b64008"] = "13",
            ["af300da49b235a2ea90d62f17fcfe8c7"] = "14",
            ["fd6700a486a6ced004db4d1d5eb8e098"] = "15",
        }

        local function checkFailedToLoad()
            local topCard = PlayerGui:FindFirstChild("CardCaptchaGame")
            if not topCard then return false end

            for _, v in pairs(topCard:GetDescendants()) do
                if v:IsA("TextLabel") and string.find(string.lower(v.Text), "failed to load") then
                    return true
                end
            end
            return false
        end

        local function captchaVisible()
            local captchaGame = safeFind(PlayerGui, "CardCaptchaGame", "CaptchaGame")
            return captchaGame and captchaGame.Visible or false
        end

        local function getTargetId()
            local topCard = PlayerGui:FindFirstChild("CardCaptchaGame")
            if not topCard or (topCard.Enabled == false) then return nil end

            local card = safeFind(topCard, "CaptchaGame", "Top", "Card")
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
            if Captcha.Cache[assetId] then
                return Captcha.Cache[assetId]
            end

            local btn = getButtonFromAPI(assetId)
            if btn then
                Captcha.Cache[assetId] = btn
            end

            return btn
        end

        local function clickCaptchaButton(buttonNumber)
            local buttons = safeFind(PlayerGui, "CardCaptchaGame", "CaptchaGame", "Bottom", "Buttons")
            if not buttons then return false end

            local btn = buttons:FindFirstChild(tostring(buttonNumber))
            if not btn then
                warn("[Captcha Click] Target button element not found in UI:", buttonNumber)
                return false
            end

            local clickSuccess = pcall(function()
                local absPos = btn.AbsolutePosition
                local absSize = btn.AbsoluteSize
                local s, inset = pcall(function() return GuiService:GetGuiInset() end)
                local insetY = s and inset.Y or 0
                
                local offsetX = randomGaussian(0, 3)
                local offsetY = randomGaussian(0, 3)
                
                local x = absPos.X + (absSize.X / 2) + offsetX
                local y = absPos.Y + (absSize.Y / 2) + insetY + offsetY

                humanClickAt(x, y)
            end)

            return clickSuccess
        end

        local function startSolveRoutine()
            if Captcha.Solving then return end
            Captcha.Solving = true
            getgenv().IsCaptchaActive = true
            print("[Captcha] UI detected! Solver routine started.")

            task.spawn(function()
                while captchaVisible() do
                    if checkFailedToLoad() then
                        warn("[Captcha] Detected 'Failed to Load' state. Kicking player...")
                        LocalPlayer:Kick("Failed to load captcha.")
                        break
                    end

                    local asset = getTargetId()
                    if not asset then
                        humanWait(CAPTCHA_CONFIG.POLL_INTERVAL, 0.05)
                        continue
                    end

                    local now = tick()
                    if now - Captcha.LastClick < CAPTCHA_CONFIG.CLICK_COOLDOWN then
                        humanWait(CAPTCHA_CONFIG.POLL_INTERVAL, 0.05)
                        continue
                    end

                    local button = getCachedButton(asset)
                    if not button then
                        local randomBtn = tostring(math.random(1, 15))
                        warn("[Captcha] Image hash missing. Attempting refresh click (" .. randomBtn .. ")...")
                        button = randomBtn
                    end

                    print(string.format("[Captcha] Solving Asset ID: %s -> Button: %s", tostring(asset), tostring(button)))
                    clickCaptchaButton(button)

                    Captcha.LastClick = tick()
                    humanWait(CAPTCHA_CONFIG.RETRY_DELAY, 0.2)
                end

                Captcha.Solving = false
                getgenv().IsCaptchaActive = false
                print("[Captcha] Solved or hidden. Shared solver state reset.")
            end)
        end

        local cardCaptchaUI = PlayerGui:WaitForChild("CardCaptchaGame", 10)
        if cardCaptchaUI then
            local captchaGameFrame = cardCaptchaUI:WaitForChild("CaptchaGame", 10)
            if captchaGameFrame then
                captchaGameFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                    task.defer(function()
                        if captchaGameFrame.Visible then
                            humanWait(0.2, 0.05)
                            startSolveRoutine()
                        end
                    end)
                end)
            end
        end

        if captchaVisible() then
            startSolveRoutine()
        end

        LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:Button2Down(Vector2.new(0, 0))
                humanWait(0.1, 0.02)
                VirtualUser:Button2Up(Vector2.new(0, 0))
                print("[Anti-AFK] Prevented disconnection via VirtualUser click.")
            end)
        end)
    end)
end

-- ========================================================================
-- 🛑 STARTUP GATE: WAIT FOR INITIAL CAPTCHA CLEARANCE
-- ========================================================================
local function isCaptchaOnScreen()
    local captchaGame = safeFind(PlayerGui, "CardCaptchaGame", "CaptchaGame")
    return (captchaGame and captchaGame.Visible) or getgenv().IsCaptchaActive
end

if isCaptchaOnScreen() then
    print("[Startup] Captcha detected on join! Pausing Auto-Setup...")
    while isCaptchaOnScreen() do
        task.wait(0.5)
    end
    print("[Startup] Captcha cleared! Proceeding to Auto-Setup...")
    humanWait(1.5, 0.3)
end

-- ========================================================================
-- 🤖 PART 2: UI NUKE & ART CLASS BOT
-- ========================================================================
task.spawn(function()
    local TARGET_UIS = {
        ["DailyRewardsMain"] = true,
        ["WonRoll"] = true,
        ["Reward"] = true
    }

    local function nukeElement(guiObject)
        if TARGET_UIS[guiObject.Name] then
            pcall(function()
                if guiObject:IsA("GuiObject") then
                    guiObject.Visible = false
                elseif guiObject:IsA("LayerCollector") then
                    guiObject.Enabled = false
                end
            end)
            print("💥 [UI Nuke] Itinago: " .. guiObject.Name)
        end
    end

    for _, descendant in ipairs(PlayerGui:GetDescendants()) do
        nukeElement(descendant)
    end
    PlayerGui.DescendantAdded:Connect(nukeElement)
end)

-- ========================================================================
-- 🌟 PART 1: AUTO-SETUP SCRIPT
-- ========================================================================
local function clickUI(element)
    if not element then return end
    local target = element:IsA("GuiButton") and element or element:FindFirstChildWhichIsA("GuiButton", true) or element

    if target and target:IsA("GuiObject") and target.AbsoluteSize.X > 0 and target.AbsoluteSize.Y > 0 then
        pcall(function()
            local absPos, absSize = target.AbsolutePosition, target.AbsoluteSize
            local s, inset = pcall(function() return GuiService:GetGuiInset() end)
            local insetY = s and inset.Y or 0
            
            local offsetX = randomGaussian(0, 4)
            local offsetY = randomGaussian(0, 4)
            
            local x = absPos.X + (absSize.X / 2) + offsetX
            local y = absPos.Y + (absSize.Y / 2) + insetY + offsetY

            humanClickAt(x, y)
        end)
    end
end

-- DATABASES
local safeEgirlNames = {
    "Luna", "Angel", "Mimi", "Yuna", "Ari", "Lily", "Misa", "Aiko",
    "Sora", "Kira", "Nini", "Rin", "Yuki", "Nyla", "Ava", "Bella",
    "Skye", "Ivy", "Chloe", "Mika", "Emi", "Noa", "Coco", "Suki",
    "Nova", "Celeste", "Mochi", "Peach", "Daisy", "Rosie", "Willow", "Aurora",
    "Violet", "Serenity", "Melody", "Dream", "Cupid", "Cherry", "Blair", "Ophelia",
    "Aster", "Nyx", "Freya", "Evelyn", "Elodie", "Hazel", "Sabrina", "Sylvie"
}
local pfpList = { "rbxassetid://115029257457567", "rbxassetid://88815506216062" }
local hairs = {
    "Avrilla's Chained Tails", "Avrilla's Buns", "Buzzy Bunz", "Chromae's Braid",
    "Cupid's Touch Bantu Knots", "Deepsea Radiant Puffs", "Fallen Fae's Chopped Braids",
    "Fallen Fae's Longing Braids", "Fallen Fae's Messy Bob", "Fallen Fae's Reminiscing Braids",
    "Fountain Girl's Blowing Hair", "Fountain Girl's Diamond Blowing Hair",
    "Fountain Girl's Diamond Hair", "Fountain Girl's Hair", "Hibiscus Curls",
    "Hibiscus Waves", "Inventor's Top Bun", "Inventor's Top Bun Windy"
}
local outfits = {
    "2026July1", "2026July2", "2026July3", "2026July4", "2026July5", "2026July6",
    "2026July7", "2026July8", "2026July9", "2026July10", "2026July11", "2026July12",
    "2026July13", "2026July14", "2026July15", "2026July16", "2026July17", "2026July18",
    "2026July19", "2026July20", "2026July21", "2026July22", "2026July23", "2026July24",
    "2026July25", "2026July26", "2026June1", "2026June2", "2026June3", "2026June4",
    "2026June5", "2026June6"
}
local faces = {
    "Winnie", "90s Grunge", "Animal Nose", "Apocalypse Survivor", "Apocalypse Survivor v2",
    "Boba Pearls", "Cheetah", "Daring Diva", "Enchanted Eyes", "Faye", "Fern",
    "Flower Garden", "Futuristic Cyborg", "Glazed Donut", "Huh?", "Iris", "Jellyfish Dreams",
    "Lipliner", "Maeve", "Peachy", "Petals", "Pink Glow", "Queen of the Sirens",
    "Royale Queen", "Shade", "Sunblock V1", "Sunblock V2", "Sunburn", "Sunshine",
    "Tanning Day", "Ultra Gloss", "Water Goddess"
}

-- AUTO SETUP MAIN LOGIC
local success, rpNameBox = pcall(function()
    return PlayerGui:WaitForChild("HUD"):WaitForChild("Frame"):WaitForChild("Top"):WaitForChild("RPName")
end)

if success and rpNameBox then
    local currentText = rpNameBox.Text
    local username = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName

    if currentText == "" or currentText:lower() == username:lower() or currentText:lower() == displayName:lower() then
        print("Walang custom RP name na na-detect. Sisimulan na ang Auto Setup...")

        local randomName = safeEgirlNames[math.random(1, #safeEgirlNames)]
        if rpNameBox:IsA("TextBox") then
            rpNameBox:CaptureFocus()
            humanWait(0.1, 0.02)
            rpNameBox.Text = randomName
            humanWait(0.1, 0.02)
            rpNameBox:ReleaseFocus(true)
        else
            rpNameBox.Text = randomName
        end
        print("Nagpalit ng RP Name: " .. randomName)

        humanWait(1.0, 0.2)
        local updatePfpEvent = ReplicatedStorage:WaitForChild("UpdateProfilePicture", 5)
        if updatePfpEvent and updatePfpEvent:IsA("RemoteEvent") then
            local randomId = pfpList[math.random(1, #pfpList)]
            pcall(function() updatePfpEvent:FireServer(randomId) end)
            print("Profile picture updated smoothly gamit ang ID: " .. randomId)
        end

        print("Starting Auto-Dress Sequence...")
        local dressUpBtn = PlayerGui:WaitForChild("HUD"):WaitForChild("Frame"):WaitForChild("DressUp"):WaitForChild("Button")
        local MainUI = PlayerGui:WaitForChild("CharacterCreation"):WaitForChild("Main")

        clickUI(dressUpBtn)
        humanWait(1.5, 0.3)

        if not MainUI.Visible then
            MainUI.Visible = true
            if MainUI:FindFirstChild("FirstSelection") then
                MainUI.FirstSelection.Visible = true
            end
            humanWait(1.0, 0.2)
        end

        local outfitTab = MainUI.FirstSelection:WaitForChild("Outfit")
        clickUI(outfitTab)
        humanWait(1.5, 0.2)
        local randomOutfitName = outfits[math.random(1, #outfits)]
        local outfitElement = MainUI.CentralFrame.ClothesFrame.ClothesPage:WaitForChild(randomOutfitName)
        clickUI(outfitElement)
        humanWait(1.5, 0.2)

        local faceTab = MainUI.FirstSelection:WaitForChild("Face")
        clickUI(faceTab)
        humanWait(1.5, 0.2)
        local randomFaceName = faces[math.random(1, #faces)]
        local faceElement = MainUI.CentralFrame.MakeupFrame.FullFaceFrame.MakeupPage:WaitForChild(randomFaceName)
        clickUI(faceElement)
        humanWait(1.5, 0.2)

        local bodyTab = MainUI.FirstSelection:WaitForChild("Body")
        clickUI(bodyTab)
        humanWait(1.5, 0.2)
        
        local bodyTypesTab = MainUI.SecondSelection.Body:WaitForChild("BodyTypes")
        clickUI(bodyTypesTab)
        humanWait(1.5, 0.2)
        
        local womanBody = MainUI.CentralFrame.BodyTypesFrame.ClothesPage:WaitForChild("Woman")
        clickUI(womanBody)
        humanWait(1.5, 0.2)
        
        local animationsTab = MainUI.SecondSelection.Body:WaitForChild("Animations")
        clickUI(animationsTab)
        humanWait(1.5, 0.2)
        
        local stylishWalkBtn = MainUI.ThirdSelection.Animations.WalkFrame.Walks.Stylish:WaitForChild("Button")
        clickUI(stylishWalkBtn)
        humanWait(1.5, 0.2)
        
        local skintoneTab = MainUI.SecondSelection.Body:WaitForChild("Skintone")
        clickUI(skintoneTab)
        humanWait(1.5, 0.2)
        
        local color5Btn = MainUI.ThirdSelection["Skin Colors"].Colors:WaitForChild("5")
        clickUI(color5Btn)
        humanWait(1.5, 0.2)

        local hairTab = MainUI.FirstSelection:WaitForChild("Hairstyle")
        clickUI(hairTab)
        humanWait(1.5, 0.2)
        local randomHairName = hairs[math.random(1, #hairs)]
        local hairBtn = MainUI.CentralFrame.HairFrame.Inner:WaitForChild(randomHairName):WaitForChild("Button")
        clickUI(hairBtn)
        humanWait(1.5, 0.2)

        print("Clicking Done...")
        local doneBtn = MainUI.FirstSelection:WaitForChild("Done")
        local attemptsDone = 0
        while MainUI.Visible and attemptsDone < 5 do
            clickUI(doneBtn)
            humanWait(1.5, 0.3)
            attemptsDone = attemptsDone + 1
        end

        if not MainUI.Visible then
            print("Auto Setup Complete! Menu successfully closed.")
        else
            warn("Failed to close menu after 5 tries.")
        end
    else
        print("May custom RP name na (" .. currentText .. "). I-ski-skip na ang Auto Name, PFP, at Auto Dress.")
    end
else
    warn("RPName TextBox could not be found.")
end

-- 🎨 ART CLASS - SMART UNIFIED BOT
if getgenv().Config.AutoArtClass then
    task.spawn(function()
        local SERVER_ID = game.JobId
        if SERVER_ID == "" then SERVER_ID = "LocalServer" end
        
        local MY_API_URL = "https://api.sharafaithcenabreflores.dev/api/word"

        local artClassGui = PlayerGui:WaitForChild("ArtClass", 15)
        if not artClassGui then return warn("❌ ArtClass UI not found!") end
        
        local guessingGame = artClassGui:WaitForChild("GuessingGame", 10)
        local chooseAWord = guessingGame:WaitForChild("ChooseAWord", 10)
        local midGameArtist = guessingGame:WaitForChild("Mid-GameArtist", 10)
        local artistsWordLabel = midGameArtist:WaitForChild("ArtistsWord", 10)

        local lastSentWord = ""

        print("🤖 [SMART BOT] Ready! Kumokonekta sa Server API: " .. MY_API_URL)

        local function cleanWord(str)
            local s = string.gsub(str, "Your Drawing Subject:", "")
            s = string.gsub(s, "[\n\r]", "") 
            return string.match(s, "^%s*(.-)%s*$") 
        end

        local function sendData(word)
            if makeHttpRequest then
                task.spawn(function()
                    pcall(function()
                        makeHttpRequest({
                            Url = MY_API_URL,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({
                                server_id = SERVER_ID,
                                answer = word
                            })
                        })
                    end)
                    print("🌐 [PYTHON SERVER] Na-save ang salita: " .. word)
                end)
            end
        end

        -- DYNAMIC CANVAS BOUNDS EXTRACTOR
        local function getCanvasBounds()
            local canvasFrame = safeFind(guessingGame, "Canvas") or safeFind(guessingGame, "CanvasFrame") or safeFind(guessingGame, "Easel")
            if canvasFrame and canvasFrame:IsA("GuiObject") then
                local pos = canvasFrame.AbsolutePosition
                local size = canvasFrame.AbsoluteSize
                local s, inset = pcall(function() return GuiService:GetGuiInset() end)
                local insetY = s and inset.Y or 0
                return {
                    MinX = pos.X + 10,
                    MaxX = pos.X + size.X - 10,
                    MinY = pos.Y + insetY + 10,
                    MaxY = pos.Y + size.Y + insetY - 10,
                    Width = size.X - 20,
                    Height = size.Y - 20
                }
            end

            -- Fallback to relative center viewport if canvas object is undetected
            local viewport = workspace.CurrentCamera.ViewportSize
            local s, inset = pcall(function() return GuiService:GetGuiInset() end)
            local insetY = s and inset.Y or 0
            return {
                MinX = viewport.X * 0.2,
                MaxX = viewport.X * 0.8,
                MinY = viewport.Y * 0.2 + insetY,
                MaxY = viewport.Y * 0.7 + insetY,
                Width = viewport.X * 0.6,
                Height = viewport.Y * 0.5
            }
        end

        local function drawLineOnCanvas(startX, startY, endX, endY)
            local safeWait = 0
            while getgenv().IsCaptchaActive and safeWait < 60 do 
                task.wait(0.5); safeWait = safeWait + 1 
            end

            moveMouseSmooth(startX, startY)
            humanWait(0.03, 0.01)
            VirtualInputManager:SendMouseButtonEvent(startX, startY, 0, true, game, 1)
            humanWait(0.02, 0.005)

            moveMouseSmooth(endX, endY)
            humanWait(0.03, 0.01)
            VirtualInputManager:SendMouseButtonEvent(endX, endY, 0, false, game, 1)
            humanWait(0.08, 0.02)
        end

        local function drawChar(char, x, y, s)
            local bounds = getCanvasBounds()
            local function cX(val) return math.clamp(val, bounds.MinX, bounds.MaxX) end
            local function cY(val) return math.clamp(val, bounds.MinY, bounds.MaxY) end

            char = string.upper(char)
            if char == "A" then 
                drawLineOnCanvas(cX(x), cY(y+s), cX(x+s/2), cY(y)) 
                drawLineOnCanvas(cX(x+s/2), cY(y), cX(x+s), cY(y+s)) 
                drawLineOnCanvas(cX(x+s*0.25), cY(y+s*0.5), cX(x+s*0.75), cY(y+s*0.5))
            elseif char == "B" then 
                drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)) 
                drawLineOnCanvas(cX(x), cY(y), cX(x+s*0.8), cY(y+s*0.25)) 
                drawLineOnCanvas(cX(x+s*0.8), cY(y+s*0.25), cX(x), cY(y+s*0.5)) 
                drawLineOnCanvas(cX(x), cY(y+s*0.5), cX(x+s*0.8), cY(y+s*0.75)) 
                drawLineOnCanvas(cX(x+s*0.8), cY(y+s*0.75), cX(x), cY(y+s))
            elseif char == "C" then 
                drawLineOnCanvas(cX(x+s), cY(y), cX(x), cY(y)) 
                drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)) 
                drawLineOnCanvas(cX(x), cY(y+s), cX(x+s), cY(y+s))
            elseif char == "D" then 
                drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)) 
                drawLineOnCanvas(cX(x), cY(y), cX(x+s*0.8), cY(y+s*0.5)) 
                drawLineOnCanvas(cX(x+s*0.8), cY(y+s*0.5), cX(x), cY(y+s))
            elseif char == "E" then 
                drawLineOnCanvas(cX(x), cY(y), cX(x), cY(y+s)) 
                drawLineOnCanvas(cX(x), cY(y), cX(x+s), cY(y)) 
                drawLineOnCanvas(cX(x), cY(y+s*0.5), cX(x+s*0.8), cY(y+s*0.5)) 
                drawLineOnCanvas(cX(x), cY(y+s), cX(x+s), cY(y+s))
            else 
                humanWait(0.2, 0.05) 
            end
        end

        local function startWritingWord(wordToDraw)
            if PlayerState.IsDrawing then return end
            PlayerState.IsDrawing = true
            print("✍️ [HUMANIZED MODE] Isinusulat ang: " .. wordToDraw)

            task.spawn(function()
                humanWait(3.0, 0.5)

                local bounds = getCanvasBounds()
                local startX = bounds.MinX + (bounds.Width * 0.1)
                local startY = bounds.MinY + (bounds.Height * 0.3)
                local baseSize = math.clamp(bounds.Height * 0.3, 25, 45)
                local baseSpacing = baseSize * 1.2

                for i = 1, #wordToDraw do
                    if not midGameArtist.Visible then break end
                    
                    local safeWait = 0
                    while getgenv().IsCaptchaActive and safeWait < 60 do 
                        task.wait(0.5); safeWait = safeWait + 1 
                    end

                    local char = string.sub(wordToDraw, i, i)
                    local charX = startX + ((i - 1) * baseSpacing) + randomGaussian(0, 3)
                    local charY = startY + randomGaussian(0, 3)
                    
                    drawChar(char, charX, charY, baseSize + randomGaussian(0, 2))
                    humanWait(0.25, 0.06) 
                end
                PlayerState.IsDrawing = false
            end)
        end

        local function attemptChooseWord()
            if chooseAWord.Visible then
                task.spawn(function()
                    while getgenv().IsCaptchaActive do task.wait(0.5) end
                    humanWait(2.0, 0.4)
                    
                    local option1 = chooseAWord:FindFirstChild("Option1")
                    if option1 then
                        clickUI(option1) 
                        print("🖱️ [SMART BOT] Pinili ang Option 1.")
                    else
                        warn("❌ [SMART BOT] Hindi mahanap ang Option 1 button.")
                    end
                end)
            end
        end

        chooseAWord:GetPropertyChangedSignal("Visible"):Connect(function()
            task.defer(attemptChooseWord)
        end)
        attemptChooseWord() 

        artistsWordLabel:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                humanWait(0.3, 0.08)
                if not midGameArtist.Visible then return end
                
                local cleanText = cleanWord(artistsWordLabel.ContentText)
                if cleanText and string.len(cleanText) > 1 and cleanText ~= lastSentWord then
                    lastSentWord = cleanText
                    sendData(cleanText)
                    startWritingWord(cleanText)
                end
            end)
        end)
        
        -- PURE HUMANIZED TYPING SIMULATOR
        local function typeAnswer(text)
            local textBox = guessingGame:FindFirstChildWhichIsA("TextBox", true)
            if not textBox then return end

            PlayerState.IsTyping = true

            local absPos = textBox.AbsolutePosition
            local absSize = textBox.AbsoluteSize
            local s, inset = pcall(function() return GuiService:GetGuiInset() end)
            local insetY = s and inset.Y or 0
            
            local x = absPos.X + (absSize.X / 2) + randomGaussian(0, 4)
            local y = absPos.Y + (absSize.Y / 2) + insetY + randomGaussian(0, 4)

            humanClickAt(x, y)
            humanWait(0.2, 0.05)

            textBox:CaptureFocus()
            textBox.Text = "" 
            
            local madeTypo = false
            for i = 1, #text do
                if not madeTypo and math.random(1, 18) == 1 then
                    local randomChar = string.char(math.random(97, 122))
                    textBox.Text = textBox.Text .. randomChar
                    humanWait(0.25, 0.05)
                    textBox.Text = string.sub(textBox.Text, 1, -2)
                    humanWait(0.15, 0.03)
                    madeTypo = true
                end
                
                local char = string.sub(text, i, i)
                textBox.Text = textBox.Text .. char
                humanWait(0.08, 0.02) 
            end
            
            humanWait(0.15, 0.04)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            humanWait(0.05, 0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

            PlayerState.IsTyping = false
        end

        local isProcessingGuess = false 
        local attemptedWords = {} 

        midGameArtist:GetPropertyChangedSignal("Visible"):Connect(function()
            task.defer(function()
                if midGameArtist.Visible then 
                    PlayerState.IsDrawing = false 
                    attemptedWords = {} 
                end
            end)
        end)

        task.spawn(function()
            while task.wait(3) do
                if midGameArtist.Visible or isProcessingGuess then continue end
                
                if makeHttpRequest then
                    local pSuccess, response = pcall(function() 
                        return makeHttpRequest({
                            Url = MY_API_URL .. "?server_id=" .. SERVER_ID,
                            Method = "GET"
                        })
                    end)
                    
                    if pSuccess and response and response.StatusCode == 200 then
                        local dataSuccess, decodedData = pcall(function() return HttpService:JSONDecode(response.Body) end)
                        
                        if dataSuccess and decodedData and decodedData.answer and decodedData.answer ~= "" then
                            local finalAnswer = cleanWord(decodedData.answer)
                            
                            if finalAnswer ~= "" and string.len(finalAnswer) > 1 and not attemptedWords[finalAnswer] then
                                attemptedWords[finalAnswer] = true 
                                isProcessingGuess = true 
                                
                                task.spawn(function()
                                    local isSkippingRound = (math.random(1, 100) <= 40)
                                    humanWait(3.5, 0.8)
                                    while getgenv().IsCaptchaActive do task.wait(0.5) end
                                    
                                    if guessingGame.Visible and not midGameArtist.Visible then
                                        pcall(function()
                                            if decodedData.related and #decodedData.related > 0 then
                                                local fakeGuess = decodedData.related[math.random(1, #decodedData.related)]
                                                print("🎭 [HUMANIZER] Contextual fake guess: " .. fakeGuess)
                                                typeAnswer(fakeGuess)
                                                humanWait(3.5, 0.6)
                                            else
                                                local dummyGuesses = {"idk", "what is that", "umm", "is it a person"}
                                                typeAnswer(dummyGuesses[math.random(1, #dummyGuesses)])
                                                humanWait(3.5, 0.6)
                                            end

                                            if isSkippingRound then
                                                print("📉 [HUMANIZER] Intentionally skipping this round to lower win rate.")
                                                isProcessingGuess = false
                                                return
                                            end

                                            typeAnswer(finalAnswer)
                                            print("🗣️ [SMART BOT] Ligtas na nai-type ang hula: " .. finalAnswer)
                                        end)
                                    end
                                    
                                    isProcessingGuess = false 
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- ========================================================================
-- 🏃‍♂️ PART 3: STATE-DRIVEN BEHAVIORAL HUMANIZER
-- ========================================================================
task.spawn(function()
    local function humanCameraPan()
        if PlayerState.IsTyping or PlayerState.IsDrawing or getgenv().IsCaptchaActive then return end
        
        local viewport = workspace.CurrentCamera.ViewportSize
        local startX = viewport.X * 0.5
        local startY = viewport.Y * 0.5
        local dragDistance = math.random(-120, 120)

        -- Right-click drag simulation
        VirtualInputManager:SendMouseButtonEvent(startX, startY, 1, true, game, 1)
        humanWait(0.05, 0.01)
        
        moveMouseSmooth(startX + dragDistance, startY + math.random(-20, 20))
        
        humanWait(0.05, 0.01)
        VirtualInputManager:SendMouseButtonEvent(startX + dragDistance, startY, 1, false, game, 1)
    end

    while true do
        -- Exponential/Poisson delay distribution for idle intervals (averages ~25s)
        local idleDelay = -math.log(1 - math.random()) * 25
        task.wait(math.max(8, idleDelay))

        -- Execute idle actions ONLY when player is completely idle
        if not PlayerState.IsTyping and not PlayerState.IsDrawing and not getgenv().IsCaptchaActive then
            local actionRoll = math.random(1, 100)
            
            if actionRoll <= 40 then
                humanCameraPan()
            elseif actionRoll <= 55 then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                humanWait(0.08, 0.02)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end
end)
