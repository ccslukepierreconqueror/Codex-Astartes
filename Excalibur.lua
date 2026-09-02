-- ================================================================
-- AUTO TRADE - STANDALONE V31
-- ================================================================
-- Current modes:
--   SENDER: existing V22 queue/stock/offer/finalization flow.
--   RECEIVER: when this script runs on the configured TargetUsername/UserId,
--             it waits for incoming trade requests, accepts one sender at a
--             time, offers 10-20 configured item copies + a deterministic
--             rounded diamond amount, re-accepts after offer modifications,
--             and completes the final confirmation.
--
-- Sender stages:
--   0) Read global target/items config, profile preflight, then auto-stock configured items.
--   1) Queue/retry trade requests without spamming a busy receiver.
--   2) Open trade and send several randomized chat messages.
--   3) Read the sender's current diamond balance from TradeGui.
--   4) Type the full balance into the real DiamondAmount TextBox with VIM.
--   5) Build a randomized 10-20 item offer plan from the stocked-item pool.
--   6) Click the real inventory item repeatedly according to the RNG plan.
--   7) Verify EACH copy appears in TradeGui.TradeGui.MyItems before continuing.
--   8) AcceptOffer only runs after every required offer stage succeeds.
--   9) Wait for BOTH parties to reach TradeConfirmation, then SetConfirmState(true).
--  10) Wait through Royale High's final countdown and VIM-click the real final Accept button.
--  11) Post-trade verify diamonds/items, write a receipt, and permanently stop this sender.
--
-- IMPORTANT:
-- This deliberately does NOT auto-accept an empty/partial trade.
-- ================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================================================================
-- CONFIG
-- ================================================================

-- ================================================================
-- EXTERNAL GLOBAL CONFIG
-- ================================================================
-- Set getgenv().AutoTradeConfig (and preferably _G.AutoTradeConfig) BEFORE running this script.
-- This stays easy to change even if the main script is obfuscated.
--
-- Example:
--
-- getgenv().AutoTradeConfig = {
--     TargetUsername = "Martha566951",
--     -- TargetUserId = 123456789, -- optional, more robust
--
--     Items = {
--         {
--             Item = "Crystal Ice",
--             Category = "Wings",
--             Currency = "Diamonds",
--             Target = 15
--         },
--         {
--             Item = "Miniskirt",
--             Category = "Skirts",
--             Currency = "Diamonds",
--             Target = 5
--         }
--     }
-- }
--
-- Then execute/load the obfuscated AutoTrade script.

local ExecutorEnvironment = nil

if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)

    if ok and type(result) == "table" then
        ExecutorEnvironment = result
    end
end

-- The loader writes the SAME table to getgenv() and _G.
-- Read getgenv first, then _G as a compatibility fallback for obfuscators.
local GlobalConfig = nil

if ExecutorEnvironment
    and type(ExecutorEnvironment.AutoTradeConfig) == "table"
then
    GlobalConfig =
        ExecutorEnvironment.AutoTradeConfig
elseif type(_G.AutoTradeConfig) == "table" then
    GlobalConfig =
        _G.AutoTradeConfig
else
    GlobalConfig = {}
end

-- Keep both environments pointing to the exact same table.
if ExecutorEnvironment then
    ExecutorEnvironment.AutoTradeConfig =
        GlobalConfig
end

_G.AutoTradeConfig =
    GlobalConfig

if type(GlobalConfig.TargetUsername) ~= "string"
    or GlobalConfig.TargetUsername == ""
then
    GlobalConfig.TargetUsername =
        "Martha566951"
end

-- Optional and preferred when mass-running accounts:
-- UserId avoids username capitalization/rename mistakes.
if GlobalConfig.TargetUserId ~= nil then
    GlobalConfig.TargetUserId =
        tonumber(GlobalConfig.TargetUserId)
end

if type(GlobalConfig.Receiver) ~= "table" then
    GlobalConfig.Receiver = {}
end

if type(GlobalConfig.Receiver.DiamondOptions) ~= "table"
    or #GlobalConfig.Receiver.DiamondOptions == 0
then
    -- Deterministic, rounded receiver amounts. The sender UserId chooses
    -- one of these values; this is not randomized.
    GlobalConfig.Receiver.DiamondOptions = {
        2000,
        3000,
        4000,
        5000
    }
end

if GlobalConfig.Receiver.Enabled == nil then
    GlobalConfig.Receiver.Enabled = true
end

if GlobalConfig.Receiver.ChatEnabled == nil then
    GlobalConfig.Receiver.ChatEnabled = true
end

if type(GlobalConfig.Items) ~= "table"
    or #GlobalConfig.Items == 0
then
    GlobalConfig.Items = {
        {
            Item = "Crystal Ice",
            Category = "Wings",
            Currency = "Diamonds",
            Target = 15
        },
        {
            Item = "Miniskirt",
            Category = "Skirts",
            Currency = "Diamonds",
            Target = 5
        },
        {
            Item = "Royale Rebel Bustle Skirt",
            Category = "Skirts",
            Currency = "Diamonds",
            Target = 2
        }
    }
end

local function buildConfiguredItems()
    local stockTargets = {}
    local offerPool = {}
    local categoryByItem = {}

    for index, raw in ipairs(GlobalConfig.Items) do
        if type(raw) == "table" then
            local itemName =
                tostring(
                    raw.Item
                    or raw.Name
                    or ""
                )

            local category =
                tostring(
                    raw.Category
                    or ""
                )

            local currency =
                tostring(
                    raw.Currency
                    or "Diamonds"
                )

            local target =
                math.max(
                    0,
                    math.floor(
                        tonumber(raw.Target)
                        or tonumber(raw.StockTarget)
                        or 0
                    )
                )

            if itemName ~= ""
                and category ~= ""
            then
                table.insert(
                    stockTargets,
                    {
                        Item = itemName,
                        Category = category,
                        Currency = currency,
                        Target = target
                    }
                )

                -- Only items with Target > 0 are included in the random
                -- outgoing item pool.
                if target > 0 then
                    table.insert(
                        offerPool,
                        itemName
                    )

                    categoryByItem[itemName] =
                        category
                end
            else
                warn(
                    "[AutoTrade] Ignoring invalid global item config at index",
                    index,
                    "- Item/Category required."
                )
            end
        end
    end

    return
        stockTargets,
        offerPool,
        categoryByItem
end

local GlobalStockTargets,
    GlobalOfferPool,
    GlobalCategoryByItem =
    buildConfiguredItems()

local Config = {
    TargetUsername =
        tostring(GlobalConfig.TargetUsername),

    TargetUserId =
        tonumber(GlobalConfig.TargetUserId),

    -- Optional: "Auto", "Sender", or "Receiver".
    -- Auto = the configured target account becomes the receiver;
    -- every other account remains a sender.
    Mode =
        tostring(GlobalConfig.Mode or "Auto"),

    Receiver = {
        Enabled =
            GlobalConfig.Receiver.Enabled ~= false,

        -- Optional fixed value. If nil, V23 deterministically selects one
        -- of DiamondOptions based on the active sender's UserId.
        FixedDiamondAmount =
            tonumber(GlobalConfig.Receiver.DiamondAmount),

        DiamondOptions =
            GlobalConfig.Receiver.DiamondOptions,

        ChatEnabled =
            GlobalConfig.Receiver.ChatEnabled ~= false,

        IncomingRequestTimeout = 999999,
        TradeOpenTimeout = 35.0,

        -- Incoming requests can arrive while the receiver is already trading
        -- or restocking. Keep them in a local FIFO instead of dropping them.
        RequestQueueEnabled = true,

        -- RH request cards themselves expire quickly, but sender accounts can
        -- retry while the receiver is occupied. Keep the local entry long
        -- enough for those retries to refresh it; stale server requests are
        -- skipped automatically if AcceptTradeRequest rejects them.
        RequestQueueTTL = 180.0,
        RequestQueueMax = 100,
        RequestQueueProcessDelay = 0.15,

        -- Sweep the ACTUAL TradeRequests.Inner cards continuously, including
        -- while another trade/restock is active. This makes the receiver much
        -- more reliable with many sender accounts arriving at once.
        RequestCardSweepEnabled = true,
        RequestCardSweepPollRate = 0.15,

        -- A transient auto-stock failure must never permanently wedge
        -- ReceiverBusy=true. Retry a few times, then release the receiver and
        -- keep servicing/collecting requests while stock recovery retries.
        PostTradeRestockAttempts = 3,
        PostTradeRestockRetryDelay = 1.00,
        StockRecoveryRetryDelay = 2.00,

        -- If the user manually clicks Accept on an incoming request, the
        -- trade opens without receiverAcceptRequest() owning that transition.
        -- V28 detects that already-open trade and adopts it automatically.
        ManualTradeAdoption = true,
        ManualTradeAdoptPollRate = 0.20,

        -- Re-accept only after the offer has stayed unchanged for this long.
        ReacceptStabilityDelay = 0.90,
        ReacceptMinGap = 0.75,
        MaxReaccepts = 20,

        -- AcceptOffer is a RemoteEvent, so a successful FireServer() call only
        -- means the packet was sent; it does not prove our checkbox became
        -- checked. If the OTHER player is visibly accepted but RH has not
        -- advanced to TradeConfirmation, retry our own AcceptOffer.
        AcceptWatchdogEnabled = true,
        AcceptWatchdogDelay = 1.25,
        AcceptWatchdogMaxRetries = 8,

        -- Safety: receiver will not AcceptOffer while the sender's side
        -- appears empty. Both sides now contribute configured item copies.
        MinPartnerItemCards = 1,

        ChatReplyCooldown = 6.0,
        MaxChatReplies = 3,

        -- Optional allowlist. Empty/nil means accept any sender while idle.
        -- Entries may be Roblox usernames or numeric UserIds.
        AllowedSenders =
            GlobalConfig.Receiver.AllowedSenders
            or {}
    },

    -- ============================================================
    -- AUTO STOCK
    -- ============================================================
    AutoStock = true,

    Stock = {
        ReadyTimeout = 8.0,
        VerifyTimeout = 3.5,
        PollRate = 0.10,
        PurchaseDelay = 0.60,

        Targets =
            GlobalStockTargets
    },

    -- Keep the chat varied without changing the typing cadence.
    ChatEnabled = true,

    Chat = {
        -- SmartChat combines fragments instead of picking from only a few
        -- complete fixed sentences. This gives hundreds of possible messages
        -- while keeping the trade conversation relevant to the current stage.
        Smart = true,
        -- Stage-aware cap: normally 5 core messages, with up to 2 more
        -- only when the trade actually reaches/waits on later confirmation stages.
        MaxMessagesPerTrade = 7,
        LongConfirmationWaitMessageAt = 12.0,

        Greetings = {
            "hey",
            "hi",
            "hello",
            "hey there",
            "hiya",
            "hii",
            "yo"
        },

        OpenActions = {
            "give me a sec to load everything",
            "one sec while i get my side ready",
            "let me put everything in",
            "i'm loading my trade stuff now",
            "just a sec, getting everything ready",
            "i'll add my side now",
            "one moment while i set up the offer",
            "let me get the trade filled in",
            "putting my side together now",
            "i'm getting the offer ready"
        },

        OpenTails = {
            "",
            "should be quick",
            "won't take long",
            "just a moment",
            "one sec",
            "give me a little bit"
        },

        OfferGeneric = {
            "adding my diamonds and items now",
            "putting the diamonds and items in now",
            "i'm filling in the offer now",
            "adding everything on my side",
            "working on my side of the trade now",
            "putting everything into the offer",
            "adding the stuff now",
            "i'm setting the offer up now",
            "filling my side in",
            "getting all of it into the trade"
        },

        OfferShort = {
            "should only take a sec",
            "this one should be pretty quick",
            "almost done adding",
            "just a few things to add",
            "finishing the last few items"
        },

        OfferLong = {
            "there are quite a few items so give me a sec",
            "i have a bunch of items to add so one moment",
            "this one has a few more items, just a sec",
            "adding a bigger batch so give me a moment",
            "there are several items on this one, still adding"
        },

        ReadyGeneric = {
            "all set on my side",
            "done adding everything",
            "my side should be complete now",
            "everything is in on my side",
            "okay, my offer is ready",
            "finished adding everything",
            "my side is ready now",
            "that should be everything from me",
            "offer is complete on my side",
            "i'm done adding now"
        },

        ReadyWithCount = {
            "all %d items are in now",
            "done, all %d items are added",
            "finished adding the %d items",
            "%d items are in, my side is ready",
            "all %d items should be showing now"
        },

        ReadyWithDiamondsAndCount = {
            "all %d items plus %s diamonds are in",
            "done, %d items and %s diamonds are added",
            "%d items + %s diamonds should all be showing",
            "finished, i added %d items and %s diamonds",
            "my side has %d items and %s diamonds now"
        },

        Accepting = {
            "looks good, accepting on my side",
            "okay, accepting now",
            "all good on my end, accepting",
            "my side is ready, i'll accept",
            "everything looks right, accepting now",
            "done on my side, accepting",
            "okay i'm accepting mine now",
            "offer looks good, i'll accept",
            "ready here, accepting",
            "all set, accepting my side",
            "everything checks out, accepting mine",
            "i'm good with this, accepting now"
        },

        PostAccept = {
            "accepted mine, waiting on your side now",
            "i accepted on my end, waiting for yours",
            "mine is accepted, just waiting on the next step",
            "accepted here, waiting for your side",
            "my side is accepted now",
            "accepted mine, take your time",
            "i'm accepted on my side, waiting now",
            "accepted here, just waiting for the confirmation",
            "mine is locked in, waiting on your side",
            "accepted my offer, waiting for the next screen",
            "i've accepted mine, just waiting here",
            "accepted on my end, we're good so far"
        },

        WaitingForConfirmation = {
            "still waiting on the confirmation screen on my side",
            "i'm still here, waiting for the next confirmation",
            "still waiting for the second confirmation to show",
            "no rush, i'm just waiting on the confirmation screen",
            "still on the trade, waiting for the final confirmation",
            "i'm waiting for the next screen to come up",
            "still waiting here for the confirmation step",
            "the final confirmation hasn't shown for me yet",
            "still here, just waiting for the confirmation",
            "waiting for the second accept screen on my side"
        },

        Confirmation = {
            "got the confirmation screen, checking it now",
            "final confirmation is up on my side now",
            "i'm on the final confirmation screen now",
            "got the second confirmation, one sec",
            "confirmation screen is showing for me now",
            "i'm checking the final confirmation now",
            "the final accept screen just came up",
            "got the last confirmation screen now",
            "second confirmation is here, checking it",
            "i'm at the final confirmation step now",
            "final screen is up, just checking everything",
            "confirmation came up on my side"
        },

        FinalConfirmed = {
            "confirmed on my side",
            "final confirmation done here",
            "confirmed mine, waiting for it to finish",
            "all confirmed on my end",
            "done with the final confirmation",
            "confirmed everything on my side",
            "final confirm is done for me",
            "confirmed mine, should be finishing now",
            "all done confirming here",
            "my final confirmation is in",
            "confirmed the last step on my side",
            "final accept is done here"
        }
    },

    -- Actual outgoing text is entered character-by-character through VIM.
    CharacterDelay = 0.055,
    ChatOpenDelay = 0.75,
    BetweenChatMessages = 0.60,

    -- Multi-account request pacing.
    QueueSlots = 20,
    InitialSlotSpacing = 0.80,
    BusyRetryBase = 5.0,
    BusyRetrySlotSpacing = 0.25,

    TradeOpenTimeout = 35.0,
    RequestTimeoutRetry = 8.0,
    PollRate = 0.10,

    -- CAPTCHA GUARD
    -- V25 detects Royale High's CardCaptchaGame and pauses all trade actions
    -- until the challenge is no longer visible. It does not attempt to solve
    -- or bypass the CAPTCHA.
    CaptchaGuard = {
        Enabled =
            GlobalConfig.CaptchaGuardEnabled ~= false,

        -- Matches the Campus script's CardCaptchaGame polling model.
        PollRate = 0.20,
        ClearSettleTime = 0.35,
        MaxPauseTime = 300.0,

        -- Campus solver detects this text explicitly. In AutoTrade we stop
        -- the current action instead of clicking/guessing when the challenge
        -- itself failed to load.
        StopOnFailedToLoad = true
    },

    -- Diamond stage
    OfferAllDiamonds = true,
    DiamondSettleDelay = 0.75,

    -- Deterministic amount policy. This is NOT randomized.
    -- Example: 126236 with RoundDown10 -> 126230.
    DiamondPolicy = {
        Mode = "RoundDown10", -- Exact / RoundDown10 / RoundDown100 / KeepReserve
        Reserve = 0,
        StrictDisplayVerification = false,
        DisplayVerifyTimeout = 2.50
    },

    -- Item stage.
    -- A random 10-20 total copies are selected from this SAFE pool.
    -- We deliberately do not choose arbitrary owned items, so the script
    -- cannot accidentally offer something valuable outside this list.
    RequireItemsBeforeAccept = true,

    RandomOffer = {
        MinItems = 10,
        MaxItems = 20,

        -- Fixed pacing between each real inventory click.
        -- Example: Crystal Ice x10 = 10 separate clicks with this delay.
        ItemClickDelay = 0.55,
        ItemFindTimeout = 2.50,
        BetweenItemTypesDelay = 0.20,

        -- MyItems is the sender's "You Offer" container.
        -- Every copy must replicate here before the script moves on.
        OfferVerifyTimeout = 3.00,
        OfferVerifyPollRate = 0.10,

        -- Prefer the normal TradeInventory GUI path.
        PreferInventoryClicks = true,

        -- If the item's clickable GUI entry genuinely cannot be found,
        -- use the confirmed Trade.AddItem RemoteFunction as a fallback.
        DirectAddItemFallback = true,

        Pool =
            GlobalOfferPool,

        CategoryByItem =
            GlobalCategoryByItem
    },

    -- Final trade confirmation.
    -- TradeConfirmation appears only after the normal offer-accept stage
    -- has progressed to Royale High's second confirmation screen.
    FinalConfirmation = {
        WaitTimeout = 120.0,
        PollRate = 0.10,
        InvokeAttempts = 2,
        RetryDelay = 1.00,

        -- After SetConfirmState(true), Royale High shows a timed final screen.
        FinalizeReadyTimeout = 75.0,

        -- V13 tries multiple coordinate interpretations because
        -- AbsolutePosition + GuiInset can double-offset small buttons.
        FinalizeClickAttempts = 5,
        FinalizeClickRetryDelay = 0.60,
        FinalizePostClickObserve = 3.00,

        -- A VIM coordinate/input failure is a client automation failure,
        -- not evidence that the trade/account itself is bad.
        QuarantineOnFinalizeClickFailure = false,

        CompletionTimeout = 120.0
    },

    Reliability = {
        RecipientLock = true,

        -- V29: Royale High clears BOTH offer-accept checkboxes whenever
        -- either side edits items/diamonds. If the receiver changes its offer
        -- after the sender accepted, the sender should re-accept after the
        -- offer settles instead of treating that normal change as fatal.
        ReacceptOnCounterpartyModification = true,
        SenderReacceptStabilityDelay = 0.90,
        SenderReacceptMinGap = 0.75,
        SenderMaxReaccepts = 20,

        -- Kept for backward compatibility. When re-accept is enabled, normal
        -- trade modifications are handled by the re-accept state machine.
        AbortOnTradeModifiedAfterOfferLock = false,

        AbortIfStockIncomplete = true,

        PostTradeVerify = true,
        PostTradeVerifyTimeout = 10.0,
        PostTradeVerifyPollRate = 0.25,

        -- Once a verified trade completes, this sender will not trade the same
        -- configured receiver again, even if the script is reinjected.
        PersistCompletion = true,
        PersistQuarantine = true,

        -- ACCOUNT-LEVEL protection, intentionally NOT JobId scoped.
        -- Volt writefile/makefolder paths are relative to its workspace.
        TradeBanFolder = "tradebans",

        -- PRE-FLIGHT: inspect the target profile before any trade request.
        ProfileTradeIconPreflight = true,
        ProfilePreflightTimeout = 4.0,
        ProfilePreflightPollRate = 0.10,
        ProfilePreflightSettleTime = 0.35,

        TargetResolveTimeout = 15.0,
        TargetResolvePollRate = 0.25,

        ReceiptFolder = "AutoTradeReceipts",
        StateFolder = "AutoTradeState"
    },

    -- Chat fallback is intentionally disabled while testing the real GUI path.
    DirectChatRemoteFallback = false
}

-- ================================================================
-- REMOTES
-- ================================================================

local TradeFolder = ReplicatedStorage:WaitForChild("Trade")
local MakeTradeRequest = TradeFolder:WaitForChild("MakeTradeRequest")
local AcceptTradeRequest = TradeFolder:WaitForChild("AcceptTradeRequest")
local ReceiveTradeRequest = TradeFolder:WaitForChild("ReceiveTradeRequest")
local AcceptOffer = TradeFolder:WaitForChild("AcceptOffer")
local SetConfirmState = TradeFolder:WaitForChild("SetConfirmState")

local ProfileShow =
    ReplicatedStorage
        :WaitForChild("Profile")
        :WaitForChild("Show")

