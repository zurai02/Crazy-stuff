--[[
    Enhanced Vector3 & Serialization Module for Roblox

    Features:
    - Extended Vector3 operations (clamp, round, snap, reflect, project, reject, etc.)
    - Buffer-based serialization for Vector3, CFrame, Color3, and generic tables
    - Schema-based serialization (inspired by Sera)
    - Delta serialization support
    - Type-safe deserialization
    - Performance optimized with minimal table lookups

    Author: Generated for Roblox GitHub
    License: MIT
--]]

local Vector3Plus = {}
Vector3Plus.__index = Vector3Plus

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local EPSILON = 1e-6
local BIG_BUFFER_SIZE = 65536 -- 64KB max buffer size
local TYPE_IDS = {
    Nil = 0,
    Bool = 1,
    Int8 = 2,
    Int16 = 3,
    Int32 = 4,
    Uint8 = 5,
    Uint16 = 6,
    Uint32 = 7,
    Float32 = 8,
    Float64 = 9,
    String8 = 10,
    String16 = 11,
    String32 = 12,
    Vector3 = 13,
    Vector3int16 = 14,
    Vector2 = 15,
    Vector2int16 = 16,
    CFrame = 17,
    Color3 = 18,
    UDim = 19,
    UDim2 = 20,
    NumberRange = 21,
    NumberSequence = 22,
    ColorSequence = 23,
    BrickColor = 24,
    Enum = 25,
    Table = 26,
    Array = 27,
    Buffer = 28,
    DateTime = 29,
    Ray = 30,
    Rect = 31,
    Region3 = 32,
    Region3int16 = 33,
    TweenInfo = 34,
    PhysicalProperties = 35,
    Random = 36,
    Faces = 37,
    Axes = 38,
    PathWaypoint = 39,
    Font = 40,
}

-- ============================================================================
-- ENHANCED VECTOR3 OPERATIONS
-- ============================================================================

function Vector3Plus.new(x, y, z)
    return setmetatable({
        X = x or 0,
        Y = y or 0,
        Z = z or 0,
    }, Vector3Plus)
end

function Vector3Plus.fromRobloxVector3(v3)
    return Vector3Plus.new(v3.X, v3.Y, v3.Z)
end

function Vector3Plus:toRobloxVector3()
    return Vector3.new(self.X, self.Y, self.Z)
end

-- Basic properties
function Vector3Plus:Magnitude()
    return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
end

function Vector3Plus:SqrMagnitude()
    return self.X * self.X + self.Y * self.Y + self.Z * self.Z
end

function Vector3Plus:Unit()
    local mag = self:Magnitude()
    if mag < EPSILON then
        return Vector3Plus.new(0, 0, 0)
    end
    return Vector3Plus.new(self.X / mag, self.Y / mag, self.Z / mag)
end

-- Advanced math operations
function Vector3Plus:Dot(other)
    return self.X * other.X + self.Y * other.Y + self.Z * other.Z
end

function Vector3Plus:Cross(other)
    return Vector3Plus.new(
        self.Y * other.Z - self.Z * other.Y,
        self.Z * other.X - self.X * other.Z,
        self.X * other.Y - self.Y * other.X
    )
end

function Vector3Plus:Distance(other)
    local dx = self.X - other.X
    local dy = self.Y - other.Y
    local dz = self.Z - other.Z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Vector3Plus:DistanceSquared(other)
    local dx = self.X - other.X
    local dy = self.Y - other.Y
    local dz = self.Z - other.Z
    return dx * dx + dy * dy + dz * dz
end

function Vector3Plus:Lerp(other, alpha)
    return Vector3Plus.new(
        self.X + (other.X - self.X) * alpha,
        self.Y + (other.Y - self.Y) * alpha,
        self.Z + (other.Z - self.Z) * alpha
    )
end

function Vector3Plus:Slerp(other, alpha)
    local dot = self:Dot(other)
    dot = math.clamp(dot, -1, 1)

    local theta = math.acos(dot) * alpha
    local relative = other - self * dot
    relative = relative:Unit()

    return self * math.cos(theta) + relative * math.sin(theta)
end

function Vector3Plus:Project(onNormal)
    local sqrMag = onNormal:SqrMagnitude()
    if sqrMag < EPSILON then
        return Vector3Plus.new(0, 0, 0)
    end
    local dot = self:Dot(onNormal)
    return Vector3Plus.new(
        onNormal.X * dot / sqrMag,
        onNormal.Y * dot / sqrMag,
        onNormal.Z * dot / sqrMag
    )
end

function Vector3Plus:ProjectOnPlane(planeNormal)
    return self - self:Project(planeNormal)
end

function Vector3Plus:Reflect(inNormal)
    local factor = -2 * self:Dot(inNormal)
    return Vector3Plus.new(
        factor * inNormal.X + self.X,
        factor * inNormal.Y + self.Y,
        factor * inNormal.Z + self.Z
    )
end

function Vector3Plus:Reject(onNormal)
    return self - self:Project(onNormal)
end

function Vector3Plus:Angle(other, isSigned)
    local dot = self:Dot(other)
    local magProduct = self:Magnitude() * other:Magnitude()

    if magProduct < EPSILON then
        return 0
    end

    local cosAngle = math.clamp(dot / magProduct, -1, 1)
    local angle = math.deg(math.acos(cosAngle))

    if isSigned then
        local cross = self:Cross(other)
        if cross.Y < 0 then
            angle = -angle
        end
    end

    return angle
end

function Vector3Plus:AngleBetween(other)
    local cross = self:Cross(other)
    local dot = self:Dot(other)
    return math.deg(math.atan2(cross:Magnitude(), dot))
end

function Vector3Plus:MoveTowards(target, maxDistanceDelta)
    local toVector = target - self
    local dist = toVector:Magnitude()

    if dist <= maxDistanceDelta or dist < EPSILON then
        return target
    end

    return self + toVector / dist * maxDistanceDelta
end

function Vector3Plus:ClampMagnitude(maxLength)
    local mag = self:Magnitude()
    if mag > maxLength then
        return self:Unit() * maxLength
    end
    return Vector3Plus.new(self.X, self.Y, self.Z)
end

function Vector3Plus:Clamp(min, max)
    return Vector3Plus.new(
        math.clamp(self.X, min.X, max.X),
        math.clamp(self.Y, min.Y, max.Y),
        math.clamp(self.Z, min.Z, max.Z)
    )
end

function Vector3Plus:Floor()
    return Vector3Plus.new(
        math.floor(self.X),
        math.floor(self.Y),
        math.floor(self.Z)
    )
