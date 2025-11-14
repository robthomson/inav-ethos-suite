--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local arg = {...}
local config = arg[1]

local ini = {}

ini.api = assert(loadfile("tasks/ini/api.lua"))()

function ini.wakeup() end

function ini.reset() end

return ini
