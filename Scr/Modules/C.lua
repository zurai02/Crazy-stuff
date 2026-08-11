--[[
    C.lua - Centralized Service & Dependency Mapper for Roblox

    Place in: Scr/Modules/C.lua

    Provides:
    - Lazy-loaded Roblox services (no repeated :GetService calls)
    - Safe service access with fallbacks
    - Module caching and dependency injection
    - Player/Character state tracking
    - Environment detection (Studio vs Client vs Server)
    - Utility wrappers for common patterns

    Usage:
        local C = require(path.to.C)
        C.Players.LocalPlayer -- auto-cached
        C.RunService.Heartbeat:Connect(...)
        C.TweenService:Create(...)

        -- Or use shorthand:
        C.tween(...) -- shorthand for TweenService:Create
        C.debounce(fn, delay) -- debounced function wrapper
--]]

local C = {}
C.__index = C

-- ============================================================================
-- SERVICE CACHE
-- ============================================================================

local _services = {}
local _serviceMeta = {
    __index = function(_, serviceName)
        if not _services[serviceName] then
            local success, service = pcall(function()
                return game:GetService(serviceName)
            end)
            if success and service then
                _services[serviceName] = service
            else
                warn("[C.lua] Service not found: " .. tostring(serviceName))
                return nil
            end
        end
        return _services[serviceName]
    end
}

setmetatable(C, _serviceMeta)

-- ============================================================================
-- DIRECT SERVICE SHORTCUTS
-- ============================================================================

-- These are eagerly cached on first access
function C:_initShortcuts()
    self.Players = game:GetService("Players")
    self.RunService = game:GetService("RunService")
    self.TweenService = game:GetService("TweenService")
    self.UserInputService = game:GetService("UserInputService")
    self.HttpService = game:GetService("HttpService")
    self.ReplicatedStorage = game:GetService("ReplicatedStorage")
    self.Workspace = game:GetService("Workspace")
    self.Lighting = game:GetService("Lighting")
    self.SoundService = game:GetService("SoundService")
    self.TeleportService = game:GetService("TeleportService")
    self.MarketplaceService = game:GetService("MarketplaceService")
    self.GroupService = game:GetService("GroupService")
    self.TextService = game:GetService("TextService")
    self.PathfindingService = game:GetService("PathfindingService")
    self.CollectionService = game:GetService("CollectionService")
    self.GuiService = game:GetService("GuiService")
    self.ContextActionService = game:GetService("ContextActionService")
    self.PolicyService = game:GetService("PolicyService")
    self.MemoryStoreService = game:GetService("MemoryStoreService")
    self.MessagingService = game:GetService("MessagingService")
    self.DataStoreService = game:GetService("DataStoreService")
    self.BadgeService = game:GetService("BadgeService")
    self.PointsService = game:GetService("PointsService")
    self.AnalyticsService = game:GetService("AnalyticsService")
    self.SocialService = game:GetService("SocialService")
    self.Chat = game:GetService("Chat")
    self.StarterGui = game:GetService("StarterGui")
    self.StarterPack = game:GetService("StarterPack")
    self.StarterPlayer = game:GetService("StarterPlayer")
    self.Teams = game:GetService("Teams")
    self.FriendService = game:GetService("FriendService")
    self.InsertService = game:GetService("InsertService")
    self.AssetService = game:GetService("AssetService")
    self.GamePassService = game:GetService("GamePassService")
    self.VRService = game:GetService("VRService")
    self.HapticService = game:GetService("HapticService")
    self.LocalizationService = game:GetService("LocalizationService")
end

-- ============================================================================
-- PLAYER STATE
-- ============================================================================

C.Player = {
    _localPlayer = nil,
    _character = nil,
    _humanoid = nil,
    _rootPart = nil,
    _connections = {},
}

function C.Player:Get()
    if not C.Player._localPlayer then
        C.Player._localPlayer = C.Players.LocalPlayer
    end
    return C.Player._localPlayer
end

function C.Player:Character()
    local plr = C.Player:Get()
    if plr then
        C.Player._character = plr.Character or plr.CharacterAdded:Wait()
    end
    return C.Player._character
end

function C.Player:Humanoid()
    local char = C.Player:Character()
    if char then
        C.Player._humanoid = char:FindFirstChildOfClass("Humanoid")
    end
    return C.Player._humanoid
end

