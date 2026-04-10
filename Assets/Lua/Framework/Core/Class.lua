--- Class.lua
--- 轻量级 Lua 面向对象基础类
---
--- 用法示例:
---   local Animal = Class:extend()
---   function Animal:init(name) self.name = name end
---   function Animal:speak() return self.name end
---
---   local Dog = Animal:extend()
---   function Dog:init(name) Dog.super.init(self, name) end
---   function Dog:speak() return "Woof! " .. Dog.super.speak(self) end
---
---   local d = Dog("Rex")
---   print(d:speak())  --> "Woof! Rex"

local Class = {}
Class.__index = Class

--- 创建一个继承自当前类的子类
---@return table 新的子类
function Class:extend()
    local cls = {}
    cls.__index = cls
    cls.super = self
    setmetatable(cls, {
        __index = self,
        __call  = function(c, ...)
            local instance = setmetatable({}, c)
            if instance.init then
                instance:init(...)
            end
            return instance
        end,
    })
    return cls
end

--- 检查 instance 是否是 klass 的实例（支持继承链）
---@param instance table
---@param klass table
---@return boolean
function Class.isInstance(instance, klass)
    local mt = getmetatable(instance)
    while mt do
        if mt == klass then return true end
        mt = getmetatable(mt)
        if mt then mt = mt.__index end
    end
    return false
end

setmetatable(Class, {
    __call = function(c, ...)
        local instance = setmetatable({}, c)
        if instance.init then
            instance:init(...)
        end
        return instance
    end,
})

return Class
