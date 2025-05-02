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

function Cell:checkCollision(other)
    -- Precise AABB collision using Entity's method
    return Entity.checkCollision(self, other)
end

function Cell:onCollision(player)
    if self.health > 0 then
        -- Damage cell
        self.health = self.health - player.drillPower

        if self.health <= 0 then
            local moneyEarned
            if self.type == "core" then
                moneyEarned = 10
            elseif self.type == "mantel" then
                moneyEarned = 5
            elseif self.type == "crust" then
                moneyEarned = 1
            end
            player.money = player.money + moneyEarned
        end

        -- Check cell is solid
        if self.solid then
            local dx = player.x - self.x
            local dy = player.y - self.y
            local combinedW = (player.width + self.size) / 2
            local combinedH = (player.height + self.size) / 2
            local overlapX = combinedW - math.abs(dx)
            local overlapY = combinedH - math.abs(dy)
            
            --Push player out along smallest axis
            if overlapX < overlapY then
                if dx > 0 then -- Player is to the right
                    player.x = self.x + combinedW
                else -- Player is to the left
                    player.x = self.x - combinedW
                end
            else
                if dy > 0 then -- Player is below
                    player.y = self.y + combinedH
                else -- Player is above
                    player.y = self.y - combinedH
                end
            end
        end
        return true
    end
    return false
end

return Cell