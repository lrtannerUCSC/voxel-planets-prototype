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
    
    -- Collision detection (simplified)
    for i, entity1 in ipairs(entities) do
        for j, entity2 in ipairs(entities) do
            if i ~= j then
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
