--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local version = inavadmin.version().version
local ethosVersion = inavadmin.config.environment.major .. "." .. inavadmin.config.environment.minor .. "." .. inavadmin.config.environment.revision
local apiVersion = inavadmin.session.apiVersion
local fcVersion = inavadmin.session.fcVersion
local rfVersion = inavadmin.session.rfVersion
local mspTransport = (inavadmin.tasks and inavadmin.tasks.msp and inavadmin.tasks.msp.protocol and inavadmin.tasks.msp.protocol.mspProtocol) or "-"
local closeProgressLoader = true
local simulation

local supportedMspVersion = ""
for i, v in ipairs(inavadmin.config.supportedMspApiVersion) do
    if i == 1 then
        supportedMspVersion = v
    else
        supportedMspVersion = supportedMspVersion .. "," .. v
    end
end

if system.getVersion().simulation == true then
    simulation = "ON"
else
    simulation = "OFF"
end

local displayType = 0
local disableType = false
local displayPos
local w, h = lcd.getWindowSize()
local buttonW = 100
local buttonWs = buttonW - (buttonW * 20) / 100
local x = w - 15

displayPos = {x = x - buttonW - buttonWs - 5 - buttonWs, y = inavadmin.app.radio.linePaddingTop, w = 300, h = inavadmin.app.radio.navbuttonHeight}

local apidata = {
    api = {[1] = nil},
    formdata = {
        labels = {},
        fields = {
            {t = "@i18n(app.modules.info.version)@", value = version, type = displayType, disable = disableType, position = displayPos}, {t = "@i18n(app.modules.info.ethos_version)@", value = ethosVersion, type = displayType, disable = disableType, position = displayPos}, {t = "@i18n(app.modules.info.rf_version)@", value = rfVersion, type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.info.fc_version)@", value = fcVersion, type = displayType, disable = disableType, position = displayPos}, {t = "@i18n(app.modules.info.msp_version)@", value = apiVersion, type = displayType, disable = disableType, position = displayPos}, {t = "@i18n(app.modules.info.msp_transport)@", value = string.upper(mspTransport), type = displayType, disable = disableType, position = displayPos},
            {t = "@i18n(app.modules.info.supported_versions)@", value = supportedMspVersion, type = displayType, disable = disableType, position = displayPos}, {t = "@i18n(app.modules.info.simulation)@", value = simulation, type = displayType, disable = disableType, position = displayPos}
        }
    }
}

local function wakeup()
    if closeProgressLoader == false then
        inavadmin.app.triggers.closeProgressLoader = true
        closeProgressLoader = true
    end
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.diagnostics.name)@", "diagnostics/diagnostics.lua")
        return true
    end
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.diagnostics.name)@", "diagnostics/diagnostics.lua")
end

return {apidata = apidata, reboot = false, eepromWrite = false, minBytes = 0, wakeup = wakeup, refreshswitch = false, simulatorResponse = {}, onNavMenu = onNavMenu, event = event, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}, API = {}}
