--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local enableWakeup = false
local lastWakeup = 0

local w, h = lcd.getWindowSize()
local btnW = 100
local btnWs = btnW - (btnW * 20) / 100
local xRight = w - 15

local x, y

local displayPos = {x = xRight - btnW - btnWs - 5 - btnWs, y = inavadmin.app.radio.linePaddingTop, w = 150, h = inavadmin.app.radio.navbuttonHeight}

local IDX_CPULOAD = 0
local IDX_FREERAM = 1
local IDX_BG_TASK = 2
local IDX_RF_MODULE = 3
local IDX_MSP = 4
local IDX_TELEM = 5
local IDX_FBLCONNECTED = 6
local IDX_APIVERSION = 7

local function setStatus(field, ok, dashIfNil)
    if not field then return end
    if dashIfNil and ok == nil then
        field:value("-")
        return
    end
    if ok then
        field:value("@i18n(app.modules.rfstatus.ok)@")
        field:color(GREEN)
    else
        field:value("@i18n(app.modules.rfstatus.error)@")
        field:color(RED)
    end
end

local function addStatusLine(captionText, initialText)

    inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine(captionText)
    inavadmin.app.formFields[inavadmin.app.formFieldCount] = form.addStaticText(inavadmin.app.formLines[inavadmin.app.formLineCnt], displayPos, initialText)
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formFieldCount = inavadmin.app.formFieldCount + 1
end

local function moduleEnabled()
    local m0 = model.getModule(0)
    local m1 = model.getModule(1)
    return (m0 and m0:enable()) or (m1 and m1:enable()) or false
end

local function haveMspSensor()
    local sportSensor = system.getSource({appId = 0xF101})
    local elrsSensor = system.getSource({crsfId = 0x14, subIdStart = 0, subIdEnd = 1})
    return sportSensor or elrsSensor
end

local function openPage(pidx, title, script)
    enableWakeup = false
    inavadmin.app.triggers.closeProgressLoader = true
    form.clear()

    inavadmin.app.lastIdx = pidx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.diagnostics.name)@" .. " / " .. "@i18n(app.modules.rfstatus.name)@")

    inavadmin.app.formLineCnt = 0
    inavadmin.app.formFieldCount = 0

    local app = inavadmin.app
    if app.formFields then for i = 1, #app.formFields do app.formFields[i] = nil end end
    if app.formLines then for i = 1, #app.formLines do app.formLines[i] = nil end end

    addStatusLine("@i18n(app.modules.fblstatus.cpu_load)@", string.format("%.1f%%", inavadmin.performance.cpuload or 0))

    addStatusLine("@i18n(app.modules.msp_speed.memory_free)@", string.format("%.1f kB", inavadmin.performance.freeram or 0))

    addStatusLine("@i18n(app.modules.rfstatus.bgtask)@", inavadmin.tasks.active() and "@i18n(app.modules.rfstatus.ok)@" or "@i18n(app.modules.rfstatus.error)@")

    addStatusLine("@i18n(app.modules.rfstatus.rfmodule)@", moduleEnabled() and "@i18n(app.modules.rfstatus.ok)@" or "@i18n(app.modules.rfstatus.error)@")

    addStatusLine("@i18n(app.modules.rfstatus.mspsensor)@", haveMspSensor() and "@i18n(app.modules.rfstatus.ok)@" or "@i18n(app.modules.rfstatus.error)@")

    addStatusLine("@i18n(app.modules.rfstatus.telemetrysensors)@", "-")

    addStatusLine("@i18n(app.modules.rfstatus.fblconnected)@", "-")

    addStatusLine("@i18n(app.modules.rfstatus.apiversion)@", "-")

    enableWakeup = true
end

local function postLoad(self) inavadmin.utils.log("postLoad", "debug") end
local function postRead(self) inavadmin.utils.log("postRead", "debug") end

local function wakeup()
    if not enableWakeup then return end

    local now = os.clock()
    if (now - lastWakeup) < 2 then return end
    lastWakeup = now

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_CPULOAD]
        if field then field:value(string.format("%.1f%%", inavadmin.performance.cpuload or 0)) end
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_FREERAM]
        if field then field:value(string.format("%.1f kB", inavadmin.utils.round(inavadmin.performance.freeram or 0, 1))) end
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_BG_TASK]
        local ok = inavadmin.tasks and inavadmin.tasks.active()
        setStatus(field, ok)
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_RF_MODULE]
        setStatus(field, moduleEnabled())
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_MSP]
        setStatus(field, haveMspSensor())
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_TELEM]
        if field then
            local sensors = inavadmin.tasks and inavadmin.tasks.telemetry and inavadmin.tasks.telemetry.validateSensors(false) or false
            if type(sensors) == "table" then

                setStatus(field, #sensors == 0)
            else

                setStatus(field, nil, true)
            end
        end
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_FBLCONNECTED]
        if field then
            local isConnected = inavadmin.session and inavadmin.session.isConnected
            if isConnected then
                setStatus(field, isConnected)
            else
                setStatus(field, nil, true)
            end
        end
    end

    do
        local field = inavadmin.app.formFields and inavadmin.app.formFields[IDX_APIVERSION]
        if field then
            local isInvalid = not inavadmin.session.apiVersionInvalid
            setStatus(field, isInvalid)
        end
    end

end

local function event(widget, category, value, x, y)

    if (category == EVT_CLOSE and value == 0) or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.diagnostics.name)@", "diagnostics/diagnostics.lua")
        return true
    end
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.diagnostics.name)@", "diagnostics/diagnostics.lua")
end

return {reboot = false, eepromWrite = false, minBytes = 0, wakeup = wakeup, refreshswitch = false, simulatorResponse = {}, postLoad = postLoad, postRead = postRead, openPage = openPage, onNavMenu = onNavMenu, event = event, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}, API = {}}