end

function Vector3Plus:Ceil()
    return Vector3Plus.new(
        math.ceil(self.X),
        math.ceil(self.Y),
        math.ceil(self.Z)
    )
end

function Vector3Plus:Round(decimals)
    local mult = 10 ^ (decimals or 0)
    return Vector3Plus.new(
        math.floor(self.X * mult + 0.5) / mult,
        math.floor(self.Y * mult + 0.5) / mult,
        math.floor(self.Z * mult + 0.5) / mult
    )
end

function Vector3Plus:Abs()
    return Vector3Plus.new(
        math.abs(self.X),
        math.abs(self.Y),
        math.abs(self.Z)
    )
end

function Vector3Plus:Sign()
    return Vector3Plus.new(
        math.sign(self.X),
        math.sign(self.Y),
        math.sign(self.Z)
    )
end

function Vector3Plus:Snap(gridSize)
    return Vector3Plus.new(
        math.floor(self.X / gridSize + 0.5) * gridSize,
        math.floor(self.Y / gridSize + 0.5) * gridSize,
        math.floor(self.Z / gridSize + 0.5) * gridSize
    )
end

function Vector3Plus:Min(other)
    return Vector3Plus.new(
        math.min(self.X, other.X),
        math.min(self.Y, other.Y),
        math.min(self.Z, other.Z)
    )
end

function Vector3Plus:Max(other)
    return Vector3Plus.new(
        math.max(self.X, other.X),
        math.max(self.Y, other.Y),
        math.max(self.Z, other.Z)
    )
end

function Vector3Plus:Normalize()
    local mag = self:Magnitude()
    if mag < EPSILON then
        return Vector3Plus.new(0, 0, 0)
    end
    return Vector3Plus.new(self.X / mag, self.Y / mag, self.Z / mag)
end

function Vector3Plus:IsNormalized()
    return math.abs(self:SqrMagnitude() - 1) < EPSILON
end

function Vector3Plus:IsNaN()
    return self.X ~= self.X or self.Y ~= self.Y or self.Z ~= self.Z
end

function Vector3Plus:IsClose(other, epsilon)
    epsilon = epsilon or EPSILON
    return math.abs(self.X - other.X) <= epsilon
        and math.abs(self.Y - other.Y) <= epsilon
        and math.abs(self.Z - other.Z) <= epsilon
end

function Vector3Plus:IsZero()
    return self.X == 0 and self.Y == 0 and self.Z == 0
end

function Vector3Plus:Perpendicular()
    local x, y, z = math.abs(self.X), math.abs(self.Y), math.abs(self.Z)
    local other = (x < y) and ((x < z) and Vector3Plus.new(1, 0, 0) or Vector3Plus.new(0, 0, 1)) or ((y < z) and Vector3Plus.new(0, 1, 0) or Vector3Plus.new(0, 0, 1))
    return self:Cross(other):Normalize()
end

function Vector3Plus:RotateAround(axis, angle)
    local rad = math.rad(angle)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)

    local u = axis:Normalize()
    local dot = self:Dot(u)
    local cross = u:Cross(self)

    return Vector3Plus.new(
        self.X * cosA + cross.X * sinA + u.X * dot * (1 - cosA),
        self.Y * cosA + cross.Y * sinA + u.Y * dot * (1 - cosA),
        self.Z * cosA + cross.Z * sinA + u.Z * dot * (1 - cosA)
    )
end

function Vector3Plus:RotateByQuaternion(q)
    local u = Vector3Plus.new(q.X, q.Y, q.Z)
    local s = q.W

    local dot1 = u * 2 * self:Dot(u)
    local dot2 = self * (s * s - u:Dot(u))
    local cross = u:Cross(self) * 2 * s

    return dot1 + dot2 + cross
end

function Vector3Plus:ToQuaternion()
    local mag = self:Magnitude()
    if mag < EPSILON then
        return {X = 0, Y = 0, Z = 0, W = 1}
    end

    local halfAngle = math.rad(mag) / 2
    local sinHalf = math.sin(halfAngle) / mag

    return {
        X = self.X * sinHalf,
        Y = self.Y * sinHalf,
        Z = self.Z * sinHalf,
        W = math.cos(halfAngle)
    }
end

function Vector3Plus:ToCFrame()
    return CFrame.new(self.X, self.Y, self.Z)
end

function Vector3Plus:ToArray()
    return {self.X, self.Y, self.Z}
end

function Vector3Plus:ToString(precision)
    if precision then
        return string.format("(%." .. precision .. "f, %." .. precision .. "f, %." .. precision .. "f)", self.X, self.Y, self.Z)
    end
    return string.format("(%.3f, %.3f, %.3f)", self.X, self.Y, self.Z)
end

-- Random vector generation
function Vector3Plus.Random(min, max)
    min = min or -1
    max = max or 1
    return Vector3Plus.new(
        math.random() * (max - min) + min,
        math.random() * (max - min) + min,
        math.random() * (max - min) + min
    )
end

function Vector3Plus.RandomUnit()
    local theta = math.random() * 2 * math.pi
    local phi = math.acos(2 * math.random() - 1)
    return Vector3Plus.new(
        math.sin(phi) * math.cos(theta),
        math.sin(phi) * math.sin(theta),
        math.cos(phi)
    )
end

function Vector3Plus.RandomOnSphere(radius)
    return Vector3Plus.RandomUnit() * (radius or 1)
end

function Vector3Plus.RandomInSphere(radius)
    return Vector3Plus.RandomUnit() * (math.random() ^ (1/3)) * (radius or 1)
end

function Vector3Plus.RandomInBox(min, max)
    return Vector3Plus.new(
        math.random() * (max.X - min.X) + min.X,
        math.random() * (max.Y - min.Y) + min.Y,
        math.random() * (max.Z - min.Z) + min.Z
    )
end

function Vector3Plus.RandomOnCircle(radius, axis)
    axis = axis or "Y"
    local angle = math.random() * 2 * math.pi
    local r = radius or 1

    if axis == "X" then
        return Vector3Plus.new(0, math.cos(angle) * r, math.sin(angle) * r)
    elseif axis == "Y" then
        return Vector3Plus.new(math.cos(angle) * r, 0, math.sin(angle) * r)
    else
        return Vector3Plus.new(math.cos(angle) * r, math.sin(angle) * r, 0)
    end
end

-- Utility functions
function Vector3Plus:Unpack()
    return self.X, self.Y, self.Z
end

function Vector3Plus:Copy()
    return Vector3Plus.new(self.X, self.Y, self.Z)