local TradeChatFolder = TradeFolder:WaitForChild("Chat")
local DirectSendMessage = TradeChatFolder:WaitForChild("SendMessage")

local AssetPurchase =
    ReplicatedStorage
        :WaitForChild("Network")
        :WaitForChild("Functions")
        :WaitForChild("Asset")
        :WaitForChild("Purchase")

local GetTradeInventoryCategoryItems =
    TradeFolder:WaitForChild("GetTradeInventoryCategoryItems")

local AddTradeItem =
    TradeFolder:WaitForChild("AddItem")

-- ================================================================
-- STATE
-- ================================================================

local State = {
    StockingFinished = false,
    StockingResults = {},

    Target = nil,
    ManifestLocked = false,
    PreTradeSnapshot = nil,
    PostTradeSnapshot = nil,

    TradeOpened = false,
    GreetingSent = false,
    DiamondsOffered = false,
    DiamondOfferAmount = nil,
    ChatMessagesSent = 0,
    ChatUsedMessages = {},
    ItemOfferPlan = nil,
    ItemOfferSequence = nil,
    ItemOfferTargetCount = 0,
    ItemOfferAddedCount = 0,
    ItemsOffered = false,
    Accepted = false,
    ConfirmationVisible = false,
    FinalConfirmed = false,

    FinalizeButtonReady = false,
    FinalizeCountdownObserved = false,
    FinalizeClicked = false,
    FinalizeClickAttempts = 0,

    TradeFinished = false,

    TradeOfferLocked = false,
    TradeModifiedAfterLock = false,
    TradeModifiedAt = nil,
    TradeModifiedConnections = {},
    SenderReacceptCount = 0,
    SenderLastAcceptAt = 0,

    Completed = false,
    Quarantined = false,

    TradeBanned = false,
    TradeBanCode = nil,
    TradeBanPath = nil,

    RuntimeMode = nil,

    CaptchaActive = false,
    CaptchaPauseStartedAt = nil,
    CaptchaFailedToLoad = false,

    ReceiverBusy = false,
    ReceiverSender = nil,

    -- FIFO of requests observed while the receiver is occupied.
    ReceiverRequestQueue = {},
    ReceiverRequestQueuedByUserId = {},
    ReceiverRequestSequence = 0,
    ReceiverStockReady = true,
    ReceiverStockRecoveryRunning = false,
    ReceiverRequestSweepRunning = false,

    ReceiverManualAdoptions = 0,
    ReceiverLastManualPartner = nil,

    ReceiverDiamondAmount = nil,
    ReceiverReacceptCount = 0,
    ReceiverLastAcceptAt = 0,
    ReceiverAcceptWatchdogRetries = 0,
    ReceiverOfferModifiedAt = nil,
    ReceiverOfferModificationPending = false,
    ReceiverConnections = {},
    ReceiverChatConnections = {},
    ReceiverRequestConnection = nil,
    ReceiverChatReplies = 0,
    ReceiverLastChatReplyAt = 0,

    ProfilePreflightChecked = false,
    ProfilePreflightPassed = false,
    ProfilePreflightDetail = nil,

    TerminalReason = nil,
    ReceiptPath = nil,

    DiamondBalanceObject = nil,
    DiamondOfferDisplayObject = nil
}

-- ================================================================
-- CAMPUS-STYLE CAPTCHA GUARD
-- ================================================================
-- Ported from the uploaded Campus script's detection/state flow:
--   CardCaptchaGame -> CaptchaGame.Visible
--   scan descendants for "failed to load"
--   event-driven Visible watcher + polling fallback
--
-- Intentionally NOT ported:
--   asset thumbnail lookup
--   hash -> answer mapping
--   automatic CAPTCHA button clicking
--
-- Trading simply pauses until the challenge is gone.

local function checkCaptchaFailedToLoad()
    local topCard =
        PlayerGui:FindFirstChild("CardCaptchaGame")

    if not topCard then
        return false
    end

    for _, object in ipairs(topCard:GetDescendants()) do
        if object:IsA("TextLabel") then
            local value =
                string.lower(
                    tostring(object.Text or "")
                )

            if string.find(
                value,
                "failed to load",
                1,
                true
            ) then
                return true
            end
        end
    end

    return false
end

local function captchaChallengeVisible()
    if not Config.CaptchaGuard.Enabled then
        return false
    end

    local topCard =
        PlayerGui:FindFirstChild("CardCaptchaGame")

    if not topCard then
        return false
    end

    local gameFrame =
        topCard:FindFirstChild("CaptchaGame")

    if not gameFrame then
        return false
    end

    local enabled = true
    local visible = false

    pcall(function()
        if topCard:IsA("LayerCollector") then
            enabled = topCard.Enabled
        end
    end)

    pcall(function()
        visible = gameFrame.Visible
    end)

    return enabled and visible
end

local function waitForCaptchaClear(context)
    if not Config.CaptchaGuard.Enabled then
        return true
    end

    if not captchaChallengeVisible() then
        return true
    end

    local started = os.clock()

    if not State.CaptchaActive then
        State.CaptchaActive = true
        State.CaptchaPauseStartedAt = started

        warn(
            "[AutoTrade][CaptchaGuard] CardCaptchaGame visible - pausing",
            "| stage:",
            tostring(context or "unknown")
        )
    end

    while captchaChallengeVisible() do
        if checkCaptchaFailedToLoad() then
            State.CaptchaFailedToLoad = true

            warn(
                "[AutoTrade][CaptchaGuard] Captcha reports 'Failed to Load'."
            )

            if Config.CaptchaGuard.StopOnFailedToLoad then
                return false
            end
        end

        if os.clock() - started
            >= Config.CaptchaGuard.MaxPauseTime
        then
            warn(
                "[AutoTrade][CaptchaGuard] Captcha remained active too long; "
                .. "stopping the current action."
            )

            return false
        end

        task.wait(
            Config.CaptchaGuard.PollRate
        )
    end

    task.wait(
        Config.CaptchaGuard.ClearSettleTime
    )

    State.CaptchaActive = false
    State.CaptchaPauseStartedAt = nil
    State.CaptchaFailedToLoad = false

    print(
        "[AutoTrade][CaptchaGuard] Captcha hidden - resuming",
        "| stage:",
        tostring(context or "unknown")
    )

    return true
end

local function startCaptchaVisibilityWatcher()
    if not Config.CaptchaGuard.Enabled then
        return
    end

    task.spawn(function()
        local cardCaptchaUI =
            PlayerGui:FindFirstChild("CardCaptchaGame")
            or PlayerGui:WaitForChild(
                "CardCaptchaGame",
                10
            )

        local captchaGameFrame =
            cardCaptchaUI
            and (
                cardCaptchaUI:FindFirstChild("CaptchaGame")
                or cardCaptchaUI:WaitForChild(
                    "CaptchaGame",
                    10
                )
            )

        if captchaGameFrame then
            captchaGameFrame
                :GetPropertyChangedSignal("Visible")
                :Connect(function()
                    if captchaGameFrame.Visible then
                        State.CaptchaActive = true
                        State.CaptchaPauseStartedAt =
                            os.clock()

                        warn(
                            "[AutoTrade][CaptchaGuard] Captcha UI detected."
                        )
                    else
                        State.CaptchaActive = false
                        State.CaptchaPauseStartedAt = nil
                        State.CaptchaFailedToLoad = false

                        print(
                            "[AutoTrade][CaptchaGuard] Captcha UI closed."
                        )
                    end
                end)
        end

        if captchaChallengeVisible() then
            State.CaptchaActive = true
            State.CaptchaPauseStartedAt =
                os.clock()
        end
    end)

    -- Low-frequency fallback in case the game replaces the GUI instance.
    task.spawn(function()
        local previousVisible =
            captchaChallengeVisible()

        while true do
            local visible =
                captchaChallengeVisible()

            if visible ~= previousVisible then
                previousVisible = visible

                if visible then
                    State.CaptchaActive = true
                    State.CaptchaPauseStartedAt =
                        os.clock()

                    warn(
                        "[AutoTrade][CaptchaGuard] Captcha became visible."
                    )
                else
                    State.CaptchaActive = false
                    State.CaptchaPauseStartedAt = nil
                    State.CaptchaFailedToLoad = false

                    print(
                        "[AutoTrade][CaptchaGuard] Captcha became hidden."
                    )
                end
            end

            task.wait(
                Config.CaptchaGuard.PollRate
            )
        end
    end)
end

startCaptchaVisibilityWatcher()

-- ================================================================
-- RELIABILITY / PERSISTENT STATE
-- ================================================================

local function safeMakeFolder(path)
    if type(makefolder) ~= "function" then
        return false
    end

    local ok = pcall(function()
        if type(isfolder) == "function" and isfolder(path) then
            return
        end
        makefolder(path)
    end)

    return ok
end

local function safeWriteFile(path, content)
    if type(writefile) ~= "function" then
        return false
    end

    return pcall(function()
        writefile(path, content)
    end)
end

local function safeIsFile(path)
    if type(isfile) ~= "function" then
        return false
    end

    local ok, result = pcall(function()
        return isfile(path)
    end)

    return ok and result == true
end


local function safeReadFile(path)
    if type(readfile) ~= "function" then
        return nil
    end

    local ok, result = pcall(function()
        return readfile(path)
    end)

    if not ok then
        return nil
    end

    return tostring(result or "")
end


-- ================================================================
-- GLOBAL SENDER TRADE-BAN VAULT
-- ================================================================
-- Unlike normal completion/quarantine state, an RH trading ban/review is
-- account-level. It must remain blocked across different JobIds.

local SENDER_TRADE_RESTRICTION_MESSAGES = {
    sender_banned_from_trading =
        "Exploitive activity has been found on your account. Your trading privileges have been revoked.",

    sender_is_suspicious =
        "We're sorry: before you can trade, an RH Staff Member needs to manually investigate your account to approve transactions.",

    profile_trade_icon_missing =
        "The Royale High profile loaded, but no visible Trade control/icon was found. AutoTrade stopped before sending a trade request."
}

local function tradeBanFilename()
    -- V22: only authoritative RH SERVER restriction responses use this file.
    return
        Config.Reliability.TradeBanFolder
        .. "/server_"
        .. tostring(LocalPlayer.UserId)
        .. "_"
        .. tostring(LocalPlayer.Name)
        .. ".txt"
end

local function legacyTradeBanFilename()
    -- V19-V21 used this same file for both server errors AND profile-icon
    -- heuristics. V22 reads it only to migrate genuine server restrictions.
    return
        Config.Reliability.TradeBanFolder
        .. "/"
        .. tostring(LocalPlayer.UserId)
        .. "_"
        .. tostring(LocalPlayer.Name)
        .. ".txt"
end

local function profilePreflightFilename(target)
    return
        Config.Reliability.TradeBanFolder
        .. "/profile_"
        .. tostring(LocalPlayer.UserId)
        .. "_to_"
        .. tostring(target and target.UserId or "unknown")
        .. ".txt"
end

local function hasSavedSenderTradeBan()
    local authoritative = tradeBanFilename()

    if safeIsFile(authoritative) then
        return true
    end

    -- Backward compatibility:
    -- migrate ONLY genuine old RH server restriction markers.
    local legacy = legacyTradeBanFilename()

    if not safeIsFile(legacy) then
        return false
    end

    local body = safeReadFile(legacy)

    if not body then
        -- Do not permanently block from an unreadable legacy marker because
        -- V20/V21 could have created it from a profile-icon heuristic.
        warn(
            "[AutoTrade] Legacy tradeban marker exists but cannot be read. "
            .. "Ignoring it; RH server restriction checks remain authoritative."
        )
        return false
    end

    local isServerRestriction =
        string.find(body, "errorCode=sender_banned_from_trading", 1, true)
        or string.find(body, "errorCode=sender_is_suspicious", 1, true)

    if not isServerRestriction then
        -- Most importantly, ignore the old V20/V21:
        -- errorCode=profile_trade_icon_missing
        return false
    end

    safeMakeFolder(Config.Reliability.TradeBanFolder)
    safeWriteFile(authoritative, body)

    print(
        "[AutoTrade] Migrated legacy SERVER trade restriction marker ->",
        authoritative
    )

    return true
end

local function saveProfilePreflightMarker(target, detail)
    safeMakeFolder(Config.Reliability.TradeBanFolder)

    local path =
        profilePreflightFilename(target)

    local body =
        "status=PROFILE_PREFLIGHT_BLOCK"
        .. "\ndetail=" .. tostring(detail or "profile_trade_icon_missing")
        .. "\nusername=" .. tostring(LocalPlayer.Name)
        .. "\nuserId=" .. tostring(LocalPlayer.UserId)
        .. "\ntarget=" .. tostring(target and target.Name or Config.TargetUsername)
        .. "\ntargetUserId=" .. tostring(target and target.UserId or "unknown")
        .. "\nplaceId=" .. tostring(game.PlaceId)
        .. "\njobId=" .. tostring(game.JobId)
        .. "\ndetectedUnix=" .. tostring(os.time())

    safeWriteFile(path, body)

    warn(
        "[AutoTrade] Profile preflight marker saved:",
        path
    )

    return path
end

local function saveSenderTradeBan(errorCode)
    errorCode = tostring(errorCode or "unknown_trade_restriction")

    State.TradeBanned = true
    State.TradeBanCode = errorCode
    State.TerminalReason = "sender_trade_restricted_" .. errorCode

    safeMakeFolder(Config.Reliability.TradeBanFolder)

    local status =
        errorCode == "sender_banned_from_trading"
        and "TRADE_BANNED"
        or "MANUAL_REVIEW"

    local message =
        SENDER_TRADE_RESTRICTION_MESSAGES[errorCode]
        or "Sender trading is restricted."

    local path = tradeBanFilename()

    local body =
        "status=" .. status
        .. "\nerrorCode=" .. errorCode
        .. "\nmessage=" .. message
        .. "\nusername=" .. tostring(LocalPlayer.Name)
        .. "\nuserId=" .. tostring(LocalPlayer.UserId)
        .. "\nplaceId=" .. tostring(game.PlaceId)
        .. "\njobId=" .. tostring(game.JobId)
        .. "\ntarget="
            .. tostring(
                State.Target
                and State.Target.Name
                or Config.TargetUsername
            )
        .. "\ntargetUserId="
            .. tostring(
                State.Target
                and State.Target.UserId
                or "unknown"
            )
        .. "\ndetectedUnix=" .. tostring(os.time())

    if safeWriteFile(path, body) then
        State.TradeBanPath = path

        warn(
            "[AutoTrade] TRADE RESTRICTION SAVED:",
            path
        )
    else
        warn(
            "[AutoTrade] Trade restriction detected, but Volt writefile/makefolder "
            .. "could not save the tradebans marker."
        )
    end

    warn(
        "[AutoTrade] SENDER TRADING STOPPED:",
        errorCode,
        "|",
        message
    )

    -- Runtime-global guard too, even if filesystem APIs are unavailable.
    local env = _G

    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then
            env = result
        end
    end

    env.__AutoTradeSenderTradeBanned = true
    env.__AutoTradeSenderTradeBanCode = errorCode
end

local function senderTradeBanRuntimeGuarded()
    local env = _G

    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then
            env = result
        end
    end

    if env.__AutoTradeSenderTradeBanned ~= true then
        return false
    end

    -- V20/V21 could set this from a profile-icon heuristic. Do not let that
    -- old heuristic block a different TargetUsername forever.
    if tostring(env.__AutoTradeSenderTradeBanCode)
        == "profile_trade_icon_missing"
    then
        env.__AutoTradeSenderTradeBanned = false
        env.__AutoTradeSenderTradeBanCode = nil
        return false
    end

    return true
end


-- ================================================================
-- PROFILE TRADE-ICON PRE-FLIGHT
-- ================================================================

