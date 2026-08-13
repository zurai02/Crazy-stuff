--[[
    Rayfield Interface Suite - DEBUG VERSION v1.3.1
    Minimal working version to isolate failures
--]]

-- ============================================================================
-- REMOTE MODULE LOADING (with error reporting)
-- ============================================================================

local function loadRemoteModule(path)
    local url = getgitpath("src") .. path
    print("[Rayfield] Loading: " .. url)
    local success, result = pcall(function()
        local src = game:HttpGet(url)
        print("[Rayfield] Got " .. #src .. " bytes")
        return loadstring(src)()
    end)
    if not success then
        error("[Rayfield] Failed to load: " .. path .. "\n" .. tostring(result))
    end
    print("[Rayfield] Loaded: " .. path .. " successfully")
    return result
end

-- Load external modules with explicit error handling
local MainModule = loadRemoteModule("Modules/Main%20module.lua")
local C = loadRemoteModule("Modules/C.lua")

-- Verify C.lua exports
print("[Rayfield] C.TweenService = " .. tostring(C.TweenService))
print("[Rayfield] C.Color = " .. tostring(C.Color))
print("[Rayfield] C.Math = " .. tostring(C.Math))
print("[Rayfield] C.Players = " .. tostring(C.Players))

-- Test C.Color functions
local testColor = C.Color:FromHex("#ff0000")
print("[Rayfield] C.Color:FromHex test = " .. tostring(testColor))

local testBrighten = C.Color:Brighten(testColor, 0.1)
print("[Rayfield] C.Color:Brighten test = " .. tostring(testBrighten))

local testDarken = C.Color:Darken(testColor, 0.1)
print("[Rayfield] C.Color:Darken test = " .. tostring(testDarken))

-- Test C.tween
print("[Rayfield] C.tween = " .. tostring(C.tween))

-- Extract utilities
local Vector3Plus = MainModule.Vector3
local SerDes = MainModule.SerDes
local V3 = MainModule.V3

-- Use C.lua services
local TweenService = C.TweenService
local RunService = C.RunService
local UserInputService = C.UserInputService
local HttpService = C.HttpService
local TextService = C.TextService
local GuiService = C.GuiService
local Players = C.Players
local Workspace = C.Workspace

-- ============================================================================
-- RAYFIELD CORE
-- ============================================================================

local Rayfield = {}

-- Theme - using raw Color3 values to eliminate C.Color dependency issues
Rayfield.Theme = {
    Primary = Color3.fromRGB(26, 26, 46),
    Secondary = Color3.fromRGB(22, 33, 62),
    Accent = Color3.fromRGB(15, 52, 96),
    Text = Color3.fromRGB(233, 69, 96),
    Success = Color3.fromRGB(0, 217, 255),
    Error = Color3.fromRGB(255, 0, 110),
}

function Rayfield:CreateWindow(config)
    config = config or {}

    local window = {}
    window.Tabs = {}
    window.ActiveTab = nil
    window.Config = config
    window.Flags = {}
    window.Destroyed = false
    window.Notifications = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "Rayfield"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Parent detection
    local function safeParent(gui)
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = game:GetService("CoreGui")
        elseif gethui then
            gui.Parent = gethui()
        elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
            gui.Parent = game:GetService("CoreGui")
        else
            gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    local success, err = pcall(function()
        safeParent(screenGui)
    end)
    if not success then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    print("[Rayfield] ScreenGui parented successfully")

    -- Shadow container
    local shadowContainer = Instance.new("Frame")
    shadowContainer.Name = "ShadowContainer"
    shadowContainer.Size = UDim2.new(0, 0, 0, 0)
    shadowContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadowContainer.BackgroundTransparency = 1
    shadowContainer.BorderSizePixel = 0
    shadowContainer.ZIndex = 1
    shadowContainer.Parent = screenGui

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 1
    shadow.Parent = shadowContainer

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = Rayfield.Theme.Primary
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.ZIndex = 2
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 40)
    topbar.BackgroundColor3 = Rayfield.Theme.Secondary
    topbar.BorderSizePixel = 0
    topbar.ZIndex = 3
    topbar.Parent = mainFrame

    local topbarCorner = Instance.new("UICorner")
    topbarCorner.CornerRadius = UDim.new(0, 8)
    topbarCorner.Parent = topbar

    local topbarFill = Instance.new("Frame")
    topbarFill.Size = UDim2.new(1, 0, 0, 8)
    topbarFill.Position = UDim2.new(0, 0, 1, -8)
    topbarFill.BackgroundColor3 = Rayfield.Theme.Secondary
    topbarFill.BorderSizePixel = 0
    topbarFill.ZIndex = 3
    topbarFill.Parent = topbar

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -110, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.Name or "Rayfield"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 4
    title.Parent = topbar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Rayfield.Theme.Error
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 4
    closeBtn.Parent = topbar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    local closing = false
    closeBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        C.tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        C.tween(shadowContainer, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        task.delay(0.35, function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            window.Destroyed = true
        end)
    end)

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -70, 0, 5)
    minBtn.BackgroundColor3 = Rayfield.Theme.Accent
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.new(1, 1, 1)
    minBtn.TextSize = 18
    minBtn.Font = Enum.Font.GothamBold
    minBtn.AutoButtonColor = false
    minBtn.ZIndex = 4
    minBtn.Parent = topbar

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minBtn

    local minimized = false
    local originalSize = config.Size or UDim2.new(0, 600, 0, 400)
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            C.tween(mainFrame, {Size = UDim2.new(0, originalSize.X.Offset, 0, 40)}, 0.3)
            C.tween(shadowContainer, {Size = UDim2.new(0, originalSize.X.Offset + 40, 0, 80)}, 0.3)
            tabContainer.Visible = false
            contentArea.Visible = false
            minBtn.Text = "+"
        else
            C.tween(mainFrame, {Size = originalSize}, 0.3)
            C.tween(shadowContainer, {Size = UDim2.new(0, originalSize.X.Offset + 40, 0, originalSize.Y.Offset + 40)}, 0.3)
            task.delay(0.15, function()
                tabContainer.Visible = true
                contentArea.Visible = true
            end)
            minBtn.Text = "-"
        end
    end)

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 120, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Rayfield.Theme.Secondary
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = 3
    tabContainer.Parent = mainFrame

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 5)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.Parent = tabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingBottom = UDim.new(0, 10)
    tabPadding.Parent = tabContainer

    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -120, 1, -40)
    contentArea.Position = UDim2.new(0, 120, 0, 40)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.ZIndex = 3
    contentArea.Parent = mainFrame

    -- Dragging with boundary clamping
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragConnection1, dragConnection2

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    dragConnection1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            local viewport = Workspace.CurrentCamera.ViewportSize
            local frameSize = mainFrame.AbsoluteSize
            newX = math.clamp(newX, -frameSize.X / 2, viewport.X - frameSize.X / 2)
            newY = math.clamp(newY, -frameSize.Y / 2, viewport.Y - frameSize.Y / 2)
            mainFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
            shadowContainer.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)

    dragConnection2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local viewportConn = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if mainFrame and mainFrame.Parent then
            local viewport = Workspace.CurrentCamera.ViewportSize
            local frameSize = mainFrame.AbsoluteSize
            local pos = mainFrame.Position
            local newX = math.clamp(pos.X.Offset, -frameSize.X / 2, viewport.X - frameSize.X / 2)
            local newY = math.clamp(pos.Y.Offset, -frameSize.Y / 2, viewport.Y - frameSize.Y / 2)
            mainFrame.Position = UDim2.new(pos.X.Scale, newX, pos.Y.Scale, newY)
            shadowContainer.Position = UDim2.new(pos.X.Scale, newX, pos.Y.Scale, newY)
        end
    end)

    function window:Unload()
        if window.Destroyed then return end
        window.Destroyed = true
        if dragConnection1 then dragConnection1:Disconnect() end
        if dragConnection2 then dragConnection2:Disconnect() end
        if viewportConn then viewportConn:Disconnect() end
        if C.Player and C.Player.Cleanup then
            C.Player:Cleanup()
        end
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end

    local function autoSave()
        if config.Configuration and config.Configuration.autoSave then
            window:Save()
        end
    end

    -- Tab creation
    function window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}

        local tab = {}
        tab.Name = tabConfig.Name or "Tab"
        tab.Elements = {}

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.Name
        tabBtn.Size = UDim2.new(1, -10, 0, 35)
        tabBtn.Position = UDim2.new(0, 5, 0, 0)
        tabBtn.BackgroundColor3 = Rayfield.Theme.Accent
        tabBtn.Text = tab.Name
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 4
        tabBtn.Parent = tabContainer

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 6)
        tabBtnCorner.Parent = tabBtn

        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tab.Name .. "Content"
        tabContent.Size = UDim2.new(1, -10, 1, -10)
        tabContent.Position = UDim2.new(0, 5, 0, 5)
        tabContent.BackgroundTransparency = 1
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Rayfield.Theme.Accent
        tabContent.ScrollBarImageTransparency = 0.3
        tabContent.Visible = false
        tabContent.ZIndex = 3
        tabContent.Parent = contentArea
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)

        local contentList = Instance.new("UIListLayout")
        contentList.Padding = UDim.new(0, 8)
        contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        contentList.Parent = tabContent

        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingTop = UDim.new(0, 5)
        contentPadding.PaddingBottom = UDim.new(0, 5)
        contentPadding.PaddingLeft = UDim.new(0, 5)
        contentPadding.PaddingRight = UDim.new(0, 5)
        contentPadding.Parent = tabContent

        local function updateCanvas()
            task.wait()
            local contentSize = contentList.AbsoluteContentSize
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 20)
        end

        contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        tabBtn.MouseButton1Click:Connect(function()
            if window.ActiveTab and window.ActiveTab.Content == tabContent then return end
            if window.ActiveTab then
                window.ActiveTab.Content.Visible = false
                C.tween(window.ActiveTab.Button, {BackgroundColor3 = Rayfield.Theme.Accent}, 0.2)
            end
            tabContent.Visible = true
            C.tween(tabBtn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.2)
            window.ActiveTab = {Button = tabBtn, Content = tabContent, Tab = tab}
            task.delay(0.05, updateCanvas)
        end)

        tabBtn.MouseEnter:Connect(function()
            if window.ActiveTab and window.ActiveTab.Button == tabBtn then return end
            C.tween(tabBtn, {BackgroundColor3 = C.Color:Brighten(Rayfield.Theme.Accent, 0.1)}, 0.15)
        end)
        tabBtn.MouseLeave:Connect(function()
            if window.ActiveTab and window.ActiveTab.Button == tabBtn then return end
            C.tween(tabBtn, {BackgroundColor3 = Rayfield.Theme.Accent}, 0.15)
        end)

        -- ========================================================================
        -- ELEMENTS
        -- ========================================================================

        function tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local btn = Instance.new("TextButton")
            btn.Name = btnConfig.Name or "Button"
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = Rayfield.Theme.Accent
            btn.Text = btnConfig.Name or "Button"
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 14
            btn.Font = Enum.Font.Gotham
            btn.AutoButtonColor = false
            btn.ZIndex = 4
            btn.Parent = tabContent

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn

            btn.MouseEnter:Connect(function()
                C.tween(btn, {BackgroundColor3 = C.Color:Brighten(Rayfield.Theme.Accent, 0.15)}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                C.tween(btn, {BackgroundColor3 = Rayfield.Theme.Accent}, 0.15)
            end)
            btn.MouseButton1Down:Connect(function()
                C.tween(btn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.1)
            end)
            btn.MouseButton1Up:Connect(function()
                C.tween(btn, {BackgroundColor3 = C.Color:Brighten(Rayfield.Theme.Accent, 0.15)}, 0.1)
            end)

            btn.MouseButton1Click:Connect(function()
                if btnConfig.Callback then
                    local ok, err = pcall(btnConfig.Callback)
                    if not ok then warn("[Rayfield] Button callback error: " .. tostring(err)) end
                end
            end)

            local handle = {}
            function handle:SetText(text) btn.Text = tostring(text) end
            function handle:GetText() return btn.Text end
            function handle:Destroy() btn:Destroy() end
            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = toggleConfig.Name or "Toggle"
            toggleFrame.Size = UDim2.new(1, 0, 0, 35)
            toggleFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            toggleFrame.ZIndex = 4
            toggleFrame.Parent = tabContent

            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 6)
            toggleCorner.Parent = toggleFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = toggleConfig.Name or "Toggle"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.ZIndex = 5
            label.Parent = toggleFrame

            local switch = Instance.new("Frame")
            switch.Name = "Switch"
            switch.Size = UDim2.new(0, 40, 0, 20)
            switch.Position = UDim2.new(1, -50, 0.5, -10)
            switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            switch.ZIndex = 5
            switch.Parent = toggleFrame

            local switchCorner = Instance.new("UICorner")
            switchCorner.CornerRadius = UDim.new(1, 0)
            switchCorner.Parent = switch

            local knob = Instance.new("Frame")
            knob.Name = "Knob"
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = UDim2.new(0, 2, 0.5, -8)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.ZIndex = 6
            knob.Parent = switch

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = knob

            local enabled = toggleConfig.Default or false
            local flag = toggleConfig.Flag or (toggleConfig.Name and toggleConfig.Name:gsub("%s+", "")) or "Toggle"

            local function updateToggle(skipCallback)
                if enabled then
                    C.tween(switch, {BackgroundColor3 = Rayfield.Theme.Success}, 0.2)
                    C.tween(knob, {Position = UDim2.new(0, 22, 0.5, -8)}, 0.2)
                else
                    C.tween(switch, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2)
                    C.tween(knob, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2)
                end
                window.Flags[flag] = enabled
                if not skipCallback and toggleConfig.Callback then
                    local ok, err = pcall(toggleConfig.Callback, enabled)
                    if not ok then warn("[Rayfield] Toggle callback error: " .. tostring(err)) end
                end
                autoSave()
            end

            local clickDetector = Instance.new("TextButton")
            clickDetector.Name = "ClickDetector"
            clickDetector.Size = UDim2.new(1, 0, 1, 0)
            clickDetector.BackgroundTransparency = 1
            clickDetector.Text = ""
            clickDetector.ZIndex = 7
            clickDetector.Parent = toggleFrame

            clickDetector.MouseButton1Click:Connect(function()
                enabled = not enabled
                updateToggle()
            end)

            if enabled then
                switch.BackgroundColor3 = Rayfield.Theme.Success
                knob.Position = UDim2.new(0, 22, 0.5, -8)
            else
                switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                knob.Position = UDim2.new(0, 2, 0.5, -8)
            end
            window.Flags[flag] = enabled

            local handle = {
                value = enabled,
                Set = function(self, value, skipCallback)
                    enabled = not not value
                    self.value = enabled
                    updateToggle(skipCallback)
                end,
                Get = function(self) return enabled end,
                Destroy = function(self) toggleFrame:Destroy() end,
            }
            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = sliderConfig.Name or "Slider"
            sliderFrame.Size = UDim2.new(1, 0, 0, 50)
            sliderFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            sliderFrame.ZIndex = 4
            sliderFrame.Parent = tabContent

            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 6)
            sliderCorner.Parent = sliderFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = (sliderConfig.Name or "Slider") .. ": " .. tostring(sliderConfig.Default or sliderConfig.Min or 0)
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.ZIndex = 5
            label.Parent = sliderFrame

            local track = Instance.new("Frame")
            track.Name = "Track"
            track.Size = UDim2.new(1, -20, 0, 6)
            track.Position = UDim2.new(0, 10, 0, 32)
            track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            track.BorderSizePixel = 0
            track.ZIndex = 5
            track.Parent = sliderFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Rayfield.Theme.Success
            fill.BorderSizePixel = 0
            fill.ZIndex = 6
            fill.Parent = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill

            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local value = sliderConfig.Default or min
            local flag = sliderConfig.Flag or (sliderConfig.Name and sliderConfig.Name:gsub("%s+", "")) or "Slider"
            local increment = sliderConfig.Increment

            local function updateSlider(inputX, skipCallback)
                local trackPos = track.AbsolutePosition.X
                local trackSize = math.max(track.AbsoluteSize.X, 1)
                local percent = math.clamp((inputX - trackPos) / trackSize, 0, 1)
                local rawValue = min + (max - min) * percent
                if increment and increment > 0 then
                    value = math.floor((rawValue - min) / increment + 0.5) * increment + min
                else
                    value = rawValue
                end
                value = math.clamp(value, min, max)
                local fillPercent = (value - min) / (max - min)
                fill.Size = UDim2.new(fillPercent, 0, 1, 0)
                label.Text = (sliderConfig.Name or "Slider") .. ": " .. C.Math:Round(value, 2)
                window.Flags[flag] = value
                if not skipCallback and sliderConfig.Callback then
                    local ok, err = pcall(sliderConfig.Callback, value)
                    if not ok then warn("[Rayfield] Slider callback error: " .. tostring(err)) end
                end
                autoSave()
            end

            local sliderDragging = false
            local clickDetector = Instance.new("TextButton")
            clickDetector.Name = "ClickDetector"
            clickDetector.Size = UDim2.new(1, 0, 1, 0)
            clickDetector.BackgroundTransparency = 1
            clickDetector.Text = ""
            clickDetector.ZIndex = 7
            clickDetector.Parent = sliderFrame

            clickDetector.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliderDragging = true
                    updateSlider(input.Position.X)
                end
            end)

            local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
                if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input.Position.X)
                end
            end)

            local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliderDragging = false
                end
            end)

            if max > min then
                local initPercent = math.clamp((value - min) / (max - min), 0, 1)
                fill.Size = UDim2.new(initPercent, 0, 1, 0)
                label.Text = (sliderConfig.Name or "Slider") .. ": " .. C.Math:Round(value, 2)
            end
            window.Flags[flag] = value

            local handle = {
                value = value,
                Set = function(self, newValue, skipCallback)
                    value = math.clamp(newValue, min, max)
                    self.value = value
                    local fillPercent = (value - min) / (max - min)
                    fill.Size = UDim2.new(fillPercent, 0, 1, 0)
                    label.Text = (sliderConfig.Name or "Slider") .. ": " .. C.Math:Round(value, 2)
                    window.Flags[flag] = value
                    if not skipCallback and sliderConfig.Callback then
                        local ok, err = pcall(sliderConfig.Callback, value)
                        if not ok then warn("[Rayfield] Slider callback error: " .. tostring(err)) end
                    end
                    autoSave()
                end,
                Get = function(self) return value end,
                Destroy = function(self)
                    if inputChangedConn then inputChangedConn:Disconnect() end
                    if inputEndedConn then inputEndedConn:Disconnect() end
                    sliderFrame:Destroy()
                end,
            }
            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Name = dropdownConfig.Name or "Dropdown"
            dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            dropdownFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            dropdownFrame.ClipsDescendants = false
            dropdownFrame.ZIndex = 4
            dropdownFrame.Parent = tabContent

            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 6)
            dropdownCorner.Parent = dropdownFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -40, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = dropdownConfig.Name or "Dropdown"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.ZIndex = 5
            label.Parent = dropdownFrame

            local arrow = Instance.new("TextLabel")
            arrow.Name = "Arrow"
            arrow.Size = UDim2.new(0, 30, 0, 30)
            arrow.Position = UDim2.new(1, -35, 0.5, -15)
            arrow.BackgroundTransparency = 1
            arrow.Text = "v"
            arrow.TextColor3 = Color3.new(1, 1, 1)
            arrow.TextSize = 12
            arrow.Font = Enum.Font.GothamBold
            arrow.ZIndex = 5
            arrow.Parent = dropdownFrame

            -- FIXED: Options in ScreenGui-level container
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Name = "Options_" .. dropdownFrame.Name
            optionsFrame.Size = UDim2.new(0, 0, 0, 0)
            optionsFrame.Position = UDim2.new(0, 0, 0, 0)
            optionsFrame.BackgroundColor3 = C.Color:Darken(Rayfield.Theme.Secondary, 0.05)
            optionsFrame.BorderSizePixel = 0
            optionsFrame.ClipsDescendants = true
            optionsFrame.Visible = false
            optionsFrame.ZIndex = 100
            optionsFrame.Parent = screenGui

            local optionsCorner = Instance.new("UICorner")
            optionsCorner.CornerRadius = UDim.new(0, 6)
            optionsCorner.Parent = optionsFrame

            local optionsList = Instance.new("UIListLayout")
            optionsList.Padding = UDim.new(0, 2)
            optionsList.Parent = optionsFrame

            local optionsPadding = Instance.new("UIPadding")
            optionsPadding.PaddingTop = UDim.new(0, 4)
            optionsPadding.PaddingBottom = UDim.new(0, 4)
            optionsPadding.PaddingLeft = UDim.new(0, 4)
            optionsPadding.PaddingRight = UDim.new(0, 4)
            optionsPadding.Parent = optionsFrame

            local selected = dropdownConfig.Default
            local open = false
            local flag = dropdownConfig.Flag or (dropdownConfig.Name and dropdownConfig.Name:gsub("%s+", "")) or "Dropdown"
            local multi = dropdownConfig.Multi or false
            local selectedValues = multi and {} or nil

            if selected and multi then
                if type(selected) == "table" then
                    selectedValues = selected
                else
                    selectedValues = {selected}
                end
            end

            local function refreshLabel()
                if multi then
                    if #selectedValues > 0 then
                        label.Text = (dropdownConfig.Name or "Dropdown") .. ": " .. table.concat(selectedValues, ", ")
                    else
                        label.Text = dropdownConfig.Name or "Dropdown"
                    end
                else
                    if selected then
                        label.Text = (dropdownConfig.Name or "Dropdown") .. ": " .. tostring(selected)
                    else
                        label.Text = dropdownConfig.Name or "Dropdown"
                    end
                end
            end

            local function updateOptionsPosition()
                local absPos = dropdownFrame.AbsolutePosition
                local absSize = dropdownFrame.AbsoluteSize
                optionsFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
                optionsFrame.Size = UDim2.new(0, absSize.X, 0, 0)
            end

            local function toggleDropdown()
                open = not open
                if open then
                    updateOptionsPosition()
                    optionsFrame.Visible = true
                    local optionCount = dropdownConfig.Options and #dropdownConfig.Options or 0
                    local targetHeight = math.min(optionCount * 32 + 8, 200)
                    C.tween(optionsFrame, {Size = UDim2.new(0, dropdownFrame.AbsoluteSize.X, 0, targetHeight)}, 0.2)
                    arrow.Text = "^"
                else
                    C.tween(optionsFrame, {Size = UDim2.new(0, dropdownFrame.AbsoluteSize.X, 0, 0)}, 0.2)
                    task.delay(0.2, function()
                        if not open then optionsFrame.Visible = false end
                    end)
                    arrow.Text = "v"
                end
            end

            local clickDetector = Instance.new("TextButton")
            clickDetector.Name = "ClickDetector"
            clickDetector.Size = UDim2.new(1, 0, 1, 0)
            clickDetector.BackgroundTransparency = 1
            clickDetector.Text = ""
            clickDetector.ZIndex = 7
            clickDetector.Parent = dropdownFrame

            clickDetector.MouseButton1Click:Connect(function()
                toggleDropdown()
            end)

            local function buildOptions()
                for _, child in ipairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                if dropdownConfig.Options then
                    for _, option in ipairs(dropdownConfig.Options) do
                        local optionBtn = Instance.new("TextButton")
                        optionBtn.Size = UDim2.new(1, 0, 0, 28)
                        optionBtn.BackgroundColor3 = C.Color:Darken(Rayfield.Theme.Secondary, 0.05)
                        optionBtn.Text = option
                        optionBtn.TextColor3 = Color3.new(1, 1, 1)
                        optionBtn.TextSize = 13
                        optionBtn.Font = Enum.Font.Gotham
                        optionBtn.AutoButtonColor = false
                        optionBtn.ZIndex = 101
                        optionBtn.Parent = optionsFrame

                        local optionCorner = Instance.new("UICorner")
                        optionCorner.CornerRadius = UDim.new(0, 4)
                        optionCorner.Parent = optionBtn

                        optionBtn.MouseEnter:Connect(function()
                            C.tween(optionBtn, {BackgroundColor3 = C.Color:Brighten(Rayfield.Theme.Accent, 0.1)}, 0.1)
                        end)
                        optionBtn.MouseLeave:Connect(function()
                            C.tween(optionBtn, {BackgroundColor3 = C.Color:Darken(Rayfield.Theme.Secondary, 0.05)}, 0.1)
                        end)

                        optionBtn.MouseButton1Click:Connect(function()
                            if multi then
                                local found = false
                                for i, v in ipairs(selectedValues) do
                                    if v == option then
                                        table.remove(selectedValues, i)
                                        found = true
                                        break
                                    end
                                end
                                if not found then
                                    table.insert(selectedValues, option)
                                end
                                window.Flags[flag] = selectedValues
                                if dropdownConfig.Callback then
                                    local ok, err = pcall(dropdownConfig.Callback, selectedValues)
                                    if not ok then warn("[Rayfield] Dropdown callback error: " .. tostring(err)) end
                                end
                            else
                                selected = option
                                window.Flags[flag] = selected
                                toggleDropdown()
                                if dropdownConfig.Callback then
                                    local ok, err = pcall(dropdownConfig.Callback, selected)
                                    if not ok then warn("[Rayfield] Dropdown callback error: " .. tostring(err)) end
                                end
                            end
                            refreshLabel()
                            autoSave()
                        end)
                    end
                end
            end

            buildOptions()
            refreshLabel()

            local posConn = mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
                if open then
                    updateOptionsPosition()
                end
            end)

            local handle = {
                value = multi and selectedValues or selected,
                Set = function(self, value, skipCallback)
                    if multi then
                        selectedValues = type(value) == "table" and value or {value}
                        self.value = selectedValues
                        window.Flags[flag] = selectedValues
                    else
                        selected = value
                        self.value = selected
                        window.Flags[flag] = selected
                    end
                    refreshLabel()
                    if not skipCallback and dropdownConfig.Callback then
                        local ok, err = pcall(dropdownConfig.Callback, self.value)
                        if not ok then warn("[Rayfield] Dropdown callback error: " .. tostring(err)) end
                    end
                    autoSave()
                end,
                Get = function(self) return multi and selectedValues or selected end,
                Refresh = function(self, newOptions)
                    dropdownConfig.Options = newOptions
                    buildOptions()
                end,
                Destroy = function(self)
                    if posConn then posConn:Disconnect() end
                    optionsFrame:Destroy()
                    dropdownFrame:Destroy()
                end,
            }
            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateInput(inputConfig)
            inputConfig = inputConfig or {}
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = inputConfig.Name or "Input"
            inputFrame.Size = UDim2.new(1, 0, 0, 35)
            inputFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            inputFrame.ZIndex = 4
            inputFrame.Parent = tabContent

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.4, -5, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = inputConfig.Name or "Input"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.ZIndex = 5
            label.Parent = inputFrame

            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0.6, -15, 0, 25)
            textBox.Position = UDim2.new(0.4, 5, 0.5, -12)
            textBox.BackgroundColor3 = Rayfield.Theme.Primary
            textBox.Text = inputConfig.Default or ""
            textBox.PlaceholderText = inputConfig.Placeholder or ""
            textBox.TextColor3 = Color3.new(1, 1, 1)
            textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            textBox.TextSize = 13
            textBox.Font = Enum.Font.Gotham
            textBox.ClearTextOnFocus = false
            textBox.ZIndex = 5
            textBox.Parent = inputFrame

            local textCorner = Instance.new("UICorner")
            textCorner.CornerRadius = UDim.new(0, 4)
            textCorner.Parent = textBox

            textBox.Focused:Connect(function()
                C.tween(textBox, {BackgroundColor3 = C.Color:Brighten(Rayfield.Theme.Primary, 0.05)}, 0.15)
            end)
            textBox.FocusLost:Connect(function()
                C.tween(textBox, {BackgroundColor3 = Rayfield.Theme.Primary}, 0.15)
            end)

            local flag = inputConfig.Flag or (inputConfig.Name and inputConfig.Name:gsub("%s+", "")) or "Input"
            window.Flags[flag] = textBox.Text

            textBox.FocusLost:Connect(function(enterPressed)
                window.Flags[flag] = textBox.Text
                if inputConfig.Callback then
                    local ok, err = pcall(inputConfig.Callback, textBox.Text, enterPressed)
                    if not ok then warn("[Rayfield] Input callback error: " .. tostring(err)) end
                end
                autoSave()
            end)

            if inputConfig.Numeric then
                textBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local text = textBox.Text
                    if text ~= "" and text ~= "-" then
                        local num = tonumber(text)
                        if not num then
                            textBox.Text = text:sub(1, -2)
                        end
                    end
                end)
            end

            local handle = {
                value = textBox.Text,
                Set = function(self, value, skipCallback)
                    textBox.Text = tostring(value)
                    self.value = textBox.Text
                    window.Flags[flag] = textBox.Text
                    if not skipCallback and inputConfig.Callback then
                        local ok, err = pcall(inputConfig.Callback, textBox.Text, false)
                        if not ok then warn("[Rayfield] Input callback error: " .. tostring(err)) end
                    end
                    autoSave()
                end,
                Get = function(self) return textBox.Text end,
                Destroy = function(self) inputFrame:Destroy() end,
            }
            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateKeybind(keybindConfig)
            keybindConfig = keybindConfig or {}
            local keybindFrame = Instance.new("Frame")
            keybindFrame.Name = keybindConfig.Name or "Keybind"
            keybindFrame.Size = UDim2.new(1, 0, 0, 35)
            keybindFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            keybindFrame.ZIndex = 4
            keybindFrame.Parent = tabContent

            local keybindCorner = Instance.new("UICorner")
            keybindCorner.CornerRadius = UDim.new(0, 6)
            keybindCorner.Parent = keybindFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -80, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = keybindConfig.Name or "Keybind"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.ZIndex = 5
            label.Parent = keybindFrame

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 70, 0, 25)
            keyBtn.Position = UDim2.new(1, -75, 0.5, -12)
            keyBtn.BackgroundColor3 = Rayfield.Theme.Primary
            keyBtn.Text = keybindConfig.Default and tostring(keybindConfig.Default.Name) or "None"
            keyBtn.TextColor3 = Color3.new(1, 1, 1)
            keyBtn.TextSize = 12
            keyBtn.Font = Enum.Font.Gotham
            keyBtn.AutoButtonColor = false
            keyBtn.ZIndex = 5
            keyBtn.Parent = keybindFrame

            local keyBtnCorner = Instance.new("UICorner")
            keyBtnCorner.CornerRadius = UDim.new(0, 4)
            keyBtnCorner.Parent = keyBtn

            local currentKey = keybindConfig.Default
            local flag = keybindConfig.Flag or (keybindConfig.Name and keybindConfig.Name:gsub("%s+", "")) or "Keybind"
            local listening = false
            local inputConn


                        Utilities:Tween(keyBtn, {BackgroundColor3 = tab.Theme.Primary}, 0.15)
                        if inputConn then inputConn:Disconnect() end
                        if keybindConfig.onChanged then
                            local ok, err = pcall(keybindConfig.onChanged, currentKey)
                            if not ok then warn("[Rayfield] Keybind error: " .. tostring(err)) end
                        end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        listening = false
                        keyBtn.Text = currentKey and currentKey.Name or "None"
                        Utilities:Tween(keyBtn, {BackgroundColor3 = tab.Theme.Primary}, 0.15)
                        if inputConn then inputConn:Disconnect() end
                    end
                end)
            end)

            local pressConn = UserInputService.InputBegan:Connect(function(input)
                if not listening and currentKey and input.KeyCode == currentKey then
                    if keybindConfig.Callback then
                        local ok, err = pcall(keybindConfig.Callback)
                        if not ok then warn("[Rayfield] Keybind error: " .. tostring(err)) end
                    end
                end
            end)

            window.Flags[flag] = currentKey and currentKey.Name or nil

            return {
                Set = function(self, key)
                    currentKey = key
                    keyBtn.Text = currentKey and currentKey.Name or "None"
                    window.Flags[flag] = currentKey and currentKey.Name or nil
                end,
                Get = function(self) return currentKey end,
                Destroy = function(self)
                    if inputConn then inputConn:Disconnect() end
                    pressConn:Disconnect()
                    keybindFrame:Destroy()
                end,
            }
        end

        function tab:CreateColorPicker(colorConfig)
            colorConfig = colorConfig or {}
            local pickerFrame = Instance.new("Frame")
            pickerFrame.Name = colorConfig.Name or "ColorPicker"
            pickerFrame.Size = UDim2.new(1, 0, 0, 38)
            pickerFrame.BackgroundColor3 = tab.Theme.Secondary
            pickerFrame.Parent = tabContent

            local pickerCorner = Instance.new("UICorner")
            pickerCorner.CornerRadius = UDim.new(0, 8)
            pickerCorner.Parent = pickerFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = colorConfig.Name or "Color"
            label.TextColor3 = tab.Theme.Foreground
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = pickerFrame

            local colorPreview = Instance.new("Frame")
            colorPreview.Size = UDim2.new(0, 36, 0, 28)
            colorPreview.Position = UDim2.new(1, -48, 0.5, -14)
            colorPreview.BackgroundColor3 = colorConfig.Default or Color3.fromRGB(255, 255, 255)
            colorPreview.BorderSizePixel = 0
            colorPreview.Parent = pickerFrame

            local previewCorner = Instance.new("UICorner")
            previewCorner.CornerRadius = UDim.new(0, 6)
            previewCorner.Parent = colorPreview

            local currentColor = colorConfig.Default or Color3.fromRGB(255, 255, 255)
            local flag = colorConfig.Flag or (colorConfig.Name and colorConfig.Name:gsub("%s+", "")) or "Color"
            window.Flags[flag] = {
                R = currentColor.R,
                G = currentColor.G,
                B = currentColor.B
            }

            local pickerOpen = false
            local pickerPanel = Instance.new("Frame")
            pickerPanel.Size = UDim2.new(0, 200, 0, 0)
            pickerPanel.Position = UDim2.new(0, 0, 0, 0)
            pickerPanel.BackgroundColor3 = tab.Theme.Primary
            pickerPanel.BorderSizePixel = 0
            pickerPanel.Visible = false
            pickerPanel.ZIndex = 100
            pickerPanel.Parent = screenGui

            local panelCorner = Instance.new("UICorner")
            panelCorner.CornerRadius = UDim.new(0, 8)
            panelCorner.Parent = pickerPanel

            -- Hue slider
            local hueTrack = Instance.new("Frame")
            hueTrack.Size = UDim2.new(1, -20, 0, 12)
            hueTrack.Position = UDim2.new(0, 10, 0, 10)
            hueTrack.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            hueTrack.BorderSizePixel = 0
            hueTrack.Parent = pickerPanel

            local hueCorner = Instance.new("UICorner")
            hueCorner.CornerRadius = UDim.new(1, 0)
            hueCorner.Parent = hueTrack

            -- Saturation/Value box
            local svBox = Instance.new("Frame")
            svBox.Size = UDim2.new(1, -20, 0, 80)
            svBox.Position = UDim2.new(0, 10, 0, 32)
            svBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            svBox.BorderSizePixel = 0
            svBox.Parent = pickerPanel

            local svCorner = Instance.new("UICorner")
            svCorner.CornerRadius = UDim.new(0, 6)
            svCorner.Parent = svBox

            local clickDetector = Instance.new("TextButton")
            clickDetector.Size = UDim2.new(1, 0, 1, 0)
            clickDetector.BackgroundTransparency = 1
            clickDetector.Text = ""
            clickDetector.Parent = pickerFrame

            clickDetector.MouseButton1Click:Connect(function()
                pickerOpen = not pickerOpen
                if pickerOpen then
                    local absPos = pickerFrame.AbsolutePosition
                    local absSize = pickerFrame.AbsoluteSize
                    pickerPanel.Position = UDim2.new(0, absPos.X + absSize.X - 210, 0, absPos.Y + absSize.Y + 2)
                    pickerPanel.Visible = true
                    Utilities:Tween(pickerPanel, {Size = UDim2.new(0, 200, 0, 120)}, 0.2)
                else
                    Utilities:Tween(pickerPanel, {Size = UDim2.new(0, 200, 0, 0)}, 0.2)
                    task.delay(0.2, function() if not pickerOpen then pickerPanel.Visible = false end end)
                end
            end)

            return {
                Set = function(self, color)
                    currentColor = color
                    colorPreview.BackgroundColor3 = color
                    window.Flags[flag] = {R = color.R, G = color.G, B = color.B}
                    if colorConfig.Callback then
                        local ok, err = pcall(colorConfig.Callback, color)
                        if not ok then warn("[Rayfield] ColorPicker error: " .. tostring(err)) end
                    end
                end,
                Get = function(self) return currentColor end,
                Destroy = function(self)
                    pickerPanel:Destroy()
                    pickerFrame:Destroy()
                end,
            }
        end

        function tab:CreateLabel(labelConfig)
            labelConfig = labelConfig or {}
            local labelFrame = Instance.new("Frame")
            labelFrame.Name = labelConfig.Name or "Label"
            labelFrame.Size = UDim2.new(1, 0, 0, labelConfig.Size == "Large" and 35 or 25)
            labelFrame.BackgroundTransparency = 1
            labelFrame.Parent = tabContent

            local labelText = Instance.new("TextLabel")
            labelText.Size = UDim2.new(1, -20, 1, 0)
            labelText.Position = UDim2.new(0, 10, 0, 0)
            labelText.BackgroundTransparency = 1
            labelText.Text = labelConfig.Text or labelConfig.Name or "Label"
            labelText.TextColor3 = labelConfig.Color or tab.Theme.Muted
            labelText.TextSize = labelConfig.Size == "Large" and 18 or (labelConfig.Size == "Small" and 11 or 14)
            labelText.Font = labelConfig.Bold and Enum.Font.GothamBold or Enum.Font.Gotham
            labelText.TextXAlignment = labelConfig.Alignment or Enum.TextXAlignment.Left
            labelText.TextWrapped = true
            labelText.Parent = labelFrame

            return {
                Set = function(self, text) labelText.Text = tostring(text) end,
                Get = function(self) return labelText.Text end,
                Destroy = function(self) labelFrame:Destroy() end,
            }
        end

        function tab:CreateParagraph(paraConfig)
            paraConfig = paraConfig or {}
            local paraFrame = Instance.new("Frame")
            paraFrame.Name = paraConfig.Name or "Paragraph"
            paraFrame.Size = UDim2.new(1, 0, 0, 60)
            paraFrame.BackgroundColor3 = tab.Theme.Secondary
            paraFrame.Parent = tabContent

            local paraCorner = Instance.new("UICorner")
            paraCorner.CornerRadius = UDim.new(0, 8)
            paraCorner.Parent = paraFrame

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -20, 0, 20)
            title.Position = UDim2.new(0, 10, 0, 6)
            title.BackgroundTransparency = 1
            title.Text = paraConfig.Title or ""
            title.TextColor3 = tab.Theme.Foreground
            title.TextSize = 14
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = paraFrame

            local content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, -20, 0, 30)
            content.Position = UDim2.new(0, 10, 0, 26)
            content.BackgroundTransparency = 1
            content.Text = paraConfig.Content or ""
            content.TextColor3 = tab.Theme.Muted
            content.TextSize = 12
            content.Font = Enum.Font.Gotham
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextWrapped = true
            content.Parent = paraFrame

            return {
                SetTitle = function(self, text) title.Text = tostring(text) end,
                SetContent = function(self, text) content.Text = tostring(text) end,
                Destroy = function(self) paraFrame:Destroy() end,
            }
        end

        function tab:CreateDivider()
            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.Size = UDim2.new(1, -20, 0, 1)
            divider.Position = UDim2.new(0, 10, 0, 0)
            divider.BackgroundColor3 = tab.Theme.Accent
            divider.BackgroundTransparency = 0.8
            divider.BorderSizePixel = 0
            divider.Parent = tabContent

            return {
                Destroy = function(self) divider:Destroy() end,
            }
        end

        function tab:CreateImage(imageConfig)
            imageConfig = imageConfig or {}
            local imgFrame = Instance.new("Frame")
            imgFrame.Name = imageConfig.Name or "Image"
            imgFrame.Size = UDim2.new(1, 0, 0, imageConfig.Height or 100)
            imgFrame.BackgroundColor3 = tab.Theme.Secondary
            imgFrame.Parent = tabContent

            local imgCorner = Instance.new("UICorner")
            imgCorner.CornerRadius = UDim.new(0, 8)
            imgCorner.Parent = imgFrame

            local imgLabel = Instance.new("ImageLabel")
            imgLabel.Size = UDim2.new(1, -10, 1, -10)
            imgLabel.Position = UDim2.new(0, 5, 0, 5)
            imgLabel.BackgroundTransparency = 1
            imgLabel.Image = imageConfig.Image or ""
            imgLabel.ScaleType = Enum.ScaleType.Fit
            imgLabel.Parent = imgFrame

            return {
                SetImage = function(self, id) imgLabel.Image = id end,
                Destroy = function(self) imgFrame:Destroy() end,
            }
        end

        -- First tab activation
        if not window.ActiveTab then
            tabContent.Visible = true
            Utilities:Tween(tabBtn, {BackgroundColor3 = tab.Theme.Text}, 0.2)
            window.ActiveTab = {Button = tabBtn, Content = tabContent, Tab = tab}
        end

        table.insert(window.Tabs, tab)
        return tab
    end

    -- ============================================================================
    -- WINDOW METHODS
    -- ============================================================================

    function window:Notify(notifyConfig)
        return notifSystem:Notify(notifyConfig)
    end

    function window:Show()
        mainContainer.Visible = true
        Utilities:Tween(mainContainer, {Size = window.OriginalSize}, 0.3)
    end

    function window:Hide()
        Utilities:Tween(mainContainer, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.delay(0.3, function() mainContainer.Visible = false end)
    end

    function window:Toggle()
        if mainContainer.Size.X.Offset > 50 then
            window:Hide()
        else
            window:Show()
        end
    end

    function window:Navigate(tabName)
        for _, tab in ipairs(window.Tabs) do
            if tab.Name == tabName then
                for _, child in ipairs(tabListFrame:GetChildren()) do
                    if child:IsA("TextButton") and child.Name == tabName then
                        child.MouseButton1Click:Fire()
                        return true
                    end
                end
            end
        end
        return false
    end

    function window:Save(name)
        if not config.Configuration then return false end
        local fileName = name or (config.Configuration.fileName or config.Name or "Rayfield")
        local folder = config.Configuration.folder or "RayfieldConfigs"
        local path = folder .. "/" .. fileName .. ".json"

        local data = {}
        for flag, value in pairs(window.Flags) do
            data[flag] = value
        end

        local json = HttpService:JSONEncode(data)
        if writefile then
            makefolder(folder)
            writefile(path, json)
            return true
        end
        return false
    end

    function window:Load(name)
        if not config.Configuration then return false end
        local fileName = name or (config.Configuration.fileName or config.Name or "Rayfield")
        local folder = config.Configuration.folder or "RayfieldConfigs"
        local path = folder .. "/" .. fileName .. ".json"

        if readfile and isfile and isfile(path) then
            local json = readfile(path)
            local data = HttpService:JSONDecode(json)
            for flag, value in pairs(data) do
                window.Flags[flag] = value
                for _, tab in ipairs(window.Tabs) do
                    for _, elem in ipairs(tab.Elements) do
                        if elem.Set then elem:Set(value) end
                    end
                end
            end
            return true
        end
        return false
    end

    function window:Get(flag)
        return window.Flags[flag]
    end

    function window:Set(flag, value)
        window.Flags[flag] = value
        for _, tab in ipairs(window.Tabs) do
            for _, elem in ipairs(tab.Elements) do
                if elem.Set then elem:Set(value) end
            end
        end
    end

    function window:Unload()
        if window.Destroyed then return end
        window.Destroyed = true
        screenGui:Destroy()
    end

    table.insert(Rayfield.Windows, window)
    return window
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Rayfield.Vector3 = Vector3Plus
Rayfield.V3 = V3
Rayfield.SerDes = SerDes
Rayfield.SD = SerDes
Rayfield.C = C

function Rayfield:Serialize(data, schema)
    if schema then return SerDes.Serialize(schema, data)
    else return SerDes.SerializeTable(data) end
end

function Rayfield:Deserialize(buffer, schema)
    if schema then return SerDes.Deserialize(schema, buffer)
    else return SerDes.DeserializeTable(buffer) end
end

function Rayfield:Encode(data)
    return SerDes.BufferToBase64(SerDes.SerializeTable(data))
end

function Rayfield:Decode(base64String)
    return SerDes.DeserializeTable(SerDes.Base64ToBuffer(base64String))
end

return Rayfield


-- ============================================================================
-- FPS COUNTER (Integrated, not separate)
-- ============================================================================

function Rayfield:CreateFPSCounter(parent)
    local fpsFrame = Instance.new("Frame")
    fpsFrame.Name = "FPSCounter"
    fpsFrame.Size = UDim2.new(0, 80, 0, 24)
    fpsFrame.Position = UDim2.new(1, -90, 0, 8)
    fpsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fpsFrame.BackgroundTransparency = 0.5
    fpsFrame.BorderSizePixel = 0
    fpsFrame.Parent = parent

    local fpsCorner = Instance.new("UICorner")
    fpsCorner.CornerRadius = UDim.new(0, 6)
    fpsCorner.Parent = fpsFrame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
    fpsLabel.TextSize = 12
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.Parent = fpsFrame

    local fps = 0
    local lastUpdate = tick()
    local frameCount = 0

    local conn = RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            fps = frameCount
            frameCount = 0
            lastUpdate = now
            fpsLabel.Text = "FPS: " .. fps
            if fps >= 55 then
                fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        end
    end)

    return {
        Frame = fpsFrame,
        Disconnect = function() conn:Disconnect() end,
    }