end

function Vector3Plus:Scale(scalar)
    return Vector3Plus.new(self.X * scalar, self.Y * scalar, self.Z * scalar)
end

function Vector3Plus:Inverse()
    return Vector3Plus.new(1 / self.X, 1 / self.Y, 1 / self.Z)
end

function Vector3Plus:Negate()
    return Vector3Plus.new(-self.X, -self.Y, -self.Z)
end

-- Metamethods
function Vector3Plus.__add(a, b)
    if type(a) == "number" then
        return Vector3Plus.new(a + b.X, a + b.Y, a + b.Z)
    elseif type(b) == "number" then
        return Vector3Plus.new(a.X + b, a.Y + b, a.Z + b)
    end
    return Vector3Plus.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vector3Plus.__sub(a, b)
    if type(a) == "number" then
        return Vector3Plus.new(a - b.X, a - b.Y, a - b.Z)
    elseif type(b) == "number" then
        return Vector3Plus.new(a.X - b, a.Y - b, a.Z - b)
    end
    return Vector3Plus.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vector3Plus.__mul(a, b)
    if type(a) == "number" then
        return Vector3Plus.new(a * b.X, a * b.Y, a * b.Z)
    elseif type(b) == "number" then
        return Vector3Plus.new(a.X * b, a.Y * b, a.Z * b)
    end
    return Vector3Plus.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end

function Vector3Plus.__div(a, b)
    if type(a) == "number" then
        return Vector3Plus.new(a / b.X, a / b.Y, a / b.Z)
    elseif type(b) == "number" then
        return Vector3Plus.new(a.X / b, a.Y / b, a.Z / b)
    end
    return Vector3Plus.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end

function Vector3Plus.__mod(a, b)
    if type(b) == "number" then
        return Vector3Plus.new(a.X % b, a.Y % b, a.Z % b)
    end
    return Vector3Plus.new(a.X % b.X, a.Y % b.Y, a.Z % b.Z)
end

function Vector3Plus.__pow(a, b)
    if type(b) == "number" then
        return Vector3Plus.new(a.X ^ b, a.Y ^ b, a.Z ^ b)
    end
    return Vector3Plus.new(a.X ^ b.X, a.Y ^ b.Y, a.Z ^ b.Z)
end

function Vector3Plus.__unm(a)
    return Vector3Plus.new(-a.X, -a.Y, -a.Z)
end

function Vector3Plus.__eq(a, b)
    return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end

function Vector3Plus.__lt(a, b)
    return a:SqrMagnitude() < b:SqrMagnitude()
end

function Vector3Plus.__le(a, b)
    return a:SqrMagnitude() <= b:SqrMagnitude()
end

function Vector3Plus.__tostring(a)
    return a:ToString()
end

function Vector3Plus.__len(a)
    return a:Magnitude()
end

-- ============================================================================
-- SERIALIZATION MODULE
-- ============================================================================

local SerDes = {}

-- Helper functions for buffer operations
local function writeString8(b, offset, str)
    local len = #str
    buffer.writeu8(b, offset, len)
    buffer.writestring(b, offset + 1, str, len)
    return offset + 1 + len
end

local function readString8(b, offset)
    local len = buffer.readu8(b, offset)
    return buffer.readstring(b, offset + 1, len), offset + 1 + len
end

local function writeString16(b, offset, str)
    local len = #str
    buffer.writeu16(b, offset, len)
    buffer.writestring(b, offset + 2, str, len)
    return offset + 2 + len
end

local function readString16(b, offset)
    local len = buffer.readu16(b, offset)
    return buffer.readstring(b, offset + 2, len), offset + 2 + len
end

local function writeString32(b, offset, str)
    local len = #str
    buffer.writeu32(b, offset, len)
    buffer.writestring(b, offset + 4, str, len)
    return offset + 4 + len
end

local function readString32(b, offset)
    local len = buffer.readu32(b, offset)
    return buffer.readstring(b, offset + 4, len), offset + 4 + len
end

-- Type serializers/deserializers
SerDes.Types = {}

SerDes.Types.Nil = {
    Size = 0,
    Serialize = function(b, offset, value)
        return offset
    end,
    Deserialize = function(b, offset)
        return nil, offset
    end
}

SerDes.Types.Bool = {
    Size = 1,
    Serialize = function(b, offset, value)
        buffer.writeu8(b, offset, value and 1 or 0)
        return offset + 1
    end,
    Deserialize = function(b, offset)
        return buffer.readu8(b, offset) == 1, offset + 1
    end
}

SerDes.Types.Int8 = {
    Size = 1,
    Serialize = function(b, offset, value)
        buffer.writei8(b, offset, value)
        return offset + 1
    end,
    Deserialize = function(b, offset)
        return buffer.readi8(b, offset), offset + 1
    end
}

SerDes.Types.Int16 = {
    Size = 2,
    Serialize = function(b, offset, value)
        buffer.writei16(b, offset, value)
        return offset + 2
    end,
    Deserialize = function(b, offset)
        return buffer.readi16(b, offset), offset + 2
    end
}

SerDes.Types.Int32 = {
    Size = 4,
    Serialize = function(b, offset, value)
        buffer.writei32(b, offset, value)
        return offset + 4
    end,
    Deserialize = function(b, offset)
        return buffer.readi32(b, offset), offset + 4
    end
}

SerDes.Types.Uint8 = {
    Size = 1,
    Serialize = function(b, offset, value)
        buffer.writeu8(b, offset, value)
        return offset + 1
    end,
    Deserialize = function(b, offset)
        return buffer.readu8(b, offset), offset + 1
    end
}

SerDes.Types.Uint16 = {
    Size = 2,
    Serialize = function(b, offset, value)
        buffer.writeu16(b, offset, value)
        return offset + 2
    end,
    Deserialize = function(b, offset)
        return buffer.readu16(b, offset), offset + 2
    end
}

SerDes.Types.Uint32 = {
    Size = 4,
    Serialize = function(b, offset, value)
        buffer.writeu32(b, offset, value)
        return offset + 4
    end,
    Deserialize = function(b, offset)
        return buffer.readu32(b, offset), offset + 4
    end
}

SerDes.Types.Float32 = {
    Size = 4,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value)
        return offset + 4
    end,
    Deserialize = function(b, offset)
        return buffer.readf32(b, offset), offset + 4
    end
}

SerDes.Types.Float64 = {
    Size = 8,
    Serialize = function(b, offset, value)
        buffer.writef64(b, offset, value)
        return offset + 8
    end,
    Deserialize = function(b, offset)
        return buffer.readf64(b, offset), offset + 8
    end
}

