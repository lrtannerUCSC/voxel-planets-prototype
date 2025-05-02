-- main.lua
-- Entity-based programming demo for Love2D

-- Load required libraries and modules
local Entity = require("entity")
local Planet = require("planet")
local Player = require("player")

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

    local player = Player:new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    table.insert(entities, player)
end

-- Update game state
function love.update(dt)
    -- Update all entities
    for _, entity in ipairs(entities) do
        entity:update(dt)
    end
    
    -- Special collision handling
    for _, player in ipairs(entities) do
        if player.type == "player" then
            for _, planet in ipairs(entities) do
                if planet.type == "planet" then
                    -- Check against planet cells instead of planet itself
                    local gridX = math.floor((player.x - planet.x) / planet.cellSize)
                    local gridY = math.floor((player.y - planet.y) / planet.cellSize)
                    
                    -- Check 3x3 area around player
                    for x = gridX-1, gridX+1 do
                        for y = gridY-1, gridY+1 do
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
    for i, entity1 in ipairs(entities) do
        for j, entity2 in ipairs(entities) do
            if i ~= j and entity1.type ~= "player" and entity2.type ~= "planet" then
                if entity1:checkCollision(entity2) then
                    entity1:onCollision(entity2)
                end
            end
        end
    end
 
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
end

-- Input handling
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