end

-- ============================================================================
-- KEY SYSTEM
-- ============================================================================

function Rayfield:CreateKeySystem(config)
    config = config or {}
    local keyValid = false
    local checkedKeys = {}

    local keyWindow = self:CreateWindow({
        Name = config.Title or "Key System",
        Size = UDim2.new(0, 400, 0, 250),
    })

    local tab = keyWindow:CreateTab({Name = "Key"})

    tab:CreateLabel({Text = config.Description or "Enter your key to continue", Size = "Large", Bold = true})
    tab:CreateDivider()

    local keyInput = tab:CreateInput({
        Name = "Key",
        Placeholder = "Enter key...",
    })

    local statusLabel = tab:CreateLabel({Text = "Status: Waiting...", Color = Color3.fromRGB(200, 200, 200)})

    tab:CreateButton({
        Name = "Submit Key",
        Callback = function()
            local key = keyInput:Get()
            if config.Keys then
                for _, validKey in ipairs(config.Keys) do
                    if key == validKey then
                        keyValid = true
                        statusLabel:Set("Status: Valid!")
                        task.delay(1, function()
                            keyWindow:Unload()
                            if config.OnValid then
                                local ok, err = pcall(config.OnValid)
                                if not ok then warn("[Rayfield] KeySystem error: " .. tostring(err)) end
                            end
                        end)
                        return
                    end
                end
            end
            if config.ValidateUrl then
                local ok, result = pcall(function()
                    return game:HttpGet(config.ValidateUrl .. "?key=" .. key)
                end)
                if ok and result == "valid" then
                    keyValid = true
                    statusLabel:Set("Status: Valid!")
                    task.delay(1, function()
                        keyWindow:Unload()
                        if config.OnValid then
                            local ok2, err = pcall(config.OnValid)
                            if not ok2 then warn("[Rayfield] KeySystem error: " .. tostring(err)) end
                        end
                    end)
                    return
                end
            end
            statusLabel:Set("Status: Invalid key")
        end,
    })

    if config.DiscordLink then
        tab:CreateButton({
            Name = "Get Key (Discord)",
            Callback = function()
                if setclipboard then
                    setclipboard(config.DiscordLink)
                    statusLabel:Set("Discord link copied!")
                else
                    statusLabel:Set("Cannot copy - no setclipboard")
                end
            end,
        })
    end

    return keyWindow