SerDes.Types.String8 = {
    Size = nil, -- Variable size
    Serialize = function(b, offset, value)
        return writeString8(b, offset, value)
    end,
    Deserialize = function(b, offset)
        return readString8(b, offset)
    end
}

SerDes.Types.String16 = {
    Size = nil,
    Serialize = function(b, offset, value)
        return writeString16(b, offset, value)
    end,
    Deserialize = function(b, offset)
        return readString16(b, offset)
    end
}

SerDes.Types.String32 = {
    Size = nil,
    Serialize = function(b, offset, value)
        return writeString32(b, offset, value)
    end,
    Deserialize = function(b, offset)
        return readString32(b, offset)
    end
}

SerDes.Types.Vector3 = {
    Size = 12,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.X)
        buffer.writef32(b, offset + 4, value.Y)
        buffer.writef32(b, offset + 8, value.Z)
        return offset + 12
    end,
    Deserialize = function(b, offset)
        return Vector3.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4),
            buffer.readf32(b, offset + 8)
        ), offset + 12
    end
}

SerDes.Types.Vector3int16 = {
    Size = 6,
    Serialize = function(b, offset, value)
        buffer.writei16(b, offset, value.X)
        buffer.writei16(b, offset + 2, value.Y)
        buffer.writei16(b, offset + 4, value.Z)
        return offset + 6
    end,
    Deserialize = function(b, offset)
        return Vector3int16.new(
            buffer.readi16(b, offset),
            buffer.readi16(b, offset + 2),
            buffer.readi16(b, offset + 4)
        ), offset + 6
    end
}

SerDes.Types.Vector2 = {
    Size = 8,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.X)
        buffer.writef32(b, offset + 4, value.Y)
        return offset + 8
    end,
    Deserialize = function(b, offset)
        return Vector2.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4)
        ), offset + 8
    end
}

SerDes.Types.Vector2int16 = {
    Size = 4,
    Serialize = function(b, offset, value)
        buffer.writei16(b, offset, value.X)
        buffer.writei16(b, offset + 2, value.Y)
        return offset + 4
    end,
    Deserialize = function(b, offset)
        return Vector2int16.new(
            buffer.readi16(b, offset),
            buffer.readi16(b, offset + 2)
        ), offset + 4
    end
}

SerDes.Types.CFrame = {
    Size = 24,
    Serialize = function(b, offset, value)
        local x, y, z = value.X, value.Y, value.Z
        local r00, r01, r02 = value.XVector.X, value.YVector.X, value.ZVector.X
        local r10, r11, r12 = value.XVector.Y, value.YVector.Y, value.ZVector.Y
        local r20, r21, r22 = value.XVector.Z, value.YVector.Z, value.ZVector.Z

        buffer.writef32(b, offset, x)
        buffer.writef32(b, offset + 4, y)
        buffer.writef32(b, offset + 8, z)
        buffer.writef32(b, offset + 12, r00)
        buffer.writef32(b, offset + 16, r01)
        buffer.writef32(b, offset + 20, r02)
        buffer.writef32(b, offset + 24, r10)
        buffer.writef32(b, offset + 28, r11)
        buffer.writef32(b, offset + 32, r12)
        buffer.writef32(b, offset + 36, r20)
        buffer.writef32(b, offset + 40, r21)
        buffer.writef32(b, offset + 44, r22)
        return offset + 48
    end,
    Deserialize = function(b, offset)
        return CFrame.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4),
            buffer.readf32(b, offset + 8),
            buffer.readf32(b, offset + 12),
            buffer.readf32(b, offset + 16),
            buffer.readf32(b, offset + 20),
            buffer.readf32(b, offset + 24),
            buffer.readf32(b, offset + 28),
            buffer.readf32(b, offset + 32),
            buffer.readf32(b, offset + 36),
            buffer.readf32(b, offset + 40),
            buffer.readf32(b, offset + 44)
        ), offset + 48
    end
}

SerDes.Types.LossyCFrame = {
    Size = 28,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.X)
        buffer.writef32(b, offset + 4, value.Y)
        buffer.writef32(b, offset + 8, value.Z)

        local lookVector = value.LookVector
        buffer.writef32(b, offset + 12, lookVector.X)
        buffer.writef32(b, offset + 16, lookVector.Y)
        buffer.writef32(b, offset + 20, lookVector.Z)

        local upVector = value.UpVector
        buffer.writef32(b, offset + 24, upVector.X)
        buffer.writef32(b, offset + 28, upVector.Y)
        buffer.writef32(b, offset + 32, upVector.Z)

        return offset + 36
    end,
    Deserialize = function(b, offset)
        local pos = Vector3.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4),
            buffer.readf32(b, offset + 8)
        )
        local look = Vector3.new(
            buffer.readf32(b, offset + 12),
            buffer.readf32(b, offset + 16),
            buffer.readf32(b, offset + 20)
        )
        local up = Vector3.new(
            buffer.readf32(b, offset + 24),
            buffer.readf32(b, offset + 28),
            buffer.readf32(b, offset + 32)
        )
        return CFrame.lookAt(pos, pos + look, up), offset + 36
    end
}

SerDes.Types.Color3 = {
    Size = 12,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.R)
        buffer.writef32(b, offset + 4, value.G)
        buffer.writef32(b, offset + 8, value.B)
        return offset + 12
    end,
    Deserialize = function(b, offset)
        return Color3.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4),
            buffer.readf32(b, offset + 8)
        ), offset + 12
    end
}

SerDes.Types.Color3Uint8 = {
    Size = 3,
    Serialize = function(b, offset, value)
        buffer.writeu8(b, offset, math.clamp(math.floor(value.R * 255), 0, 255))
        buffer.writeu8(b, offset + 1, math.clamp(math.floor(value.G * 255), 0, 255))
        buffer.writeu8(b, offset + 2, math.clamp(math.floor(value.B * 255), 0, 255))
        return offset + 3
    end,
    Deserialize = function(b, offset)
        return Color3.new(
            buffer.readu8(b, offset) / 255,
            buffer.readu8(b, offset + 1) / 255,
            buffer.readu8(b, offset + 2) / 255
        ), offset + 3
    end
}

SerDes.Types.UDim = {
    Size = 8,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.Scale)
        buffer.writei32(b, offset + 4, value.Offset)
        return offset + 8
    end,
    Deserialize = function(b, offset)
        return UDim.new(
            buffer.readf32(b, offset),
            buffer.readi32(b, offset + 4)
        ), offset + 8
    end
}

