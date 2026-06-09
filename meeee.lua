--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// PLAYER
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// STATE & VARIABLES
local isPromptOpen = false
local currentBalance = 24267528 -- Your custom fake balance

--// STUBS FOR REMOVED DEPENDENCIES
local function updateDonatedValue(price) end
local function showSentGiftToast() end

--// HELPER FUNCTIONS
local function formatNumber(n)
    n = math.floor(n)
    local s = tostring(n)
    while true do
        local k
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return s
end

--// SAFE FADE
local function fadeOut(obj, info)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        TweenService:Create(obj, info, {TextTransparency = 1}):Play()
    elseif obj:IsA("ImageLabel") then
        TweenService:Create(obj, info, {ImageTransparency = 1}):Play()
    elseif obj:IsA("Frame") and obj.Name ~= "SafetyFill" then
        TweenService:Create(obj, info, {BackgroundTransparency = 1}):Play()
    end
end

--// SCREEN DIM OVERLAY
local function createDim(gui)
    local dim = Instance.new("Frame")
    dim.Name = "Dim"
    dim.Size = UDim2.new(1,0,1,0)
    dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
    dim.BackgroundTransparency = 1
    dim.ZIndex = 0
    dim.Active = true 
    dim.Parent = gui
    TweenService:Create(dim, TweenInfo.new(0.18), {BackgroundTransparency = 0.25}):Play()
    return dim
end

--// CLOSE WITH SLIDE DOWN + FADE (Clears Engine State)
local function closeWithSlideAndFade(frame, gui)
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(frame, info, {
        Position = frame.Position + UDim2.new(0,0,0.08,0),
        BackgroundTransparency = 1
    }):Play()
    
    for _,v in ipairs(frame:GetDescendants()) do fadeOut(v, info) end
    
    local dim = gui:FindFirstChild("Dim")
    if dim then 
        TweenService:Create(dim, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play() 
    end
    
    task.delay(0.15, function()
        if gui then gui:Destroy() end
        isPromptOpen = false
        
        -- Force-clear the purchase state by invoking the native service cleanup
        pcall(function()
            -- This is the internal Roblox method to reset the purchase state
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, 0, false)
        end)
    end)
end

