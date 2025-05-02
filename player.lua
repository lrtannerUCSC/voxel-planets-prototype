local Entity = require("entity")

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player:new(x, y)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Movement properties
    instance.velocity = {x = 0, y = 0}
    instance.facingAngle = 0  -- In radians
    instance.rotationSpeed = 4  -- How fast the player turns
    instance.thrustForce = 400
    instance.maxSpeed = 250
    instance.damping = 0.96
    
    -- Physics properties
    instance.gravityScale = 1.0
    instance.inPlanet = false
    
    -- Visual properties
    instance.thrustLineLength = 50
    instance.shipShape = {  -- Triangle pointing right
        10, 0, -5, -6, -5, 6
    }
    
    -- Gameplay properties
    instance.type = "player"
    instance.width = 16
    instance.height = 16
    instance.color = {1, 1, 1}
    instance.health = 100
    instance.drillPower = 25
    instance.money = 0
    
    return instance
end

function Player:update(dt)
    -- Rotation control (A/D keys)
    -- if love.keyboard.isDown("a") then
    --     self.facingAngle = self.facingAngle - self.rotationSpeed * dt
    -- end
    -- if love.keyboard.isDown("d") then
    --     self.facingAngle = self.facingAngle + self.rotationSpeed * dt
    -- end
    
    -- Mouse-facing control
    local mouseX, mouseY = love.mouse.getPosition()
    local dx = mouseX - self.x
    local dy = mouseY - self.y
    self.facingAngle = math.atan2(dy, dx)
    -- Thrust control (W key or mouse click)
    local thrusting = false
    if love.keyboard.isDown("w") or love.mouse.isDown(1) then
        local thrustX = math.cos(self.facingAngle) * self.thrustForce * dt
        local thrustY = math.sin(self.facingAngle) * self.thrustForce * dt
        self.velocity.x = self.velocity.x + thrustX
        self.velocity.y = self.velocity.y + thrustY
        thrusting = true
    end
    
    -- Check planets for gravity/immersion
    self.inPlanet = false
    for _, entity in ipairs(love.entities) do
        if entity.type == "planet" then
            local dx = self.x - entity.x
            local dy = self.y - entity.y
            local distance = math.sqrt(dx^2 + dy^2)
            
            if distance < entity.radius then
                self.inPlanet = true
                self.color = {1, 0, 1}  -- Purple when inside planet
            else
                -- Apply gravity if outside
                local gravityDir = {x = dx/distance, y = dy/distance}
                local gravityStrength = entity.radius * 2 * dt
                self.velocity.x = self.velocity.x - gravityDir.x * gravityStrength
                self.velocity.y = self.velocity.y - gravityDir.y * gravityStrength
            end
        end
    end
    
    -- Default color when not in planet
    if not self.inPlanet then
        self.color = {1, 1, 1}
    end
    
    -- Apply damping when not thrusting
    -- if not thrusting then
    --     self.velocity.x = self.velocity.x * self.damping
    --     self.velocity.y = self.velocity.y * self.damping
    -- end
    
    -- Limit speed
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

function Player:draw()
    -- Draw rotated ship
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.facingAngle)
    
    -- Ship body (triangle)
    love.graphics.setColor(self.color)
    love.graphics.polygon("fill", self.shipShape)
    
    -- Thrust flame (when thrusting)
    if love.keyboard.isDown("w") or love.mouse.isDown(1) then
        love.graphics.setColor(1, 0.7, 0.3)
        love.graphics.line(0, 0, -self.thrustLineLength, 0)
        love.graphics.line(0, -3, -self.thrustLineLength*0.7, 0)
        love.graphics.line(0, 3, -self.thrustLineLength*0.7, 0)
    end
    
    love.graphics.pop()
    
    -- Debug: velocity vector (green)
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.line(
        self.x, self.y,
        self.x + self.velocity.x * 0.3,
        self.y + self.velocity.y * 0.3
    )
end

function math.clamp(n, min, max)
    return math.min(math.max(n, min), max)
end

return Player