SerDes.Types.UDim2 = {
    Size = 16,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.X.Scale)
        buffer.writei32(b, offset + 4, value.X.Offset)
        buffer.writef32(b, offset + 8, value.Y.Scale)
        buffer.writei32(b, offset + 12, value.Y.Offset)
        return offset + 16
    end,
    Deserialize = function(b, offset)
        return UDim2.new(
            buffer.readf32(b, offset),
            buffer.readi32(b, offset + 4),
            buffer.readf32(b, offset + 8),
            buffer.readi32(b, offset + 12)
        ), offset + 16
    end
}

SerDes.Types.NumberRange = {
    Size = 8,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.Min)
        buffer.writef32(b, offset + 4, value.Max)
        return offset + 8
    end,
    Deserialize = function(b, offset)
        return NumberRange.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4)
        ), offset + 8
    end
}

SerDes.Types.BrickColor = {
    Size = 2,
    Serialize = function(b, offset, value)
        buffer.writeu16(b, offset, value.Number)
        return offset + 2
    end,
    Deserialize = function(b, offset)
        return BrickColor.new(buffer.readu16(b, offset)), offset + 2
    end
}

SerDes.Types.Enum = {
    Size = nil,
    Serialize = function(b, offset, value)
        local enumName = tostring(value.EnumType)
        local itemName = value.Name
        offset = writeString8(b, offset, enumName)
        offset = writeString8(b, offset, itemName)
        return offset
    end,
    Deserialize = function(b, offset)
        local enumName, newOffset = readString8(b, offset)
        local itemName, finalOffset = readString8(b, newOffset)
        return Enum[enumName][itemName], finalOffset
    end
}

SerDes.Types.DateTime = {
    Size = 8,
    Serialize = function(b, offset, value)
        buffer.writef64(b, offset, value.UnixTimestampMillis)
        return offset + 8
    end,
    Deserialize = function(b, offset)
        return DateTime.fromUnixTimestampMillis(buffer.readf64(b, offset)), offset + 8
    end
}

SerDes.Types.Ray = {
    Size = 24,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.Origin.X)
        buffer.writef32(b, offset + 4, value.Origin.Y)
        buffer.writef32(b, offset + 8, value.Origin.Z)
        buffer.writef32(b, offset + 12, value.Direction.X)
        buffer.writef32(b, offset + 16, value.Direction.Y)
        buffer.writef32(b, offset + 20, value.Direction.Z)
        return offset + 24
    end,
    Deserialize = function(b, offset)
        return Ray.new(
            Vector3.new(
                buffer.readf32(b, offset),
                buffer.readf32(b, offset + 4),
                buffer.readf32(b, offset + 8)
            ),
            Vector3.new(
                buffer.readf32(b, offset + 12),
                buffer.readf32(b, offset + 16),
                buffer.readf32(b, offset + 20)
            )
        ), offset + 24
    end
}

SerDes.Types.Rect = {
    Size = 16,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.Min.X)
        buffer.writef32(b, offset + 4, value.Min.Y)
        buffer.writef32(b, offset + 8, value.Max.X)
        buffer.writef32(b, offset + 12, value.Max.Y)
        return offset + 16
    end,
    Deserialize = function(b, offset)
        return Rect.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4),
            buffer.readf32(b, offset + 8),
            buffer.readf32(b, offset + 12)
        ), offset + 16
    end
}

SerDes.Types.NumberSequence = {
    Size = nil,
    Serialize = function(b, offset, value)
        local keypoints = value.Keypoints
        local count = #keypoints
        buffer.writeu8(b, offset, count)
        offset = offset + 1

        for i = 1, count do
            local kp = keypoints[i]
            buffer.writef32(b, offset, kp.Time)
            buffer.writef32(b, offset + 4, kp.Value)
            buffer.writef32(b, offset + 8, kp.Envelope)
            offset = offset + 12
        end

        return offset
    end,
    Deserialize = function(b, offset)
        local count = buffer.readu8(b, offset)
        offset = offset + 1

        local keypoints = table.create(count)
        for i = 1, count do
            keypoints[i] = NumberSequenceKeypoint.new(
                buffer.readf32(b, offset),
                buffer.readf32(b, offset + 4),
                buffer.readf32(b, offset + 8)
            )
            offset = offset + 12
        end

        return NumberSequence.new(keypoints), offset
    end
}

SerDes.Types.ColorSequence = {
    Size = nil,
    Serialize = function(b, offset, value)
        local keypoints = value.Keypoints
        local count = #keypoints
        buffer.writeu8(b, offset, count)
        offset = offset + 1

        for i = 1, count do
            local kp = keypoints[i]
            buffer.writef32(b, offset, kp.Time)
            buffer.writeu8(b, offset + 4, math.clamp(math.floor(kp.Value.R * 255), 0, 255))
            buffer.writeu8(b, offset + 5, math.clamp(math.floor(kp.Value.G * 255), 0, 255))
            buffer.writeu8(b, offset + 6, math.clamp(math.floor(kp.Value.B * 255), 0, 255))
            offset = offset + 7
        end

        return offset
    end,
    Deserialize = function(b, offset)
        local count = buffer.readu8(b, offset)
        offset = offset + 1

        local keypoints = table.create(count)
        for i = 1, count do
            keypoints[i] = ColorSequenceKeypoint.new(
                buffer.readf32(b, offset),
                Color3.new(
                    buffer.readu8(b, offset + 4) / 255,
                    buffer.readu8(b, offset + 5) / 255,
                    buffer.readu8(b, offset + 6) / 255
                )
            )
            offset = offset + 7
        end

        return ColorSequence.new(keypoints), offset
    end
}

SerDes.Types.Faces = {
    Size = 1,
    Serialize = function(b, offset, value)
        local flags = 0
        if value.Top then flags = flags | 1 end
        if value.Bottom then flags = flags | 2 end
        if value.Left then flags = flags | 4 end
        if value.Right then flags = flags | 8 end
        if value.Back then flags = flags | 16 end
        if value.Front then flags = flags | 32 end
        buffer.writeu8(b, offset, flags)
        return offset + 1
    end,
    Deserialize = function(b, offset)
        local flags = buffer.readu8(b, offset)
        return Faces.new(
            (flags & 1) ~= 0,
            (flags & 2) ~= 0,
            (flags & 4) ~= 0,
            (flags & 8) ~= 0,
            (flags & 16) ~= 0,
            (flags & 32) ~= 0
        ), offset + 1
    end
}

