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

function Cell:onCollision(other)
    if self.health > 0 then
        if other.type == "player" then    
            -- Damage cell based on drill power
            self.health = math.max(0, self.health - other.drillPower)

            if self.health <= 0 then
                local moneyEarned
                if self.type == "core" then
                    moneyEarned = 10
                elseif self.type == "mantel" then
                    moneyEarned = 5
                elseif self.type == "crust" then
                    moneyEarned = 1
                end
                other.money = other.money + moneyEarned
                other.fuel = math.min(other.maxFuel, other.fuel + math.floor(moneyEarned/2))
            end

            -- Check cell is solid
            if self.solid then
                -- Apply temporary speed reduction (0.5 seconds)
                other.speedReductionTimer = 1
                
                -- Push other out of collision
                local dx = other.x - self.x
                local dy = other.y - self.y
                local combinedW = (other.width + self.size) / 2
                local combinedH = (other.height + self.size) / 2
                local overlapX = combinedW - math.abs(dx)
                local overlapY = combinedH - math.abs(dy)
                
                -- Push other out along smallest axis
                if overlapX < overlapY then
                    if dx > 0 then -- other is to the right
                        other.x = self.x + combinedW
                    else -- other is to the left
                        other.x = self.x - combinedW
                    end
                else
                    if dy > 0 then -- other is below
                        other.y = self.y + combinedH
                    else -- other is above
                        other.y = self.y - combinedH
                    end
                end
            end
            return true
        end
    end
    return false
end

return Cell