local function preflightNormalize(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function preflightGuiVisible(object)
    if not object or not object:IsA("GuiObject") then
        return false
    end

    local ok, visible = pcall(function()
        return object.Visible
            and object.AbsoluteSize.X > 0
            and object.AbsoluteSize.Y > 0
    end)

    if not ok or not visible then
        return false
    end

    local current = object.Parent

    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end

        if current:IsA("LayerCollector") and current.Enabled == false then
            return false
        end

        current = current.Parent
    end

    return true
end

local function preflightVisibleText(object)
    local pieces = {}

    if object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox")
    then
        local value = tostring(object.Text or "")
        if value ~= "" then
            table.insert(pieces, value)
        end
    end

    for _, child in ipairs(object:GetDescendants()) do
        if (child:IsA("TextLabel")
            or child:IsA("TextButton")
            or child:IsA("TextBox"))
            and preflightGuiVisible(child)
        then
            local value = tostring(child.Text or "")
            if value ~= "" then
                table.insert(pieces, value)
            end
        end
    end

    return table.concat(pieces, " ")
end

local function preflightHasProfileToken(object)
    local current = object

    while current and current ~= PlayerGui do
        local name = preflightNormalize(current.Name)

        if string.find(name, "profile", 1, true)
            or string.find(name, "diary", 1, true)
            or string.find(name, "journal", 1, true)
        then
            return true
        end

        current = current.Parent
    end

    return false
end

local function preflightObjectMentionsTarget(object, target)
    local haystack = preflightNormalize(preflightVisibleText(object))
    local username = preflightNormalize(target and target.Name)
    local displayName = preflightNormalize(target and target.DisplayName)

    if username ~= ""
        and string.find(haystack, username, 1, true)
    then
        return true
    end

    if displayName ~= ""
        and string.find(haystack, displayName, 1, true)
    then
        return true
    end

    return false
end

local function findVisibleProfileTradeControl(target)
    local profileLoaded = false
    local bestProfileObject = nil

    for _, object in ipairs(PlayerGui:GetDescendants()) do
        if object:IsA("GuiObject")
            and preflightGuiVisible(object)
            and preflightHasProfileToken(object)
            and preflightObjectMentionsTarget(object, target)
        then
            profileLoaded = true
            bestProfileObject = object
            break
        end
    end

    if not profileLoaded then
        return nil, false, "profile_not_confidently_loaded"
    end

    local searchRoot = bestProfileObject
    local cursor = bestProfileObject

    while cursor and cursor ~= PlayerGui do
        local name = preflightNormalize(cursor.Name)

        if string.find(name, "profile", 1, true)
            or string.find(name, "diary", 1, true)
            or string.find(name, "journal", 1, true)
        then
            searchRoot = cursor
        end

        cursor = cursor.Parent
    end

    local candidates = {searchRoot}

    for _, child in ipairs(searchRoot:GetDescendants()) do
        table.insert(candidates, child)
    end

    for _, object in ipairs(candidates) do
        if object:IsA("GuiObject")
            and preflightGuiVisible(object)
        then
            local name = preflightNormalize(object.Name)
            local textValue = preflightNormalize(preflightVisibleText(object))
            local fullName = preflightNormalize(object:GetFullName())

            local mentionsTrade =
                string.find(name, "trade", 1, true)
                or string.find(textValue, "trade", 1, true)
                or string.find(fullName, "trade", 1, true)

            if mentionsTrade then
                local clickable =
                    object:IsA("GuiButton")
                    and object
                    or object:FindFirstAncestorWhichIsA("GuiButton")

                if clickable then
                    return clickable, true, clickable:GetFullName()
                end

                if name == "trade"
                    or string.find(name, "tradebutton", 1, true)
                    or string.find(name, "tradeicon", 1, true)
                then
                    return object, true, object:GetFullName()
                end
            end
        end
    end

    return nil, true, "profile_loaded_but_trade_control_missing"
end

local function runProfileTradeIconPreflight(target)
    if not Config.Reliability.ProfileTradeIconPreflight then
        State.ProfilePreflightChecked = true
        State.ProfilePreflightPassed = true
        State.ProfilePreflightDetail = "disabled"
        return true, "disabled"
    end

    if not target or target.Parent ~= Players then
        return false, "target_unavailable"
    end

    State.ProfilePreflightChecked = true
    State.ProfilePreflightPassed = false
    State.ProfilePreflightDetail = nil

    print(
        "[AutoTrade] Preflight: opening profile before trade request:",
        target.Name
    )

    local opened = pcall(function()
        ProfileShow:FireServer(target, "Preview")
    end)

    if not opened then
        State.ProfilePreflightDetail = "profile_show_remote_failed"

        warn(
            "[AutoTrade] Preflight UNKNOWN - profile open failed. "
            .. "Not writing a trade-ban marker from an uncertain UI state."
        )

        return true, "unknown_profile_show_failed"
    end

    task.wait(Config.Reliability.ProfilePreflightSettleTime)

    local started = os.clock()
    local profileWasSeen = false

    while os.clock() - started
        < Config.Reliability.ProfilePreflightTimeout
    do
        local control, profileLoaded, detail =
            findVisibleProfileTradeControl(target)

        if profileLoaded then
            profileWasSeen = true
        end

        if control then
            State.ProfilePreflightPassed = true
            State.ProfilePreflightDetail = tostring(detail)

            print(
                "[AutoTrade] Preflight PASS - profile Trade control found:",
                tostring(detail)
            )

            return true, detail
        end

        task.wait(Config.Reliability.ProfilePreflightPollRate)
    end

    if not profileWasSeen then
        State.ProfilePreflightPassed = true
        State.ProfilePreflightDetail = "profile_not_confidently_loaded"

        warn(
            "[AutoTrade] Preflight UNKNOWN - profile UI could not be "
            .. "confidently identified. Keeping RH server error checks active."
        )

        return true, "unknown_profile_ui"
    end

    State.ProfilePreflightDetail = "profile_trade_icon_missing"

    warn(
        "[AutoTrade] Preflight FAIL - profile loaded but Trade icon/control "
        .. "is missing. No trade request will be sent."
    )

    -- This is a UI heuristic, not an authoritative RH server response.
    -- Keep it in the tradebans workspace for diagnostics, but scope it to
    -- this target and DO NOT globally poison the sender account.
    State.ProfilePreflightDetail =
        "profile_trade_icon_missing"

    saveProfilePreflightMarker(
        target,
        "profile_trade_icon_missing"
    )

    writeTradeReceipt(
        "profile_preflight_block",
        "profile_trade_icon_missing"
    )

    return false, "profile_trade_icon_missing"
end

local function sanitizeFileKey(value)
    value = tostring(value or "")
    value = string.gsub(value, "[^%w%-%_]", "_")
    if value == "" then value = "unknown" end
    return value
end

local function tradePairKey(target)
    return tostring(LocalPlayer.UserId)
        .. "_to_"
        .. tostring(target and target.UserId or Config.TargetUsername)
end

local function serverTradeKey(target)
    -- BOTH completion and quarantine are scoped to this exact Roblox server.
    -- Same sender + same target can trade again in a different JobId.
    return tradePairKey(target)
        .. "_job_"
        .. sanitizeFileKey(game.JobId)
end

local function completionKey(target)
    return serverTradeKey(target)
end

local function quarantineKey(target)
    return serverTradeKey(target)
end

local function completedMarkerPath(target)
    return Config.Reliability.StateFolder
        .. "/completed_"
        .. completionKey(target)
        .. ".txt"
end

local function quarantinedMarkerPath(target)
    return Config.Reliability.StateFolder
        .. "/quarantined_"
        .. quarantineKey(target)
        .. ".txt"
end

local function getRuntimeStateTable()
    local env = _G

    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then
            env = result
        end
    end

    env.__AutoTradeTerminalState =
        env.__AutoTradeTerminalState or {}

    return env.__AutoTradeTerminalState
end

local function alreadyTerminalForTarget(target)
    local runtime = getRuntimeStateTable()
    local completedRuntimeKey = "completed:" .. completionKey(target)
    local quarantinedRuntimeKey = "quarantined:" .. quarantineKey(target)

    if runtime[completedRuntimeKey] then
        return true, "completed"
    end

    if runtime[quarantinedRuntimeKey] then
        return true, "quarantined"
    end

    if Config.Reliability.PersistCompletion
        and safeIsFile(completedMarkerPath(target))
    then
        return true, "completed"
    end

    if Config.Reliability.PersistQuarantine
        and safeIsFile(quarantinedMarkerPath(target))
    then
        return true, "quarantined"
    end

    return false, nil
end

local function markTerminalState(target, stateName, reason)
    local runtime = getRuntimeStateTable()
    local runtimeKey

    if stateName == "completed" then
        runtimeKey = "completed:" .. completionKey(target)
    elseif stateName == "quarantined" then
        runtimeKey = "quarantined:" .. quarantineKey(target)
    else
        runtimeKey = tostring(stateName) .. ":" .. completionKey(target)
    end

    runtime[runtimeKey] = true
    safeMakeFolder(Config.Reliability.StateFolder)

    local path = nil
    if stateName == "completed" and Config.Reliability.PersistCompletion then
        path = completedMarkerPath(target)
    elseif stateName == "quarantined" and Config.Reliability.PersistQuarantine then
        path = quarantinedMarkerPath(target)
    end

    if path then
        safeWriteFile(
            path,
            "state=" .. tostring(stateName)
            .. "\nreason=" .. tostring(reason or stateName)
            .. "\nplaceId=" .. tostring(game.PlaceId)
            .. "\njobId=" .. tostring(game.JobId)
            .. "\nsenderUserId=" .. tostring(LocalPlayer.UserId)
            .. "\ntarget=" .. tostring(target and target.UserId or Config.TargetUsername)
        )
    end
end

local function copySimpleTable(source)
    local result = {}

    if type(source) ~= "table" then
        return result
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = copySimpleTable(value)
        else
            result[key] = value
        end
    end

    return result
end

local function writeTradeReceipt(status, reason)
    safeMakeFolder(Config.Reliability.ReceiptFolder)

    local receipt = {
        Status = status,
        Reason = reason,
        TradeBanned = State.TradeBanned,
        TradeBanCode = State.TradeBanCode,
        TradeBanPath = State.TradeBanPath,
        ProfilePreflightChecked = State.ProfilePreflightChecked,
        ProfilePreflightPassed = State.ProfilePreflightPassed,
        ProfilePreflightDetail = State.ProfilePreflightDetail,
        Sender = {
            Name = LocalPlayer.Name,
            UserId = LocalPlayer.UserId
        },
        Target = State.Target and {
            Name = State.Target.Name,
            UserId = State.Target.UserId
        } or {
            Name = Config.TargetUsername
        },
        Server = {
            PlaceId = game.PlaceId,
            JobId = game.JobId
        },
        DiamondsOffered = State.DiamondOfferAmount,
        ItemOfferPlan = copySimpleTable(State.ItemOfferPlan),
        ItemOfferTargetCount = State.ItemOfferTargetCount,
        ItemOfferAddedCount = State.ItemOfferAddedCount,
        PreTrade = copySimpleTable(State.PreTradeSnapshot),
        PostTrade = copySimpleTable(State.PostTradeSnapshot),
        Accepted = State.Accepted,
        FinalConfirmed = State.FinalConfirmed,
        FinalizeButtonReady = State.FinalizeButtonReady,
        FinalizeCountdownObserved = State.FinalizeCountdownObserved,
        FinalizeClicked = State.FinalizeClicked,
        FinalizeClickAttempts = State.FinalizeClickAttempts,
        TradeFinished = State.TradeFinished,
        TradeModifiedAfterLock = State.TradeModifiedAfterLock,
        TimestampUnix = os.time()
    }

    local encoded = nil

    local ok, result = pcall(function()
        return HttpService:JSONEncode(receipt)
    end)

    if ok then
        encoded = result
    else
        encoded = tostring(receipt)
    end

    local jobShort = string.sub(sanitizeFileKey(game.JobId), 1, 12)

    local filename =
        Config.Reliability.ReceiptFolder
        .. "/"
        .. tradePairKey(State.Target)
        .. "_job_"
        .. jobShort
        .. "_"
        .. tostring(os.time())
        .. "_"
        .. tostring(status)
        .. ".json"

    if safeWriteFile(filename, encoded) then
        State.ReceiptPath = filename
        print("[AutoTrade] Receipt:", filename)
    end
end

local function quarantine(reason)
    if State.Quarantined then
        return
    end

    State.Quarantined = true
    State.TerminalReason = tostring(reason or "unknown")

    warn("[AutoTrade] Sender quarantined:", State.TerminalReason)

    markTerminalState(
        State.Target,
        "quarantined",
        State.TerminalReason
    )

    writeTradeReceipt(
        "quarantined",
        State.TerminalReason
    )
end

local function markCompleted(reason)
    if State.Completed then
        return
    end

    State.Completed = true
    State.TerminalReason = tostring(reason or "verified_success")

    print(
        "[AutoTrade] VERIFIED COMPLETE. "
        .. "This sender will not request another trade in THIS JobId."
    )

    markTerminalState(
        State.Target,
        "completed",
        State.TerminalReason
    )

    writeTradeReceipt(
        "completed",
        State.TerminalReason
    )
end

-- ================================================================
-- AUTO STOCK
-- ================================================================

local function getQuantityModule()
    local shop = PlayerGui:FindFirstChild("Shop")
        or PlayerGui:WaitForChild("Shop", Config.Stock.ReadyTimeout)

    local moduleScript =
        shop
        and shop:FindFirstChild("InventoryQuantitiesLocalModule")

    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end

    local ok, module = pcall(require, moduleScript)
    return ok and module or nil
end

local function readQuantityData(quantityModule)
    if not quantityModule
        or type(quantityModule.GetQuantityData) ~= "function"
    then
        return nil, false
    end

    local ok, data = pcall(function()
        return quantityModule:GetQuantityData()
    end)

    if not ok or type(data) ~= "table" then
        return nil, false
    end

    -- A populated table means the inventory module has finished loading.
    return data, next(data) ~= nil
end

local function waitQuantityDataReady(quantityModule)
    local started = os.clock()

    while os.clock() - started < Config.Stock.ReadyTimeout do
        local data, ready = readQuantityData(quantityModule)

        if ready then
            return data
        end

        task.wait(Config.Stock.PollRate)
    end

    return nil
end

local function getItemQuantity(quantityModule, itemName)
    local data, ready = readQuantityData(quantityModule)

    if not ready then
        return nil
    end

    return tonumber(data[itemName]) or 0
end

local function snapshotConfiguredInventory()
    local quantityModule = getQuantityModule()

    if not quantityModule then
        return nil, "quantity_module_unavailable"
    end

    local data = waitQuantityDataReady(quantityModule)

    if not data then
        return nil, "inventory_not_ready"
    end

    local snapshot = {
        Items = {}
    }

    for _, itemName in ipairs(Config.RandomOffer.Pool) do
        snapshot.Items[itemName] =
            math.max(
                0,
                math.floor(tonumber(data[itemName]) or 0)
            )
    end

    return snapshot
end

local function waitForQuantityIncrease(quantityModule, itemName, before)
    local started = os.clock()

    while os.clock() - started < Config.Stock.VerifyTimeout do
        local count = getItemQuantity(quantityModule, itemName)

        if count and count > before then
            return count
        end

        task.wait(Config.Stock.PollRate)
    end

    return nil
end

local function stockOneTarget(quantityModule, spec)
    if not waitForCaptchaClear("auto_stock") then
        return false, nil
    end

    local item = spec.Item
    local target = math.max(0, tonumber(spec.Target) or 0)

    local count = getItemQuantity(quantityModule, item)

    if count == nil then
        warn("[AutoStock] Could not read quantity for", item)
        return false, nil
    end

    print(
        "[AutoStock]",
        item,
        "| owned:",
        count,
        "| target:",
        target
    )

    if count >= target then
        return true, count
    end

    while count < target do
        if not waitForCaptchaClear("auto_stock_purchase") then
            return false, count
        end

        local before = count

        local ok, result = pcall(function()
            return AssetPurchase:InvokeServer(
                spec.Item,
                spec.Category,
                spec.Currency,
                nil
            )
        end)

        if not ok then
            warn(
                "[AutoStock]",
                item,
                "purchase invoke failed:",
                result
            )
            return false, count
        end

        local updated =
            waitForQuantityIncrease(
                quantityModule,
                item,
                before
            )

        if not updated then
            warn(
                "[AutoStock]",
                item,
                "quantity did not increase; stopping this target."
            )
            return false, count
        end

        count = updated

        print(
            "[AutoStock]",
            item,
            count .. "/" .. target
        )

        if count >= target then
            break
        end

        task.wait(Config.Stock.PurchaseDelay)
    end

    return count >= target, count
end

local function runAutoStock()
    if not Config.AutoStock then
        State.StockingFinished = true
        return true
    end

    local quantityModule = getQuantityModule()

    if not quantityModule then
        warn("[AutoStock] InventoryQuantitiesLocalModule unavailable.")
        State.StockingFinished = true
        return false
    end

    local initialData = waitQuantityDataReady(quantityModule)

    if not initialData then
        warn("[AutoStock] Inventory quantities never became ready.")
        State.StockingFinished = true
        return false
    end

    local allReached = true

    for _, spec in ipairs(Config.Stock.Targets) do
        local ok, finalCount = stockOneTarget(
            quantityModule,
            spec
        )

        State.StockingResults[spec.Item] = {
            Success = ok,
            Count = finalCount,
            Target = spec.Target
        }

        if not ok then
            allReached = false
        end

        task.wait(Config.Stock.PurchaseDelay)
    end

    State.StockingFinished = true

    if allReached then
        print("[AutoStock] All configured stock targets are ready.")
    else
        warn("[AutoStock] One or more stock targets could not be completed.")
    end

    return allReached
end

-- ================================================================
-- GUI HELPERS
-- ================================================================

local function getTradeGui()
    local screen = PlayerGui:FindFirstChild("TradeGui")
    local frame = screen and screen:FindFirstChild("TradeGui")
    return screen, frame
end

local function isFinalConfirmationOverlayVisible()
    local _, frame = getTradeGui()

    if not frame then
        return false
    end

    local finalConfirmation =
        frame:FindFirstChild("FinalConfirmation")

    return finalConfirmation
        and finalConfirmation:IsA("GuiObject")
        and finalConfirmation.Visible == true
        or false
end

local function isTradeOpen()
    local screen, frame = getTradeGui()

    if not screen or not frame then
        return false
    end

    if screen:IsA("ScreenGui") and screen.Enabled == false then
        return false
    end

    return frame.Visible == true
end

local function waitForTradeToClose()
    while isTradeOpen() do
        task.wait(Config.PollRate)
    end
end

local function getGuiCenter(guiObject)
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize

    local ok, inset = pcall(function()
        return GuiService:GetGuiInset()
    end)

    if not ok then
        inset = Vector2.new(0, 0)
    end

    return
        pos.X + size.X / 2,
        pos.Y + size.Y / 2 + inset.Y
end

local function vimClick(guiObject)
    if not guiObject
        or not guiObject:IsA("GuiObject")
        or guiObject.AbsoluteSize.X <= 0
        or guiObject.AbsoluteSize.Y <= 0
    then
        return false
    end

    local x, y = getGuiCenter(guiObject)

    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.05)

        VirtualInputManager:SendMouseButtonEvent(
            x, y, 0, true, game, 1
        )

        task.wait(0.06)

        VirtualInputManager:SendMouseButtonEvent(
            x, y, 0, false, game, 1
        )
    end)

    return ok
end

local function sendKey(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function utf8Characters(text)
    local chars = {}

    for _, codepoint in utf8.codes(text) do
        table.insert(chars, utf8.char(codepoint))
    end

    return chars
end

local function typeFocusedTextBox(textBox, text, clearFirst)
    if not textBox or not textBox:IsA("TextBox") then
        return false, "textbox_missing"
    end

    if not vimClick(textBox) then
        return false, "textbox_click_failed"
    end

    task.wait(0.10)

    pcall(function()
        textBox:CaptureFocus()
    end)

    task.wait(0.08)

    if clearFirst then
        textBox.Text = ""
    end

    for _, character in ipairs(utf8Characters(text)) do
        if not isTradeOpen() then
            return false, "trade_closed_while_typing"
        end

        local ok = pcall(function()
            VirtualInputManager:SendTextInputCharacterEvent(
                character,
                game
            )
        end)

        if not ok then
            return false, "vim_text_input_unavailable"
        end

        task.wait(Config.CharacterDelay)
    end

    return true
end

-- ================================================================
-- CHAT
-- ================================================================

local rng = Random.new(
    math.abs(tonumber(LocalPlayer.UserId) or 1)
    + math.floor(os.clock() * 1000)
)

local function chooseDifferent(list, previous)
    if type(list) ~= "table" or #list == 0 then
        return nil
    end

    if #list == 1 then
        return list[1]
    end

    local chosen = nil

    for _ = 1, 8 do
        chosen = list[rng:NextInteger(1, #list)]

        if chosen ~= previous then
            break
        end
    end

    return chosen
end

local lastFragmentByGroup = {}

local function pickFragment(groupName, list)
    local chosen =
        chooseDifferent(
            list,
            lastFragmentByGroup[groupName]
        )

    lastFragmentByGroup[groupName] = chosen
    return chosen
end

local function formatDiamondAmount(amount)
    amount = tonumber(amount)

    if not amount then
        return nil
    end

    local s = tostring(math.floor(amount))
    local formatted = s

    while true do
        local changed
        formatted, changed =
            string.gsub(
                formatted,
                "^(-?%d+)(%d%d%d)",
                "%1,%2"
            )

        if changed == 0 then
            break
        end
    end

    return formatted
end

local function normalizeChatSpacing(message)
    message = tostring(message or "")
    message = string.gsub(message, "%s+", " ")
    message = string.gsub(message, "%s+([%.,!?])", "%1")
    message = string.gsub(message, "^%s+", "")
    message = string.gsub(message, "%s+$", "")
    return message
end

local function rememberChatMessage(message)
    if not message or message == "" then
        return false
    end

    if State.ChatUsedMessages[message] then
        return false
    end

    State.ChatUsedMessages[message] = true
    return true
end

local function buildSmartTradeMessage(stage)
    if not Config.ChatEnabled then
        return nil
    end

    local chat = Config.Chat

    if not chat.Smart then
        return nil
    end

    local message = nil

    if stage == "Open" then
        local greeting =
            pickFragment("Greetings", chat.Greetings)

        local action =
            pickFragment("OpenActions", chat.OpenActions)

        local tail =
            pickFragment("OpenTails", chat.OpenTails)

        message = tostring(greeting or "hey")
            .. ", "
            .. tostring(action or "give me a sec")

        if tail and tail ~= "" then
            message = message .. ", " .. tail
        end

    elseif stage == "Offering" then
        local itemCount =
            tonumber(State.ItemOfferTargetCount) or 0

        local base =
            pickFragment("OfferGeneric", chat.OfferGeneric)

        local tail = nil

        if itemCount >= 16 then
            tail =
                pickFragment(
                    "OfferLong",
                    chat.OfferLong
                )
        elseif itemCount > 0 and itemCount <= 12 then
            tail =
                pickFragment(
                    "OfferShort",
                    chat.OfferShort
                )
        end

        message = tostring(base or "adding everything now")

        if tail and tail ~= "" then
            message = message .. ", " .. tail
        end

    elseif stage == "Ready" then
        local itemCount =
            tonumber(State.ItemOfferTargetCount) or 0

        local diamondAmount =
            formatDiamondAmount(
                State.DiamondOfferAmount
            )

        if itemCount > 0 and diamondAmount then
            local template =
                pickFragment(
                    "ReadyWithDiamondsAndCount",
                    chat.ReadyWithDiamondsAndCount
                )

            message = string.format(
                template,
                itemCount,
                diamondAmount
            )

        elseif itemCount > 0 then
            local template =
                pickFragment(
                    "ReadyWithCount",
                    chat.ReadyWithCount
                )

            message = string.format(
                template,
                itemCount
            )

        else
            message =
                pickFragment(
                    "ReadyGeneric",
                    chat.ReadyGeneric
                )
        end

    elseif stage == "Accepting" then
        message =
            pickFragment(
                "Accepting",
                chat.Accepting
            )

    elseif stage == "PostAccept" then
        message =
            pickFragment(
                "PostAccept",
                chat.PostAccept
            )

    elseif stage == "WaitingForConfirmation" then
        message =
            pickFragment(
                "WaitingForConfirmation",
                chat.WaitingForConfirmation
            )

    elseif stage == "Confirmation" then
        message =
            pickFragment(
                "Confirmation",
                chat.Confirmation
            )

    elseif stage == "FinalConfirmed" then
        message =
            pickFragment(
                "FinalConfirmed",
                chat.FinalConfirmed
            )
    end

    message = normalizeChatSpacing(message)

    if message == "" then
        return nil
    end

    -- Exact-message de-duplication for this trade session.
    if rememberChatMessage(message) then
        return message
    end

    -- Rebuild a few times if the fragment combination happened to repeat.
    for _ = 1, 6 do
        if stage == "Open" then
            message =
                normalizeChatSpacing(
                    tostring(pickFragment("Greetings", chat.Greetings) or "hey")
                    .. ", "
                    .. tostring(pickFragment("OpenActions", chat.OpenActions) or "give me a sec")
                )

        elseif stage == "Offering" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "OfferGeneric",
                            chat.OfferGeneric
                        )
                        or "adding everything now"
                    )
                )

        elseif stage == "Ready" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "ReadyGeneric",
                            chat.ReadyGeneric
                        )
                        or "all set on my side"
                    )
                )

        elseif stage == "Accepting" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "Accepting",
                            chat.Accepting
                        )
                        or "accepting now"
                    )
                )

        elseif stage == "PostAccept" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "PostAccept",
                            chat.PostAccept
                        )
                        or "accepted mine, waiting on your side"
                    )
                )

        elseif stage == "WaitingForConfirmation" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "WaitingForConfirmation",
                            chat.WaitingForConfirmation
                        )
                        or "still waiting for the confirmation screen"
                    )
                )

        elseif stage == "Confirmation" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "Confirmation",
                            chat.Confirmation
                        )
                        or "got the final confirmation screen"
                    )
                )

        elseif stage == "FinalConfirmed" then
            message =
                normalizeChatSpacing(
                    tostring(
                        pickFragment(
                            "FinalConfirmed",
                            chat.FinalConfirmed
                        )
                        or "confirmed on my side"
                    )
                )
        end

        if rememberChatMessage(message) then
            return message
        end
    end

    return message
