-- language: Lua, file: gemini-code-1790871675403_true_level.lua, target: Roblox
-- *reads live HUD level updates to trigger the 5-7 minute AFK cooldown accurately*
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
    getgenv().Config = { AutoArtClass = true, AutoCaptcha = true }
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
                        makeHttpRequest({
                            Url = MY_API_URL, Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({ server_id = SERVER_ID, answer = word })
                        })
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
            
            tb:CaptureFocus()
            tb.Text = text
            task.wait(0.05)
            
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            PlayerState.IsTyping = false
        end

        local isProcessing = false
        local attempted = {}
        local nextAnswerTick = 0
        local currentLevel = nil

        -- HUD Level Parser
        local function parseLevelText(value)
            local textValue = string.lower(tostring(value or ""))
            textValue = string.gsub(textValue, ",", "")
            return tonumber(
                string.match(textValue, "level%s*[:%-]?%s*(%d+)")
                or string.match(textValue, "lvl%s*[:%-]?%s*(%d+)")
                or string.match(textValue, "lv%.?%s*[:%-]?%s*(%d+)")
                or string.match(textValue, "(%d+)")
            )
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
                    -- Level up confirmed. Trigger 5-7 minute AFK.
                    local afkTime = tick() + math.random(300, 420)
                    if afkTime > nextAnswerTick then
                        nextAnswerTick = afkTime
                    end
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
                                        
                                        -- Standard inter-round delay; AFK override is handled by the HUD listener
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