end

-- ============================================================================
-- DISCORD RICH PRESENCE / AUTO JOIN
-- ============================================================================

function Rayfield:SetDiscordPresence(config)
    config = config or {}
    if syn and syn.set_discord_rpc then
        pcall(function()
            syn.set_discord_rpc({
                details = config.Details or "Using Rayfield UI",
                state = config.State or "v" .. Rayfield.Version,
                startTimestamp = tick(),
                largeImageKey = config.LargeImage or "logo",
                largeImageText = config.LargeText or "Rayfield",
                smallImageKey = config.SmallImage,
                smallImageText = config.SmallText,
            })
        end)
    end
end

function Rayfield:JoinDiscord(inviteCode)
    if syn and syn.request then
        local ok = pcall(function()
            syn.request({
                Url = "http://127.0.0.1:6463/rpc?v=1",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Origin"] = "https://discord.com",
                },
                Body = HttpService:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    nonce = HttpService:GenerateGUID(false),
                    args = {code = inviteCode},
                }),
            })
        end)
        return ok
    end
    return false
end

-- ============================================================================
-- ANIMATION PRESETS
-- ============================================================================

Rayfield.Animations = {
    FadeIn = function(obj, duration)
        obj.BackgroundTransparency = 1
        Utilities:Tween(obj, {BackgroundTransparency = 0}, duration or 0.3)
    end,
    SlideInLeft = function(obj, duration)
        local target = obj.Position
        obj.Position = target - UDim2.new(0, 50, 0, 0)
        obj.Visible = true
        Utilities:Tween(obj, {Position = target}, duration or 0.3, Enum.EasingStyle.Back)
    end,
    SlideInRight = function(obj, duration)
        local target = obj.Position
        obj.Position = target + UDim2.new(0, 50, 0, 0)
        obj.Visible = true
        Utilities:Tween(obj, {Position = target}, duration or 0.3, Enum.EasingStyle.Back)
    end,
    SlideInUp = function(obj, duration)
        local target = obj.Position
        obj.Position = target + UDim2.new(0, 0, 0, 50)
        obj.Visible = true
        Utilities:Tween(obj, {Position = target}, duration or 0.3, Enum.EasingStyle.Back)
    end,
    SlideInDown = function(obj, duration)
        local target = obj.Position
        obj.Position = target - UDim2.new(0, 0, 0, 50)
        obj.Visible = true
        Utilities:Tween(obj, {Position = target}, duration or 0.3, Enum.EasingStyle.Back)
    end,
    ScaleIn = function(obj, duration)
        obj.Size = UDim2.new(0, 0, 0, 0)
        obj.Visible = true
        Utilities:Tween(obj, {Size = UDim2.new(1, 0, 1, 0)}, duration or 0.3, Enum.EasingStyle.Back)
    end,
    Pulse = function(obj, duration)
        local original = obj.Size
        Utilities:Tween(obj, {Size = original + UDim2.new(0, 10, 0, 10)}, duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
            Utilities:Tween(obj, {Size = original}, duration or 0.15)
        end)
    end,
    Shake = function(obj, duration)
        duration = duration or 0.5
        local original = obj.Position
        local start = tick()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - start
            if elapsed >= duration then
                obj.Position = original
                conn:Disconnect()
                return
            end
            local offset = math.sin(elapsed * 50) * 5 * (1 - elapsed / duration)
            obj.Position = original + UDim2.new(0, offset, 0, 0)
        end)
    end,
}