end

local function typeIntoTradeChat(message)
    if not waitForCaptchaClear("trade_chat") then
        return false, "captcha_pause_timeout"
    end

    local _, frame = getTradeGui()

    if not frame or not isTradeOpen() then
        return false, "trade_not_open"
    end

    -- FinalConfirmation overlays the lower TradeGui. Its red No/Decline
    -- button overlaps the normal SendMessage screen area, so chat must stop
    -- completely once this overlay appears.
    if isFinalConfirmationOverlayVisible() then
        return false, "final_confirmation_overlay_active"
    end

    local chatBox = frame:FindFirstChild("Chat")
    local sendButton = frame:FindFirstChild("SendMessage")

    if not chatBox or not chatBox:IsA("TextBox") then
        return false, "chat_box_missing"
    end

    if not sendButton or not sendButton:IsA("GuiButton") then
        return false, "send_button_missing"
    end

    local typed, reason = typeFocusedTextBox(
        chatBox,
        message,
        true
    )

    if not typed then
        return false, reason
    end

    task.wait(0.15)

    if tostring(chatBox.Text or "") == "" then
        return false, "textbox_stayed_empty"
    end

    -- Re-check immediately before the physical Send! click. The other party
    -- can advance the trade while this account is typing.
    if isFinalConfirmationOverlayVisible() then
        return false, "final_confirmation_appeared_before_send"
    end

    if not vimClick(sendButton) then
        return false, "send_click_failed"
    end

    task.wait(0.20)
    return true
end

local function sendTradeChat(message)
    if not Config.ChatEnabled or not message then
        return true
    end

    local maxMessages =
        math.max(
            1,
            tonumber(Config.Chat.MaxMessagesPerTrade) or 7
        )

    if State.ChatMessagesSent >= maxMessages then
        return true
    end

    local ok, reason = typeIntoTradeChat(message)

    if ok then
        State.ChatMessagesSent += 1
        print("[AutoTrade] Chat:", message)
        return true
    end

    warn("[AutoTrade] GUI chat failed:", reason)

    if Config.DirectChatRemoteFallback then
        local remoteOk, remoteResult = pcall(function()
            return DirectSendMessage:InvokeServer(message)
        end)

        if remoteOk then
            State.ChatMessagesSent += 1
            print("[AutoTrade] Direct chat fallback:", message)
            return true
        end

        warn("[AutoTrade] Direct chat fallback failed:", remoteResult)
    end

    return false
end

local function sendStageChat(stage)
    local message =
        buildSmartTradeMessage(stage)

    if not message then
        return true
    end

    local ok = sendTradeChat(message)
    task.wait(Config.BetweenChatMessages)
    return ok
end

-- ================================================================
-- DIAMONDS
-- ================================================================

local function parseNumber(text)
    if type(text) ~= "string" then
        return nil
    end

    local cleaned = string.gsub(text, "[^%d]", "")

    if cleaned == "" then
        return nil
    end

    return tonumber(cleaned)
end

