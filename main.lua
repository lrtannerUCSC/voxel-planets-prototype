-- Load required libraries and modules
local World = require("world")
local Entity = require("entity")
local Planet = require("planet")
local Player = require("player")

-- Set random seed based on current time
math.randomseed(os.time())
if love.math then
    love.math.setRandomSeed(os.time())
end

-- Global variables
local world
local player
local camera
local entities = {}

-- Initialize the game
function love.load()
    entities = {}  -- Clear global table
    love.entities = entities
    love.window.setMode(1280, 720)
    math.randomseed(os.time())

    world = World:new()
    world:loadChunk(0, 0)  -- Load initial chunk

    -- Spawn player
    player = Player:new(World.CHUNK_SIZE / 2, World.CHUNK_SIZE / 2)
    table.insert(entities, player)  -- Only the player is global
    camera = { x = 0, y = 0, scale = 1 }
end

function love.update(dt)
    
    world:update(player.x, player.y)
    player:update(dt, world)
    -- -- Update all entities (player is in this table)
    -- for _, entity in ipairs(entities) do
    --     entity:update(dt)
    -- end
    
    -- Check player collision with planets from ACTIVE CHUNKS
    for _, chunk in pairs(world.activeChunks) do
        for _, planet in ipairs(chunk.entities) do
            if planet.type == "planet" then
                -- Calculate how many cells to check
                local cellsHoriz = math.ceil(player.width / planet.cellSize) + 1
                local cellsVert = math.ceil(player.height / planet.cellSize) + 1
                
                -- Get player's grid position relative to planet
                local gridX = math.floor((player.x - planet.x) / planet.cellSize)
                local gridY = math.floor((player.y - planet.y) / planet.cellSize)
                
                -- Calculate check bounds
                local startX = gridX - math.floor(cellsHoriz/2)
                local endX = gridX + math.floor(cellsHoriz/2)
                local startY = gridY - math.floor(cellsVert/2)
                local endY = gridY + math.floor(cellsVert/2)
                
                -- Check each cell in the grid
                for x = startX, endX do
                    for y = startY, endY do
                        if planet.cellGrid[x] and planet.cellGrid[x][y] then
                            local cell = planet.cellGrid[x][y]
                            if cell:checkCollision(player) then
                                cell:onCollision(player)
                            end
                        end
                    end
                end
            end
        end
    end

    updateCamera(dt)
    
    -- Cleanup inactive entities (if needed)
    for i = #entities, 1, -1 do
        if not entities[i].active then
            table.remove(entities, i)
        end
    end
end

function love.draw()
    love.graphics.clear(0.2, 0.2, 0.2)

    -- Apply camera transform (this affects all drawing until pop)
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
    love.graphics.scale(camera.scale)
    
    -- Draw world elements (affected by camera)
    for _, chunk in pairs(world.activeChunks) do
        for _, entity in ipairs(chunk.entities) do
            entity:draw()
        end
    end
    player:draw()
    
    love.graphics.pop() -- End camera transform

    -- Draw UI elements (not affected by camera)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Voxel Planet Demo - Move with WASD", 10, 10)
    love.graphics.print("Player Goobs: " .. player.money, love.graphics.getWidth() - 150, 10)
    love.graphics.print("Player Speed: " .. math.floor(player.currentSpeed), love.graphics.getWidth() - 150, 50)
    love.graphics.print("Player Fuel: " .. math.floor(player.fuel) .. " / " .. player.maxFuel, love.graphics.getWidth() - 150, 90)

end

-- Input handling
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function generateRandomPlanets(count)
    local planets = {}
    table.insert(planets, { -- Avoid spawning on player
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        radius = 124
    })
    local attempts = 0
    local maxAttempts = 100  -- Prevent infinite loops
    
    while #planets < count and attempts < maxAttempts do
        local x = math.random(100, love.graphics.getWidth() - 100)
        local y = math.random(100, love.graphics.getHeight() - 100)
        local radius = math.random(60, 124)
        while radius % 8 ~= 4 do -- Make sure radius is a multiple of cell size
            radius = math.random(60, 124)
        end
        if isPositionValid(x, y, radius, planets) then
            table.insert(planets, {
                x = x, y = y, radius = radius,
                -- Store other planet properties here if needed
            })
            table.insert(entities, Planet:new(x, y, radius))
        end
        attempts = attempts + 1
    end
    
    if attempts >= maxAttempts then
        print("Warning: Could only place", #planets, "out of", count, "planets")
    end
end

function isPositionValid(x, y, radius, planetList)
    for _, planet in ipairs(planetList) do
        local dx = x - planet.x
        local dy = y - planet.y
        local distance = math.sqrt(dx*dx + dy*dy)
        local minDistance = radius + planet.radius + 20 -- Padding
        
        if distance < minDistance then
            return false  -- Overlaps with an existing planet
        end
    end
    return true  -- Position is safe
end

function updateCamera(dt)
    -- Smooth follow with deadzone
    local targetX = player.x - love.graphics.getWidth()/2
    local targetY = player.y - love.graphics.getHeight()/2
    
    camera.x = camera.x + (targetX - camera.x) * 5 * dt
    camera.y = camera.y + (targetY - camera.y) * 5 * dt
end