-- ============================================================================
-- SOUND EFFECTS
-- ============================================================================

Rayfield.Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079853",
    Toggle = "rbxassetid://6895079853",
    Error = "rbxassetid://6895079853",
    Success = "rbxassetid://6895079853",
}

function Rayfield:PlaySound(soundId, volume)
    volume = volume or 0.5
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Parent = Workspace
    sound:Play()
    task.delay(sound.TimeLength + 0.5, function()
        sound:Destroy()
    end)
end

-- ============================================================================
-- MOBILE DETECTION
-- ============================================================================

Rayfield.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

function Rayfield:OptimizeForMobile()
    if self.IsMobile then
        -- Increase touch targets
        -- Simplify UI
        -- Add mobile-specific controls
        return true
    end
    return false
end

-- ============================================================================
-- DEBUG CONSOLE
-- ============================================================================

function Rayfield:CreateDebugConsole(parent)
    local console = Instance.new("Frame")
    console.Name = "DebugConsole"
    console.Size = UDim2.new(0, 400, 0, 200)
    console.Position = UDim2.new(0, 10, 0, 10)
    console.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    console.BorderSizePixel = 0
    console.Visible = false
    console.Parent = parent

    local consoleCorner = Instance.new("UICorner")
    consoleCorner.CornerRadius = UDim.new(0, 8)
    consoleCorner.Parent = console

    local consoleTitle = Instance.new("TextLabel")
    consoleTitle.Size = UDim2.new(1, 0, 0, 24)
    consoleTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    consoleTitle.Text = "Debug Console"
    consoleTitle.TextColor3 = Color3.new(1, 1, 1)
    consoleTitle.TextSize = 12
    consoleTitle.Font = Enum.Font.GothamBold
    consoleTitle.Parent = console

    local consoleOutput = Instance.new("ScrollingFrame")
    consoleOutput.Size = UDim2.new(1, -10, 1, -60)
    consoleOutput.Position = UDim2.new(0, 5, 0, 28)
    consoleOutput.BackgroundTransparency = 1
    consoleOutput.ScrollBarThickness = 4
    consoleOutput.CanvasSize = UDim2.new(0, 0, 0, 0)
    consoleOutput.Parent = console

    local outputList = Instance.new("UIListLayout")
    outputList.Padding = UDim.new(0, 2)
    outputList.Parent = consoleOutput

    local consoleInput = Instance.new("TextBox")
    consoleInput.Size = UDim2.new(1, -10, 0, 24)
    consoleInput.Position = UDim2.new(0, 5, 1, -28)
    consoleInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    consoleInput.Text = ""
    consoleInput.PlaceholderText = "> "
    consoleInput.TextColor3 = Color3.new(1, 1, 1)
    consoleInput.TextSize = 12
    consoleInput.Font = Enum.Font.Gotham
    consoleInput.Parent = console

    local function log(msg, color)
        color = color or Color3.new(1, 1, 1)
        local line = Instance.new("TextLabel")
        line.Size = UDim2.new(1, 0, 0, 16)
        line.BackgroundTransparency = 1
        line.Text = tostring(msg)
        line.TextColor3 = color
        line.TextSize = 11
        line.Font = Enum.Font.Gotham
        line.TextXAlignment = Enum.TextXAlignment.Left
        line.Parent = consoleOutput
        consoleOutput.CanvasSize = UDim2.new(0, 0, 0, outputList.AbsoluteContentSize.Y + 10)
    end

    consoleInput.FocusLost:Connect(function()
        local cmd = consoleInput.Text
        if cmd ~= "" then
            log("> " .. cmd, Color3.fromRGB(100, 200, 255))
            local ok, result = pcall(function()
                return loadstring(cmd)()
            end)
            if ok then
                log(tostring(result), Color3.fromRGB(0, 255, 128))
            else
                log("ERROR: " .. tostring(result), Color3.fromRGB(255, 50, 50))
            end
            consoleInput.Text = ""
        end
    end)

    return {
        Frame = console,
        Log = log,
        Show = function() console.Visible = true end,
        Hide = function() console.Visible = false end,
        Toggle = function() console.Visible = not console.Visible end,
    }
