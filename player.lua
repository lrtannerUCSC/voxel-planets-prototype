local Entity = require("entity")
local World = require("world")
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
    instance.maxSpeed = 400
    instance.damping = 0.96
    instance.currentSpeed = 0
    instance.baseSpeed = 0  -- Track speed before any reductions
    
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
    instance.speedReductionTimer = 0  -- Timer for speed reduction
    

    instance.addResource = function(resourceType, amount)
        -- Initialize inventory table if it doesn't exist
        instance.inventory = instance.inventory or {}
        
        -- Check if resource already exists in inventory
        if instance.inventory[resourceType] then
            instance.inventory[resourceType] = instance.inventory[resourceType] + amount
        else
            instance.inventory[resourceType] = amount
        end
    end

    return instance

end

function Player:update(dt, world)
    -- Mouse-facing control
    local mouseX, mouseY = love.mouse.getPosition()
    local worldMouseX, worldMouseY = self:screenToWorld(mouseX, mouseY)
    local dx = worldMouseX - self.x
    local dy = worldMouseY - self.y
    self.facingAngle = math.atan2(dy, dx)
    
    -- Thrust control
    if love.keyboard.isDown("w") or love.mouse.isDown(1) then
        local thrustX = math.cos(self.facingAngle) * self.thrustForce * dt
        local thrustY = math.sin(self.facingAngle) * self.thrustForce * dt
        self.velocity.x = self.velocity.x + thrustX
        self.velocity.y = self.velocity.y + thrustY
    end
    
    -- Get gravity from WORLD INSTANCE
    local gravityX, gravityY = world:calculateGravity(self, dt)
    
    -- Apply forces
    self.velocity.x = self.velocity.x + gravityX
    self.velocity.y = self.velocity.y + gravityY

    -- Update base speed (before any reductions)
    self.baseSpeed = math.sqrt(self.velocity.x^2 + self.velocity.y^2)
    
    -- Apply speed reduction if active
    if self.speedReductionTimer > 0 then
        self.speedReductionTimer = self.speedReductionTimer - dt
        self.currentSpeed = math.max(self.baseSpeed * 0.25, 50) -- MAGIC NUMBER FOR SPEED REDUCTION
    else
        self.currentSpeed = self.baseSpeed
    end

    -- Apply velocity to position
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt

    self:updateDrillSpeed()
end

function Player:updateDrillSpeed()
    -- Drill power scales with speed, but has a minimum value
    self.drillPower = math.max(10, self.currentSpeed / 4)
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

function Player:screenToWorld(screenX, screenY)
    -- Get camera offset (assuming camera follows player)
    local cameraX, cameraY = self.x - love.graphics.getWidth() / 2, 
                            self.y - love.graphics.getHeight() / 2
    
    -- Convert screen position to world position
    local worldX = screenX + cameraX
    local worldY = screenY + cameraY
    
    return worldX, worldY
end



return Player