function C.Player:RootPart()
    local hum = C.Player:Humanoid()
    if hum then
        C.Player._rootPart = hum.RootPart or hum.Parent:FindFirstChild("HumanoidRootPart")
    end
    return C.Player._rootPart
end

function C.Player:Position()
    local root = C.Player:RootPart()
    return root and root.Position or Vector3.zero
end

function C.Player:CFrame()
    local root = C.Player:RootPart()
    return root and root.CFrame or CFrame.new()
end

function C.Player:WaitForCharacter(timeout)
    timeout = timeout or 10
    local plr = C.Player:Get()
    if not plr then return nil end
    if plr.Character then return plr.Character end

    local char = nil
    local conn
    conn = plr.CharacterAdded:Once(function(c)
        char = c
    end)

    local start = tick()
    while not char and (tick() - start) < timeout do
        task.wait(0.1)
    end

    if conn then conn:Disconnect() end
    return char
end

function C.Player:OnCharacterAdded(callback)
    local plr = C.Player:Get()
    if not plr then return nil end

    -- Call immediately if character exists
    if plr.Character then
        task.spawn(callback, plr.Character)
    end

    local conn = plr.CharacterAdded:Connect(callback)
    table.insert(C.Player._connections, conn)
    return conn
end

function C.Player:OnCharacterRemoving(callback)
    local plr = C.Player:Get()
    if not plr then return nil end
    local conn = plr.CharacterRemoving:Connect(callback)
    table.insert(C.Player._connections, conn)
    return conn
end

function C.Player:Cleanup()
    for _, conn in ipairs(C.Player._connections) do
        conn:Disconnect()
    end
    C.Player._connections = {}
    C.Player._character = nil
    C.Player._humanoid = nil
    C.Player._rootPart = nil
end

-- ============================================================================
-- ENVIRONMENT DETECTION
-- ============================================================================

C.Env = {}

function C.Env:IsStudio()
    return C.RunService:IsStudio()
end

function C.Env:IsClient()
    return C.RunService:IsClient()
end

function C.Env:IsServer()
    return C.RunService:IsServer()
end

function C.Env:IsRunning()
    return C.RunService:IsRunning()
end

function C.Env:IsEditMode()
    return not C.RunService:IsRunning() and C.RunService:IsEdit()
end

function C.Env:IsMobile()
    return C.UserInputService.TouchEnabled and not C.UserInputService.KeyboardEnabled
end

function C.Env:IsConsole()
    return C.UserInputService.GamepadEnabled and not C.UserInputService.KeyboardEnabled
end

function C.Env:IsVR()
    return C.VRService and C.VRService.VREnabled
end

function C.Env:Platform()
    if C.Env:IsMobile() then return "Mobile" end
    if C.Env:IsConsole() then return "Console" end
    if C.Env:IsVR() then return "VR" end
    return "Desktop"
end

-- ============================================================================
-- TWEEN SHORTCUTS
-- ============================================================================

function C.tween(object, properties, duration, easingStyle, easingDirection, delay)
    duration = duration or 0.3
    easingStyle = easingStyle or Enum.EasingStyle.Quint
    easingDirection = easingDirection or Enum.EasingDirection.Out
    delay = delay or 0

    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection, 0, false, delay)
    local tween = C.TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function C.tweenAsync(object, properties, duration, easingStyle, easingDirection)
    local tween = C.tween(object, properties, duration, easingStyle, easingDirection)
    local completed = false
    tween.Completed:Once(function() completed = true end)
    while not completed do task.wait() end
    return tween
end

-- ============================================================================
-- DEBOUNCE & THROTTLE
-- ============================================================================

function C.debounce(fn, delay)
    delay = delay or 0.3
    local running = false
    return function(...)
        if running then return end
        running = true
        fn(...)
        task.delay(delay, function() running = false end)
    end
end

function C.throttle(fn, interval)
    interval = interval or 0.1
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= interval then
            lastCall = now
            fn(...)
        end
    end
end

function C.debounceLeading(fn, delay)
    delay = delay or 0.3
    local timer = nil
    return function(...)
        if timer then
            task.cancel(timer)
        else
            fn(...)
        end
        timer = task.delay(delay, function() timer = nil end)
    end
end

-- ============================================================================
-- PROMISE-LIKE PATTERNS
-- ============================================================================

function C.delay(seconds)
    seconds = seconds or 0
    local start = tick()
    while tick() - start < seconds do
        task.wait()
    end
end