end

-- ============================================================================
-- THEME PREVIEW
-- ============================================================================

function Rayfield:CreateThemePreview(parent)
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 200, 0, 300)
    preview.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    preview.Parent = parent

    local yOffset = 10
    for name, theme in pairs(Themes) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 30)
        btn.Position = UDim2.new(0, 10, 0, yOffset)
        btn.BackgroundColor3 = theme.Primary
        btn.Text = name
        btn.TextColor3 = theme.Foreground
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.Parent = preview

        btn.MouseButton1Click:Connect(function()
            self:SetTheme(name)
        end)

        yOffset = yOffset + 35
    end

    return preview
end

-- ============================================================================
-- PERFORMANCE MONITOR
-- ============================================================================

function Rayfield:CreatePerformanceMonitor(parent)
    local monitor = Instance.new("Frame")
    monitor.Name = "PerformanceMonitor"
    monitor.Size = UDim2.new(0, 200, 0, 100)
    monitor.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    monitor.BorderSizePixel = 0
    monitor.Parent = parent

    local monitorCorner = Instance.new("UICorner")
    monitorCorner.CornerRadius = UDim.new(0, 8)
    monitorCorner.Parent = monitor

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, -10, 0, 20)
    fpsLabel.Position = UDim2.new(0, 5, 0, 5)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.new(1, 1, 1)
    fpsLabel.TextSize = 12
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = monitor

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, -10, 0, 20)
    pingLabel.Position = UDim2.new(0, 5, 0, 25)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: --"
    pingLabel.TextColor3 = Color3.new(1, 1, 1)
    pingLabel.TextSize = 12
    pingLabel.Font = Enum.Font.Gotham
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = monitor

    local memoryLabel = Instance.new("TextLabel")
    memoryLabel.Size = UDim2.new(1, -10, 0, 20)
    memoryLabel.Position = UDim2.new(0, 5, 0, 45)
    memoryLabel.BackgroundTransparency = 1
    memoryLabel.Text = "Memory: --"
    memoryLabel.TextColor3 = Color3.new(1, 1, 1)
    memoryLabel.TextSize = 12
    memoryLabel.Font = Enum.Font.Gotham
    memoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    memoryLabel.Parent = monitor

    local fps = 0
    local lastUpdate = tick()
    local frameCount = 0

    local conn = RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            fps = frameCount
            frameCount = 0
            lastUpdate = now
            fpsLabel.Text = "FPS: " .. fps

            local mem = math.floor(collectgarbage("count") / 1024 * 100) / 100
            memoryLabel.Text = "Memory: " .. mem .. " MB"
        end
    end)

    return {
        Frame = monitor,
        Disconnect = function() conn:Disconnect() end,
    }
