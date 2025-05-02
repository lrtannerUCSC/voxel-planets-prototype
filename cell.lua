local Entity = require("entity")

local Cell = {}
Cell.__index = Cell

function Cell:new(x, y, planet)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    instance.x = x
    instance.y = y
    instance.planet = planet
    instance.size = planet.cellSize
    instance.health = 100
    instance.color = {0.5, 0.5, 0.5}
    instance.type = "cell"
    instance.solid = true
    return setmetatable(instance, self)
end

function Cell:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.rectangle("fill", 
        self.x - self.size/2, 
        self.y - self.size/2, 
        self.size, self.size
    )
end

function Cell:update(dt)
    -- Optional: Override in child classes
end

return Cell