--// ABSOLUTE GUI PURGE (Destroys lingering frames before making new ones)
local function purgeOldPrompts()
    -- Hunt down and destroy ANY 'ENIFakePrompt' AND any leftover 'Dim' frames
    for _, child in ipairs(playerGui:GetChildren()) do
        if child.Name == "ENIFakePrompt" then
            child:Destroy()
        end
    end
    -- Scan for stray 'Dim' overlays in the root
    for _, child in ipairs(playerGui:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Dim" then
            child:Destroy()
        end
    end
    isPromptOpen = false
end

--// UPGRADED USERNAME SCRAPER (Catches Global & Server Players)
local function getTargetUsername()
    -- Only check top-level Guis first
    for _, gui in ipairs(playerGui:GetChildren()) do
        -- Only scan inside ScreenGuis that are actually visible/enabled
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, child in ipairs(gui:GetDescendants()) do
                -- ClassName is slightly faster than :IsA() for heavy loops
                if child.ClassName == "TextLabel" or child.ClassName == "TextBox" then
                    local text = child.Text or ""
                    local placeholder = child.ClassName == "TextBox" and child.PlaceholderText or ""
                    
                    local match = string.match(text, "Gifting %[(.-)%]") 
                               or string.match(text, "Leave a gift note for %[(.-)%]")
                               or string.match(placeholder, "Leave a gift note for %[(.-)%]")
                    
                    if match then
                        return string.gsub(match, "%.%.$", "") 
                    end
                end
            end
        end
    end
    return "Someone" -- Fallback
end

--// PIXEL-PERFECT BLOX FRUITS TOAST REPLICA (Exact Colors, Locked Timers, Random Range)
local function showSentGiftToast(rawItemName)
    local targetName = getTargetUsername()
    
    -- Strip "Permanent" if the scraper accidentally grabbed it twice, so we can explicitly build it
    local cleanItemName = string.gsub(rawItemName, "Permanent ", "")
    cleanItemName = string.gsub(cleanItemName, "Permanent", "")
    
    local toastGui = Instance.new("ScreenGui", playerGui)
    toastGui.Name = "ENIToastGui"
    toastGui.DisplayOrder = 2147483647 
    toastGui.IgnoreGuiInset = true
    
    --// NOTIFICATION 1: SENDING GIFT
    local sendingLabel = Instance.new("TextLabel", toastGui)
    sendingLabel.Size = UDim2.new(0, 700, 0, 35)
    sendingLabel.AnchorPoint = Vector2.new(0.5, 0)
    sendingLabel.Position = UDim2.new(0.5, 0, 0, -100)
    sendingLabel.BackgroundTransparency = 1
    sendingLabel.Font = Enum.Font.SourceSansBold
    sendingLabel.TextSize = 28
    sendingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sendingLabel.TextStrokeTransparency = 0 
    sendingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    sendingLabel.RichText = true 
    
    local goldHex = "#FFD700"
    sendingLabel.Text = "Sending gift <font color='".. goldHex .."'>&lt;Permanent " .. cleanItemName .. "&gt;</font> to " .. targetName .. "..."
    
    --// NOTIFICATION 2: SUCCESS
    local successLabel = Instance.new("TextLabel", toastGui)
    successLabel.Size = UDim2.new(0, 700, 0, 35)
    successLabel.AnchorPoint = Vector2.new(0.5, 0)
    successLabel.Position = UDim2.new(0.5, 0, 0, -100)
    successLabel.BackgroundTransparency = 1
    successLabel.Font = Enum.Font.SourceSansBold
    successLabel.TextSize = 28

    successLabel.TextColor3 = Color3.fromRGB(0, 255, 0) 
    successLabel.TextStrokeTransparency = 0 
    successLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    successLabel.Text = "Gift sent successfully!"
    
    --// TIMING CONFIGURATION
    local sendingVisibleTime = 2.5 -- Exact locked time for the top text
    local successVisibleTime = 3.0 -- Exact locked time for the bottom text
    local successDropDelay = math.random(30, 130) / 100 -- Random float exactly between 0.3s and 1.3s
    
    -- 1. SENDING LABEL: Drops immediately
    TweenService:Create(sendingLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 60)
    }):Play()
    
    -- Sending label exit logic (locked exactly to its own visible time)
    task.delay(sendingVisibleTime, function()
        local slideLeft = TweenService:Create(sendingLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(-0.5, 0, 0, 60)
        })
        slideLeft:Play()
        slideLeft.Completed:Connect(function()
            sendingLabel:Destroy()
        end)
    end)


    -- 2. SUCCESS LABEL: Drops after randomized delay range
    task.delay(successDropDelay, function()
        TweenService:Create(successLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 95)
        }):Play()
        
        -- DYNAMIC SLIDE UP: Calculates exactly when the top text finishes sweeping left
        -- Top text vanishes at (sendingVisibleTime + 0.4s exit animation)
        local timeUntilTopSlotIsClear = (sendingVisibleTime + 0.4) - successDropDelay
        
        if timeUntilTopSlotIsClear > 0 then
            task.delay(timeUntilTopSlotIsClear, function()
                TweenService:Create(successLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, 0, 0, 60)
                }):Play()
            end)
        end
        
        -- Success label exit logic (locked exactly to its own visible time, counting from when it dropped)
        task.delay(successVisibleTime, function()
            local slideRight = TweenService:Create(successLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1.5, 0, 0, 60)
            })
            slideRight:Play()
            slideRight.Completed:Connect(function()
                successLabel:Destroy()
                toastGui:Destroy() -- Nuke the host GUI once the final animation completes
            end)
        end)
    end)
end

