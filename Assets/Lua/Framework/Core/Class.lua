---@class Class
---Lightweight OOP base. Supports single inheritance and constructor chaining.
---Usage:
---  local Animal = Class("Animal")
---  function Animal:ctor(name) self.name = name end
---  local Dog = Class("Dog", Animal)
---  function Dog:ctor(name) Dog.super.ctor(self, name) end

local Class = {}

---Create a new class with optional super class.
---@param name string
---@param super? table
---@return table
function Class.define(name, super)
    local cls = {}
    cls.__name  = name
    cls.__index = cls
    cls.super   = super

    if super then
        setmetatable(cls, { __index = super })
    end

    ---Create a new instance of this class.
    ---@vararg any  constructor arguments
    ---@return table
    function cls.new(...)
        local inst = setmetatable({}, cls)
        if inst.ctor then
            inst:ctor(...)
        end
        return inst
    end

    ---Check if an object is an instance of this class (or a subclass).
    ---@param obj table
    ---@return boolean
    function cls.isInstance(obj)
        if type(obj) ~= "table" then return false end
        local mt = getmetatable(obj)
        while mt do
            if mt == cls then return true end
            mt = mt.super and getmetatable(mt) or nil
            if mt then mt = mt.__index end
        end
        return false
    end

    return cls
end

setmetatable(Class, {
    __call = function(_, name, super)
        return Class.define(name, super)
    end,
})

return Class
