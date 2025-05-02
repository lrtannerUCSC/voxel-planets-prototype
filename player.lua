-- player.lua
-- Player entity derived from base Entity

local Entity = require("entity")

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player:new(x, y)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Player-specific properties
    instance.type = "player"
    instance.color = {255, 255, 255}
    instance.width = 16
    instance.height = 16
    instance.speed = 64
    instance.health = 100
    instance.maxHealth = 100
    instance.drillPower = 25
    
    return instance
end

function Player:update(dt)
    -- Handle player movement with WASD
    if love.keyboard.isDown("w") then
        self:move(0, -self.speed * dt)
    end
    if love.keyboard.isDown("s") then
        self:move(0, self.speed * dt)
    end
    if love.keyboard.isDown("a") then
        self:move(-self.speed * dt, 0)
    end
    if love.keyboard.isDown("d") then
        self:move(self.speed * dt, 0)
    end
    
    -- Keep player on screen
    self.x = math.max(self.width/2, math.min(self.x, love.graphics.getWidth() - self.width/2))
    self.y = math.max(self.height/2, math.min(self.y, love.graphics.getHeight() - self.height/2))
end

function Player:onCollision(other)
    -- Player-specific collision behavior
    -- if other.type == "planet" then
    --     local cellsDestroyed = other:destroyCells(self.x, self.y, self.width/2)
    -- end
end

return Player