--// PURCHASE COMPLETED UI
local function createPurchaseCompletedUI(itemName)
    purgeOldPrompts()
    
    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "ENIFakePrompt"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647 
    
    local dim = createDim(gui)

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 450, 0, 220)
    frame.Position = UDim2.new(0.5, -220, 0.5, -122)
    frame.BackgroundColor3 = Color3.fromRGB(23, 23, 29)
    frame.Active = true 
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)

    local title = Instance.new("TextLabel", frame)
    title.Text = "Purchase completed"
    title.Position = UDim2.new(0, 24, 0, 15) 
    title.Size = UDim2.new(1, -48, 0, 28)
    title.Font = Enum.Font.BuilderSansBold 
    title.TextSize = 26
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- UPDATED: Replaced TextButton layout with ImageButton to match the main Buy UI
    local close = Instance.new("ImageButton", frame)
    close.Size = UDim2.new(0, 38, 0, 38)
    close.Position = UDim2.new(1, -50, 0, 6) 
    close.BackgroundTransparency = 1
    close.AutoButtonColor = false
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 12)
    
    -- UPDATED: Added the same independent close icon layer to match your Main Buy UI look
    local closeIcon = Instance.new("ImageLabel", close)
    closeIcon.Size = UDim2.new(0, 26, 0, 26)
    closeIcon.Position = UDim2.new(0, 6, 0, 7)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = "rbxassetid://108951802009637"
    closeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    closeIcon.ScaleType = Enum.ScaleType.Fit
    
    close.MouseEnter:Connect(function()
        close.BackgroundTransparency = 0
        close.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    close.MouseLeave:Connect(function()
        close.BackgroundTransparency = 1
    end)
    close.MouseButton1Click:Connect(function() closeWithSlideAndFade(frame, gui) end)

    local ring = Instance.new("Frame", frame)
    ring.Size = UDim2.new(0, 40, 0, 40)
    ring.Position = UDim2.new(0.5, 0, 0, 65) 
    ring.AnchorPoint = Vector2.new(0.5, 0)
    ring.BackgroundTransparency = 1
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    
    local ringStroke = Instance.new("UIStroke", ring)
    ringStroke.Thickness = 3
    ringStroke.Color = Color3.fromRGB(235, 235, 235)
    ringStroke.Transparency = 1
    TweenService:Create(ringStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()

    local check = Instance.new("ImageLabel", ring)
    check.Size = UDim2.new(0, 30, 0, 30)
    check.AnchorPoint = Vector2.new(0.5, 0.5)
    check.Position = UDim2.new(0.5, 0, 0.5, 0)
    check.BackgroundTransparency = 1
    check.Image = "rbxassetid://9754130783"
    check.ImageColor3 = Color3.fromRGB(235, 235, 235)
    check.ImageTransparency = 1
    TweenService:Create(check, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()

    local desc = Instance.new("TextLabel", frame)
    desc.Text = "You have successfully bought " .. itemName .. "."
    desc.Size = UDim2.new(1, -48, 0, 40)
    desc.Position = UDim2.new(0, 24, 0, 110) 
    desc.Font = Enum.Font.GothamMedium
    desc.TextSize = 15
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Center
    desc.BackgroundTransparency = 1
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)

    local ok = Instance.new("TextButton", frame)
    ok.Text = "OK"
    ok.Size = UDim2.new(0.92, 0, 0, 40)
    ok.Position = UDim2.new(0.04, 0, 1, -61)
    ok.BackgroundColor3 = Color3.fromRGB(43, 91, 242) 
    ok.TextColor3 = Color3.fromRGB(255, 255, 255)
    ok.Font = Enum.Font.GothamBold
    ok.TextSize = 16
    Instance.new("UICorner", ok).CornerRadius = UDim.new(0, 8)
    
    ok.MouseEnter:Connect(function() 
        ok.BackgroundColor3 = Color3.fromRGB(63, 105, 255) 
    end)
    ok.MouseLeave:Connect(function() 
        ok.BackgroundColor3 = Color3.fromRGB(43, 91, 242) 
    end)
    ok.MouseButton1Click:Connect(function()
        closeWithSlideAndFade(frame, gui)
        -- Fire our beautiful custom toast the second the window closes
        task.delay(0.2, function()
            showSentGiftToast(itemName)
        end)
    end)
end

--// BUY UI
local function createBuyUI(price, name, image)
    purgeOldPrompts()
    isPromptOpen = true

    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "ENIFakePrompt"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647 
    
    local dim = createDim(gui)

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,450,0,220)
    frame.Position = UDim2.new(0.5,-220,0.5,-122)
    frame.BackgroundColor3 = Color3.fromRGB(23,23,29)
    frame.BackgroundTransparency = 1
    frame.Active = true 
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,20)

    frame.Position += UDim2.new(0,0,0.08,0)
    TweenService:Create(frame, TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
        Position = frame.Position - UDim2.new(0,0,0.08,0),
        BackgroundTransparency = 0
    }):Play()

    local title = Instance.new("TextLabel", frame)
    title.Text = "Buy item"
    title.Position = UDim2.new(0,24,0,15)
    title.Size = UDim2.new(1,-48,0,28)
    title.Font = Enum.Font.BuilderSansBold
    title.TextSize = 26
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local close = Instance.new("ImageButton", frame)
    close.Size = UDim2.new(0, 38, 0, 38)
    close.Position = UDim2.new(1, -50, 0, 8)
    close.BackgroundTransparency = 1
    close.AutoButtonColor = false

    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 12) 

    local closeIcon = Instance.new("ImageLabel", close)
    closeIcon.Size = UDim2.new(0, 26, 0, 26)
    closeIcon.Position = UDim2.new(0, 6, 0, 6)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = "rbxassetid://108951802009637"
    closeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    closeIcon.ScaleType = Enum.ScaleType.Fit

    close.MouseEnter:Connect(function()
        close.BackgroundTransparency = 0
        close.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)

    close.MouseLeave:Connect(function()
        close.BackgroundTransparency = 1
    end)

    close.MouseButton1Click:Connect(function() closeWithSlideAndFade(frame, gui) end)

    local icon = Instance.new("ImageLabel", frame)
    icon.Size = UDim2.new(0,72,0,72)
    icon.Position = UDim2.new(0,24,0,57)
    icon.BackgroundTransparency = 1
    icon.Image = image
    icon.Name = "ItemImage"

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Text = name
    nameLabel.Position = UDim2.new(0,108,0,70)
    nameLabel.Size = UDim2.new(1,-130,-0.05,32)
    nameLabel.Font = Enum.Font.BuilderSansBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextWrapped = true
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local priceFrame = Instance.new("Frame", frame)
    priceFrame.Size = UDim2.new(0, 0, 0, -10)
    priceFrame.Position = UDim2.new(0, 112, 0, 112)
    priceFrame.BackgroundTransparency = 1

    local priceIcon = Instance.new("ImageLabel", priceFrame)
    priceIcon.Size = UDim2.new(0, 19.5, 0, 18.5)
    priceIcon.Position = UDim2.new(0, -6, 0.5, -9)
    priceIcon.BackgroundTransparency = 1
    priceIcon.Image = "rbxasset://textures/ui/common/robux@3x.png"

    local priceLabel = Instance.new("TextLabel", priceFrame)
    priceLabel.Size = UDim2.new(1, 0, 1, 0)
    priceLabel.Position = UDim2.new(0, 16, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = formatNumber(price)
    priceLabel.Font = Enum.Font.BuilderSansBold
    priceLabel.TextSize = 18
    priceLabel.TextColor3 = Color3.fromRGB(255,255,255)
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.TextStrokeColor3 = Color3.fromRGB(230,230,230)
    priceLabel.TextStrokeTransparency = 0.9

    local balanceFrame = Instance.new("Frame")
    balanceFrame.Size = UDim2.new(0, 160, 0, 27)
    balanceFrame.Position = UDim2.new(1, -155, 0, 12)
    balanceFrame.BackgroundTransparency = 1
    balanceFrame.Parent = frame

    local balIcon = Instance.new("ImageLabel")
    balIcon.Size = UDim2.new(0, 18, 0, 17)
    balIcon.Position = UDim2.new(0, 6, 0.55, -8)
    balIcon.BackgroundTransparency = 1
    balIcon.Image = "rbxasset://textures/ui/common/robux@3x.png"
    balIcon.Parent = balanceFrame

    local balLabel = Instance.new("TextLabel")
    balLabel.Size = UDim2.new(1, -28, 1, 0)
    balLabel.Position = UDim2.new(0, 28, 0, 2 )
    balLabel.BackgroundTransparency = 1
    balLabel.Text = formatNumber(currentBalance)
    balLabel.Font = Enum.Font.GothamMedium
    balLabel.TextSize = 16
    balLabel.TextColor3 = Color3.fromRGB(255,255,255)
    balLabel.TextXAlignment = Enum.TextXAlignment.Left
    balLabel.TextStrokeColor3 = Color3.fromRGB(20,20,20)
    balLabel.TextStrokeTransparency = 0.1
    balLabel.Parent = balanceFrame

    -- Base button wrapper (Perfect Rounded Corners Natively)
    local buyButton = Instance.new("Frame", frame)
    buyButton.Size = UDim2.new(0.92, 0, 0, 40)
    buyButton.Position = UDim2.new(0.04, 0, 1, -61)
    buyButton.BackgroundColor3 = Color3.fromRGB(35, 66, 153) -- Dark Blue base
    Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 8)

    -- Safety Fill Layer (Fills the button perfectly with zero pixel edge bleeding)
    local safetyFill = Instance.new("Frame", buyButton)
    safetyFill.Name = "SafetyFill"
    safetyFill.Size = UDim2.new(1, 0, 1, 0) -- Stays locked at 100% size
    safetyFill.BackgroundColor3 = Color3.fromRGB(63, 105, 255) -- Lighter progress blue
    safetyFill.BorderSizePixel = 0
    safetyFill.ZIndex = 1
    Instance.new("UICorner", safetyFill).CornerRadius = UDim.new(0, 8) -- Perfect rounded sync

    -- NEW: Sharp inline gradient cuts a clean, straight line through the rounded button container
    local fillGradient = Instance.new("UIGradient", safetyFill)
    fillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.499, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    fillGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),    -- Lighter blue visible
        NumberSequenceKeypoint.new(0.499, 0),-- Lighter blue visible
        NumberSequenceKeypoint.new(0.5, 1),  -- Completely transparent (shows dark blue behind)
        NumberSequenceKeypoint.new(1, 1)     -- Completely transparent
    })
    fillGradient.Offset = Vector2.new(-0.5, 0) -- Starts completely hidden on the left side

    -- Independent Text Layer
    local buyText = Instance.new("TextLabel", buyButton)
    buyText.Size = UDim2.new(1, 0, 1, 0)
    buyText.BackgroundTransparency = 1
    buyText.Text = "Buy"
    buyText.Font = Enum.Font.GothamBold
    buyText.TextSize = 16
    buyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyText.ZIndex = 2 

    -- Invisible overlay click handler layer
    local clickDetector = Instance.new("TextButton", buyButton)
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 3
    clickDetector.Active = false

    -- CUSTOM RENDER LOOP: Exact control over "slow to less-slow" pacing with zero clipping
    local RunService = game:GetService("RunService")
    local duration = 2.6
    local elapsed = 0
    
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed = math.min(elapsed + dt, duration)
        local progress = elapsed / duration
        
        -- Custom Velocity Curve: Starts slow, shifts gently into a steady less-slow pace
        local customAlpha = (progress * 0.4) + (progress * progress * 0.6)
        
        -- Slide the gradient threshold offset across from left (-0.5) to right (0.5)
        fillGradient.Offset = Vector2.new(-0.5 + customAlpha, 0)
        
        if elapsed >= duration then
            connection:Disconnect()
            clickDetector.Active = true
        end
    end)

    clickDetector.MouseButton1Click:Connect(function()
        if not clickDetector.Active then return end
        clickDetector.Active = false 
        
        if connection then connection:Disconnect() end
        -- Instantly resets gradient back to the hidden left position (snaps layout back to dark blue)
        fillGradient.Offset = Vector2.new(-0.5, 0)

        task.delay(1.4, function()
            currentBalance -= price
            balLabel.Text = formatNumber(currentBalance)
            closeWithSlideAndFade(frame, gui)
            createPurchaseCompletedUI(name)
        end)
    end)
