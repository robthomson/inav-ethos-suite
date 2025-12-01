--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local activateWakeup = false

local apidata = {
    api = {[1] = 'PID'},
    formdata = {
        labels = {},
        rows = {
            "@i18n(app.modules.pids.roll)@",
            "@i18n(app.modules.pids.pitch)@",
            "@i18n(app.modules.pids.yaw)@"
        },
        cols = {
            "@i18n(app.modules.pids.p)@",
            "@i18n(app.modules.pids.i)@",
            "@i18n(app.modules.pids.d)@",
            "@i18n(app.modules.pids.f)@",
        },
        fields = {
            -- Roll (row 1)
            {row = 1, col = 1, mspapi = 1, apikey = "pid_0_P"},
            {row = 1, col = 2, mspapi = 1, apikey = "pid_0_I"},
            {row = 1, col = 3, mspapi = 1, apikey = "pid_0_D"},
            {row = 1, col = 4, mspapi = 1, apikey = "pid_0_FF"},

            
            -- Pitch (row 2)
            {row = 2, col = 1, mspapi = 1, apikey = "pid_1_P"},
            {row = 2, col = 2, mspapi = 1, apikey = "pid_1_I"},
            {row = 2, col = 3, mspapi = 1, apikey = "pid_1_D"},
            {row = 2, col = 4, mspapi = 1, apikey = "pid_1_FF"},
            
            -- Yaw (row 3)
            {row = 3, col = 1, mspapi = 1, apikey = "pid_2_P"},
            {row = 3, col = 2, mspapi = 1, apikey = "pid_2_I"},
            {row = 3, col = 3, mspapi = 1, apikey = "pid_2_D"},
            {row = 3, col = 4, mspapi = 1, apikey = "pid_2_FF"},
        }
    }
}

local function postLoad(self)
    inavsuite.app.triggers.closeProgressLoader = true
    activateWakeup = true
end

local function openPage(idx, title, script)
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages
    inavsuite.app.triggers.isReady = false

    inavsuite.app.Page = assert(loadfile("app/modules/" .. script))()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script
    inavsuite.session.lastPage = script

    inavsuite.app.uiState = inavsuite.app.uiStatus.pages

    local longPage = false

    form.clear()

    inavsuite.app.ui.fieldHeader(title)
    local numCols
    if inavsuite.app.Page.apidata.formdata.cols ~= nil then
        numCols = #inavsuite.app.Page.apidata.formdata.cols
    else
        numCols = 6
    end
    local screenWidth = inavsuite.app.lcdWidth - 10
    local padding = 10
    local paddingTop = inavsuite.app.radio.linePaddingTop
    local h = inavsuite.app.radio.navbuttonHeight
    local w = ((screenWidth * 70 / 100) / numCols)
    local paddingRight = 20
    local positions = {}
    local positions_r = {}
    local pos

    local line = form.addLine("")

    local loc = numCols
    local posX = screenWidth - paddingRight
    local posY = paddingTop

    local c = 1
    while loc > 0 do
        local colLabel = inavsuite.app.Page.apidata.formdata.cols[loc]
        pos = {x = posX, y = posY, w = w, h = h}
        form.addStaticText(line, pos, colLabel)
        positions[loc] = posX - w + paddingRight
        positions_r[c] = posX - w + paddingRight
        posX = math.floor(posX - w)
        loc = loc - 1
        c = c + 1
    end

    local pidRows = {}
    for ri, rv in ipairs(inavsuite.app.Page.apidata.formdata.rows) do pidRows[ri] = form.addLine(rv) end

    for i = 1, #inavsuite.app.Page.apidata.formdata.fields do
        local f = inavsuite.app.Page.apidata.formdata.fields[i]
        local l = inavsuite.app.Page.apidata.formdata.labels
        local pageIdx = i
        local currentField = i

        posX = positions[f.col]

        pos = {x = posX + padding, y = posY, w = w - padding, h = h}

        inavsuite.app.formFields[i] = form.addNumberField(pidRows[f.row], pos, 0, 0, function()
            if inavsuite.app.Page.apidata.formdata.fields == nil or inavsuite.app.Page.apidata.formdata.fields[i] == nil then
                ui.disableAllFields()
                ui.disableAllNavigationFields()
                ui.enableNavigationField('menu')
                return nil
            end
            return inavsuite.app.utils.getFieldValue(inavsuite.app.Page.apidata.formdata.fields[i])
        end, function(value)
            if f.postEdit then f.postEdit(inavsuite.app.Page) end
            if f.onChange then f.onChange(inavsuite.app.Page) end

            f.value = inavsuite.app.utils.saveFieldValue(inavsuite.app.Page.apidata.formdata.fields[i], value)
        end)
    end

end

local function wakeup() if activateWakeup == true and inavsuite.tasks.msp.mspQueue:isProcessed() then if inavsuite.session.activeProfile ~= nil then inavsuite.app.formFields['title']:value(inavsuite.app.Page.title .. " #" .. inavsuite.session.activeProfile) end end end

return {apidata = apidata, title = "@i18n(app.modules.pids.name)@", reboot = false, eepromWrite = true, refreshOnProfileChange = true, postLoad = postLoad, openPage = openPage, wakeup = wakeup, API = {}}
