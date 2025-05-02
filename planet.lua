local Entity = require("entity")
local Cell = require("cell")

local Planet = {}
Planet.__index = Planet
setmetatable(Planet, {__index = Entity})

function Planet:new(x, y, radius)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Planet-specific properties
    instance.type = "planet"
    instance.coreColor = {1, 0, 0}  -- Red
    instance.mantelColor = {0, 1, 0}  -- Green
    instance.CrustColor = {0, 0, 1}  -- Blue
    instance.radius = radius
    instance.width = radius * 2
    instance.height = radius * 2
    instance.x = x
    instance.y = y
    instance.cellSize = 8
    instance.cells = {} -- 2D grid: cells[x][y] = Cell
    instance.cellGrid = {} -- For fast coordinate->cell lookup
    
    instance:generateCells()
    return instance
end

function Planet:generateCells()
    for i = -self.radius, self.radius, self.cellSize do
        for j = -self.radius, self.radius, self.cellSize do
            if i^2 + j^2 <= self.radius^2 then
                local cell = Cell:new(self.x + i, self.y + j, self)
                if i^2 + j^2 <= (self.radius*0.25)^2 then
                    cell.color = self.coreColor
                    cell.type = "core"
                    cell.health = 500
                elseif i^2 + j^2 <= (self.radius*0.85)^2 then
                    cell.color = self.mantelColor
                    cell.type = "mantel"
                    cell.health = 200
                else
                    cell.color = self.CrustColor
                    cell.type = "crust"
                    cell.health = 50
                end
                
                -- Store in both list and grid
                table.insert(self.cells, cell)
                local gridX, gridY = math.floor(i/self.cellSize), math.floor(j/self.cellSize)
                self.cellGrid[gridX] = self.cellGrid[gridX] or {}
                self.cellGrid[gridX][gridY] = cell
            end
        end
    end
end

function Planet:draw()
    for _, cell in ipairs(self.cells) do
        if cell.health > 0 then  -- Only draw living cells
            love.graphics.setColor(cell.color)
            love.graphics.rectangle("fill",
                cell.x - self.cellSize/2,
                cell.y - self.cellSize/2,
                self.cellSize, self.cellSize
            )
        end
    end
end

-- In planet.lua
function Planet:destroyCells(x, y, radius)
    local cellsDestroyed = 0
    local gridRadius = math.ceil(radius / self.cellSize)
    
    -- Convert world coordinates to grid coordinates
    local centerGridX = math.floor((x - self.x) / self.cellSize)
    local centerGridY = math.floor((y - self.y) / self.cellSize)
    
    -- Check cells in a square area around the impact point
    for gridX = centerGridX - gridRadius, centerGridX + gridRadius do
        for gridY = centerGridY - gridRadius, centerGridY + gridRadius do
            if self.cellGrid[gridX] and self.cellGrid[gridX][gridY] then
                local cell = self.cellGrid[gridX][gridY]
                -- Check if within circular destruction radius
                local dist = math.sqrt(
                    (x - cell.x)^2 + 
                    (y - cell.y)^2
                )
                if dist <= radius*1.5 then -- padding on radius for diagonals
                    cell.health = cell.health - 1
                    if cell.health <= 0 then
                        self.cellGrid[gridX][gridY] = nil
                        cellsDestroyed = cellsDestroyed + 1
                    end
                end
            end
        end
    end
    
    -- Rebuild flat cells list (for drawing)
    self.cells = {}
    for _, row in pairs(self.cellGrid) do
        for _, cell in pairs(row) do
            table.insert(self.cells, cell)
        end
    end
    
    return cellsDestroyed
end


return Planet