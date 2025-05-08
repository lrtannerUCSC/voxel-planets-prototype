

local TabInventory = {}
TabInventory.__index = TabInventory

-- Constants
local INVENTORY_SLOTS = 20  -- inventory slots
local ROWS = 4
local COLS = 5
local SLOT_SIZE = 64
local PADDING = 12  
local ITEM_TYPES = {
    "ore", "fuel", "core", "mantel", "crust", "upgrade"
}

function TabInventory:new(player)
    local instance = {}
    setmetatable(instance, self)
    

    instance.player = player
    
    -- Initialize player upgrade properties 
    if not player.engineUpgrade then player.engineUpgrade = 0 end
    if not player.armorUpgrade then player.armorUpgrade = 0 end
    if not player.fuelUpgrade then player.fuelUpgrade = 0 end
    if not player.drillUpgrade then player.drillUpgrade = 0 end
    if not player.money then player.money = 0 end
    if not player.fuel then player.fuel = 0 end
    if not player.maxFuel then player.maxFuel = 100 end
    
    -- Inventory dimensions 
    instance.width = COLS * (SLOT_SIZE + PADDING) + PADDING + 100  
    instance.height = ROWS * (SLOT_SIZE + PADDING) + 250  
    instance.x = (love.graphics.getWidth() - instance.width) / 2
    instance.y = (love.graphics.getHeight() - instance.height) / 2
    
    -- Initialize inventory properties
    instance.visible = false
    instance.selectedSlot = 1
    

    instance.slots = {}
    local startX = instance.x + 50  
    local startY = instance.y + 120  
    
    for i = 1, INVENTORY_SLOTS do
        local row = math.floor((i-1) / COLS)
        local col = (i-1) % COLS
        
        instance.slots[i] = {
            x = startX + col * (SLOT_SIZE + PADDING),
            y = startY + row * (SLOT_SIZE + PADDING),
            item = nil,  -- Will store item data
            count = 0    -- For stackable items
        }
    end
    

    if not player.inventory then
        player.inventory = {}
    end
    
    return instance
end


function TabInventory:toggle()
    self.visible = not self.visible
    print("Inventory visibility toggled to: " .. tostring(self.visible)) -- debugger
end

-- Add item to inventory
function TabInventory:addItem(itemType, amount, properties)
    amount = amount or 1
    properties = properties or {}
    
    -- Check if the item already exists in inventory
    if itemType ~= "upgrade" then  
        for i, slot in ipairs(self.slots) do
            if slot.item and slot.item.type == itemType then
                slot.count = slot.count + amount
                return true
            end
        end
    end
    
    -- Find an empty slot
    for i, slot in ipairs(self.slots) do
        if not slot.item then
            slot.item = {
                type = itemType,
                properties = properties
            }
            slot.count = amount
            return true
        end
    end
    
    -- Inventory is full
    return false
end

-- Remove item from inventory
function TabInventory:removeItem(itemType, amount)
    amount = amount or 1
    
    for i, slot in ipairs(self.slots) do
        if slot.item and slot.item.type == itemType then
            if slot.count > amount then
                slot.count = slot.count - amount
                return true
            else
                slot.item = nil
                slot.count = 0
                return true
            end
        end
    end
    
    return false  -- item na
end

-- Check if player has a specific item
function TabInventory:hasItem(itemType, amount)
    amount = amount or 1
    
    for i, slot in ipairs(self.slots) do
        if slot.item and slot.item.type == itemType and slot.count >= amount then
            return true
        end
    end
    
    return false
end