function C.waitFor(instance, childName, timeout)
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local child = instance:FindFirstChild(childName)
        if child then return child end
        task.wait(0.1)
    end
    return nil
end

function C.waitForClass(instance, className, timeout)
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local child = instance:FindFirstChildOfClass(className)
        if child then return child end
        task.wait(0.1)
    end
    return nil
end

-- ============================================================================
-- REMOTE EVENT SHORTCUTS
-- ============================================================================

C.Remote = {}

function C.Remote:Get(name, folder)
    folder = folder or C.ReplicatedStorage:WaitForChild("Remotes")
    return folder:WaitForChild(name)
end

function C.Remote:FireServer(name, ...)
    local remote = C.Remote:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

function C.Remote:FireClient(name, player, ...)
    local remote = C.Remote:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, ...)
    end
end

function C.Remote:InvokeServer(name, ...)
    local remote = C.Remote:Get(name)
    if remote and remote:IsA("RemoteFunction") then
        return remote:InvokeServer(...)
    end
end

function C.Remote:OnClientEvent(name, callback)
    local remote = C.Remote:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote.OnClientEvent:Connect(callback)
    end
end

function C.Remote:OnServerEvent(name, callback)
    local remote = C.Remote:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote.OnServerEvent:Connect(callback)
    end
end

-- ============================================================================
-- SOUND SHORTCUTS
-- ============================================================================

C.Sound = {}

function C.Sound:Play(soundId, parent, volume)
    parent = parent or C.SoundService
    volume = volume or 0.5

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Parent = parent
    sound:Play()

    sound.Ended:Once(function()
        sound:Destroy()
    end)

    return sound
end

function C.Sound:Play3D(soundId, position, volume, maxDistance)
    volume = volume or 0.5
    maxDistance = maxDistance or 100

    local attachment = Instance.new("Attachment")
    attachment.WorldPosition = position
    attachment.Parent = C.Workspace.Terrain

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMaxDistance = maxDistance
    sound.Parent = attachment
    sound:Play()

    sound.Ended:Once(function()
        attachment:Destroy()
    end)

    return sound
end

-- ============================================================================
-- MATH UTILITIES
-- ============================================================================

C.Math = {}

function C.Math:Lerp(a, b, t)
    return a + (b - a) * t
end

function C.Math:InverseLerp(a, b, value)
    return (value - a) / (b - a)
end