SerDes.Types.Axes = {
    Size = 1,
    Serialize = function(b, offset, value)
        local flags = 0
        if value.X then flags = flags | 1 end
        if value.Y then flags = flags | 2 end
        if value.Z then flags = flags | 4 end
        if value.Top then flags = flags | 8 end
        if value.Bottom then flags = flags | 16 end
        if value.Left then flags = flags | 32 end
        if value.Right then flags = flags | 64 end
        if value.Back then flags = flags | 128 end
        buffer.writeu8(b, offset, flags)
        return offset + 1
    end,
    Deserialize = function(b, offset)
        local flags = buffer.readu8(b, offset)
        return Axes.new(
            (flags & 1) ~= 0 and Enum.Axis.X or nil,
            (flags & 2) ~= 0 and Enum.Axis.Y or nil,
            (flags & 4) ~= 0 and Enum.Axis.Z or nil,
            (flags & 8) ~= 0 and Enum.NormalId.Top or nil,
            (flags & 16) ~= 0 and Enum.NormalId.Bottom or nil,
            (flags & 32) ~= 0 and Enum.NormalId.Left or nil,
            (flags & 64) ~= 0 and Enum.NormalId.Right or nil,
            (flags & 128) ~= 0 and Enum.NormalId.Back or nil
        ), offset + 1
    end
}

SerDes.Types.PathWaypoint = {
    Size = 16,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.Position.X)
        buffer.writef32(b, offset + 4, value.Position.Y)
        buffer.writef32(b, offset + 8, value.Position.Z)
        buffer.writeu8(b, offset + 12, value.Action.Value)
        return offset + 13
    end,
    Deserialize = function(b, offset)
        return PathWaypoint.new(
            Vector3.new(
                buffer.readf32(b, offset),
                buffer.readf32(b, offset + 4),
                buffer.readf32(b, offset + 8)
            ),
            Enum.PathWaypointAction:GetEnumItems()[buffer.readu8(b, offset + 12)]
        ), offset + 13
    end
}

SerDes.Types.Font = {
    Size = nil,
    Serialize = function(b, offset, value)
        offset = writeString8(b, offset, value.Family)
        buffer.writeu16(b, offset, value.Weight.Value)
        buffer.writeu8(b, offset + 2, value.Style.Value)
        return offset + 3
    end,
    Deserialize = function(b, offset)
        local family, newOffset = readString8(b, offset)
        local weight = buffer.readu16(b, newOffset)
        local style = buffer.readu8(b, newOffset + 2)
        return Font.new(family, Enum.FontWeight:GetEnumItems()[weight], Enum.FontStyle:GetEnumItems()[style]), newOffset + 3
    end
}

SerDes.Types.TweenInfo = {
    Size = 13,
    Serialize = function(b, offset, value)
        buffer.writef32(b, offset, value.Time)
        buffer.writeu8(b, offset + 4, value.EasingStyle.Value)
        buffer.writeu8(b, offset + 5, value.EasingDirection.Value)
        buffer.writei32(b, offset + 6, value.RepeatCount)
        buffer.writeu8(b, offset + 10, value.Reverses and 1 or 0)
        buffer.writef32(b, offset + 11, value.DelayTime)
        return offset + 15
    end,
    Deserialize = function(b, offset)
        return TweenInfo.new(
            buffer.readf32(b, offset),
            Enum.EasingStyle:GetEnumItems()[buffer.readu8(b, offset + 4)],
            Enum.EasingDirection:GetEnumItems()[buffer.readu8(b, offset + 5)],
            buffer.readi32(b, offset + 6),
            buffer.readu8(b, offset + 10) == 1,
            buffer.readf32(b, offset + 11)
        ), offset + 15
    end
}

SerDes.Types.PhysicalProperties = {
    Size = 17,
    Serialize = function(b, offset, value)
        buffer.writeu8(b, offset, value.CustomPhysicalProperties and 1 or 0)
        if value.CustomPhysicalProperties then
            buffer.writef32(b, offset + 1, value.Density)
            buffer.writef32(b, offset + 5, value.Friction)
            buffer.writef32(b, offset + 9, value.Elasticity)
            buffer.writef32(b, offset + 13, value.FrictionWeight)
            buffer.writef32(b, offset + 17, value.ElasticityWeight)
            return offset + 21
        end
        return offset + 1
    end,
    Deserialize = function(b, offset)
        local hasCustom = buffer.readu8(b, offset) == 1
        if hasCustom then
            return PhysicalProperties.new(
                buffer.readf32(b, offset + 1),
                buffer.readf32(b, offset + 5),
                buffer.readf32(b, offset + 9),
                buffer.readf32(b, offset + 13),
                buffer.readf32(b, offset + 17)
            ), offset + 21
        end
        return PhysicalProperties.new(), offset + 1
    end
}

SerDes.Types.Random = {
    Size = 16,
    Serialize = function(b, offset, value)
        -- Note: Random state cannot be fully serialized in Roblox
        -- We serialize the seed instead
        buffer.writeu32(b, offset, value:NextInteger(0, 4294967295))
        buffer.writeu32(b, offset + 4, value:NextInteger(0, 4294967295))
        buffer.writeu32(b, offset + 8, value:NextInteger(0, 4294967295))
        buffer.writeu32(b, offset + 12, value:NextInteger(0, 4294967295))
        return offset + 16
    end,
    Deserialize = function(b, offset)
        local seed = buffer.readu32(b, offset)
        return Random.new(seed), offset + 16
    end
}

SerDes.Types.Region3 = {
    Size = 24,
    Serialize = function(b, offset, value)
        local min = value.CFrame.Position - value.Size / 2
        local max = value.CFrame.Position + value.Size / 2
        buffer.writef32(b, offset, min.X)
        buffer.writef32(b, offset + 4, min.Y)
        buffer.writef32(b, offset + 8, min.Z)
        buffer.writef32(b, offset + 12, max.X)
        buffer.writef32(b, offset + 16, max.Y)
        buffer.writef32(b, offset + 20, max.Z)
        return offset + 24
    end,
    Deserialize = function(b, offset)
        local min = Vector3.new(
            buffer.readf32(b, offset),
            buffer.readf32(b, offset + 4),
            buffer.readf32(b, offset + 8)
        )
        local max = Vector3.new(
            buffer.readf32(b, offset + 12),
            buffer.readf32(b, offset + 16),
            buffer.readf32(b, offset + 20)
        )
        return Region3.new(min, max), offset + 24
    end
}

