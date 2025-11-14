--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local config = {}
local enableWakeup = false

local function sensorNameMap(sensorList)
    local nameMap = {}
    for _, sensor in ipairs(sensorList) do nameMap[sensor.key] = sensor.name end
    return nameMap
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    if not inavadmin.app.navButtons then inavadmin.app.navButtons = {} end
    inavadmin.app.triggers.closeProgressLoader = true
    form.clear()

    inavadmin.app.lastIdx = pageIdx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.audio)@" .. " / " .. "@i18n(app.modules.settings.txt_audio_switches)@")
    inavadmin.app.formLineCnt = 0

    local formFieldCount = 0

    local function sortSensorListByName(sensorList)
        table.sort(sensorList, function(a, b) return a.name:lower() < b.name:lower() end)
        return sensorList
    end

    local sensorList = sortSensorListByName(inavadmin.tasks.telemetry.listSwitchSensors())

    local saved = inavadmin.preferences.switches or {}
    for k, v in pairs(saved) do config[k] = v end

    for i, v in ipairs(sensorList) do
        formFieldCount = formFieldCount + 1
        inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
        inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine(v.name or "unknown")

        inavadmin.app.formFields[formFieldCount] = form.addSwitchField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function()
            local value = config[v.key]
            if value then
                local scategory, smember = value:match("([^,]+),([^,]+)")
                if scategory and smember then
                    local source = system.getSource({category = tonumber(scategory), member = tonumber(smember)})
                    return source
                end
            end
            return nil
        end, function(newValue)
            if newValue then
                local cat_member = newValue:category() .. "," .. newValue:member()
                config[v.key] = cat_member
            else
                config[v.key] = nil
            end
        end)
    end

    for i, field in ipairs(inavadmin.app.formFields) do if field and field.enable then field:enable(true) end end
    inavadmin.app.navButtons.save = true
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/tools/audio.lua")
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavadmin.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do inavadmin.preferences.switches[key] = value end
                inavadmin.ini.save_ini_file("SCRIPTS:/" .. inavadmin.config.preferences .. "/preferences.ini", inavadmin.preferences)
                inavadmin.tasks.events.switches.resetSwitchStates()
                inavadmin.app.triggers.closeSave = true
                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/tools/audio.lua")
        return true
    end
end

return {event = event, openPage = openPage, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