function C.Math:Remap(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

function C.Math:Clamp01(value)
    return math.clamp(value, 0, 1)
end

function C.Math:Round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

function C.Math:Sign(value)
    return value > 0 and 1 or (value < 0 and -1 or 0)
end

function C.Math:Approach(current, target, delta)
    if current < target then
        return math.min(current + delta, target)
    else
        return math.max(current - delta, target)
    end
end

function C.Math:PingPong(t, length)
    length = length or 1
    t = t % (length * 2)
    return length - math.abs(t - length)
end

function C.Math:Noise2D(x, y, scale)
    scale = scale or 1
    return math.noise(x * scale, y * scale)

end

function C.Math:Noise3D(x, y, z, scale)
    scale = scale or 1
    return math.noise(x * scale, y * scale, z * scale)
end

-- ============================================================================
-- TABLE UTILITIES
-- ============================================================================

C.Table = {}

function C.Table:DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = C.Table:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function C.Table:Merge(base, override)
    local result = C.Table:DeepCopy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = C.Table:Merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function C.Table:Filter(tbl, predicate)
    local result = {}
    for i, v in ipairs(tbl) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

function C.Table:Map(tbl, transform)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = transform(v, i)
    end
    return result
end

function C.Table:Find(tbl, predicate)
    for i, v in ipairs(tbl) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil, nil
end

function C.Table:Contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

function C.Table:Keys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function C.Table:Values(tbl)
    local values = {}
    for _, v in pairs(tbl) do
        table.insert(values, v)
    end
    return values
end

function C.Table:Count(tbl)
    local count = 0
    for _ in pairs(tbl) do count += 1 end
    return count
end

function C.Table:IsEmpty(tbl)
    return next(tbl) == nil
end

-- ============================================================================
-- STRING UTILITIES
-- ============================================================================

C.String = {}

function C.String:FormatNumber(num, decimals)
    decimals = decimals or 0
    return string.format("%." .. decimals .. "f", num)
end

function C.String:FormatCompact(num)
    if num >= 1e12 then
        return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    end
    return tostring(num)
end

function C.String:Split(str, delimiter)
    local result = {}
    for match in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end
    return result
end

function C.String:Trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

function C.String:StartsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

function C.String:EndsWith(str, suffix)
    return string.sub(str, -#suffix) == suffix
end

function C.String:PadLeft(str, length, char)
    char = char or " "
    while #str < length do
        str = char .. str
    end
    return str
end

function C.String:PadRight(str, length, char)
    char = char or " "
    while #str < length do
        str = str .. char
    end
    return str
end

-- ============================================================================
-- INSTANCE UTILITIES
-- ============================================================================

C.Instance = {}

function C.Instance:WaitForDescendant(instance, path, timeout)
    timeout = timeout or 5
    local names = C.String:Split(path, ".")
    local current = instance
    local start = tick()

    for _, name in ipairs(names) do
        while tick() - start < timeout do
            local child = current:FindFirstChild(name)
            if child then
                current = child
                break
            end
            task.wait(0.1)
        end
    end

    return current ~= instance and current or nil
end

function C.Instance:GetDescendantsOfClass(instance, className)
    local result = {}
    for _, desc in ipairs(instance:GetDescendants()) do
        if desc:IsA(className) then
            table.insert(result, desc)
        end
    end
    return result
end

function C.Instance:GetFirstDescendantOfClass(instance, className)
    for _, desc in ipairs(instance:GetDescendants()) do
        if desc:IsA(className) then
            return desc
        end
    end
    return nil
end

function C.Instance:SafeDestroy(instance)
    if instance and instance.Parent then
        instance:Destroy()
    end
end

function C.Instance:CloneWithProperties(original, propertyOverrides)
    local clone = original:Clone()
    if propertyOverrides then
        for prop, value in pairs(propertyOverrides) do
            pcall(function() clone[prop] = value end)
        end
    end
    return clone
end

-- ============================================================================
-- COLOR UTILITIES
-- ============================================================================

C.Color = {}

function C.Color:FromHex(hex)
    hex = string.gsub(hex, "#", "")
    local r = tonumber(string.sub(hex, 1, 2), 16) / 255
    local g = tonumber(string.sub(hex, 3, 4), 16) / 255
    local b = tonumber(string.sub(hex, 5, 6), 16) / 255
    return Color3.new(r, g, b)
end

function C.Color:ToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function C.Color:Lerp(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

function C.Color:Brighten(color, amount)
    amount = amount or 0.1
    return Color3.new(
        math.min(color.R + amount, 1),
        math.min(color.G + amount, 1),
        math.min(color.B + amount, 1)
    )
end

function C.Color:Darken(color, amount)
    amount = amount or 0.1
    return Color3.new(
        math.max(color.R - amount, 0),
        math.max(color.G - amount, 0),
        math.max(color.B - amount, 0)
    )
end

function C.Color:Random()
    return Color3.new(math.random(), math.random(), math.random())
end

function C.Color:RandomPastel()
    local hue = math.random()
    return Color3.fromHSV(hue, 0.5, 1)
end

-- ============================================================================
-- DEBUG UTILITIES
-- ============================================================================

C.Debug = {}

function C.Debug:PrintTable(tbl, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(spacing .. tostring(k) .. ":")
            C.Debug:PrintTable(v, indent + 1)
        else
            print(spacing .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

function C.Debug:Benchmark(name, fn, iterations)
    iterations = iterations or 1000
    local start = tick()
    for _ = 1, iterations do
        fn()
    end
    local elapsed = tick() - start
    print(string.format("[Benchmark] %s: %.4fms (%d iterations, %.6fms avg)",
        name, elapsed * 1000, iterations, (elapsed / iterations) * 1000))
    return elapsed
end

function C.Debug:Traceback()
    print(debug.traceback())
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize shortcuts
C:_initShortcuts()

-- Auto-track player
if C.Players then
    C.Player._localPlayer = C.Players.LocalPlayer
    if C.Player._localPlayer then
        C.Player._character = C.Player._localPlayer.Character
        C.Player._localPlayer.CharacterAdded:Connect(function(char)
            C.Player._character = char
            C.Player._humanoid = nil
            C.Player._rootPart = nil
        end)
        C.Player._localPlayer.CharacterRemoving:Connect(function()
            C.Player._character = nil
            C.Player._humanoid = nil
            C.Player._rootPart = nil
        end)
    end
end

return C