end

local signalsToSever = {
    MarketplaceService.PromptGamePassPurchaseRequested,
    MarketplaceService.PromptProductPurchaseRequested,
    MarketplaceService.PromptPurchaseRequested,
    MarketplaceService.PromptBundlePurchaseRequested
}

for _, signal in ipairs(signalsToSever) do
    local success, connections = pcall(getconnections, signal)
    if success and connections then
        for _, conn in ipairs(connections) do
            conn:Disable()
        end
    end
end


--// ROOT-LEVEL CARPET BOMBER FOR BLOX FRUITS MENUS
-- Traces up the UI tree to hide the absolute highest frame, taking the black overlay with it
local function hideTopLevelFrame(guiElement)
    local current = guiElement
    local topFrame = nil
    
    -- Climb up the parent tree until we hit the ScreenGui
    while current and not current:IsA("ScreenGui") and current.Parent ~= game do
        if current:IsA("Frame") then
            topFrame = current
        end
        current = current.Parent
    end
    
    -- Hide the absolute highest frame (which contains their dark background)
    if topFrame and topFrame.Visible then
        topFrame.Visible = false
    end
end

--// THE ULTIMATE ANNIHILATOR (Kills both CoreGui Prompts AND PlayerGui Menus)
task.spawn(function()
    -- Using a while loop with task.wait(0.2) runs this 5 times a second instead of 60+
    while task.wait(0.2) do 
        pcall(function()
            -- 1. Obliterate Roblox CoreGui prompts
            for _, child in ipairs(CoreGui:GetChildren()) do
                if child:IsA("ScreenGui") and (string.find(child.Name, "Purchase") or string.find(child.Name, "Prompt")) then
                    if child.Enabled then
                        child.Enabled = false
                    end
                end
            end
            
            -- 2. Hunt and destroy Blox Fruits background overlays
            for _, child in ipairs(playerGui:GetDescendants()) do
                if child:IsA("Frame") and (child.Name == "Background" or child.Name == "Prompt") then
                    -- Added a quick check so we don't re-assign visibility if it's already hidden
                    if child.Visible and child.BackgroundColor3 == Color3.fromRGB(0, 0, 0) then
                        child.Visible = false
                    end
                end
            end
        end)
    end
end)