function TabInventory:draw()
    if not self.visible then
        return
    end
    
    -- semi transparent background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    

    love.graphics.setColor(0.2, 0.2, 0.25, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
    
    -- border
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
    
    -- inventory title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("Inventory", self.x + self.width/2 - 60, self.y + 30)
    
    -- player stats
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print("Engine Level: " .. (self.player.engineUpgrade or 0), self.x + 50, self.y + 70)
    love.graphics.print("Armor Level: " .. (self.player.armorUpgrade or 0), self.x + 50 + 150, self.y + 70)
    love.graphics.print("Fuel Level: " .. (self.player.fuelUpgrade or 0), self.x + 50, self.y + 90)
    love.graphics.print("Drill Level: " .. (self.player.drillUpgrade or 0), self.x + 50 + 150, self.y + 90)
    love.graphics.print("Money: " .. (self.player.money or 0) .. " Goobs", self.x + self.width - 200, self.y + 70)
    
    -- slots and items
    for i, slot in ipairs(self.slots) do
        -- slot background
        if i == self.selectedSlot then
            love.graphics.setColor(0.8, 0.8, 0.2, 0.3)  -- Highlight selected slot
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
        end
        love.graphics.rectangle("fill", slot.x, slot.y, SLOT_SIZE, SLOT_SIZE)
        
        -- slot border
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        love.graphics.rectangle("line", slot.x, slot.y, SLOT_SIZE, SLOT_SIZE)
        

        if slot.item then
            -- Different colors for different items
            if slot.item.type == "ore" then
                love.graphics.setColor(0.6, 0.3, 0.1, 1)
            elseif slot.item.type == "fuel" then
                love.graphics.setColor(0.2, 0.6, 0.9, 1)
            elseif slot.item.type == "core" then
                love.graphics.setColor(0.9, 0.8, 0.2, 1)
            elseif slot.item.type == "mantel" then
                love.graphics.setColor(0.8, 0.2, 0.2, 1)
            elseif slot.item.type == "crust" then
                love.graphics.setColor(0.3, 0.8, 0.3, 1)
            elseif slot.item.type == "upgrade" then
                love.graphics.setColor(0.8, 0.3, 0.8, 1)
            end
            
            --  item representation
            love.graphics.rectangle("fill", 
                slot.x + SLOT_SIZE/4, 
                slot.y + SLOT_SIZE/4, 
                SLOT_SIZE/2, 
                SLOT_SIZE/2
            )
            
            -- Draw item count
            if slot.count > 1 then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(slot.count, slot.x + SLOT_SIZE - 20, slot.y + SLOT_SIZE - 20)
            end
            
            -- item name
            love.graphics.setColor(1, 1, 1, 1)
            if (slot.item.type == "upgrade") then
                love.graphics.print(slot.item.type.."\n"..slot.item.properties.type, slot.x + 5, slot.y + 5)
            else
                love.graphics.print(slot.item.type, slot.x + 5, slot.y + 5)
            end
        end
    end
    
    -- item details if an item is selected
    local selectedItem = self.slots[self.selectedSlot].item
    if selectedItem then
        love.graphics.setColor(0.3, 0.3, 0.35, 1)
        love.graphics.rectangle("fill", self.x + 50, self.y + self.height - 100, self.width - 100, 80, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Selected: " .. selectedItem.type, self.x + 60, self.y + self.height - 90)
        
        -- Display item description
        local description = self:getItemDescription(selectedItem.type)
        love.graphics.print(description, self.x + 60, self.y + self.height - 70)
        

        if self:isItemUsable(selectedItem.type) then
            love.graphics.setColor(0.2, 0.6, 0.2, 1)
            love.graphics.rectangle("fill", self.x + self.width - 150, self.y + self.height - 50, 100, 30, 5, 5)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("Use [E]", self.x + self.width - 140, self.y + self.height - 45)
        end
    end
end


function TabInventory:keypressed(key)
    if not self.visible then return end
    
    if key == "up" then
        self.selectedSlot = self.selectedSlot - COLS
        if self.selectedSlot < 1 then
            self.selectedSlot = self.selectedSlot + (ROWS * COLS)
        end
    elseif key == "down" then
        self.selectedSlot = self.selectedSlot + COLS
        if self.selectedSlot > INVENTORY_SLOTS then
            self.selectedSlot = self.selectedSlot - (ROWS * COLS)
        end
    elseif key == "left" then
        self.selectedSlot = self.selectedSlot - 1
        if self.selectedSlot % COLS == 0 then
            self.selectedSlot = self.selectedSlot + COLS
        end
    elseif key == "right" then
        self.selectedSlot = self.selectedSlot + 1
        if self.selectedSlot % COLS == 1 then
            self.selectedSlot = self.selectedSlot - COLS
        end
    elseif key == "e" then
        self:useSelectedItem()
    end
end

-- Use the selected item if possible
function TabInventory:useSelectedItem()
    local slot = self.slots[self.selectedSlot]
    if not slot.item then return end
    
    if slot.item.type == "fuel" then
        -- Refill player's fuel
        local amountNeeded = self.player.maxFuel - self.player.fuel
        local amountToUse = math.floor(math.min(slot.count, amountNeeded))
        
        if amountToUse > 0 then
            self.player.fuel = self.player.fuel + amountToUse
            self:removeItem("fuel", amountToUse)
        end
    elseif slot.item.type == "upgrade" and slot.item.properties.type then
        print("Applying upgrade", slot.item.properties.type)
        -- Apply upgrade
        local upgradeType = slot.item.properties.type
        
        if upgradeType == "engine" then
            self.player.engineUpgrade = (self.player.engineUpgrade or 0) + 1
        elseif upgradeType == "armor" then
            self.player.armorUpgrade = (self.player.armorUpgrade or 0) + 1
        elseif upgradeType == "fuel" then
            self.player.fuelUpgrade = (self.player.fuelUpgrade or 0) + 1
        elseif upgradeType == "drill" then
            self.player.drillUpgrade = (self.player.drillUpgrade or 0) + 1
        end
        
        self:removeItem("upgrade", 1)
    end
end

-- Check if an item can be used
function TabInventory:isItemUsable(itemType)
    return itemType == "fuel" or itemType == "upgrade"
end

--  Add item descriptions
function TabInventory:getItemDescription(itemType)
    local descriptions = {
        ore = "Raw material mined from planets. Can be sold for goobs.",
        fuel = "Restores your ship's fuel. Press E to use.",
        core = "Valuable material from a planet's core. Worth many goobs.",
        mantel = "Material from a planet's mantel layer.",
        crust = "Common material from a planet's surface.",
        upgrade = "Improves one of your ship's systems. Press E to install."
    }
    
    return descriptions[itemType] or "No description available."
end


function TabInventory:update(dt)
    if not self.visible then return end
    self:updateItemAmounts()
    
    -- update invetory position
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
    
    -- Update slot positions
    local startX = self.x + 50
    local startY = self.y + 120
    
    for i = 1, INVENTORY_SLOTS do
        local row = math.floor((i-1) / COLS)
        local col = (i-1) % COLS
        
        self.slots[i].x = startX + col * (SLOT_SIZE + PADDING)
        self.slots[i].y = startY + row * (SLOT_SIZE + PADDING)
    end
end

function TabInventory:updateItemAmounts()
    -- First, clear all slot counts to zero
    for i, slot in ipairs(self.slots) do
        if slot.item then
            slot.count = 0
        end
    end
    
    -- Then update counts based on player.inventory
    for itemType, count in pairs(self.player.inventory) do
        -- First try to add to existing stacks
        for i, slot in ipairs(self.slots) do
            if slot.item and slot.item.type == itemType then
                slot.count = count
                break
            end
        end
    end
end

-- Mouse click handling
function TabInventory:mousepressed(x, y, button)
    if not self.visible then return end
    
    -- Check if clicked on a slot
    for i, slot in ipairs(self.slots) do
        if x >= slot.x and x <= slot.x + SLOT_SIZE and 
           y >= slot.y and y <= slot.y + SLOT_SIZE then
            self.selectedSlot = i
            
            -- Double click to use item
            if button == 1 and love.timer.getTime() - (self.lastClickTime or 0) < 0.3 then
                self:useSelectedItem()
            end
            self.lastClickTime = love.timer.getTime()
            break
        end
    end
    
    -- Check if clicked on the use button
    local selectedItem = self.slots[self.selectedSlot].item
    if selectedItem and self:isItemUsable(selectedItem.type) then
        if x >= self.x + self.width - 150 and x <= self.x + self.width - 50 and
           y >= self.y + self.height - 50 and y <= self.y + self.height - 20 then
            self:useSelectedItem()
        end
    end
end

-- Can put any item we want below for inventory tests
function TabInventory:addSampleItems()
    self:addItem("ore", 10)
    self:addItem("fuel", 5)
    self:addItem("core", 2)
    self:addItem("mantel", 8)
    self:addItem("crust", 15)
    self:addItem("upgrade", 1, {type = "engine"})
    self:addItem("upgrade", 1, {type = "drill"})
    print("Sample items added to inventory")
end

return TabInventory