SerDes.Types.Region3int16 = {
    Size = 12,
    Serialize = function(b, offset, value)
        buffer.writei16(b, offset, value.Min.X)
        buffer.writei16(b, offset + 2, value.Min.Y)
        buffer.writei16(b, offset + 4, value.Min.Z)
        buffer.writei16(b, offset + 6, value.Max.X)
        buffer.writei16(b, offset + 8, value.Max.Y)
        buffer.writei16(b, offset + 10, value.Max.Z)
        return offset + 12
    end,
    Deserialize = function(b, offset)
        return Region3int16.new(
            Vector3int16.new(
                buffer.readi16(b, offset),
                buffer.readi16(b, offset + 2),
                buffer.readi16(b, offset + 4)
            ),
            Vector3int16.new(
                buffer.readi16(b, offset + 6),
                buffer.readi16(b, offset + 8),
                buffer.readi16(b, offset + 10)
            )
        ), offset + 12
    end
}

-- ============================================================================
-- SCHEMA-BASED SERIALIZATION
-- ============================================================================

function SerDes.Schema(schemaDefinition)
    local schema = {
        fields = {},
        fieldCount = 0,
        fieldOrder = {},
    }

    for fieldName, fieldType in pairs(schemaDefinition) do
        schema.fieldCount += 1
        schema.fields[fieldName] = fieldType
        table.insert(schema.fieldOrder, fieldName)
    end

    -- Sort field order for consistent serialization
    table.sort(schema.fieldOrder)

    return schema
end

function SerDes.Serialize(schema, data)
    local b = buffer.create(BIG_BUFFER_SIZE)
    local offset = 0

    for _, fieldName in ipairs(schema.fieldOrder) do
        local fieldType = schema.fields[fieldName]
        local value = data[fieldName]

        if value == nil then
            -- Write nil type marker
            buffer.writeu8(b, offset, TYPE_IDS.Nil)
            offset += 1
        else
            -- Write type ID
            local typeId = TYPE_IDS[fieldType] or TYPE_IDS.Table
            buffer.writeu8(b, offset, typeId)
            offset += 1

            -- Serialize value
            local serializer = SerDes.Types[fieldType]
            if serializer then
                offset = serializer.Serialize(b, offset, value)
            else
                error("Unknown type: " .. tostring(fieldType))
            end
        end
    end

    -- Trim buffer to actual size
    local finalBuffer = buffer.create(offset)
    buffer.copy(finalBuffer, 0, b, 0, offset)

    return finalBuffer
end

function SerDes.Deserialize(schema, b)
    local data = {}
    local offset = 0

    for _, fieldName in ipairs(schema.fieldOrder) do
        local typeId = buffer.readu8(b, offset)
        offset += 1

        if typeId == TYPE_IDS.Nil then
            data[fieldName] = nil
        else
            local fieldType = schema.fields[fieldName]
            local deserializer = SerDes.Types[fieldType]

            if deserializer then
                data[fieldName], offset = deserializer.Deserialize(b, offset)
            else
                error("Unknown type: " .. tostring(fieldType))
            end
        end
    end

    return data
end

-- ============================================================================
-- DELTA SERIALIZATION
-- ============================================================================

function SerDes.DeltaSerialize(schema, oldData, newData)
    local b = buffer.create(BIG_BUFFER_SIZE)
    local offset = 0
    local changedFields = {}

    for i, fieldName in ipairs(schema.fieldOrder) do
        local oldValue = oldData[fieldName]
        local newValue = newData[fieldName]

        if oldValue ~= newValue then
            table.insert(changedFields, i)

            -- Write field index
            buffer.writeu8(b, offset, i)
            offset += 1

            -- Write type ID and value
            local fieldType = schema.fields[fieldName]
            local typeId = TYPE_IDS[fieldType] or TYPE_IDS.Table
            buffer.writeu8(b, offset, typeId)
            offset += 1

            local serializer = SerDes.Types[fieldType]
            if serializer then
                offset = serializer.Serialize(b, offset, newValue)
            end
        end
    end

    -- Write end marker (0 means no more fields)
    buffer.writeu8(b, offset, 0)
    offset += 1

    local finalBuffer = buffer.create(offset)
    buffer.copy(finalBuffer, 0, b, 0, offset)

    return finalBuffer, changedFields
end

function SerDes.DeltaDeserialize(schema, b, baseData)
    local data = {}

    -- Copy base data
    for k, v in pairs(baseData) do
        data[k] = v
    end

    local offset = 0

    while true do
        local fieldIndex = buffer.readu8(b, offset)
        offset += 1

        if fieldIndex == 0 then
            break
        end

        local fieldName = schema.fieldOrder[fieldIndex]
        local fieldType = schema.fields[fieldName]

        local typeId = buffer.readu8(b, offset)
        offset += 1

        local deserializer = SerDes.Types[fieldType]
        if deserializer then
            data[fieldName], offset = deserializer.Deserialize(b, offset)
        end
    end

    return data
end

-- ============================================================================
-- GENERIC TABLE SERIALIZATION
-- ============================================================================

