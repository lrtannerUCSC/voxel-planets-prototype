-- main.lua
-- Entity-based programming demo for Love2D

-- Load required libraries and modules
local Entity = require("entity")
local Planet = require("planet")
local Player = require("player")

local player
-- Game state
local entities = {}

-- Initialize the game
function love.load()
    love.entities = entities  -- Make entities accessible globally

    local planet1 = Planet:new(200, 300, 124) -- Make multiple of cell size
    table.insert(entities, planet1)
    local planet2 = Planet:new(100, 100, 60)
    table.insert(entities, planet2)
    local planet3 = Planet:new(600, 300, 60)
    table.insert(entities, planet3)

    player = Player:new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    table.insert(entities, player)
end

function love.update(dt)
    -- Update all entities
    for _, entity in ipairs(entities) do
        entity:update(dt)
    end
    
    for _, player in ipairs(entities) do
        if player.type == "player" then
            for _, planet in ipairs(entities) do
                if planet.type == "planet" then
                    -- Calculate how many cells we need to check
                    local cellsHoriz = math.ceil(player.width / planet.cellSize) + 1
                    local cellsVert = math.ceil(player.height / planet.cellSize) + 1
                    
                    -- Get player's grid position
                    local gridX = math.floor((player.x - planet.x) / planet.cellSize)
                    local gridY = math.floor((player.y - planet.y) / planet.cellSize)
                    
                    -- Calculate check bounds
                    local startX = gridX - math.floor(cellsHoriz/2)
                    local endX = gridX + math.floor(cellsHoriz/2)
                    local startY = gridY - math.floor(cellsVert/2)
                    local endY = gridY + math.floor(cellsVert/2)
                    
                    -- Check dynamically sized grid
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
    end
    
    -- Regular entity collisions (for non-planet entities)
    -- for i, entity1 in ipairs(entities) do
    --     for j, entity2 in ipairs(entities) do
    --         if i ~= j and entity1.type ~= "player" and entity2.type ~= "planet" then
    --             if entity1:checkCollision(entity2) then
    --                 entity1:onCollision(entity2)
    --             end
    --         end
    --     end
    -- end
 
    -- Remove inactive entities
    for i = #entities, 1, -1 do
        if not entities[i].active then
            table.remove(entities, i)
        end
    end
end

-- Draw the game
function love.draw()
    -- Clear the screen
    love.graphics.clear(0.2, 0.2, 0.2)
    
    -- Draw all entities
    for _, entity in ipairs(entities) do
        entity:draw()
    end

    -- Draw HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Voxel Planet Demo - Move with WASD", 10, 10)
    love.graphics.print("Player Goobs: " .. player.money, love.graphics.getWidth() - 150, 10)
end

-- Input handling
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