--// OUR EVENT LISTENER (Data Auto-Grabber)
local function onServerPrompt(playerRequested, assetId, isEquipped, currencyType)
    task.spawn(function()
        local detectedName = "Permanent Fruit"
        local mockPrice = 4000
        local detectedImage = "rbxassetid://13600173502"

        -- 1. Try querying as a Developer Product first (Blox Fruits Gifting uses this)
        local success, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Product)
        end)
        
        -- 2. Fallback to GamePass if Product fails
        if not success or not productInfo then
            success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.GamePass)
            end)
        end

        -- Map the real data to our UI
        if success and productInfo then
            -- Double check we didn't pull a random 'Place' by mistake
            if not string.find(productInfo.Name, "'s Place") then
                detectedName = productInfo.Name
            end
            mockPrice = productInfo.PriceInRobux or mockPrice
            if productInfo.IconImageAssetId then
                detectedImage = "rbxassetid://" .. productInfo.IconImageAssetId
            end
        end

        -- Launch the custom UI with the exact, dynamically pulled data
        createBuyUI(mockPrice, detectedName, detectedImage)
    end)
end

-- Bind our new intelligence-gathering listeners
MarketplaceService.PromptGamePassPurchaseRequested:Connect(onServerPrompt)
MarketplaceService.PromptProductPurchaseRequested:Connect(onServerPrompt)
MarketplaceService.PromptPurchaseRequested:Connect(onServerPrompt)
MarketplaceService.PromptBundlePurchaseRequested:Connect(onServerPrompt)

warn("@sakatoshi on telegram")

-- ====================================================================
-- NATIVE ROBLOX NOTIFICATION TRIGGER (BOTTOM RIGHT)
-- ====================================================================
local function triggerSystemNotification()
    local StarterGui = game:GetService("StarterGui")
    
    -- Wrapped in a safe retry loop because CoreScripts don't always finish loading on tick 1
    task.spawn(function()
        local success = false
        local attempts = 0
        
        while not success and attempts < 10 do
            local ok, err = pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "Bloxfruit Script:",
                    Text = "Fake Gift Send: Active",
                    Duration = 4, -- Stays on screen for 4 seconds
                    -- Icon = "rbxassetid://YOUR_ID" -- Optional: Paste an asset ID here if you want an icon
                })
            end)
            
            if ok then
                success = true
            else
                attempts += 1
                task.wait(0.5) -- Rest a moment before attempting to ping CoreGui again
            end
        end
    end)
end

-- Call it to send the system alert instantly
triggerSystemNotification()
