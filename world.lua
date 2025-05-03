local Planet = require("planet")
local json = require("dkjson")
local World = {}
World.__index = World

-- Chunk size should be 2-4x larger than your screen dimensions
World.CHUNK_SIZE = 2048 

function World:new()
    local instance = {
        activeChunks = {},
        generatedChunks = {},  -- NEW: Tracks ALL generated chunks (even unloaded ones)
        chunkSize = World.CHUNK_SIZE,
        loadDistance = 1
    }
    return setmetatable(instance, self)
end

-- Convert world position to chunk coordinates
function World:positionToChunk(x, y)
    return math.floor(x / World.CHUNK_SIZE), math.floor(y / World.CHUNK_SIZE)
end

-- Load/unload chunks based on player position
function World:update(playerX, playerY)
    local centerX, centerY = self:positionToChunk(playerX, playerY)
    
    -- Unload distant chunks
    for chunkKey, _ in pairs(self.activeChunks) do
        local cx, cy = self:keyToPosition(chunkKey)
        if math.abs(cx - centerX) > self.loadDistance or 
           math.abs(cy - centerY) > self.loadDistance then
            self:unloadChunk(cx, cy)
        end
    end
    
    -- Load new chunks
    for dx = -self.loadDistance, self.loadDistance do
        for dy = -self.loadDistance, self.loadDistance do
            local x, y = centerX + dx, centerY + dy
            if not self.activeChunks[self:positionToKey(x, y)] then
                self:loadChunk(x, y)
            end
        end
    end
end

function World:saveChunk(x, y)
    local key = self:positionToKey(x, y)
    print("saving chunk", key, self.activeChunks[key])
    local chunkData = self:sanitizeForSave(key)
    
    local jsonData, err = json.encode(chunkData)
    if not jsonData then
        print("JSON encode error:", err)
        return false
    end
    
    return love.filesystem.write("chunks/"..key..".json", jsonData)
end

function World:sanitizeForSave(key)
    local chunk = self.activeChunks[key]
    print("santizing chunk ", chunk)
    -- Create a clean copy without circular references
    local clean = {
        x = chunk.x,
        y = chunk.y,
        entities = {}
    }
    
    for _, entity in ipairs(chunk.entities) do
        table.insert(clean.entities, {
            type = entity.type,
            x = entity.x,
            y = entity.y,
            radius = entity.radius
            -- Add other serializable properties
        })
    end
    
    return clean
end

function World:loadChunk(x, y)
    local key = self:positionToKey(x, y)
    
    -- Return if already loaded
    if self.activeChunks[key] ~= nil then return self.activeChunks[key] end
    
    -- Try loading from file
    local chunkFile = "chunks/"..key..".json"
    if love.filesystem.getInfo(chunkFile) then
        local jsonData = love.filesystem.read(chunkFile)
        local chunkData, pos, err = json.decode(jsonData)
        
        if err then
            print("Failed to decode chunk data:", err)
            -- Fall back to generation if file is corrupt
            return self:generateNewChunk(x, y)
        end
        
        self.activeChunks[key] = chunkData
        self.generatedChunks[key] = true
        return chunkData
    end
    
    -- Generate new chunk if never created before
    if not self.generatedChunks[key] then
        local chunk = self:generateNewChunk(x, y)
        self.activeChunks[key] = chunk
        self.generatedChunks[key] = true
        print("info from chunk", key, self.activeChunks[key])
        return chunk
    end
    print("chunk exists but not loaded")
    return nil  -- Chunk exists but isn't currently loaded
end

function World:unloadChunk(x, y)
    local key = self:positionToKey(x, y)
    if self.activeChunks[key] then
        self:saveChunk(x, y)  -- Optional: Save before unloading
        self.activeChunks[key] = nil
    end
end

function World:generateNewChunk(x, y)
    return {
        x = x * self.chunkSize,
        y = y * self.chunkSize,
        entities = self:generateChunkContent(x, y)
    }
end

function World:generateChunkContent(x, y)
    math.randomseed(x * 10000 + y)
    local entities = {}
    local chunkWorldX = x * self.chunkSize
    local chunkWorldY = y * self.chunkSize
    
    -- Generation parameters
    local minPadding = 300  -- Minimum space between planets
    local maxPlanets = 5    -- Reduced for performance
    local gridSize = 500    -- Spatial partitioning cell size
    
    -- Create spatial grid
    local gridCells = math.ceil(World.CHUNK_SIZE / gridSize)
    local grid = {}
    for i = 1, gridCells do grid[i] = {} end
    
    local function getGridCell(px, py)
        return math.floor((px - chunkWorldX) / gridSize) + 1,
               math.floor((py - chunkWorldY) / gridSize) + 1
    end

    for _ = 1, maxPlanets do
        -- Generate candidate planet
        local planet = Planet:new(
            chunkWorldX + math.random(0, World.CHUNK_SIZE),
            chunkWorldY + math.random(0, World.CHUNK_SIZE),
            math.random(80, 200)
        )
        
        -- Check nearby grid cells only
        local cx, cy = getGridCell(planet.x, planet.y)
        local valid = true
        
        for dx = -1, 1 do
            for dy = -1, 1 do
                local checkX, checkY = cx + dx, cy + dy
                if grid[checkX] and grid[checkX][checkY] then
                    for _, other in ipairs(grid[checkX][checkY]) do
                        local dist = math.sqrt(
                            (planet.x - other.x)^2 + 
                            (planet.y - other.y)^2
                        )
                        if dist < (planet.radius + other.radius + minPadding) then
                            valid = false
                            break
                        end
                    end
                    if not valid then break end
                end
            end
            if not valid then break end
        end
        
        if valid then
            -- Add to grid and entities
            grid[cx] = grid[cx] or {}
            grid[cx][cy] = grid[cx][cy] or {}
            table.insert(grid[cx][cy], planet)
            table.insert(entities, planet)
        end
    end
    
    return entities
end

-- Fetch all entities from loaded chunks
function World:getAllEntities()
    local entities = {}
    for _, chunk in pairs(self.activeChunks) do
        for _, entity in ipairs(chunk.entities) do
            table.insert(entities, entity)
        end
    end
    return entities
end

-- Helper functions
function World:positionToKey(x, y) return x..":"..y end
function World:keyToPosition(key) return key:match("([^:]+):([^:]+)") end

function World:calculateGravity(player, dt)
    local totalFx, totalFy = 0, 0
    player.inPlanet = false
    
    if not self.activeChunks then
        print("Warning: activeChunks is nil in calculateGravity")
        return totalFx, totalFy
    end
    
    -- Check all active chunks
    for _, chunk in pairs(self.activeChunks) do
        for _, entity in ipairs(chunk.entities) do
            if entity.type == "planet" then
                local dx = player.x - entity.x
                local dy = player.y - entity.y
                local distance = math.sqrt(dx^2 + dy^2)
                
                -- Inside planet (landing)
                if distance < entity.radius then
                    player.inPlanet = true
                    player.color = {1, 0, 1} -- Visual feedback
                else 
                    -- Gravity force (inverse square law)
                    local force = (entity.radius^2 / distance) * 5 * dt
                    totalFx = totalFx - (dx/distance) * force
                    totalFy = totalFy - (dy/distance) * force
                end
            end
        end
    end
    
    return totalFx, totalFy
end

return World