end

-- ============================================================================
-- AUTO-SAVE SYSTEM
-- ============================================================================

function Rayfield:EnableAutoSave(window, interval)
    interval = interval or 30
    local lastSave = tick()

    local conn = RunService.Heartbeat:Connect(function()
        if tick() - lastSave >= interval then
            lastSave = tick()
            window:Save()
        end
    end)

    return conn
end

-- ============================================================================
-- DRAGGABLE SYSTEM (Global)
-- ============================================================================

function Rayfield:MakeDraggable(obj, handle)
    handle = handle or obj
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ============================================================================
-- RESIZABLE SYSTEM
-- ============================================================================

function Rayfield:MakeResizable(obj, minSize, maxSize)
    minSize = minSize or UDim2.new(0, 200, 0, 150)
    maxSize = maxSize or UDim2.new(0, 1000, 0, 800)

    local handle = Instance.new("Frame")
    handle.Name = "ResizeHandle"
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new(1, -16, 1, -16)
    handle.BackgroundTransparency = 1
    handle.Parent = obj

    local resizeConn1, resizeConn2, resizeConn3
    local resizing = false
    local resizeStart, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = obj.Size
        end
    end)

    resizeConn2 = UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newSize = UDim2.new(
                0, math.clamp(startSize.X.Offset + delta.X, minSize.X.Offset, maxSize.X.Offset),
                0, math.clamp(startSize.Y.Offset + delta.Y, minSize.Y.Offset, maxSize.Y.Offset)
            )
            obj.Size = newSize
        end
    end)

    resizeConn3 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    return {
        Handle = handle,
        Disconnect = function()
            if resizeConn2 then resizeConn2:Disconnect() end
            if resizeConn3 then resizeConn3:Disconnect() end
        end,
    }
