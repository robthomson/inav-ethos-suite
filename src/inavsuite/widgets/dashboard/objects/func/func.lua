--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local render = {}

local utils = inavsuite.widgets.dashboard.utils

function render.dirty(box) return true end

function render.wakeup(box)

    local telemetry = inavsuite.tasks.telemetry

    if type(box.wakeup) == "function" then
        box._cache = box.wakeup(box, telemetry)
    else
        box._cache = nil
    end
end

function render.paint(x, y, w, h, box, telemetry)
    x, y = utils.applyOffset(x, y, box)
    local v = box.paint
    if type(v) == "function" then v(x, y, w, h, box, box._cache, telemetry) end
end

return render
