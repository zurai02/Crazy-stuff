--[[
    Rayfield Interface Suite
    Modified Gen2 v1.3.0 - External Module Loading Edition (FULLY FIXED)

    Changes from v1.2:
    - FIXED: Shadow now in separate container with proper ZIndex layering
    - FIXED: Intro animation no longer jumps (position set immediately)
    - FIXED: Dropdown options render in ScreenGui to prevent clipping
    - FIXED: Notification stacking with auto-repositioning
    - FIXED: Window drag clamping to screen boundaries
    - FIXED: Auto-save on value changes
    - FIXED: Auto-load on startup
    - FIXED: All ZIndex values properly set throughout
    - FIXED: Shadow follows window during minimize/close animations
    - ADDED: CreateKeybind element
    - ADDED: Focus indicator on Input
    - ADDED: Viewport resize handling

    Requires: getgitpath() function defined in parent scope
    Example:
        getgitpath = function(subpath)
            return "https://raw.githubusercontent.com/zurai02/Crazy-stuff/main/Scr/" .. (subpath or "")
        end
        local Rayfield = loadstring(game:HttpGet(getgitpath("src").."Luau-scripts/Main.lua"))()
--]]

-- ============================================================================
-- REMOTE MODULE LOADING
-- ============================================================================

local function loadRemoteModule(path)
    local url = getgitpath("src") .. path
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        error("[Rayfield] Failed to load remote module: " .. path .. "\n" .. tostring(result))
    end
    return result
end

-- Load external modules
local MainModule = loadRemoteModule("Modules/Main%20module.lua")
local C = loadRemoteModule("Modules/C.lua")

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