end

-- ============================================================================
-- TOOLTIP SYSTEM
-- ============================================================================

function Rayfield:CreateTooltip(parent, text)
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 0, 0, 0)
    tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tooltip.BorderSizePixel = 0
    tooltip.Visible = false
    tooltip.ZIndex = 1000
    tooltip.Parent = parent

    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = tooltip

    local tooltipText = Instance.new("TextLabel")
    tooltipText.Size = UDim2.new(1, -10, 1, -6)
    tooltipText.Position = UDim2.new(0, 5, 0, 3)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Text = text or ""
    tooltipText.TextColor3 = Color3.new(1, 1, 1)
    tooltipText.TextSize = 11
    tooltipText.Font = Enum.Font.Gotham
    tooltipText.TextWrapped = true
    tooltipText.Parent = tooltip

    return {
        Show = function(pos)
            tooltip.Visible = true
            tooltip.Position = pos
            Utilities:Tween(tooltip, {Size = UDim2.new(0, 150, 0, 30)}, 0.15)
        end,
        Hide = function()
            Utilities:Tween(tooltip, {Size = UDim2.new(0, 0, 0, 0)}, 0.1, nil, nil, function()
                tooltip.Visible = false
            end)
        end,
        SetText = function(t) tooltipText.Text = t end,
    }
