
local shipGFX = {}
shipGFX.__index = shipGFX
setmetatable(shipGFX, {__index = require("entity")})

function load shipGFX