-- Theme using C.lua color utilities
Rayfield.Theme = {
    Primary = C.Color:FromHex("#1a1a2e"),
    Secondary = C.Color:FromHex("#16213e"),
    Accent = C.Color:FromHex("#0f3460"),
    Text = C.Color:FromHex("#e94560"),
    Success = C.Color:FromHex("#00d9ff"),
    Error = C.Color:FromHex("#ff006e"),
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

    -- FIXED v1.3: Proper parent detection for all executors
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

    -- FIXED v1.3: Shadow in separate container for proper layering
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

    -- FIXED v1.3: Proper dragging with screen boundary clamping
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

            -- FIXED v1.3: Clamp to screen bounds
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

    -- FIXED v1.3: Handle viewport resize
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
        C.Player:Cleanup()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end

    -- FIXED v1.3: Auto-save helper
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
        -- ELEMENT CREATION METHODS
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
            arrow.Text = "\u25BC"
            arrow.TextColor3 = Color3.new(1, 1, 1)
            arrow.TextSize = 12
            arrow.Font = Enum.Font.GothamBold
            arrow.ZIndex = 5
            arrow.Parent = dropdownFrame

            -- FIXED v1.3: Options in ScreenGui-level container to prevent clipping
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
                    arrow.Text = "\u25B2"
                else
                    C.tween(optionsFrame, {Size = UDim2.new(0, dropdownFrame.AbsoluteSize.X, 0, 0)}, 0.2)
                    task.delay(0.2, function()
                        if not open then optionsFrame.Visible = false end
                    end)
                    arrow.Text = "\u25BC"
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

            -- FIXED v1.3: Focus indicator
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

        -- FIXED v1.3: Keybind element
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

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text = "..."
                C.tween(keyBtn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.15)

                inputConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        keyBtn.Text = currentKey.Name
                        window.Flags[flag] = currentKey.Name
                        listening = false
                        C.tween(keyBtn, {BackgroundColor3 = Rayfield.Theme.Primary}, 0.15)
                        if inputConn then inputConn:Disconnect() end
                        if keybindConfig.onChanged then
                            local ok, err = pcall(keybindConfig.onChanged, currentKey)
                            if not ok then warn("[Rayfield] Keybind onChanged error: " .. tostring(err)) end
                        end
                        autoSave()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        listening = false
                        keyBtn.Text = currentKey and currentKey.Name or "None"
                        C.tween(keyBtn, {BackgroundColor3 = Rayfield.Theme.Primary}, 0.15)
                        if inputConn then inputConn:Disconnect() end
                    end
                end)
            end)

            local pressConn = UserInputService.InputBegan:Connect(function(input)
                if not listening and currentKey and input.KeyCode == currentKey then
                    if keybindConfig.Callback then
                        local ok, err = pcall(keybindConfig.Callback)
                        if not ok then warn("[Rayfield] Keybind callback error: " .. tostring(err)) end
                    end
                end
            end)

            window.Flags[flag] = currentKey and currentKey.Name or nil

            local handle = {
                value = currentKey,
                Set = function(self, key, skipCallback)
                    currentKey = key
                    self.value = currentKey
                    keyBtn.Text = currentKey and currentKey.Name or "None"
                    window.Flags[flag] = currentKey and currentKey.Name or nil
                    if not skipCallback and keybindConfig.onChanged then
                        local ok, err = pcall(keybindConfig.onChanged, currentKey)
                        if not ok then warn("[Rayfield] Keybind onChanged error: " .. tostring(err)) end
                    end
                    autoSave()
                end,
                Get = function(self) return currentKey end,
                Destroy = function(self)
                    if inputConn then inputConn:Disconnect() end
                    if pressConn then pressConn:Disconnect() end
                    keybindFrame:Destroy()
                end,
            }

            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateLabel(labelConfig)
            labelConfig = labelConfig or {}
            local labelFrame = Instance.new("Frame")
            labelFrame.Name = labelConfig.Name or "Label"
            labelFrame.Size = UDim2.new(1, 0, 0, 25)
            labelFrame.BackgroundTransparency = 1
            labelFrame.ZIndex = 4
            labelFrame.Parent = tabContent

            local labelText = Instance.new("TextLabel")
            labelText.Size = UDim2.new(1, -20, 1, 0)
            labelText.Position = UDim2.new(0, 10, 0, 0)
            labelText.BackgroundTransparency = 1
            labelText.Text = labelConfig.Text or labelConfig.Name or "Label"
            labelText.TextColor3 = labelConfig.Color or Color3.fromRGB(200, 200, 200)
            labelText.TextSize = labelConfig.Size or 14
            labelText.Font = labelConfig.Bold and Enum.Font.GothamBold or Enum.Font.Gotham
            labelText.TextXAlignment = labelConfig.Alignment or Enum.TextXAlignment.Left
            labelText.TextWrapped = true
            labelText.ZIndex = 5
            labelText.Parent = labelFrame

            local handle = {
                Set = function(self, text)
                    labelText.Text = tostring(text)
                    task.delay(0.05, updateCanvas)
                end,
                Get = function(self) return labelText.Text end,
                Destroy = function(self) labelFrame:Destroy() end,
            }

            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        function tab:CreateDivider()
            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.Size = UDim2.new(1, -20, 0, 1)
            divider.Position = UDim2.new(0, 10, 0, 0)
            divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            divider.BorderSizePixel = 0
            divider.ZIndex = 4
            divider.Parent = tabContent

            local handle = {
                Destroy = function(self) divider:Destroy() end,
            }

            table.insert(tab.Elements, handle)
            task.delay(0.05, updateCanvas)
            return handle
        end

        if not window.ActiveTab then
            tabContent.Visible = true
            C.tween(tabBtn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.2)
            window.ActiveTab = {Button = tabBtn, Content = tabContent, Tab = tab}
            task.delay(0.1, updateCanvas)
        end

        table.insert(window.Tabs, tab)
        return tab
    end

    -- FIXED v1.3: Notification stacking
    function window:Notify(notifyConfig)
        notifyConfig = notifyConfig or {}

        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.new(0, 250, 0, 0)
        notifFrame.Position = UDim2.new(1, 10, 1, -70)
        notifFrame.BackgroundColor3 = Rayfield.Theme.Secondary
        notifFrame.BorderSizePixel = 0
        notifFrame.ClipsDescendants = true
        notifFrame.ZIndex = 1000
        notifFrame.Parent = screenGui

        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notifFrame

        local notifTitle = Instance.new("TextLabel")
        notifTitle.Size = UDim2.new(1, -20, 0, 20)
        notifTitle.Position = UDim2.new(0, 10, 0, 5)
        notifTitle.BackgroundTransparency = 1
        notifTitle.Text = notifyConfig.Title or "Notification"
        notifTitle.TextColor3 = Color3.new(1, 1, 1)
        notifTitle.TextSize = 14
        notifTitle.Font = Enum.Font.GothamBold
        notifTitle.TextXAlignment = Enum.TextXAlignment.Left
        notifTitle.ZIndex = 1001
        notifTitle.Parent = notifFrame

        local notifText = Instance.new("TextLabel")
        notifText.Size = UDim2.new(1, -20, 0, 30)
        notifText.Position = UDim2.new(0, 10, 0, 25)
        notifText.BackgroundTransparency = 1
        notifText.Text = notifyConfig.Content or ""
        notifText.TextColor3 = Color3.fromRGB(200, 200, 200)
        notifText.TextSize = 12
        notifText.Font = Enum.Font.Gotham
        notifText.TextXAlignment = Enum.TextXAlignment.Left
        notifText.TextWrapped = true
        notifText.ZIndex = 1001
        notifText.Parent = notifFrame

        local stackOffset = #window.Notifications * 70
        table.insert(window.Notifications, notifFrame)

        C.tween(notifFrame, {
            Size = UDim2.new(0, 250, 0, 60),
            Position = UDim2.new(1, -260, 1, -70 - stackOffset)
        }, 0.3)

        local duration = notifyConfig.Duration or 3
        task.delay(duration, function()
            if notifFrame and notifFrame.Parent then
                C.tween(notifFrame, {
                    Position = UDim2.new(1, 10, 1, -70 - stackOffset),
                    Size = UDim2.new(0, 250, 0, 0)
                }, 0.3)
                task.delay(0.35, function()
                    if notifFrame and notifFrame.Parent then
                        notifFrame:Destroy()
                        for i, n in ipairs(window.Notifications) do
                            if n == notifFrame then
                                table.remove(window.Notifications, i)
                                break
                            end
                        end
                        for i, n in ipairs(window.Notifications) do
                            if n and n.Parent then
                                local newOffset = (i - 1) * 70
                                C.tween(n, {Position = UDim2.new(1, -260, 1, -70 - newOffset)}, 0.2)
                            end
                        end
                    end
                end)
            end
        end)
    end

    function window:Show()
        mainFrame.Visible = true
        shadowContainer.Visible = true
        C.tween(mainFrame, {Size = config.Size or UDim2.new(0, 600, 0, 400)}, 0.3)
        C.tween(shadowContainer, {Size = UDim2.new(0, (config.Size or UDim2.new(0, 600, 0, 400)).X.Offset + 40, 0, (config.Size or UDim2.new(0, 600, 0, 400)).Y.Offset + 40)}, 0.3)
    end

    function window:Hide()
        C.tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        C.tween(shadowContainer, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.delay(0.3, function()
            mainFrame.Visible = false
            shadowContainer.Visible = false
        end)
    end

    function window:ToggleHide()
        if mainFrame.Size.X.Offset > 50 then
            window:Hide()
        else
            window:Show()
        end
    end

    function window:Navigate(tabName)
        for _, tab in ipairs(window.Tabs) do
            if tab.Name == tabName then
                for _, child in ipairs(tabContainer:GetChildren()) do
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
                        if elem.Set then
                            elem:Set(value, true)
                        end
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
                if elem.Set then
                    elem:Set(value, true)
                end
            end
        end
    end

    -- FIXED v1.3: Proper intro animation (position set immediately, only size tweens)
    local targetSize = config.Size or UDim2.new(0, 600, 0, 400)
    local targetPos = config.Position or UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.Position = targetPos
    shadowContainer.Position = targetPos
    shadowContainer.Size = UDim2.new(0, 0, 0, 0)

    task.delay(0.05, function()
        C.tween(mainFrame, {Size = targetSize}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        C.tween(shadowContainer, {Size = UDim2.new(0, targetSize.X.Offset + 40, 0, targetSize.Y.Offset + 40)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- FIXED v1.3: Auto-load on startup
    if config.Configuration and config.Configuration.autoLoad then
        task.delay(0.6, function()
            window:Load()
        end)
    end

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