end

-- ============================================================================
-- CONFIRMATION DIALOG
-- ============================================================================

function Rayfield:ShowConfirmation(config)
    config = config or {}
    local dialog = Instance.new("Frame")
    dialog.Name = "ConfirmDialog"
    dialog.Size = UDim2.new(0, 300, 0, 150)
    dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
    dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 2000
    dialog.Parent = game:GetService("CoreGui")

    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 10)
    dialogCorner.Parent = dialog

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Confirm"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = dialog

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -20, 0, 50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.Text = config.Content or "Are you sure?"
    content.TextColor3 = Color3.fromRGB(200, 200, 200)
    content.TextSize = 13
    content.Font = Enum.Font.Gotham
    content.TextWrapped = true
    content.Parent = dialog

    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0, 80, 0, 30)
    yesBtn.Position = UDim2.new(0.5, -85, 1, -40)
    yesBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    yesBtn.Text = "Yes"
    yesBtn.TextColor3 = Color3.new(1, 1, 1)
    yesBtn.TextSize = 14
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.Parent = dialog

    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 6)
    yesCorner.Parent = yesBtn

    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0, 80, 0, 30)
    noBtn.Position = UDim2.new(0.5, 5, 1, -40)
    noBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    noBtn.Text = "No"
    noBtn.TextColor3 = Color3.new(1, 1, 1)
    noBtn.TextSize = 14
    noBtn.Font = Enum.Font.GothamBold
    noBtn.Parent = dialog

    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 6)
    noCorner.Parent = noBtn

    local result = nil

    yesBtn.MouseButton1Click:Connect(function()
        result = true
        dialog:Destroy()
    end)

    noBtn.MouseButton1Click:Connect(function()
        result = false
        dialog:Destroy()
    end)

    -- Wait for result
    while result == nil do
        task.wait()
    end

    return result
end

-- ============================================================================
-- LOADING SCREEN
-- ============================================================================

function Rayfield:ShowLoading(config)
    config = config or {}
    local loading = Instance.new("ScreenGui")
    loading.Name = "RayfieldLoading"
    loading.ResetOnSpawn = false
    loading.Parent = game:GetService("CoreGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    bg.BackgroundTransparency = 0.3
    bg.Parent = loading

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 300, 0, 100)
    container.Position = UDim2.new(0.5, -150, 0.5, -50)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    container.BorderSizePixel = 0
    container.Parent = bg

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 10)
    containerCorner.Parent = container

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Loading..."
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 55)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bar.BorderSizePixel = 0
    bar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 70)
    status.BackgroundTransparency = 1
    status.Text = "0%"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = container

    return {
        SetProgress = function(self, percent)
            percent = math.clamp(percent, 0, 100)
            Utilities:Tween(fill, {Size = UDim2.new(percent / 100, 0, 1, 0)}, 0.2)
            status.Text = math.floor(percent) .. "%"
        end,
        SetText = function(self, text)
            title.Text = text
        end,
        Destroy = function(self)
            Utilities:Tween(container, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, nil, nil, function()
                loading:Destroy()
            end)
        end,
    }
end

-- ============================================================================
-- NOTIFICATION SHORTCUTS
-- ============================================================================

function Rayfield:NotifySuccess(title, content, duration)
    for _, window in ipairs(self.Windows) do
        if window.NotificationSystem then
            return window.NotificationSystem:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Type = "Success",
            })
        end
    end
end

function Rayfield:NotifyError(title, content, duration)
    for _, window in ipairs(self.Windows) do
        if window.NotificationSystem then
            return window.NotificationSystem:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Type = "Error",
            })
        end
    end
end

function Rayfield:NotifyWarning(title, content, duration)
    for _, window in ipairs(self.Windows) do
        if window.NotificationSystem then
            return window.NotificationSystem:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Type = "Warning",
            })
        end
    end
end

function Rayfield:NotifyInfo(title, content, duration)
    for _, window in ipairs(self.Windows) do
        if window.NotificationSystem then
            return window.NotificationSystem:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Type = "Info",
            })
        end
    end
end

print("[Rayfield] Ultra Jacked v2.0.0 loaded successfully!")
print("[Rayfield] " .. tostring(#Themes) .. " themes available")
print("[Rayfield] " .. tostring(#Rayfield.Animations) .. " animations available")