function SerDes.SerializeTable(data)
    local b = buffer.create(BIG_BUFFER_SIZE)
    local offset = 0

    local function serializeValue(value)
        local valueType = typeof(value)

        if value == nil then
            buffer.writeu8(b, offset, TYPE_IDS.Nil)
            offset += 1
        elseif valueType == "boolean" then
            buffer.writeu8(b, offset, TYPE_IDS.Bool)
            offset += 1
            buffer.writeu8(b, offset, value and 1 or 0)
            offset += 1
        elseif valueType == "number" then
            if value % 1 == 0 and value >= -2147483648 and value <= 2147483647 then
                buffer.writeu8(b, offset, TYPE_IDS.Int32)
                offset += 1
                buffer.writei32(b, offset, value)
                offset += 4
            else
                buffer.writeu8(b, offset, TYPE_IDS.Float64)
                offset += 1
                buffer.writef64(b, offset, value)
                offset += 8
            end
        elseif valueType == "string" then
            local len = #value
            if len <= 255 then
                buffer.writeu8(b, offset, TYPE_IDS.String8)
                offset += 1
                offset = writeString8(b, offset, value)
            elseif len <= 65535 then
                buffer.writeu8(b, offset, TYPE_IDS.String16)
                offset += 1
                offset = writeString16(b, offset, value)
            else
                buffer.writeu8(b, offset, TYPE_IDS.String32)
                offset += 1
                offset = writeString32(b, offset, value)
            end
        elseif valueType == "Vector3" then
            buffer.writeu8(b, offset, TYPE_IDS.Vector3)
            offset += 1
            buffer.writef32(b, offset, value.X)
            buffer.writef32(b, offset + 4, value.Y)
            buffer.writef32(b, offset + 8, value.Z)
            offset += 12
        elseif valueType == "Vector2" then
            buffer.writeu8(b, offset, TYPE_IDS.Vector2)
            offset += 1
            buffer.writef32(b, offset, value.X)
            buffer.writef32(b, offset + 4, value.Y)
            offset += 8
        elseif valueType == "Color3" then
            buffer.writeu8(b, offset, TYPE_IDS.Color3)
            offset += 1
            buffer.writef32(b, offset, value.R)
            buffer.writef32(b, offset + 4, value.G)
            buffer.writef32(b, offset + 8, value.B)
            offset += 12
        elseif valueType == "CFrame" then
            buffer.writeu8(b, offset, TYPE_IDS.CFrame)
            offset += 1
            offset = SerDes.Types.CFrame.Serialize(b, offset, value)
        elseif valueType == "UDim2" then
            buffer.writeu8(b, offset, TYPE_IDS.UDim2)
            offset += 1
            offset = SerDes.Types.UDim2.Serialize(b, offset, value)
        elseif valueType == "table" then
            buffer.writeu8(b, offset, TYPE_IDS.Table)
            offset += 1

            -- Check if it's an array
            local isArray = true
            local count = 0
            for k, v in pairs(value) do
                count += 1
                if type(k) ~= "number" or k ~= count then
                    isArray = false
                    break
                end
            end

            buffer.writeu8(b, offset, isArray and 1 or 0)
            offset += 1
            buffer.writeu32(b, offset, count)
            offset += 4

            if isArray then
                for i = 1, count do
                    serializeValue(value[i])
                end
            else
                for k, v in pairs(value) do
                    serializeValue(k)
                    serializeValue(v)
                end
            end
        else
            -- Fallback: serialize as string
            buffer.writeu8(b, offset, TYPE_IDS.String8)
            offset += 1
            local str = tostring(value)
            offset = writeString8(b, offset, str)
        end
    end

    serializeValue(data)

    local finalBuffer = buffer.create(offset)
    buffer.copy(finalBuffer, 0, b, 0, offset)

    return finalBuffer
end

function SerDes.DeserializeTable(b)
    local offset = 0

    local function deserializeValue()
        local typeId = buffer.readu8(b, offset)
        offset += 1

        if typeId == TYPE_IDS.Nil then
            return nil
        elseif typeId == TYPE_IDS.Bool then
            local val = buffer.readu8(b, offset) == 1
            offset += 1
            return val
        elseif typeId == TYPE_IDS.Int32 then
            local val = buffer.readi32(b, offset)
            offset += 4
            return val
        elseif typeId == TYPE_IDS.Float64 then
            local val = buffer.readf64(b, offset)
            offset += 8
            return val
        elseif typeId == TYPE_IDS.String8 then
            local val, newOffset = readString8(b, offset)
            offset = newOffset
            return val
        elseif typeId == TYPE_IDS.String16 then
            local val, newOffset = readString16(b, offset)
            offset = newOffset
            return val
        elseif typeId == TYPE_IDS.String32 then
            local val, newOffset = readString32(b, offset)
            offset = newOffset
            return val
        elseif typeId == TYPE_IDS.Vector3 then
            local val = Vector3.new(
                buffer.readf32(b, offset),
                buffer.readf32(b, offset + 4),
                buffer.readf32(b, offset + 8)
            )
            offset += 12
            return val
        elseif typeId == TYPE_IDS.Vector2 then
            local val = Vector2.new(
                buffer.readf32(b, offset),
                buffer.readf32(b, offset + 4)
            )
            offset += 8
            return val
        elseif typeId == TYPE_IDS.Color3 then
            local val = Color3.new(
                buffer.readf32(b, offset),
                buffer.readf32(b, offset + 4),
                buffer.readf32(b, offset + 8)
            )
            offset += 12
            return val
        elseif typeId == TYPE_IDS.CFrame then
            local val, newOffset = SerDes.Types.CFrame.Deserialize(b, offset)
            offset = newOffset
            return val
        elseif typeId == TYPE_IDS.UDim2 then
            local val, newOffset = SerDes.Types.UDim2.Deserialize(b, offset)
            offset = newOffset
            return val
        elseif typeId == TYPE_IDS.Table then
            local isArray = buffer.readu8(b, offset) == 1
            offset += 1
            local count = buffer.readu32(b, offset)
            offset += 4

            local t = {}
            if isArray then
                for i = 1, count do
                    t[i] = deserializeValue()
                end
            else
                for i = 1, count do
                    local k = deserializeValue()
                    local v = deserializeValue()
                    t[k] = v
                end
            end
            return t
        else
            return nil
        end
    end

    return deserializeValue()
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function SerDes.GetBufferSize(b)
    return buffer.len(b)
end

function SerDes.CombineBuffers(...)
    local buffers = {...}
    local totalSize = 0

    for _, b in ipairs(buffers) do
        totalSize += buffer.len(b)
    end

    local combined = buffer.create(totalSize)
    local offset = 0

    for _, b in ipairs(buffers) do
        local len = buffer.len(b)
        buffer.copy(combined, offset, b, 0, len)
        offset += len
    end

    return combined
end

function SerDes.BufferToString(b)
    return buffer.tostring(b)
end

function SerDes.StringToBuffer(str)
    local b = buffer.create(#str)
    buffer.writestring(b, 0, str)
    return b
end

function SerDes.BufferToBase64(b)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local str = buffer.tostring(b)
    local result = {}
    local padding = 0

    for i = 1, #str, 3 do
        local a, b_val, c = string.byte(str, i), string.byte(str, i + 1), string.byte(str, i + 2)
        b_val = b_val or 0
        c = c or 0

        if not string.byte(str, i + 1) then padding = 2
        elseif not string.byte(str, i + 2) then padding = 1 end

        local n = a * 65536 + b_val * 256 + c

        table.insert(result, string.sub(chars, math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1))
        table.insert(result, string.sub(chars, math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
        table.insert(result, padding >= 2 and "=" or string.sub(chars, math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1))
        table.insert(result, padding >= 1 and "=" or string.sub(chars, n % 64 + 1, n % 64 + 1))
    end

    return table.concat(result)
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

local Module = {
    Vector3 = Vector3Plus,
    SerDes = SerDes,
    EPSILON = EPSILON,
    TYPE_IDS = TYPE_IDS,
}

-- Aliases for convenience
Module.V3 = Vector3Plus
Module.SD = SerDes

return Module