local function findCurrentDiamondBalance()
    local _, frame = getTradeGui()

    if not frame then
        return nil
    end

    local bestAmount = nil
    local bestObject = nil

    -- Prefer text objects whose names/parents mention diamonds.
    for _, object in ipairs(frame:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") then
            local amount = parseNumber(object.Text)

            if amount and amount > 0 then
                local path = string.lower(object:GetFullName())
                local score = amount

                if string.find(path, "diamond", 1, true) then
                    score += 1000000000
                end

                if not bestAmount or score > bestAmount.score then
                    bestAmount = {
                        value = amount,
                        score = score
                    }
                    bestObject = object
                end
            end
        end
    end

    if bestAmount then
        print(
            "[AutoTrade] Diamond balance candidate:",
            bestAmount.value,
            "|",
            bestObject:GetFullName()
        )

        return bestAmount.value, bestObject
    end

    return nil, nil
end

local function applyDiamondPolicy(balance)
    local mode = tostring(Config.DiamondPolicy.Mode or "Exact")
    local reserve = math.max(
        0,
        math.floor(tonumber(Config.DiamondPolicy.Reserve) or 0)
    )

    balance = math.max(0, math.floor(tonumber(balance) or 0))

    if mode == "RoundDown10" then
        return math.floor(balance / 10) * 10

    elseif mode == "RoundDown100" then
        return math.floor(balance / 100) * 100

    elseif mode == "KeepReserve" then
        return math.max(0, balance - reserve)
    end

    return balance
end

local function findDiamondOfferDisplayObject(expectedAmount)
    local _, frame = getTradeGui()

    if not frame then
        return nil
    end

    for _, object in ipairs(frame:GetDescendants()) do
        if (object:IsA("TextLabel") or object:IsA("TextButton"))
            and object ~= State.DiamondBalanceObject
        then
            local amount = parseNumber(object.Text)

            if amount == expectedAmount then
                return object
            end
        end
    end

    return nil
end

local function waitForDiamondOfferDisplay(expectedAmount)
    local started = os.clock()

    while os.clock() - started
        < Config.DiamondPolicy.DisplayVerifyTimeout
    do
        if not isTradeOpen() then
            return false, nil
        end

        local object =
            findDiamondOfferDisplayObject(expectedAmount)

        if object then
            return true, object
        end

        task.wait(Config.PollRate)
    end

    return false, nil
end

local function verifyCurrentDiamondOffer()
    if not Config.OfferAllDiamonds then
        return true
    end

    local _, frame = getTradeGui()

    if not frame then
        return false
    end

    local diamondBox = frame:FindFirstChild("DiamondAmount")
    local expected = tonumber(State.DiamondOfferAmount)

    if not diamondBox or not expected then
        return false
    end

    if parseNumber(diamondBox.Text) ~= expected then
        return false
    end

    if State.DiamondOfferDisplayObject
        and State.DiamondOfferDisplayObject.Parent
    then
        return
            parseNumber(State.DiamondOfferDisplayObject.Text)
            == expected
    end

    if Config.DiamondPolicy.StrictDisplayVerification then
        local verified, object =
            waitForDiamondOfferDisplay(expected)

        if verified then
            State.DiamondOfferDisplayObject = object
        end

        return verified
    end

    return true
end

local function offerAllDiamonds()
    if not waitForCaptchaClear("sender_diamonds") then
        return false
    end

    if not Config.OfferAllDiamonds then
        State.DiamondsOffered = true
        return true
    end

    local _, frame = getTradeGui()

    if not frame or not isTradeOpen() then
        return false
    end

    local diamondBox = frame:FindFirstChild("DiamondAmount")

    if not diamondBox or not diamondBox:IsA("TextBox") then
        warn("[AutoTrade] TradeGui.TradeGui.DiamondAmount missing.")
        return false
    end

    local balance, balanceObject =
        findCurrentDiamondBalance()

    if balance == nil then
        warn("[AutoTrade] Could not determine current diamond balance.")
        return false
    end

    State.DiamondBalanceObject = balanceObject

    if not State.PreTradeSnapshot then
        State.PreTradeSnapshot = {
            Items = {}
        }
    end

    State.PreTradeSnapshot.Diamonds = balance

    local amount = applyDiamondPolicy(balance)

    if amount <= 0 then
        warn("[AutoTrade] Diamond policy produced no transferable diamonds.")
        return false
    end

    local typed, reason = typeFocusedTextBox(
        diamondBox,
        tostring(amount),
        true
    )

    if not typed then
        warn("[AutoTrade] Could not type diamond amount:", reason)
        return false
    end

    sendKey(Enum.KeyCode.Return)
    task.wait(Config.DiamondSettleDelay)

    local boxAmount = parseNumber(diamondBox.Text)

    if boxAmount ~= amount then
        warn(
            "[AutoTrade] Diamond TextBox verification failed:",
            tostring(boxAmount),
            "/",
            tostring(amount)
        )
        return false
    end

    local displayVerified, displayObject =
        waitForDiamondOfferDisplay(amount)

    if displayVerified then
        State.DiamondOfferDisplayObject = displayObject
        print(
            "[AutoTrade] Diamond offer display verified:",
            amount
        )
    elseif Config.DiamondPolicy.StrictDisplayVerification then
        warn(
            "[AutoTrade] Offered diamond display could not be verified."
        )
        return false
    else
        warn(
            "[AutoTrade] Could not identify the separate offered-diamond label; "
            .. "TextBox verification passed."
        )
    end

    State.DiamondsOffered = true
    State.DiamondOfferAmount = amount

    print(
        "[AutoTrade] Diamond policy:",
        tostring(Config.DiamondPolicy.Mode),
        "| balance:",
        balance,
        "| offer:",
        amount
    )

    return true
end

-- ================================================================
-- ITEMS
-- ================================================================

local function normalizeItemText(value)
    return string.lower(
        string.gsub(
            tostring(value or ""),
            "^%s*(.-)%s*$",
            "%1"
        )
    )
end

local function randomOfferPoolSet()
    local set = {}

    for _, name in ipairs(Config.RandomOffer.Pool) do
        set[name] = true
    end

    return set
end

local function buildRandomItemOfferPlan()
    if State.ManifestLocked
        and type(State.ItemOfferPlan) == "table"
        and type(State.ItemOfferSequence) == "table"
        and #State.ItemOfferSequence > 0
    then
        return State.ItemOfferPlan, State.ItemOfferSequence
    end

    local quantityModule = getQuantityModule()

    if not quantityModule then
        return nil, "quantity_module_unavailable"
    end

    local data = waitQuantityDataReady(quantityModule)

    if not data then
        return nil, "inventory_not_ready"
    end

    local poolSet = randomOfferPoolSet()
    local copies = {}

    -- Expand owned copies into individual RNG slots.
    -- With the configured stock targets this can be:
    --   Crystal Ice x15
    --   Miniskirt x5
    --   Royale Rebel Bustle Skirt x2
    -- = 22 individual selectable copies.
    for itemName, rawCount in pairs(data) do
        if poolSet[itemName] then
            local count = math.max(
                0,
                math.floor(tonumber(rawCount) or 0)
            )

            for _ = 1, count do
                table.insert(copies, itemName)
            end
        end
    end

    if #copies == 0 then
        return nil, "no_safe_items_owned"
    end

    -- Fisher-Yates: the actual COPY ORDER is randomized, not just the total.
    for i = #copies, 2, -1 do
        local j = rng:NextInteger(1, i)
        copies[i], copies[j] = copies[j], copies[i]
    end

    local minWanted = math.max(
        1,
        math.floor(tonumber(Config.RandomOffer.MinItems) or 10)
    )

    local maxWanted = math.max(
        minWanted,
        math.floor(tonumber(Config.RandomOffer.MaxItems) or 20)
    )

    local wanted = rng:NextInteger(minWanted, maxWanted)
    wanted = math.min(wanted, #copies)

    local plan = {}
    local sequence = {}

    for i = 1, wanted do
        local itemName = copies[i]

        table.insert(sequence, itemName)
        plan[itemName] = (plan[itemName] or 0) + 1
    end

    State.ItemOfferPlan = plan
    State.ItemOfferSequence = sequence
    State.ItemOfferTargetCount = #sequence
    State.ItemOfferAddedCount = 0

    print(
        "[AutoTrade] Random item offer target:",
        #sequence,
        "item(s)"
    )

    for itemName, count in pairs(plan) do
        print(
            "[AutoTrade]   ",
            itemName,
            "x" .. tostring(count)
        )
    end

    return plan, sequence
end

local function getTradeInventoryFrame()
    local _, frame = getTradeGui()

    if not frame then
        return nil
    end

    return frame:FindFirstChild("TradeInventory")
end

local function getTradeInventoryInner()
    local inventory = getTradeInventoryFrame()
    return inventory and inventory:FindFirstChild("Inner") or nil
end

local function getMyItemsFrame()
    local _, frame = getTradeGui()
    return frame and frame:FindFirstChild("MyItems") or nil
end

local function countMyOfferedItemCopies(itemName)
    local myItems = getMyItemsFrame()

    if not myItems then
        return nil
    end

    local count = 0

    -- Roblox allows multiple siblings with the same Name, so ten copies of
    -- Crystal Ice can appear as ten children all named "Crystal Ice".
    for _, object in ipairs(myItems:GetChildren()) do
        if object.Name == itemName then
            count += 1
        end
    end

    return count
end

local function countTotalPlannedItemsPresent(plan)
    local total = 0

    for itemName, expected in pairs(plan) do
        local count = countMyOfferedItemCopies(itemName)

        if count == nil then
            return nil
        end

        total += math.min(count, expected)
    end

    return total
end

local function waitForOfferedCopyIncrease(itemName, beforeCount)
    local started = os.clock()

    while os.clock() - started < Config.RandomOffer.OfferVerifyTimeout do
        if not isTradeOpen() then
            return false, "trade_closed"
        end

        local now = countMyOfferedItemCopies(itemName)

        if now and now >= beforeCount + 1 then
            return true, now
        end

        task.wait(Config.RandomOffer.OfferVerifyPollRate)
    end

    local finalCount = countMyOfferedItemCopies(itemName)

    if finalCount and finalCount >= beforeCount + 1 then
        return true, finalCount
    end

    return false, finalCount
end

local function guiObjectActuallyVisible(object)
    if not object or not object:IsA("GuiObject") then
        return false
    end

    if object.Visible == false
        or object.AbsoluteSize.X <= 0
        or object.AbsoluteSize.Y <= 0
    then
        return false
    end

    local current = object.Parent

    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end

        if current:IsA("ScreenGui") and current.Enabled == false then
            return false
        end

        current = current.Parent
    end

    return true
end

local function findClickableInside(container)
    if not container then
        return nil
    end

    if container:IsA("GuiButton") and guiObjectActuallyVisible(container) then
        return container
    end

    -- Common Royale High structure: item Frame -> Button.
    local namedButton = container:FindFirstChild("Button")

    if namedButton
        and namedButton:IsA("GuiButton")
        and guiObjectActuallyVisible(namedButton)
    then
        return namedButton
    end

    for _, object in ipairs(container:GetDescendants()) do
        if object:IsA("GuiButton") and guiObjectActuallyVisible(object) then
            return object
        end
    end

    return nil
end

local function findTradeInventoryItemButton(itemName)
    local inventory = getTradeInventoryFrame()
    local inner = getTradeInventoryInner()

    if not inventory then
        return nil
    end

    local wanted = normalizeItemText(itemName)

    -- Confirmed exact structure:
    -- TradeGui.TradeGui.TradeInventory.Inner["Crystal Ice"]
    -- TradeGui.TradeGui.TradeInventory.Inner.Miniskirt
    -- TradeGui.TradeGui.TradeInventory.Inner["Royale Rebel Bustle Skirt"]
    local direct = inner and inner:FindFirstChild(itemName)

    if direct then
        local button = findClickableInside(direct)

        if button then
            return button
        end
    end

    -- Fallback recursive path in case the GUI structure changes slightly.
    direct = inventory:FindFirstChild(itemName, true)

    if direct then
        local button = findClickableInside(direct)

        if button then
            return button
        end

        -- If the exact named object is a label inside an item card, walk up
        -- a few levels and look for that card's button.
        local parent = direct.Parent

        for _ = 1, 5 do
            if not parent or parent == inventory.Parent then
                break
            end

            button = findClickableInside(parent)

            if button then
                return button
            end

            parent = parent.Parent
        end
    end

    -- Text path: locate an exact item-name label and then its nearest
    -- clickable card/container.
    for _, object in ipairs(inventory:GetDescendants()) do
        local text = nil

        if object:IsA("TextLabel")
            or object:IsA("TextButton")
            or object:IsA("TextBox")
        then
            text = object.Text
        end

        local nameMatches =
            normalizeItemText(object.Name) == wanted

        local textMatches =
            text ~= nil
            and normalizeItemText(text) == wanted

        if nameMatches or textMatches then
            if object:IsA("GuiButton")
                and guiObjectActuallyVisible(object)
            then
                return object
            end

            local parent = object.Parent

            for _ = 1, 6 do
                if not parent then
                    break
                end

                local button = findClickableInside(parent)

                if button then
                    return button
                end

                if parent == inventory then
                    break
                end

                parent = parent.Parent
            end
        end
    end

    return nil
end

local function waitForTradeInventoryItemButton(itemName)
    local started = os.clock()

    while os.clock() - started < Config.RandomOffer.ItemFindTimeout do
        if not isTradeOpen() then
            return nil
        end

        local button = findTradeInventoryItemButton(itemName)

        if button then
            return button
        end

        task.wait(Config.PollRate)
    end

    return nil
end

local function directAddTradeItem(itemName)
    local category =
        Config.RandomOffer.CategoryByItem[itemName]

    if not category then
        return false, "category_missing"
    end

    local ok, result = pcall(function()
        return AddTradeItem:InvokeServer(
            itemName,
            category
        )
    end)

    if not ok then
        return false, tostring(result)
    end

    -- A literal false is treated as rejection.
    if result == false then
        return false, "server_rejected"
    end

    return true, result
end

local function addOneTradeItemByNormalClick(itemName)
    if not waitForCaptchaClear("sender_add_item") then
        return false, "captcha_pause_timeout"
    end

    if not isTradeOpen() then
        return false, "trade_closed"
    end

    local beforeCount = countMyOfferedItemCopies(itemName)

    if beforeCount == nil then
        return false, "my_items_missing"
    end

    if Config.RandomOffer.PreferInventoryClicks then
        -- Re-find the exact TradeInventory.Inner item for EVERY copy.
        -- The game may rebuild/reorder the inventory after each AddItem.
        local button =
            waitForTradeInventoryItemButton(itemName)

        if button then
            local clicked = vimClick(button)

            if clicked then
                local verified, afterCount =
                    waitForOfferedCopyIncrease(
                        itemName,
                        beforeCount
                    )

                if verified then
                    return true, "gui_click_verified", afterCount
                end

                -- IMPORTANT: do not immediately fire the fallback without
                -- checking MyItems. A delayed GUI replication could otherwise
                -- produce an accidental duplicate.
                local finalCount =
                    countMyOfferedItemCopies(itemName)

                if finalCount
                    and finalCount >= beforeCount + 1
                then
                    return true, "gui_click_late_verified", finalCount
                end
            end
        end
    end

    if Config.RandomOffer.DirectAddItemFallback then
        -- Only fallback after the GUI path failed AND MyItems still confirms
        -- that this copy was not added.
        local stillCount =
            countMyOfferedItemCopies(itemName)

        if stillCount == nil then
            return false, "my_items_missing"
        end

        if stillCount >= beforeCount + 1 then
            return true, "gui_click_late_verified", stillCount
        end

        local ok, result = directAddTradeItem(itemName)

        if not ok then
            return false, result
        end

        local verified, afterCount =
            waitForOfferedCopyIncrease(
                itemName,
                beforeCount
            )

        if verified then
            return true, "remote_fallback_verified", afterCount
        end

        return false, "additem_not_reflected_in_myitems"
    end

    return false, "item_button_not_found"
end

local function offerConfiguredItems()
    if not Config.RequireItemsBeforeAccept then
        State.ItemsOffered = true
        return true
    end

    local plan = State.ItemOfferPlan
    local sequence = State.ItemOfferSequence

    if type(plan) ~= "table"
        or type(sequence) ~= "table"
        or #sequence == 0
    then
        warn("[AutoTrade] Locked item manifest is missing.")
        State.ItemsOffered = false
        return false
    end

    -- The plan was generated once before entering the request queue.
    -- Retries cannot silently change what this sender intends to transfer.
    sendStageChat("Offering")

    -- Ask the normal inventory endpoint to load/refresh Show All before
    -- searching the TradeInventory GUI.
    local inventoryOk, inventoryResult = pcall(function()
        return GetTradeInventoryCategoryItems:InvokeServer(
            "Show All",
            nil
        )
    end)

    if not inventoryOk then
        warn(
            "[AutoTrade] GetTradeInventoryCategoryItems failed:",
            inventoryResult
        )

        State.ItemsOffered = false
        return false
    end

    task.wait(0.40)

    print(
        "[AutoTrade] Adding",
        #sequence,
        "RNG-selected item copies..."
    )

    local previousItem = nil

    -- IMPORTANT:
    -- sequence contains INDIVIDUAL COPIES.
    -- If the RNG plan contains Crystal Ice x10, this loop performs
    -- TEN separate inventory clicks, each separated by ItemClickDelay.
    for index, itemName in ipairs(sequence) do
        if not waitForCaptchaClear("sender_item_loop") then
            State.ItemsOffered = false
            return false
        end

        if not isTradeOpen() then
            warn("[AutoTrade] Trade closed while adding items.")
            State.ItemsOffered = false
            return false
        end

        if previousItem
            and previousItem ~= itemName
            and Config.RandomOffer.BetweenItemTypesDelay > 0
        then
            task.wait(Config.RandomOffer.BetweenItemTypesDelay)
        end

        local added, method, replicatedCount =
            addOneTradeItemByNormalClick(itemName)

        if not added then
            warn(
                "[AutoTrade] Failed to add item",
                index .. "/" .. #sequence,
                itemName,
                "|",
                tostring(method)
            )

            State.ItemsOffered = false
            return false
        end

        State.ItemOfferAddedCount += 1

        print(
            "[AutoTrade] Added + verified",
            index .. "/" .. #sequence,
            itemName,
            "| MyItems:",
            tostring(replicatedCount),
            "|",
            tostring(method)
        )

        previousItem = itemName

        -- Fixed pacing so repeated AddItem operations do not hammer the
        -- trade inventory. No blind loop / no zero-delay spam.
        if index < #sequence then
            task.wait(Config.RandomOffer.ItemClickDelay)
        end
    end

    local visiblePlannedTotal =
        countTotalPlannedItemsPresent(plan)

    State.ItemsOffered =
        State.ItemOfferAddedCount == State.ItemOfferTargetCount
        and visiblePlannedTotal == State.ItemOfferTargetCount

    if not State.ItemsOffered then
        warn(
            "[AutoTrade] Final You Offer verification mismatch:",
            "actions=" .. tostring(State.ItemOfferAddedCount),
            "visible=" .. tostring(visiblePlannedTotal),
            "target=" .. tostring(State.ItemOfferTargetCount)
        )
        return false
    end

    -- Per-item final verification.
    for itemName, expectedCount in pairs(plan) do
        local actualCount =
            countMyOfferedItemCopies(itemName) or 0

        if actualCount < expectedCount then
            warn(
                "[AutoTrade] Final per-item mismatch:",
                itemName,
                actualCount .. "/" .. expectedCount
            )
            State.ItemsOffered = false
            return false
        end
    end

    print(
        "[AutoTrade] Finished adding + verifying all",
        State.ItemOfferAddedCount,
        "planned item copies in MyItems."
    )

    return true
end

-- ================================================================
-- RECIPIENT / OFFER LOCK
-- ================================================================

local function tradeGuiMatchesTarget(target)
    if not Config.Reliability.RecipientLock then
        return true
    end

    if not target then
        return false
    end

    local _, frame = getTradeGui()

    if not frame then
        return false
    end

    local wanted = string.lower(target.Name)

    for _, object in ipairs(frame:GetDescendants()) do
        if object:IsA("TextLabel")
            or object:IsA("TextButton")
        then
            local value = string.lower(tostring(object.Text or ""))

            -- The trade header normally contains "Let's Trade <username>!"
            if string.find(value, wanted, 1, true) then
                return true
            end
        end
    end

    return false
end

local function verifyLockedItemOffer()
    local plan = State.ItemOfferPlan

    if type(plan) ~= "table" then
        return false
    end

    local total = countTotalPlannedItemsPresent(plan)

    if total ~= State.ItemOfferTargetCount then
        return false
    end

    for itemName, expectedCount in pairs(plan) do
        local actual =
            countMyOfferedItemCopies(itemName) or 0

        if actual < expectedCount then
            return false
        end
    end

    return true
end

local function verifyLockedOffer()
    if not verifyLockedItemOffer() then
        return false, "item_offer_changed"
    end

    if not verifyCurrentDiamondOffer() then
        return false, "diamond_offer_changed"
    end

    if not tradeGuiMatchesTarget(State.Target) then
        return false, "recipient_mismatch"
    end

    return true
end

local function disconnectTradeModifiedWatcher()
    for _, connection in ipairs(State.TradeModifiedConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    State.TradeModifiedConnections = {}
end

local function armTradeModifiedWatcher()
    disconnectTradeModifiedWatcher()

    local _, frame = getTradeGui()

    if not frame then
        return false
    end

    State.TradeModifiedAfterLock = false
    State.TradeModifiedAt = nil
    State.TradeOfferLocked = true

    local function markModified(source)
        if not State.TradeOfferLocked
            or State.TradeFinished
            or isTradeConfirmationVisible()
        then
            return
        end

        State.TradeModifiedAfterLock = true
        State.TradeModifiedAt = os.clock()

        -- RH clears the offer-stage checkbox after an offer edit.
        State.Accepted = false

        print(
            "[AutoTrade] Offer changed after sender accepted; "
            .. "sender acceptance marked stale.",
            "| source:",
            tostring(source or "unknown")
        )
    end

    local function watch(object)
        if not object then
            return
        end

        local connection =
            object.Changed:Connect(function()
                markModified(object.Name)
            end)

        table.insert(
            State.TradeModifiedConnections,
            connection
        )
    end

    watch(frame:FindFirstChild("TradeModified"))
    watch(frame:FindFirstChild("TradeModifiedNotice"))

    return true
end

local function abortIfTradeModified()
    if not State.TradeModifiedAfterLock then
        return false
    end

    if Config.Reliability.ReacceptOnCounterpartyModification then
        return false
    end

    if Config.Reliability.AbortOnTradeModifiedAfterOfferLock then
        quarantine("trade_modified_after_offer_lock")
        return true
    end

    return false
end

-- ================================================================
-- ACCEPT + FINAL CONFIRMATION
-- ================================================================

local function getTradeConfirmation()
    local _, frame = getTradeGui()
    return frame and frame:FindFirstChild("TradeConfirmation") or nil
end

local function isTradeConfirmationVisible()
    local confirmation = getTradeConfirmation()

    if not confirmation then
        return false
    end

    if confirmation:IsA("GuiObject") then
        return guiObjectActuallyVisible(confirmation)
    end

    return false
end

local function senderReacceptAfterModification()
    if not State.TradeModifiedAfterLock then
        return true, "no_change"
    end

    if not Config.Reliability.ReacceptOnCounterpartyModification then
        return not abortIfTradeModified(),
            "reaccept_disabled"
    end

    local changedAt =
        tonumber(State.TradeModifiedAt)
        or os.clock()

    local now =
        os.clock()

    if now - changedAt
        < Config.Reliability.SenderReacceptStabilityDelay
    then
        return nil, "waiting_for_offer_stability"
    end

    if now - (State.SenderLastAcceptAt or 0)
        < Config.Reliability.SenderReacceptMinGap
    then
        return nil, "waiting_for_reaccept_gap"
    end

    -- Re-accept only if OUR OWN locked contribution is still exactly intact.
    -- A counterparty change is okay; our own items/diamonds changing is not.
    local offerOK, offerReason =
        verifyLockedOffer()

    if not offerOK then
        quarantine(
            "sender_offer_changed_during_reaccept_"
            .. tostring(offerReason)
        )

        return false, offerReason
    end

    if State.SenderReacceptCount
        >= Config.Reliability.SenderMaxReaccepts
    then
        quarantine("sender_reaccept_limit")
        return false, "sender_reaccept_limit"
    end

    local ok, err =
        pcall(function()
            AcceptOffer:FireServer()
        end)

    if not ok then
        warn(
            "[AutoTrade] Sender re-AcceptOffer failed:",
            tostring(err)
        )

        return false, "sender_reaccept_invoke_failed"
    end

    State.SenderReacceptCount += 1
    State.SenderLastAcceptAt = os.clock()
    State.Accepted = true
    State.TradeModifiedAfterLock = false
    State.TradeModifiedAt = nil

    print(
        "[AutoTrade] Sender re-accepted after receiver/offer update",
        State.SenderReacceptCount
            .. "/"
            .. Config.Reliability.SenderMaxReaccepts
    )

    return true, "reaccepted"
end

local function waitForTradeConfirmation()
    local started = os.clock()
    local waitingMessageSent = false

    while os.clock() - started < Config.FinalConfirmation.WaitTimeout do
        if abortIfTradeModified() then
            return false, "trade_modified_after_offer_lock"
        end

        if State.TradeModifiedAfterLock then
            local reaccepted, reacceptReason =
                senderReacceptAfterModification()

            if reaccepted == false then
                return false, reacceptReason
            end

            -- nil means the offer is still inside the stability/min-gap
            -- debounce. Keep waiting without firing AcceptOffer repeatedly.
        end

        local offerOK, offerReason = verifyLockedOffer()
        if not offerOK then
            quarantine("offer_verification_failed_" .. tostring(offerReason))
            return false, offerReason
        end

        -- The normal trade GUI can disappear if the trade is cancelled.
        if not isTradeOpen() then
            return false, "trade_closed_before_confirmation"
        end

        if isTradeConfirmationVisible() then
            State.ConfirmationVisible = true

            -- This message is tied to a real state transition, not a timer.
            sendStageChat("Confirmation")

            print(
                "[AutoTrade] Final TradeConfirmation is visible. "
                .. "Both parties reached the confirmation stage."
            )
            return true
        end

        -- Optional sixth message only when the user has genuinely been
        -- waiting for the second confirmation for a while.
        if not waitingMessageSent
            and os.clock() - started
                >= (tonumber(Config.Chat.LongConfirmationWaitMessageAt) or 12)
        then
            waitingMessageSent = true
            sendStageChat("WaitingForConfirmation")
        end

        task.wait(Config.FinalConfirmation.PollRate)
    end

    return false, "confirmation_timeout"
end

local function setFinalConfirmState()
    if not waitForCaptchaClear("sender_confirm_state") then
        return false, "captcha_pause_timeout"
    end

    if State.FinalConfirmed then
        return true
    end

    if abortIfTradeModified() then
        return false, "trade_modified_after_offer_lock"
    end

    local offerOK, offerReason = verifyLockedOffer()
    if not offerOK then
        quarantine("offer_verification_failed_" .. tostring(offerReason))
        return false, offerReason
    end

    if not isTradeConfirmationVisible() then
        return false, "confirmation_not_visible"
    end

    local attempts = math.max(
        1,
        tonumber(Config.FinalConfirmation.InvokeAttempts) or 2
    )

    for attempt = 1, attempts do
        if not isTradeOpen() then
            return false, "trade_closed_before_final_confirm"
        end

        if not isTradeConfirmationVisible() then
            return false, "confirmation_disappeared"
        end

        local ok, result = pcall(function()
            return SetConfirmState:InvokeServer(true)
        end)

        if ok and result ~= false then
            State.FinalConfirmed = true

            print(
                "[AutoTrade] Final confirmation sent",
                result ~= nil and ("| result: " .. tostring(result)) or ""
            )

            -- Do not send any trade-chat messages after SetConfirmState.
            -- FinalConfirmation can appear immediately and cover SendMessage.
            return true
        end

        warn(
            "[AutoTrade] SetConfirmState(true) attempt",
            attempt .. "/" .. attempts,
            "failed/rejected:",
            tostring(result)
        )

        if attempt < attempts then
            task.wait(Config.FinalConfirmation.RetryDelay)
        end
    end

    return false, "final_confirm_rejected"
end


-- ================================================================
-- THIRD / FINAL ACCEPT SCREEN
-- ================================================================
-- Cobalt showed that the game's own final green Accept eventually invokes
-- ReplicatedStorage.Trade.FinalizeTrade. V11 does not call that remote itself.
-- It waits for the countdown to finish and physically clicks the live GUI.

local function normalizeFinalizeText(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function getButtonVisibleText(button)
    if not button then
        return ""
    end

    local pieces = {}

    if button:IsA("TextButton") then
        table.insert(pieces, tostring(button.Text or ""))
    end

    for _, object in ipairs(button:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") then
            local value = tostring(object.Text or "")

            if value ~= "" then
                table.insert(pieces, value)
            end
        end
    end

    return table.concat(pieces, " ")
end

local function getExactFinalizeYesButton()
    local _, frame = getTradeGui()

    if not frame then
        return nil
    end

    -- CONFIRMED EXACT PATH:
    -- Players.LocalPlayer.PlayerGui.TradeGui.TradeGui.FinalConfirmation.Yes
    local finalConfirmation =
        frame:FindFirstChild("FinalConfirmation")

    if not finalConfirmation then
        return nil
    end

    local yesButton =
        finalConfirmation:FindFirstChild("Yes")

    if yesButton and yesButton:IsA("GuiButton") then
        return yesButton
    end

    return nil
end

local function getFinalizeYesState(button)
    if not button then
        return "missing", ""
    end

    local visibleText =
        normalizeFinalizeText(
            getButtonVisibleText(button)
        )

    if string.find(visibleText, "waiting for other player", 1, true) then
        return "already_accepted", visibleText
    end

    if string.find(visibleText, "can accept in", 1, true) then
        return "countdown", visibleText
    end

    if visibleText == "accept"
        or string.find(visibleText, "accept", 1, true)
    then
        return "ready", visibleText
    end

    return "unknown", visibleText
end

local function findFinalizeAcceptButton()
    local button = getExactFinalizeYesButton()

    if not button then
        return nil, nil
    end

    return button, normalizeFinalizeText(getButtonVisibleText(button))
end

local function finalizeButtonIsReady(button, visibleText)
    local exact = getExactFinalizeYesButton()

    if not button or not exact or button ~= exact then
        return false
    end

    if not guiObjectActuallyVisible(button) then
        return false
    end

    local state =
        getFinalizeYesState(button)

    if state ~= "ready" then
        return false
    end

    local okActive, active = pcall(function()
        return button.Active
    end)

    if okActive and active == false then
        return false
    end

    local okInteractable, interactable = pcall(function()
        return button.Interactable
    end)

    if okInteractable and interactable == false then
        return false
    end

    return true
end

local function waitForFinalizeButtonReady()
    local started = os.clock()
    local lastText = nil
    local preCountdownAcceptSeenAt = nil

    while os.clock() - started
        < Config.FinalConfirmation.FinalizeReadyTimeout
    do
        if not isTradeOpen() then
            return false, "trade_closed_before_finalize"
        end

        local button = getExactFinalizeYesButton()

        if button and guiObjectActuallyVisible(button) then
            local state, visibleText =
                getFinalizeYesState(button)

            if state == "already_accepted" then
                State.FinalizeButtonReady = true
                State.FinalizeClicked = true

                print(
                    "[AutoTrade] FinalConfirmation.Yes already accepted:",
                    visibleText
                )

                return true, "already_accepted"
            end

            if state == "countdown" then
                if not State.FinalizeCountdownObserved then
                    State.FinalizeCountdownObserved = true
                    print(
                        "[AutoTrade] Final cooldown is now armed; "
                        .. "will only click after this countdown returns to Accept."
                    )
                end

                preCountdownAcceptSeenAt = nil
            elseif state == "ready" then
                -- CRITICAL V17 FIX:
                -- RH briefly exposes FinalConfirmation.Yes as "Accept"
                -- immediately after SetConfirmState(true), BEFORE it starts
                -- the mandatory ~30 second cooldown. That first "Accept" is
                -- transitional and must never be clicked.
                if State.FinalizeCountdownObserved then
                    State.FinalizeButtonReady = true

                    -- We are now at the real post-cooldown Accept state.
                    State.TradeOfferLocked = false
                    disconnectTradeModifiedWatcher()

                    print(
                        "[AutoTrade] REAL post-cooldown FinalConfirmation.Yes is ready:",
                        visibleText
                    )

                    return true, button
                end

                if not preCountdownAcceptSeenAt then
                    preCountdownAcceptSeenAt = os.clock()

                    print(
                        "[AutoTrade] Pre-cooldown Accept observed; waiting for RH countdown to start."
                    )
                end
            end

            if visibleText ~= ""
                and visibleText ~= lastText
            then
                lastText = visibleText

                print(
                    "[AutoTrade] FinalConfirmation.Yes state:",
                    state,
                    "|",
                    visibleText
                )
            end
        end

        task.wait(Config.FinalConfirmation.PollRate)
    end

    return false, "finalize_yes_timeout"
end

local function finalButtonContainsGuiObject(button, object)
    if not button or not object then
        return false
    end

    if object == button then
        return true
    end

    local ok, result = pcall(function()
        return object:IsDescendantOf(button)
    end)

    return ok and result == true
end

local function pointHitsFinalButton(button, x, y)
    local ok, objects = pcall(function()
        return GuiService:GetGuiObjectsAtPosition(
            math.floor(x),
            math.floor(y)
        )
    end)

    if not ok or type(objects) ~= "table" then
        return nil
    end

    for _, object in ipairs(objects) do
        if finalButtonContainsGuiObject(button, object) then
            return true
        end
    end

    return false
end


local function vimClickExactFinalYes(button)
    if not button
        or not button:IsA("GuiButton")
        or button.AbsoluteSize.X <= 0
        or button.AbsoluteSize.Y <= 0
    then
        return false, "invalid_final_yes"
    end

    local position = button.AbsolutePosition
    local size = button.AbsoluteSize

    local rawX = position.X + size.X / 2
    local rawY = position.Y + size.Y / 2

    local inset = Vector2.new(0, 0)

    local insetOK, insetResult = pcall(function()
        return GuiService:GetGuiInset()
    end)

    if insetOK and typeof(insetResult) == "Vector2" then
        inset = insetResult
    end

    -- This matches the coordinate convention already used successfully by
    -- the script's regular VIM GUI clicks. AbsolutePosition is in Roblox GUI
    -- space, while VirtualInputManager mouse input needs the top-bar inset.
    local x = rawX + inset.X
    local y = rawY + inset.Y

    print(
        "[AutoTrade] Final Yes coordinates",
        "| raw:",
        math.floor(rawX),
        math.floor(rawY),
        "| inset:",
        math.floor(inset.X),
        math.floor(inset.Y),
        "| VIM:",
        math.floor(x),
        math.floor(y)
    )

    local ok, err = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.15)

        VirtualInputManager:SendMouseButtonEvent(
            x,
            y,
            0,
            true,
            game,
            0
        )

        task.wait(0.12)

        VirtualInputManager:SendMouseButtonEvent(
            x,
            y,
            0,
            false,
            game,
            0
        )
    end)

    if not ok then
        return false, tostring(err)
    end

    return true
end


local function clickFinalizeTradeViaVIM()
    if not waitForCaptchaClear("final_accept") then
        return false, "captcha_pause_timeout"
    end

    if State.FinalizeClicked then
        return true
    end

    local ready, buttonOrState =
        waitForFinalizeButtonReady()

    if not ready then
        return false, buttonOrState
    end

    if buttonOrState == "already_accepted" then
        return true
    end

    local attempts = math.max(
        1,
        tonumber(
            Config.FinalConfirmation.FinalizeClickAttempts
        ) or 3
    )

    for attempt = 1, attempts do
        if not waitForCaptchaClear("final_accept_retry") then
            return false, "captcha_pause_timeout"
        end

        if not isTradeOpen() then
            return false, "trade_closed_before_finalize_click"
        end

        -- IMPORTANT:
        -- Do NOT use the old TradeModified UI watcher here. We have already
        -- reached FinalConfirmation, which is the game's final server-built
        -- review snapshot. The old watcher could fire during normal UI state
        -- transitions and block the final click.

        local button =
            getExactFinalizeYesButton()

        if not button then
            return false, "final_confirmation_yes_missing"
        end

        local state, visibleText =
            getFinalizeYesState(button)

        if state == "already_accepted" then
            State.FinalizeClicked = true

            print(
                "[AutoTrade] FinalConfirmation.Yes already says:",
                visibleText
            )

            return true
        end

        if state == "countdown" then
            local reReady, refreshed =
                waitForFinalizeButtonReady()

            if not reReady then
                return false, refreshed
            end

            if refreshed == "already_accepted" then
                State.FinalizeClicked = true
                return true
            end

            button = refreshed
            state, visibleText =
                getFinalizeYesState(button)
        end

        if state ~= "ready"
            or not State.FinalizeCountdownObserved
        then
            warn(
                "[AutoTrade] FinalConfirmation.Yes not eligible for final click:",
                tostring(state),
                "| countdownObserved:",
                tostring(State.FinalizeCountdownObserved),
                "|",
                tostring(visibleText)
            )

            local reReady, refreshed =
                waitForFinalizeButtonReady()

            if not reReady then
                return false, refreshed
            end

            if refreshed == "already_accepted" then
                State.FinalizeClicked = true
                return true
            end

            button = refreshed
            state, visibleText =
                getFinalizeYesState(button)

            if state ~= "ready"
                or not State.FinalizeCountdownObserved
            then
                task.wait(Config.FinalConfirmation.FinalizeClickRetryDelay)
                continue
            end
        end

        -- Exact known button:
        -- TradeGui.TradeGui.FinalConfirmation.Yes
        --
        -- V17 proved the state machine is correct, but its RAW y-coordinate
        -- was about one Roblox GUI inset too high. V18 uses the same
        -- AbsolutePosition + GuiInset convention as our already-working
        -- inventory/chat VIM clicks.
        State.FinalizeClickAttempts += 1

        print(
            "[AutoTrade] VIM clicking REAL post-cooldown FinalConfirmation.Yes",
            attempt .. "/" .. attempts,
            "| text:",
            normalizeFinalizeText(
                getButtonVisibleText(button)
            )
        )

        local clicked, clickReason =
            vimClickExactFinalYes(button)

        if clicked then
            local observeStarted = os.clock()

            while os.clock() - observeStarted
                < Config.FinalConfirmation.FinalizePostClickObserve
            do
                if not isTradeOpen() then
                    State.FinalizeClicked = true
                    print("[AutoTrade] Trade closed after final Yes click.")
                    return true
                end

                local current =
                    getExactFinalizeYesButton()

                if not current then
                    State.FinalizeClicked = true
                    print("[AutoTrade] FinalConfirmation.Yes disappeared.")
                    return true
                end

                local currentState, currentText =
                    getFinalizeYesState(current)

                if currentState == "already_accepted" then
                    State.FinalizeClicked = true

                    print(
                        "[AutoTrade] FinalConfirmation.Yes changed to:",
                        currentText
                    )

                    return true
                end

                task.wait(0.10)
            end
        else
            warn(
                "[AutoTrade] Final Yes VIM input call failed:",
                tostring(clickReason)
            )
        end

        if attempt < attempts then
            task.wait(
                Config.FinalConfirmation.FinalizeClickRetryDelay
            )
        end
    end

    return false, "final_confirmation_yes_vim_failed"
end

local function readPostTradeDiamondBalance()
    if State.DiamondBalanceObject
        and State.DiamondBalanceObject.Parent
    then
        return parseNumber(State.DiamondBalanceObject.Text)
    end

    local value = findCurrentDiamondBalance()
    return value
end

local function postTradeVerificationMatches(snapshot)
    local pre = State.PreTradeSnapshot

    if not pre or not snapshot then
        return false, "snapshot_missing"
    end

    if type(pre.Items) ~= "table"
        or type(snapshot.Items) ~= "table"
    then
        return false, "item_snapshot_missing"
    end

    for itemName, sentCount in pairs(State.ItemOfferPlan or {}) do
        local before = tonumber(pre.Items[itemName]) or 0
        local after = tonumber(snapshot.Items[itemName]) or 0
        local expected = before - sentCount

        if after ~= expected then
            return false,
                "item_delta_"
                .. itemName
                .. "_expected_"
                .. tostring(expected)
                .. "_got_"
                .. tostring(after)
        end
    end

    if Config.OfferAllDiamonds
        and pre.Diamonds ~= nil
        and State.DiamondOfferAmount ~= nil
        and snapshot.Diamonds ~= nil
    then
        local expected =
            math.max(
                0,
                tonumber(pre.Diamonds)
                - tonumber(State.DiamondOfferAmount)
            )

        if tonumber(snapshot.Diamonds) ~= expected then
            return false,
                "diamond_delta_expected_"
                .. tostring(expected)
                .. "_got_"
                .. tostring(snapshot.Diamonds)
        end
    end

    return true
end

local function verifyPostTrade()
    if not Config.Reliability.PostTradeVerify then
        return true, "verification_disabled"
    end

    local started = os.clock()
    local lastReason = "not_checked"

    while os.clock() - started
        < Config.Reliability.PostTradeVerifyTimeout
    do
        local inventorySnapshot =
            snapshotConfiguredInventory()

        if inventorySnapshot then
            inventorySnapshot.Diamonds =
                readPostTradeDiamondBalance()

            State.PostTradeSnapshot =
                inventorySnapshot

            local ok, reason =
                postTradeVerificationMatches(
                    inventorySnapshot
                )

            if ok then
                print(
                    "[AutoTrade] Post-trade inventory/diamond verification passed."
                )
                return true, "verified"
            end

            lastReason = reason
        else
            lastReason = "inventory_snapshot_unavailable"
        end

        task.wait(
            Config.Reliability.PostTradeVerifyPollRate
        )
    end

    return false, lastReason
end

local function waitForTradeCompletion()
    local started = os.clock()

    while os.clock() - started < Config.FinalConfirmation.CompletionTimeout do
        if not isTradeOpen() then
            State.TradeFinished = true
            State.TradeOfferLocked = false
            disconnectTradeModifiedWatcher()

            print("[AutoTrade] Trade window closed after final VIM Accept.")

            -- Give inventory/balance replication a moment before verification.
            task.wait(1.00)

            local verified, reason =
                verifyPostTrade()

            if verified then
                markCompleted("post_trade_verified")
                return true
            end

            quarantine(
                "post_trade_verification_failed_"
                .. tostring(reason)
            )
            return false
        end

        task.wait(Config.FinalConfirmation.PollRate)
    end

    warn(
        "[AutoTrade] Still waiting for the other party/final trade completion."
    )

    return false
end

local function acceptTradeOffer()
    if State.Accepted then
        return true
    end

    if Config.OfferAllDiamonds and not State.DiamondsOffered then
        warn("[AutoTrade] Refusing to accept: diamonds are not confirmed.")
        return false
    end

    if Config.RequireItemsBeforeAccept and not State.ItemsOffered then
        warn("[AutoTrade] Refusing to accept: items are not confirmed.")
        return false
    end

    if not tradeGuiMatchesTarget(State.Target) then
        quarantine("recipient_lock_failed_before_accept")
        return false
    end

    local offerOK, offerReason = verifyLockedOffer()
    if not offerOK then
        quarantine("pre_accept_offer_verification_failed_" .. tostring(offerReason))
        return false
    end

    -- Arm only AFTER our own diamond/item changes are complete. Any later
    -- TradeModified signal is therefore treated as a changed counterparty/
    -- unexpected trade state and blocks final confirmation.
    armTradeModifiedWatcher()

    sendStageChat("Ready")
    sendStageChat("Accepting")

    local ok, err = pcall(function()
        AcceptOffer:FireServer()
    end)

    if not ok then
        warn("[AutoTrade] AcceptOffer failed:", err)
        return false
    end

    State.Accepted = true
    State.SenderLastAcceptAt = os.clock()
    State.SenderReacceptCount = 0
    State.TradeModifiedAfterLock = false
    State.TradeModifiedAt = nil

    -- Fifth core trade message: only sent after our initial offer acceptance
    -- actually succeeds.
    sendStageChat("PostAccept")

    print(
        "[AutoTrade] Initial AcceptOffer sent. "
        .. "Waiting for the other party to accept..."
    )

    -- IMPORTANT:
    -- SetConfirmState(true) is NOT sent immediately.
    -- We wait until TradeGui.TradeGui.TradeConfirmation is actually visible,
    -- which is the second confirmation stage shown after the offer stage.
    local confirmationReady, confirmationReason =
        waitForTradeConfirmation()

    if not confirmationReady then
        warn(
            "[AutoTrade] Final confirmation stage was not reached:",
            tostring(confirmationReason)
        )
        return false
    end

    local confirmed, confirmReason =
        setFinalConfirmState()

    if not confirmed then
        warn(
            "[AutoTrade] Could not set confirmation state:",
            tostring(confirmReason)
        )
        return false
    end

    -- SetConfirmState(true) only advances us to Royale High's timed
    -- Accept/Decline screen. Wait for the countdown and click the real green
    -- Accept with VirtualInputManager.
    local finalized, finalizeReason =
        clickFinalizeTradeViaVIM()

    if not finalized then
        warn(
            "[AutoTrade] Could not complete final VIM Accept:",
            tostring(finalizeReason)
        )

        if Config.FinalConfirmation.QuarantineOnFinalizeClickFailure then
            quarantine(
                "finalize_vim_failed_"
                .. tostring(finalizeReason)
            )
        else
            State.TerminalReason =
                "finalize_vim_failed_"
                .. tostring(finalizeReason)

            warn(
                "[AutoTrade] Final VIM failure was NOT quarantined. "
                .. "The script stops this run so the same trade is not duplicated."
            )
        end

        return false
    end

    -- From here the game's own GUI code should handle the finalization remote.
    local completed =
        waitForTradeCompletion()

    return completed == true
end

-- ================================================================
-- QUEUE / REQUEST STATE
-- ================================================================

local function getQueueSlot()
    local slots = math.max(1, tonumber(Config.QueueSlots) or 20)
    return math.abs(tonumber(LocalPlayer.UserId) or 0) % slots
end

local function waitInitialQueueSlot()
    local slot = getQueueSlot()
    local spacing = math.max(0, tonumber(Config.InitialSlotSpacing) or 0.80)
    local delay = slot * spacing

    if delay > 0 then
        print(
            "[AutoTrade] Queue slot",
            slot,
            "| initial wait",
            string.format("%.2fs", delay)
        )

        task.wait(delay)
    end
end

local function waitBusyRetry()
    local slot = getQueueSlot()

    local delay =
        math.max(0, tonumber(Config.BusyRetryBase) or 5)
        + slot * math.max(0, tonumber(Config.BusyRetrySlotSpacing) or 0.25)

    print(
        "[AutoTrade] Receiver/sender busy. Retrying in",
        string.format("%.2fs", delay)
    )

    task.wait(delay)
end

local BUSY_ERRORS = {
    sender_already_in_trade = true,
    receiver_already_in_trade = true,
    other_player_already_in_trade = true
}

local SENDER_TRADE_RESTRICTION_ERRORS = {
    sender_banned_from_trading = true,
    sender_is_suspicious = true
}

local TERMINAL_ERRORS = {
    player_too_low_level = true,
    trading_player_too_low_level = true,
    receiver_disabled_trade_requests = true,
    receiver_banned_from_trading = true,
    receiver_is_suspicious = true
}

local function invokeTradeRequest(target)
    if not waitForCaptchaClear("send_trade_request") then
        return "error", "captcha_pause_timeout"
    end

    local ok, result = pcall(function()
        return MakeTradeRequest:InvokeServer(target)
    end)

    if not ok then
        return "invoke_error", tostring(result)
    end

    if type(result) == "table" and result.error then
        local err = tostring(result.error)

        if BUSY_ERRORS[err] then
            return "busy", err
        end

        if SENDER_TRADE_RESTRICTION_ERRORS[err] then
            return "sender_trade_restricted", err
        end

        if TERMINAL_ERRORS[err] then
            return "terminal", err
        end

        return "error", err
    end

    return "sent", result
end

local function waitForTradeOpen(timeout)
    local started = os.clock()

    while os.clock() - started < timeout do
        if isTradeOpen() then
            return true
        end

        task.wait(Config.PollRate)
    end

    return false
end

-- ================================================================
-- TRADE WORKFLOW
-- ================================================================

local function runActiveTrade(target)
    State.Target = target
    State.TradeOpened = true

    task.wait(Config.ChatOpenDelay)

    if not tradeGuiMatchesTarget(target) then
        quarantine("recipient_lock_failed_on_trade_open")
        return false
    end

    sendStageChat("Open")
    State.GreetingSent = true

    if not offerAllDiamonds() then
        warn("[AutoTrade] Diamond stage failed; trade left unaccepted.")
        return false
    end

    if not offerConfiguredItems() then
        warn("[AutoTrade] Item stage incomplete; trade left unaccepted.")
        return false
    end

    return acceptTradeOffer()
end


-- ================================================================
-- RECEIVER MODE
-- ================================================================

local function normalizeRuntimeName(value)
    return string.lower(tostring(value or ""))
end

local function receiverAccountMatchesConfiguredTarget()
    if Config.TargetUserId
        and LocalPlayer.UserId == Config.TargetUserId
    then
        return true
    end

    return
        normalizeRuntimeName(LocalPlayer.Name)
        == normalizeRuntimeName(Config.TargetUsername)
end

local function detectRuntimeMode()
    local requested =
        normalizeRuntimeName(Config.Mode)

    if requested == "receiver" then
        return "receiver"
    end

    if requested == "sender" then
        return "sender"
    end

    if receiverAccountMatchesConfiguredTarget() then
        return "receiver"
    end

    return "sender"
end

local function receiverSenderAllowed(sender)
    if not sender or sender == LocalPlayer then
        return false
    end

    local allowed =
        Config.Receiver.AllowedSenders

    if type(allowed) ~= "table"
        or #allowed == 0
    then
        return true
    end

    local wantedName =
        normalizeRuntimeName(sender.Name)

    local wantedId =
        tonumber(sender.UserId)

    for _, entry in ipairs(allowed) do
        if tonumber(entry)
            and tonumber(entry) == wantedId
        then
            return true
        end

        if normalizeRuntimeName(entry)
            == wantedName
        then
            return true
        end
    end

    return false
end

local function disconnectReceiverConnections()
    for _, connection in ipairs(State.ReceiverConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    State.ReceiverConnections = {}
end

local function disconnectReceiverChatConnections()
    for _, connection in ipairs(State.ReceiverChatConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    State.ReceiverChatConnections = {}
end

local function resetReceiverTradeState(sender)
    disconnectReceiverConnections()
    disconnectReceiverChatConnections()

    State.Target = sender
    State.ReceiverSender = sender
    State.ReceiverDiamondAmount = nil
    State.ReceiverReacceptCount = 0
    State.ReceiverLastAcceptAt = 0
    State.ReceiverAcceptWatchdogRetries = 0
    State.ReceiverOfferModifiedAt = nil
    State.ReceiverOfferModificationPending = false
    State.ReceiverChatReplies = 0
    State.ReceiverLastChatReplyAt = 0

    State.TradeOpened = false
    State.DiamondsOffered = false
    State.DiamondOfferAmount = nil
    State.DiamondBalanceObject = nil
    State.DiamondOfferDisplayObject = nil

    -- Receiver gets a fresh 10-20 item manifest for every sender.
    State.ManifestLocked = false
    State.ItemOfferPlan = nil
    State.ItemOfferSequence = nil
    State.ItemOfferTargetCount = 0
    State.ItemOfferAddedCount = 0
    State.ItemsOffered = false

    State.Accepted = false
    State.ConfirmationVisible = false
    State.FinalConfirmed = false
    State.FinalizeButtonReady = false
    State.FinalizeCountdownObserved = false
    State.FinalizeClicked = false
    State.FinalizeClickAttempts = 0
    State.TradeFinished = false

    State.ChatMessagesSent = 0
    State.ChatUsedMessages = {}
end

local function receiverSendChat(message)
    if not Config.Receiver.ChatEnabled
        or not message
        or message == ""
    then
        return true
    end

    if isFinalConfirmationOverlayVisible() then
        return false
    end

    local ok, reason =
        typeIntoTradeChat(message)

    if ok then
        print("[AutoTrade][Receiver] Chat:", message)
        return true
    end

    warn(
        "[AutoTrade][Receiver] Chat failed:",
        tostring(reason)
    )

    return false
end

local function receiverBuildReply(message)
    local text =
        normalizeRuntimeName(message)

    if string.find(text, "wait", 1, true)
        or string.find(text, "sec", 1, true)
        or string.find(text, "moment", 1, true)
    then
        return "no worries, take your time"
    end

    if string.find(text, "ready", 1, true)
        or string.find(text, "accept", 1, true)
        or string.find(text, "done", 1, true)
    then
        return "yep, i'm ready on my side too"
    end

    if string.find(text, "diamond", 1, true)
        or string.find(text, "item", 1, true)
        or string.find(text, "offer", 1, true)
    then
        return "got it, i can see the offer"
    end

    if string.find(text, "thank", 1, true)
        or text == "ty"
        or string.find(text, "ty ", 1, true)
    then
        return "you're good"
    end

    return "got it"
end

local function receiverMaybeReply(sender, message)
    if not Config.Receiver.ChatEnabled
        or not sender
        or sender ~= State.ReceiverSender
        or not isTradeOpen()
        or isFinalConfirmationOverlayVisible()
    then
        return
    end

    if State.ReceiverChatReplies
        >= Config.Receiver.MaxChatReplies
    then
        return
    end

    local now = os.clock()

    if now - State.ReceiverLastChatReplyAt
        < Config.Receiver.ChatReplyCooldown
    then
        return
    end

    State.ReceiverLastChatReplyAt = now
    State.ReceiverChatReplies += 1

    local reply =
        receiverBuildReply(message)

    task.spawn(function()
        receiverSendChat(reply)
    end)
end

local function bindReceiverIncomingChat(sender)
    disconnectReceiverChatConnections()

    for _, remote in ipairs(TradeChatFolder:GetDescendants()) do
        if remote:IsA("RemoteEvent")
            and string.find(
                normalizeRuntimeName(remote.Name),
                "message",
                1,
                true
            )
            and normalizeRuntimeName(remote.Name)
                ~= "sendmessage"
        then
            local connection =
                remote.OnClientEvent:Connect(
                    function(...)
                        local args = {...}
                        local fromSender = false
                        local message = nil

                        for _, value in ipairs(args) do
                            if typeof(value) == "Instance"
                                and value:IsA("Player")
                                and value == sender
                            then
                                fromSender = true
                            elseif type(value) == "string"
                                and value ~= ""
                            then
                                message = value

                                if string.find(
                                    normalizeRuntimeName(value),
                                    normalizeRuntimeName(sender.Name),
                                    1,
                                    true
                                ) then
                                    fromSender = true
                                end
                            end
                        end

                        if fromSender and message then
                            receiverMaybeReply(
                                sender,
                                message
                            )
                        end
                    end
                )

            table.insert(
                State.ReceiverChatConnections,
                connection
            )

            print(
                "[AutoTrade][Receiver] Bound incoming chat remote:",
                remote:GetFullName()
            )
        end
    end
end

local function normalizeReceiverDiamondOptions()
    local values = {}

    for _, raw in ipairs(
        Config.Receiver.DiamondOptions or {}
    ) do
        local amount =
            tonumber(raw)

        if amount then
            amount =
                math.floor(amount / 1000) * 1000

            if amount >= 2000
                and amount <= 5000
            then
                local duplicate = false

                for _, existing in ipairs(values) do
                    if existing == amount then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then
                    table.insert(values, amount)
                end
            end
        end
    end

    table.sort(values)

    if #values == 0 then
        values = {
            2000,
            3000,
            4000,
            5000
        }
    end

    return values
end

local function chooseReceiverDiamondAmount(sender, balance)
    balance =
        math.floor(
            tonumber(balance)
            or 0
        )

    if balance < 2000 then
        return nil, "receiver_balance_below_2000"
    end

    local fixed =
        tonumber(
            Config.Receiver.FixedDiamondAmount
        )

    if fixed then
        fixed =
            math.floor(fixed / 1000) * 1000

        fixed =
            math.max(
                2000,
                math.min(5000, fixed)
            )

        if fixed <= balance then
            return fixed
        end
    end

    local options =
        normalizeReceiverDiamondOptions()

    local affordable = {}

    for _, amount in ipairs(options) do
        if amount <= balance then
            table.insert(affordable, amount)
        end
    end

    if #affordable == 0 then
        return nil, "no_affordable_receiver_diamond_option"
    end

    -- Deterministic by sender account. This keeps the selected rounded
    -- amount stable for the same sender instead of randomizing it.
    local senderId =
        math.abs(
            tonumber(sender and sender.UserId)
            or 0
        )

    local index =
        (senderId % #affordable) + 1

    return affordable[index]
end

local function setReceiverDiamondOffer(sender)
    if not waitForCaptchaClear("receiver_diamonds") then
        return false, "captcha_pause_timeout"
    end

    local _, frame =
        getTradeGui()

    if not frame or not isTradeOpen() then
        return false, "trade_not_open"
    end

    local diamondBox =
        frame:FindFirstChild("DiamondAmount")

    if not diamondBox
        or not diamondBox:IsA("TextBox")
    then
        return false, "diamond_box_missing"
    end

    local balance, balanceObject =
        findCurrentDiamondBalance()

    if balance == nil then
        return false, "diamond_balance_unknown"
    end

    local amount, amountReason =
        chooseReceiverDiamondAmount(
            sender,
            balance
        )

    if not amount then
        return false, amountReason
    end

    State.DiamondBalanceObject =
        balanceObject

    State.ReceiverDiamondAmount =
        amount

    State.DiamondOfferAmount =
        amount

    local typed, reason =
        typeFocusedTextBox(
            diamondBox,
            tostring(amount),
            true
        )

    if not typed then
        return false, reason
    end

    sendKey(Enum.KeyCode.Return)
    task.wait(Config.DiamondSettleDelay)

    local boxAmount =
        parseNumber(diamondBox.Text)

    if boxAmount ~= amount then
        return false,
            "receiver_diamond_box_mismatch_"
            .. tostring(boxAmount)
    end

    local displayVerified, displayObject =
        waitForDiamondOfferDisplay(amount)

    if displayVerified then
        State.DiamondOfferDisplayObject =
            displayObject
    end

    State.DiamondsOffered = true

    print(
        "[AutoTrade][Receiver] Diamond offer:",
        amount,
        "| balance:",
        balance
    )

    return true, amount
end

local function receiverBuildItemManifest()
    local plan, sequenceOrReason =
        buildRandomItemOfferPlan()

    if not plan then
        return false, sequenceOrReason
    end

    State.ManifestLocked = true

    print(
        "[AutoTrade][Receiver] Item manifest locked:",
        State.ItemOfferTargetCount,
        "item(s)"
    )

    return true, State.ItemOfferSequence
end

local function receiverOfferConfiguredItems()
    if not waitForCaptchaClear("receiver_items") then
        return false, "captcha_pause_timeout"
    end

    local plan =
        State.ItemOfferPlan

    local sequence =
        State.ItemOfferSequence

    if type(plan) ~= "table"
        or type(sequence) ~= "table"
        or #sequence == 0
    then
        return false, "receiver_item_manifest_missing"
    end

    local inventoryOK, inventoryResult =
        pcall(function()
            return GetTradeInventoryCategoryItems:InvokeServer(
                "Show All",
                nil
            )
        end)

    if not inventoryOK then
        return false,
            "receiver_inventory_refresh_failed_"
            .. tostring(inventoryResult)
    end

    task.wait(0.40)

    receiverSendChat(
        "adding my items now"
    )

    print(
        "[AutoTrade][Receiver] Adding",
        #sequence,
        "configured item copies..."
    )

    local previousItem = nil

    for index, itemName in ipairs(sequence) do
        if not waitForCaptchaClear("receiver_item_loop") then
            State.ItemsOffered = false
            return false, "captcha_pause_timeout"
        end

        if not isTradeOpen() then
            State.ItemsOffered = false
            return false, "trade_closed_while_receiver_adding_items"
        end

        if previousItem
            and previousItem ~= itemName
            and Config.RandomOffer.BetweenItemTypesDelay > 0
        then
            task.wait(
                Config.RandomOffer.BetweenItemTypesDelay
            )
        end

        local added, method, replicatedCount =
            addOneTradeItemByNormalClick(itemName)

        if not added then
            State.ItemsOffered = false

            warn(
                "[AutoTrade][Receiver] Failed to add item",
                index .. "/" .. #sequence,
                itemName,
                "|",
                tostring(method)
            )

            return false,
                "receiver_add_item_failed_"
                .. tostring(itemName)
                .. "_"
                .. tostring(method)
        end

        State.ItemOfferAddedCount += 1

        print(
            "[AutoTrade][Receiver] Added + verified",
            index .. "/" .. #sequence,
            itemName,
            "| MyItems:",
            tostring(replicatedCount),
            "|",
            tostring(method)
        )

        previousItem = itemName

        if index < #sequence then
            task.wait(
                Config.RandomOffer.ItemClickDelay
            )
        end
    end

    local visiblePlannedTotal =
        countTotalPlannedItemsPresent(plan)

    State.ItemsOffered =
        State.ItemOfferAddedCount
            == State.ItemOfferTargetCount
        and visiblePlannedTotal
            == State.ItemOfferTargetCount

    if not State.ItemsOffered then
        return false,
            "receiver_item_offer_verification_mismatch"
    end

    for itemName, expectedCount in pairs(plan) do
        local actualCount =
            countMyOfferedItemCopies(itemName)
            or 0

        if actualCount < expectedCount then
            State.ItemsOffered = false

            return false,
                "receiver_item_count_mismatch_"
                .. tostring(itemName)
        end
    end

    print(
        "[AutoTrade][Receiver] Finished adding + verifying",
        State.ItemOfferAddedCount,
        "item copies."
    )

    return true
end

local function receiverCountPartnerItemCards()
    local _, frame =
        getTradeGui()

    local container =
        frame and frame:FindFirstChild(
            "TradingPlayerItems"
        )

    if not container then
        return 0
    end

    local count = 0

    for _, object in ipairs(container:GetChildren()) do
        if object:IsA("GuiObject")
            and object.Visible
            and object.AbsoluteSize.X > 0
            and object.AbsoluteSize.Y > 0
        then
            count += 1
        end
    end

    return count
end

local function receiverPartnerOfferReady()
    local minimum =
        math.max(
            0,
            math.floor(
                tonumber(
                    Config.Receiver.MinPartnerItemCards
                )
                or 1
            )
        )

    if minimum <= 0 then
        return true
    end

    local count =
        receiverCountPartnerItemCards()

    if count < minimum then
        print(
            "[AutoTrade][Receiver] Waiting for sender items:",
            count .. "/" .. minimum
        )
        return false
    end

    return true
end

local receiverFireAcceptOffer

local function receiverOtherPartyAccepted()
    local _, frame =
        getTradeGui()

    if not frame then
        return false, "trade_gui_missing"
    end

    -- Confirmed from the live TradeGui dump: Player2Accept is the OTHER
    -- player's acceptance label on this client's screen.
    local label =
        frame:FindFirstChild("Player2Accept")

    if not label
        or not (label:IsA("TextLabel") or label:IsA("TextButton"))
    then
        return false, "player2_accept_label_missing"
    end

    local value =
        string.lower(
            tostring(label.Text or "")
        )

    local accepted =
        string.find(value, "accept", 1, true) ~= nil
        and string.find(value, "✅", 1, true) ~= nil

    return accepted, value
end

local function receiverAcceptWatchdogTick()
    if not Config.Receiver.AcceptWatchdogEnabled
        or not isTradeOpen()
        or isTradeConfirmationVisible()
        or captchaChallengeVisible()
    then
        return false, "watchdog_not_applicable"
    end

    local otherAccepted, otherText =
        receiverOtherPartyAccepted()

    if not otherAccepted then
        return false, "other_not_accepted"
    end

    local now = os.clock()

    if now - (State.ReceiverLastAcceptAt or 0)
        < Config.Receiver.AcceptWatchdogDelay
    then
        return false, "watchdog_gap"
    end

    if State.ReceiverAcceptWatchdogRetries
        >= Config.Receiver.AcceptWatchdogMaxRetries
    then
        return false, "watchdog_retry_limit"
    end

    -- Other party is checked, but we're STILL on the offer screen. If our
    -- receiver checkbox were actually checked too, RH should have advanced.
    -- This recovers the exact screenshot state where Player2Accept is green
    -- but the receiver's own checkbox is blank.
    State.ReceiverAcceptWatchdogRetries += 1

    print(
        "[AutoTrade][Receiver] Accept watchdog retry",
        State.ReceiverAcceptWatchdogRetries
            .. "/"
            .. Config.Receiver.AcceptWatchdogMaxRetries,
        "| other:",
        tostring(otherText)
    )

    local accepted =
        receiverFireAcceptOffer(
            "partner_accepted_watchdog"
        )

    if accepted then
        State.ReceiverLastAcceptAt = os.clock()
        return true, "watchdog_accept_sent"
    end

    return false, "watchdog_accept_failed"
end

receiverFireAcceptOffer = function(reason)
    if not waitForCaptchaClear("receiver_accept_offer") then
        return false
    end

    if not isTradeOpen()
        or isTradeConfirmationVisible()
    then
        return false
    end

    if not receiverPartnerOfferReady() then
        return false
    end

    State.ReceiverLastAcceptAt = os.clock()

    local ok, err = pcall(function()
        AcceptOffer:FireServer()
    end)

    if not ok then
        warn(
            "[AutoTrade][Receiver] AcceptOffer failed:",
            tostring(err)
        )
        return false
    end

    State.Accepted = true

    print(
        "[AutoTrade][Receiver] AcceptOffer sent",
        "| reason:",
        tostring(reason or "initial")
    )

    return true
end

local function bindReceiverOfferModificationWatcher()
    disconnectReceiverConnections()

    local _, frame =
        getTradeGui()

    if not frame then
        return false
    end

    local function markReceiverOfferChanged(source)
        if not isTradeOpen()
            or isTradeConfirmationVisible()
        then
            return
        end

        State.ReceiverOfferModifiedAt =
            os.clock()

        State.ReceiverOfferModificationPending =
            true

        -- RH clears our offer-stage check when either side edits the offer.
        State.Accepted = false

        print(
            "[AutoTrade][Receiver] Offer changed; receiver acceptance is stale.",
            "| source:",
            tostring(source or "unknown")
        )
    end

    local function watch(object)
        if not object then
            return
        end

        local connection =
            object.Changed:Connect(function()
                markReceiverOfferChanged(
                    object.Name
                )
            end)

        table.insert(
            State.ReceiverConnections,
            connection
        )
    end

    watch(frame:FindFirstChild("TradeModified"))
    watch(frame:FindFirstChild("TradeModifiedNotice"))

    -- Extra direct coverage for manual receiver edits after initial accept.
    local myItems =
        frame:FindFirstChild("MyItems")

    if myItems then
        table.insert(
            State.ReceiverConnections,
            myItems.ChildAdded:Connect(function()
                markReceiverOfferChanged("MyItems.ChildAdded")
            end)
        )

        table.insert(
            State.ReceiverConnections,
            myItems.ChildRemoved:Connect(function()
                markReceiverOfferChanged("MyItems.ChildRemoved")
            end)
        )
    end

    local diamondBox =
        frame:FindFirstChild("DiamondAmount")

    if diamondBox and diamondBox:IsA("TextBox") then
        table.insert(
            State.ReceiverConnections,
            diamondBox:GetPropertyChangedSignal("Text"):Connect(function()
                markReceiverOfferChanged("DiamondAmount.Text")
            end)
        )
    end

    return true
end

local function receiverWaitAndMaintainAccept()
    local started = os.clock()
    local lastAcceptAt =
        tonumber(State.ReceiverLastAcceptAt)
        or 0

    local reacceptChatSent = false

    if not State.Accepted then
        if receiverFireAcceptOffer("initial") then
            lastAcceptAt = os.clock()
            State.ReceiverLastAcceptAt = lastAcceptAt
            State.ReceiverOfferModificationPending = false
            State.ReceiverOfferModifiedAt = nil
        end
    end

    while os.clock() - started
        < Config.FinalConfirmation.WaitTimeout
    do
        if not isTradeOpen() then
            return false, "trade_closed_before_confirmation"
        end

        if isTradeConfirmationVisible() then
            State.ConfirmationVisible = true
            disconnectReceiverConnections()

            print(
                "[AutoTrade][Receiver] TradeConfirmation reached."
            )

            return true
        end

        -- Do not trust the local State.Accepted flag as authoritative.
        -- If the partner is visibly accepted and this screen has not advanced,
        -- the receiver checkbox is still unchecked/reset and needs another
        -- AcceptOffer attempt.
        receiverAcceptWatchdogTick()

        if State.ReceiverOfferModificationPending
            and State.ReceiverOfferModifiedAt
        then
            local now = os.clock()

            if now - State.ReceiverOfferModifiedAt
                    >= Config.Receiver.ReacceptStabilityDelay
                and now - lastAcceptAt
                    >= Config.Receiver.ReacceptMinGap
            then
                if State.ReceiverReacceptCount
                    >= Config.Receiver.MaxReaccepts
                then
                    return false, "receiver_reaccept_limit"
                end

                if receiverFireAcceptOffer(
                    "offer_modified"
                ) then
                    State.ReceiverReacceptCount += 1
                    lastAcceptAt = now
                    State.ReceiverLastAcceptAt = now
                    State.ReceiverOfferModificationPending = false
                    State.ReceiverOfferModifiedAt = nil
                    State.Accepted = true

                    print(
                        "[AutoTrade][Receiver] Re-accepted after offer update",
                        State.ReceiverReacceptCount
                            .. "/"
                            .. Config.Receiver.MaxReaccepts
                    )

                    if not reacceptChatSent then
                        reacceptChatSent = true
                        receiverSendChat(
                            "reaccepted after the update"
                        )
                    end
                end
            end
        end

        task.wait(Config.PollRate)
    end

    return false, "receiver_confirmation_timeout"
end

local function receiverSetFinalConfirmState()
    if not waitForCaptchaClear("receiver_confirm_state") then
        return false, "captcha_pause_timeout"
    end

    if not isTradeConfirmationVisible() then
        return false, "confirmation_not_visible"
    end

    local attempts =
        math.max(
            1,
            tonumber(
                Config.FinalConfirmation.InvokeAttempts
            )
            or 2
        )

    for attempt = 1, attempts do
        local ok, result =
            pcall(function()
                return SetConfirmState:InvokeServer(true)
            end)

        if ok and result ~= false then
            State.FinalConfirmed = true

            print(
                "[AutoTrade][Receiver] Final confirmation sent",
                result ~= nil
                    and ("| result: " .. tostring(result))
                    or ""
            )

            return true
        end

        warn(
            "[AutoTrade][Receiver] SetConfirmState attempt",
            attempt .. "/" .. attempts,
            "failed:",
            tostring(result)
        )

        if attempt < attempts then
            task.wait(
                Config.FinalConfirmation.RetryDelay
            )
        end
    end

    return false, "receiver_final_confirm_rejected"
end

local function receiverWaitForTradeClose()
    local started = os.clock()

    while os.clock() - started
        < Config.FinalConfirmation.CompletionTimeout
    do
        if not isTradeOpen() then
            State.TradeFinished = true

            print(
                "[AutoTrade][Receiver] Trade window closed; "
                .. "receiver cycle completed."
            )

            return true
        end

        task.wait(
            Config.FinalConfirmation.PollRate
        )
    end

    return false
end

local function runReceiverActiveTrade(sender)
    resetReceiverTradeState(sender)

    if not waitForTradeOpen(
        Config.Receiver.TradeOpenTimeout
    ) then
        return false, "receiver_trade_open_timeout"
    end

    State.TradeOpened = true

    if not tradeGuiMatchesTarget(sender) then
        warn(
            "[AutoTrade][Receiver] Trade opened, but partner lock "
            .. "did not match expected sender:",
            sender.Name
        )
        return false, "receiver_partner_mismatch"
    end

    print(
        "[AutoTrade][Receiver] Trade opened with:",
        sender.Name
    )

    bindReceiverIncomingChat(sender)

    task.wait(Config.ChatOpenDelay)

    receiverSendChat(
        "got it, i'll add my side now"
    )

    -- Build a fresh 10-20 item manifest from the configured safe pool.
    local manifestOK, manifestReason =
        receiverBuildItemManifest()

    if not manifestOK then
        warn(
            "[AutoTrade][Receiver] Item manifest failed:",
            tostring(manifestReason)
        )
        return false, manifestReason
    end

    local itemsOK, itemsReason =
        receiverOfferConfiguredItems()

    if not itemsOK then
        warn(
            "[AutoTrade][Receiver] Item stage failed:",
            tostring(itemsReason)
        )
        return false, itemsReason
    end

    local diamondOK, diamondResult =
        setReceiverDiamondOffer(sender)

    if not diamondOK then
        warn(
            "[AutoTrade][Receiver] Diamond stage failed:",
            tostring(diamondResult)
        )
        return false, diamondResult
    end

    receiverSendChat(
        "i added "
        .. tostring(State.ItemOfferAddedCount)
        .. " items and "
        .. formatDiamondAmount(
            State.ReceiverDiamondAmount
        )
        .. " diamonds on my side"
    )

    -- Bind AFTER our automated item + diamond changes so those 10-20 setup
    -- edits do not produce repeated re-accepts. From this point onward, any
    -- sender edit OR manual receiver edit marks the checkbox stale.
    bindReceiverOfferModificationWatcher()

    -- Critical V29 behavior:
    -- If the sender accepted BEFORE we finished adding our diamonds/items,
    -- RH reset the offer-stage checkboxes. Explicitly accept our finalized
    -- receiver offer here, immediately after our own last change.
    task.wait(
        Config.Receiver.ReacceptStabilityDelay
    )

    if not receiverFireAcceptOffer(
        "own_offer_complete_after_items_and_diamonds"
    ) then
        return false, "receiver_initial_reaccept_failed"
    end

    State.ReceiverLastAcceptAt = os.clock()
    State.ReceiverOfferModificationPending = false
    State.ReceiverOfferModifiedAt = nil
    State.Accepted = true

    print(
        "[AutoTrade][Receiver] Receiver AcceptOffer sent after final "
        .. "item/diamond offer; acceptance watchdog armed."
    )

    receiverSendChat(
        "i'm ready on my side"
    )

    local confirmationOK, confirmationReason =
        receiverWaitAndMaintainAccept()

    if not confirmationOK then
        return false, confirmationReason
    end

    receiverSendChat(
        "final confirmation is up on my side"
    )

    local confirmOK, confirmReason =
        receiverSetFinalConfirmState()

    if not confirmOK then
        return false, confirmReason
    end

    -- Reuse the V18/V22 exact FinalConfirmation.Yes + GuiInset path.
    local finalized, finalizeReason =
        clickFinalizeTradeViaVIM()

    if not finalized then
        return false, finalizeReason
    end

    local completed =
        receiverWaitForTradeClose()

    disconnectReceiverConnections()
    disconnectReceiverChatConnections()

    return completed == true,
        completed and "completed" or "receiver_completion_timeout"
end

local processReceiverRequestQueue
local receiverQueueIncomingRequest
local removeReceiverQueuedSender
local startReceiverTradeWorker

removeReceiverQueuedSender = function(sender)
    if not sender then
        return false
    end

    local userId =
        tonumber(sender.UserId)

    local removed = false

    for index = #State.ReceiverRequestQueue, 1, -1 do
        local entry =
            State.ReceiverRequestQueue[index]

        if entry
            and tonumber(entry.UserId) == userId
        then
            table.remove(
                State.ReceiverRequestQueue,
                index
            )

            removed = true
        end
    end

    State.ReceiverRequestQueuedByUserId[userId] =
        nil

    for index, queued in ipairs(
        State.ReceiverRequestQueue
    ) do
        queued.PositionHint = index
    end

    return removed
end

local function getReceiverRequestInner()
    local screen =
        PlayerGui:FindFirstChild("TradeGui")

    local frame =
        screen and screen:FindFirstChild("TradeGui")

    local requests =
        frame and frame:FindFirstChild("TradeRequests")

    return
        requests and requests:FindFirstChild("Inner")
end

local function receiverFindRequestCardsForSender(sender)
    local inner =
        getReceiverRequestInner()

    local results = {}

    if not inner or not sender then
        return results
    end

    for _, card in ipairs(inner:GetChildren()) do
        local playerValue =
            card:FindFirstChild("Player")

        if playerValue
            and playerValue:IsA("ObjectValue")
            and playerValue.Value == sender
        then
            table.insert(results, card)
        end
    end

    return results
end

local function receiverHideRequestCardsForSender(sender)
    local hidden = 0

    for _, card in ipairs(
        receiverFindRequestCardsForSender(sender)
    ) do
        if card:IsA("GuiObject") then
            pcall(function()
                card.Visible = false
            end)

            hidden += 1
        end
    end

    if hidden > 0 then
        print(
            "[AutoTrade][ReceiverQueue] Hid accepted request card(s):",
            sender.Name,
            "| count:",
            hidden
        )
    end

    return hidden
end

local function receiverCollectAllVisibleRequestCards(source)
    local inner =
        getReceiverRequestInner()

    if not inner then
        return 0
    end

    local queued = 0

    -- IMPORTANT V31: do not return after the first card. Queue EVERY visible
    -- request so 5-10 sender accounts can stack safely while one trade runs.
    for _, card in ipairs(inner:GetChildren()) do
        if card:IsA("GuiObject")
            and card.Visible
        then
            local playerValue =
                card:FindFirstChild("Player")

            if playerValue
                and playerValue:IsA("ObjectValue")
                and playerValue.Value
                and playerValue.Value:IsA("Player")
            then
                if receiverQueueIncomingRequest(
                    playerValue.Value,
                    source or "request_card_sweep"
                ) then
                    queued += 1
                end
            end
        end
    end

    return queued
end

local function receiverTryRestockWithRetries(context)
    local attempts =
        math.max(
            1,
            tonumber(Config.Receiver.PostTradeRestockAttempts)
            or 3
        )

    for attempt = 1, attempts do
        State.StockingFinished = false
        State.StockingResults = {}

        local ok, result =
            pcall(runAutoStock)

        if ok and result == true then
            State.ReceiverStockReady = true

            print(
                "[AutoTrade][Receiver] Stock ready",
                "| context:",
                tostring(context or "unknown"),
                "| attempt:",
                attempt .. "/" .. attempts
            )

            return true
        end

        State.ReceiverStockReady = false

        warn(
            "[AutoTrade][Receiver] Restock attempt failed",
            attempt .. "/" .. attempts,
            "| context:",
            tostring(context or "unknown"),
            "| result:",
            tostring(result)
        )

        if attempt < attempts then
            task.wait(
                Config.Receiver.PostTradeRestockRetryDelay
            )
        end
    end

    return false
end

local function receiverScheduleStockRecovery()
    if State.ReceiverStockRecoveryRunning
        or State.ReceiverStockReady
    then
        return
    end

    State.ReceiverStockRecoveryRunning = true

    task.spawn(function()
        while Config.Receiver.Enabled
            and not State.ReceiverStockReady
        do
            -- Never try to purchase over an active trade.
            if not isTradeOpen() then
                local recovered =
                    receiverTryRestockWithRetries(
                        "background_recovery"
                    )

                if recovered then
                    break
                end
            end

            task.wait(
                Config.Receiver.StockRecoveryRetryDelay
            )
        end

        State.ReceiverStockRecoveryRunning = false

        if State.ReceiverStockReady
            and not State.ReceiverBusy
            and not isTradeOpen()
            and processReceiverRequestQueue
        then
            processReceiverRequestQueue()
        end
    end)
end

startReceiverTradeWorker = function(sender, source)
    if not sender
        or not sender:IsA("Player")
    then
        return false
    end

    -- Both automatic AcceptTradeRequest and manual GUI acceptance end up here.
    -- ReceiverBusy must already be true before this worker is started.
    removeReceiverQueuedSender(sender)

    State.ReceiverSender =
        sender

    print(
        "[AutoTrade][Receiver] Starting active trade worker:",
        sender.Name,
        "| source:",
        tostring(source or "unknown")
    )

    task.spawn(function()
        local success, reason =
            runReceiverActiveTrade(sender)

        if success then
            print(
                "[AutoTrade][Receiver] Finished trade with:",
                sender.Name
            )
        else
            warn(
                "[AutoTrade][Receiver] Receiver trade ended:",
                sender.Name,
                "|",
                tostring(reason)
            )
        end

        disconnectReceiverConnections()
        disconnectReceiverChatConnections()

        -- Whether the trade completed or was cancelled, try to top stock up.
        -- V30 could permanently wedge here: if runAutoStock() failed once it
        -- returned while ReceiverBusy was STILL true. V31 always releases the
        -- busy lock, even when stock recovery needs to continue in background.
        local restockOK =
            receiverTryRestockWithRetries(
                "post_trade"
            )

        State.ReceiverBusy = false
        State.ReceiverSender = nil

        if not restockOK then
            warn(
                "[AutoTrade][Receiver] Post-trade stock is incomplete. "
                .. "Busy lock released; background stock recovery started."
            )

            receiverScheduleStockRecovery()
        end

        task.wait(
            Config.Receiver.RequestQueueProcessDelay
        )

        -- Harvest every currently-visible card before choosing the next sender.
        receiverCollectAllVisibleRequestCards(
            "post_trade_sweep"
        )

        if State.ReceiverStockReady
            and processReceiverRequestQueue
        then
            processReceiverRequestQueue()
        end
    end)

    return true
end

local function receiverAcceptRequest(sender)
    if not waitForCaptchaClear("receiver_accept_request") then
        return false
    end

    if not receiverSenderAllowed(sender) then
        return false, "sender_not_allowed"
    end

    if State.ReceiverBusy
        or isTradeOpen()
    then
        if receiverQueueIncomingRequest then
            receiverQueueIncomingRequest(
                sender,
                "receiver_busy"
            )
        end

        return false, "queued_while_busy"
    end

    State.ReceiverBusy = true

    print(
        "[AutoTrade][Receiver] Incoming trade request from:",
        sender.Name
    )

    local ok, result =
        pcall(function()
            return AcceptTradeRequest:InvokeServer(
                sender
            )
        end)

    if not ok then
        State.ReceiverBusy = false

        warn(
            "[AutoTrade][Receiver] AcceptTradeRequest invoke failed:",
            tostring(result)
        )

        if processReceiverRequestQueue then
            task.defer(processReceiverRequestQueue)
        end

        return false, "accept_request_invoke_failed"
    end

    if typeof(result) == "table"
        and result.error
    then
        State.ReceiverBusy = false

        warn(
            "[AutoTrade][Receiver] AcceptTradeRequest rejected:",
            tostring(result.error)
        )

        -- Most commonly this means a queued request expired while another
        -- trade/restock was running. Immediately try the next queued sender.
        if processReceiverRequestQueue then
            task.defer(processReceiverRequestQueue)
        end

        return false, tostring(result.error)
    end

    -- RH's own GUI handler hides this request card after clicking Accept.
    -- Because our script invokes AcceptTradeRequest directly, reproduce that
    -- local UI cleanup or the stale visible card can be queued again later.
    receiverHideRequestCardsForSender(sender)

    startReceiverTradeWorker(
        sender,
        "AcceptTradeRequest"
    )

    return true
end

-- ================================================================
-- MANUALLY-ACCEPTED TRADE ADOPTION
-- ================================================================
-- If the user clicks the green Accept button herself, Royale High opens
-- TradeGui directly. No AcceptTradeRequest call from this script occurs, so
-- older receiver versions never launched runReceiverActiveTrade().
--
-- V28 identifies the trade partner from the already-open trade header and
-- adopts that trade into the exact same receiver worker used by auto-accept.

local function resolveOpenReceiverTradePartner()
    if not isTradeOpen() then
        return nil
    end

    -- tradeGuiMatchesTarget() already verifies the header/visible TradeGui
    -- contains the player's real Roblox username (e.g. "Let's Trade X!").
    for _, player in ipairs(
        Players:GetPlayers()
    ) do
        if player ~= LocalPlayer
            and receiverSenderAllowed(player)
            and tradeGuiMatchesTarget(player)
        then
            return player
        end
    end

    return nil
end

local function adoptManualReceiverTradeIfNeeded()
    if not Config.Receiver.ManualTradeAdoption
        or State.ReceiverBusy
        or not isTradeOpen()
        or captchaChallengeVisible()
    then
        return false
    end

    local sender =
        resolveOpenReceiverTradePartner()

    if not sender then
        return false
    end

    State.ReceiverBusy = true
    State.ReceiverManualAdoptions += 1
    State.ReceiverLastManualPartner =
        sender.Name

    removeReceiverQueuedSender(sender)
    receiverHideRequestCardsForSender(sender)

    print(
        "[AutoTrade][Receiver] MANUAL TRADE ADOPTED:",
        sender.Name,
        "| adoption:",
        State.ReceiverManualAdoptions
    )

    return startReceiverTradeWorker(
        sender,
        "manual_gui_accept"
    )
end

-- ================================================================
-- RECEIVER REQUEST FIFO
-- ================================================================

receiverQueueIncomingRequest = function(sender, source)
    if not Config.Receiver.RequestQueueEnabled
        or not sender
        or not sender:IsA("Player")
        or sender == LocalPlayer
        or not receiverSenderAllowed(sender)
    then
        return false
    end

    -- The currently active sender does not need another queue entry.
    if State.ReceiverSender
        and State.ReceiverSender.UserId == sender.UserId
    then
        return false
    end

    local userId =
        tonumber(sender.UserId)

    local existing =
        State.ReceiverRequestQueuedByUserId[userId]

    if existing then
        -- A sender may retry while waiting. Refresh its timestamp instead of
        -- creating duplicate queue entries.
        existing.LastSeen = os.clock()
        existing.Player = sender
        existing.Username = sender.Name
        existing.SeenCount =
            (existing.SeenCount or 1) + 1

        print(
            "[AutoTrade][ReceiverQueue] Refreshed:",
            sender.Name,
            "| position:",
            tostring(existing.PositionHint or "?"),
            "| seen:",
            existing.SeenCount,
            "| source:",
            tostring(source or "event")
        )

        return true
    end

    if #State.ReceiverRequestQueue
        >= Config.Receiver.RequestQueueMax
    then
        warn(
            "[AutoTrade][ReceiverQueue] Queue full; cannot store:",
            sender.Name
        )
        return false
    end

    State.ReceiverRequestSequence += 1

    local entry = {
        Player = sender,
        UserId = userId,
        Username = sender.Name,
        FirstSeen = os.clock(),
        LastSeen = os.clock(),
        Sequence = State.ReceiverRequestSequence,
        SeenCount = 1,
        Source = tostring(source or "event")
    }

    table.insert(
        State.ReceiverRequestQueue,
        entry
    )

    State.ReceiverRequestQueuedByUserId[userId] =
        entry

    -- Recompute simple position hints for logs.
    for index, queued in ipairs(
        State.ReceiverRequestQueue
    ) do
        queued.PositionHint = index
    end

    print(
        "[AutoTrade][ReceiverQueue] Queued:",
        sender.Name,
        "| position:",
        #State.ReceiverRequestQueue,
        "| busy:",
        tostring(State.ReceiverBusy),
        "| tradeOpen:",
        tostring(isTradeOpen())
    )

    return true
end

local function popNextReceiverQueuedRequest()
    while #State.ReceiverRequestQueue > 0 do
        local entry =
            table.remove(
                State.ReceiverRequestQueue,
                1
            )

        if entry and entry.UserId then
            State.ReceiverRequestQueuedByUserId[
                entry.UserId
            ] = nil
        end

        for index, queued in ipairs(
            State.ReceiverRequestQueue
        ) do
            queued.PositionHint = index
        end

        if entry then
            local age =
                os.clock()
                - (entry.LastSeen or entry.FirstSeen or 0)

            local sender =
                entry.Player

            if (not sender
                    or sender.Parent ~= Players)
                and entry.Username
            then
                sender =
                    Players:FindFirstChild(
                        entry.Username
                    )
            end

            if age > Config.Receiver.RequestQueueTTL then
                print(
                    "[AutoTrade][ReceiverQueue] Dropping expired local queue entry:",
                    tostring(entry.Username),
                    "| age:",
                    string.format("%.1fs", age)
                )
            elseif sender
                and sender.Parent == Players
                and receiverSenderAllowed(sender)
            then
                return sender, entry
            else
                print(
                    "[AutoTrade][ReceiverQueue] Dropping unavailable sender:",
                    tostring(entry.Username)
                )
            end
        end
    end

    return nil, nil
end

processReceiverRequestQueue = function()
    if State.ReceiverBusy
        or isTradeOpen()
        or captchaChallengeVisible()
    then
        return false
    end

    if not State.ReceiverStockReady then
        receiverScheduleStockRecovery()
        return false, "receiver_stock_recovering"
    end

    -- Pick up cards that may have arrived before our event listener or while
    -- the receiver was busy. This sweep adds ALL visible cards to the FIFO.
    receiverCollectAllVisibleRequestCards(
        "pre_process_sweep"
    )

    local sender, entry =
        popNextReceiverQueuedRequest()

    if not sender then
        return false
    end

    print(
        "[AutoTrade][ReceiverQueue] Processing next sender:",
        sender.Name,
        "| remaining:",
        #State.ReceiverRequestQueue,
        "| queued age:",
        string.format(
            "%.1fs",
            os.clock()
                - (entry.LastSeen or entry.FirstSeen or os.clock())
        )
    )

    local accepted, reason =
        receiverAcceptRequest(sender)

    if accepted then
        return true
    end

    -- If this request expired/rejected, continue to the next queued entry
    -- after a short deterministic gap.
    if not State.ReceiverBusy
        and not isTradeOpen()
    then
        task.delay(
            Config.Receiver.RequestQueueProcessDelay,
            function()
                if processReceiverRequestQueue then
                    processReceiverRequestQueue()
                end
            end
        )
    end

    return false, reason
end

local function acceptExistingReceiverRequestCard()
    local queued =
        receiverCollectAllVisibleRequestCards(
            "visible_request_card"
        )

    if queued <= 0 then
        return false
    end

    if not State.ReceiverBusy
        and not isTradeOpen()
        and State.ReceiverStockReady
    then
        return processReceiverRequestQueue()
    end

    return true
end

local function runReceiverMode()
    if not Config.Receiver.Enabled then
        warn(
            "[AutoTrade][Receiver] Receiver mode detected but disabled."
        )
        return
    end

    print(
        "[AutoTrade] MODE = RECEIVER",
        "| account:",
        LocalPlayer.Name
    )

    if #Config.RandomOffer.Pool == 0 then
        warn(
            "[AutoTrade][Receiver] No configured item pool. "
            .. "Receiver cannot build a 10-20 item offer."
        )
        return
    end

    -- Receiver needs the same configured inventory reserve as senders.
    -- However, if a trade is ALREADY open because the user manually accepted
    -- it before/during startup, do not purchase over that live trade. Adopt it.
    if not isTradeOpen() then
        State.StockingFinished = false
        State.StockingResults = {}

        local initialStockOK =
            receiverTryRestockWithRetries(
                "receiver_startup"
            )

        State.ReceiverStockReady =
            initialStockOK == true

        if not initialStockOK then
            warn(
                "[AutoTrade][Receiver] Initial auto-stock incomplete. "
                .. "Receiver stays alive and will recover stock in background."
            )

            receiverScheduleStockRecovery()
        end
    else
        State.ReceiverStockReady = true

        print(
            "[AutoTrade][Receiver] Trade already open at receiver startup; "
            .. "skipping initial stock and preparing manual adoption."
        )
    end

    print(
        "[AutoTrade][Receiver] Waiting for incoming trade requests..."
    )

    State.ReceiverRequestConnection =
        ReceiveTradeRequest.OnClientEvent:Connect(
            function(sender)
                if sender
                    and sender:IsA("Player")
                then
                    -- V26 used to call receiverAcceptRequest directly here.
                    -- If the receiver was trading/restocking, that function
                    -- returned immediately and the request was LOST.
                    receiverQueueIncomingRequest(
                        sender,
                        "ReceiveTradeRequest"
                    )

                    if not State.ReceiverBusy
                        and not isTradeOpen()
                        and not captchaChallengeVisible()
                    then
                        processReceiverRequestQueue()
                    end
                end
            end
        )

    -- Keep this listener separate from per-trade connections so resetting
    -- one completed trade does not disable the receiver for the next sender.

    -- V31: continuously harvest every visible request card, even while busy.
    -- This is important when many accounts send around the same time or when
    -- an executor misses one ReceiveTradeRequest event.
    if Config.Receiver.RequestCardSweepEnabled
        and not State.ReceiverRequestSweepRunning
    then
        State.ReceiverRequestSweepRunning = true

        task.spawn(function()
            while Config.Receiver.Enabled do
                receiverCollectAllVisibleRequestCards(
                    "continuous_card_sweep"
                )

                task.wait(
                    Config.Receiver.RequestCardSweepPollRate
                )
            end

            State.ReceiverRequestSweepRunning = false
        end)
    end

    -- Covers the case where the request UI appeared just before injection.
    task.defer(function()
        if isTradeOpen() then
            adoptManualReceiverTradeIfNeeded()
            return
        end

        acceptExistingReceiverRequestCard()

        if #State.ReceiverRequestQueue > 0
            and not State.ReceiverBusy
            and not isTradeOpen()
        then
            processReceiverRequestQueue()
        end
    end)

    -- Keep the receiver alive for sequential sender accounts.
    while Config.Receiver.Enabled do
        task.wait(
            Config.Receiver.ManualTradeAdoptPollRate
        )

        if not State.ReceiverBusy
            and not captchaChallengeVisible()
        then
            if isTradeOpen() then
                -- Covers a manual click on the in-game request's Accept button.
                adoptManualReceiverTradeIfNeeded()
            else
                receiverCollectAllVisibleRequestCards(
                    "idle_loop_sweep"
                )

                if not State.ReceiverStockReady then
                    receiverScheduleStockRecovery()
                elseif #State.ReceiverRequestQueue > 0 then
                    processReceiverRequestQueue()
                end
            end
        end
    end
end

local function resolveConfiguredTarget()
    local wantedUserId =
        tonumber(Config.TargetUserId)

    local wantedName =
        string.lower(
            tostring(Config.TargetUsername or "")
        )

    local function findNow()
        if wantedUserId then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.UserId == wantedUserId then
                    return player
                end
            end
        end

        if wantedName ~= "" then
            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == wantedName then
                    return player
                end
            end
        end

        return nil
    end

    local target = findNow()

    if target then
        return target
    end

    local started = os.clock()

    while os.clock() - started
        < Config.Reliability.TargetResolveTimeout
    do
        target = findNow()

        if target then
            return target
        end

        task.wait(
            Config.Reliability.TargetResolvePollRate
        )
    end

    return nil
end

local function runQueuedTradeSender()
    print(
        "[AutoTrade] Global target config:",
        Config.TargetUsername,
        "| userId:",
        tostring(Config.TargetUserId or "not-set")
    )

    print(
        "[AutoTrade] Global configured items:",
        #Config.Stock.Targets
    )

    for _, spec in ipairs(Config.Stock.Targets) do
        print(
            "[AutoTrade] Item config:",
            spec.Item,
            "| category:",
            spec.Category,
            "| currency:",
            spec.Currency,
            "| stock target:",
            spec.Target
        )
    end

    if #Config.RandomOffer.Pool == 0 then
        warn(
            "[AutoTrade] Global Items config has no enabled items "
            .. "(Target must be > 0). Stopping."
        )
        return
    end

    -- Global account-level trade-ban marker takes priority over everything.
    -- This check happens before auto-stock and before any trade request.
    if hasSavedSenderTradeBan() or senderTradeBanRuntimeGuarded() then
        State.TradeBanned = true

        warn(
            "[AutoTrade] Sender is already recorded in Volt workspace/",
            Config.Reliability.TradeBanFolder,
            "- refusing to stock or send any trade requests."
        )

        return
    end

    local target =
        resolveConfiguredTarget()

    if not target then
        warn(
            "[AutoTrade] Target could not be resolved in this server.",
            "| configured username:",
            Config.TargetUsername,
            "| configured userId:",
            tostring(Config.TargetUserId or "not-set"),
            "| IMPORTANT: use the Roblox USERNAME, not DisplayName."
        )
        return
    end

    print(
        "[AutoTrade] Resolved target:",
        target.Name,
        "(" .. tostring(target.UserId) .. ")"
    )

    if target == LocalPlayer then
        warn("[AutoTrade] Target cannot be the local player.")
        return
    end

    State.Target = target

    -- PRE-FLIGHT BEFORE AUTO-STOCK.
    local preflightOK, preflightReason =
        runProfileTradeIconPreflight(target)

    if not preflightOK then
        warn(
            "[AutoTrade] Stopped by profile trade-icon preflight:",
            tostring(preflightReason)
        )
        return
    end

    local terminal, terminalState =
        alreadyTerminalForTarget(target)

    if terminal then
        if terminalState == "quarantined" then
            print(
                "[AutoTrade] Sender is quarantined for THIS JobId:",
                string.sub(tostring(game.JobId), 1, 12),
                "| target:",
                target.Name,
                "- no new trade will be sent in this server job."
            )
        else
            print(
                "[AutoTrade] Sender already completed a verified trade for",
                target.Name,
                "in THIS JobId:",
                string.sub(tostring(game.JobId), 1, 12),
                "- no new trade will be sent in this server job."
            )
        end
        return
    end

    -- Finish stock preparation before entering the request queue.
    local stockOK = runAutoStock()

    if not stockOK
        and Config.Reliability.AbortIfStockIncomplete
    then
        quarantine("stock_targets_incomplete")
        return
    end

    local preSnapshot, snapshotReason =
        snapshotConfiguredInventory()

    if not preSnapshot then
        quarantine(
            "pretrade_snapshot_failed_"
            .. tostring(snapshotReason)
        )
        return
    end

    State.PreTradeSnapshot = preSnapshot

    -- Lock the item manifest ONCE. Busy/request retries reuse this exact
    -- manifest instead of rolling a different 10-20 item set each time.
    local plan, sequenceOrReason =
        buildRandomItemOfferPlan()

    if not plan then
        quarantine(
            "manifest_generation_failed_"
            .. tostring(sequenceOrReason)
        )
        return
    end

    State.ManifestLocked = true

    print(
        "[AutoTrade] Manifest locked before queue:",
        State.ItemOfferTargetCount,
        "item(s)"
    )

    waitInitialQueueSlot()

    while target.Parent == Players do
        if State.TradeBanned
            or hasSavedSenderTradeBan()
            or senderTradeBanRuntimeGuarded()
        then
            warn(
                "[AutoTrade] Trade-ban guard became active. "
                .. "No further trade requests will be sent."
            )
            return
        end

        -- Never request another trade while this sender is already trading.
        if isTradeOpen() then
            print("[AutoTrade] Local account already trading. Waiting...")
            waitForTradeToClose()
            task.wait(1)
        end

        -- Re-check immediately before EVERY request attempt.
        local requestPreflightOK, requestPreflightReason =
            runProfileTradeIconPreflight(target)

        if not requestPreflightOK then
            warn(
                "[AutoTrade] Request blocked by profile preflight:",
                tostring(requestPreflightReason)
            )
            return
        end

        local state, detail = invokeTradeRequest(target)

        if state == "busy" then
            print("[AutoTrade] Trade busy:", tostring(detail))
            waitBusyRetry()
            continue
        end

        if state == "sender_trade_restricted" then
            saveSenderTradeBan(detail)

            -- Dedicated receipt for diagnostics, but do NOT use normal
            -- JobId-scoped quarantine as the primary guard. The tradebans
            -- marker is global for this sender account.
            writeTradeReceipt(
                "trade_restricted",
                tostring(detail)
            )

            return
        end

        if state == "terminal" then
            quarantine("trade_terminal_" .. tostring(detail))
            return
        end

        if state == "invoke_error" or state == "error" then
            warn("[AutoTrade] Request error:", tostring(detail))
            task.wait(Config.BusyRetryBase)
            continue
        end

        print("[AutoTrade] Trade request sent to", target.Name)

        if waitForTradeOpen(Config.TradeOpenTimeout) then
            print("[AutoTrade] Trade opened with", target.Name)

            local success = runActiveTrade(target)

            if success and State.Completed then
                print(
                    "[AutoTrade] Sender finished successfully. "
                    .. "Trade loop permanently stopped."
                )
            elseif State.Quarantined then
                warn(
                    "[AutoTrade] Sender stopped in quarantine:",
                    tostring(State.TerminalReason)
                )
            else
                warn(
                    "[AutoTrade] Active trade ended without verified completion. "
                    .. "No new trade will be attempted in this run."
                )
            end

            return
        end

        print("[AutoTrade] Request timed out without opening.")
        task.wait(Config.RequestTimeoutRetry)
    end

    warn("[AutoTrade] Target left the server.")
end

State.RuntimeMode =
    detectRuntimeMode()

if State.RuntimeMode == "receiver" then
    task.spawn(runReceiverMode)
else
    print(
        "[AutoTrade] MODE = SENDER",
        "| account:",
        LocalPlayer.Name,
        "| receiver:",
        Config.TargetUsername
    )

    task.spawn(runQueuedTradeSender)
end
