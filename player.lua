local Entity = require("entity")

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player:new(x, y)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Player properties
    instance.type = "player"
    instance.color = {1, 1, 1}  -- Changed to 0-1 range for LÖVE
    instance.width = 16
    instance.height = 16

    -- Movement properties
    instance.velocity = {x = 0, y = 0}
    instance.thrustForce = 500
    instance.maxSpeed = 500
    instance.damping = 0.92

    -- Physics properties
    instance.gravityScale = 1.0
    instance.inPlanet = false

    instance.health = 100
    instance.maxHealth = 100
    instance.drillPower = 25
    instance.money = 0
    
    -- Add movement properties
    instance.targetX = x
    instance.targetY = y
    instance.moveThreshold = 5  -- Distance to stop moving
    
    return instance
end

function Player:update(dt)
    -- Get mouse position
    self.targetX, self.targetY = love.mouse.getPosition()
    
    -- Calculate direction vector
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local thrustDirection = {x = 0, y = 0}
    
    if distance > 5 then
        thrustDirection.x = dx / distance
        thrustDirection.y = dy / distance
    end
    
    -- Apply thrust
    self.velocity.x = self.velocity.x + thrustDirection.x * self.thrustForce * dt
    self.velocity.y = self.velocity.y + thrustDirection.y * self.thrustForce * dt

        -- Check planet collisions and gravity
    self.inPlanet = false
    self.color = ({1, 1, 1})
    for _, entity in ipairs(love.entities) do
        if entity.type == "planet" then
            -- Check if inside planet
            local dx = self.x - entity.x
            local dy = self.y - entity.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < entity.radius then
                self.inPlanet = true
                self.color = ({1, 0, 1})
            else
                -- Apply gravity if outside
                local gravityStrength = entity.radius*2
                local gravityDir = {x = dx/distance, y = dy/distance}
                self.velocity.x = self.velocity.x - gravityDir.x * gravityStrength * dt
                self.velocity.y = self.velocity.y - gravityDir.y * gravityStrength * dt
            end
        end
    end
    
    -- Apply velocity damping if not thrusting
    if distance < 20 then
        self.velocity.x = self.velocity.x * self.damping
        self.velocity.y = self.velocity.y * self.damping
    end
    
    -- Limit maximum speed
    local speed = math.sqrt(self.velocity.x^2 + self.velocity.y^2)
    if speed > self.maxSpeed then
        self.velocity.x = (self.velocity.x / speed) * self.maxSpeed
        self.velocity.y = (self.velocity.y / speed) * self.maxSpeed
    end
    
    -- Update position
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
    
    -- Screen bounds
    self.x = math.clamp(self.x, self.width/2, love.graphics.getWidth() - self.width/2)
    self.y = math.clamp(self.y, self.height/2, love.graphics.getHeight() - self.height/2)
end

-- Optional: Visualize target
function Player:draw()
    -- Default draw
    Entity.draw(self)
    
    -- Calculate thrust vector properties
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Only draw if mouse is far enough
    if distance > 10 then
        -- Normalize direction
        local dirX, dirY = dx/distance, dy/distance
        
        -- Calculate thrust strength (0-1)
        local thrustStrength = math.min(1, distance / 100)  -- 100 = max distance for full strength
        
        -- Line properties
        local maxLineLength = self.maxSpeed/2
        local lineLength = maxLineLength * thrustStrength
        local lineEndX = self.x + dirX * lineLength
        local lineEndY = self.y + dirY * lineLength
        
        -- Draw thrust line (points toward mouse)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0, 0.8, 1, 0.8)  -- Cyan thrust indicator
        love.graphics.line(self.x, self.y, lineEndX, lineEndY)
        
    end
end

-- helper function for gravity
function math.clamp(n, min, max)
    return math.min(math.max(n, min), max)
end

return Player
