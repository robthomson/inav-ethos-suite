--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")
local enableWakeup = false

local config = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    if not inavadmin.app.navButtons then inavadmin.app.navButtons = {} end
    inavadmin.app.triggers.closeProgressLoader = true
    form.clear()

    inavadmin.app.lastIdx = pageIdx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.localizations)@")
    inavadmin.app.formLineCnt = 0
    local formFieldCount = 0

    local saved = inavadmin.preferences.localizations or {}
    for k, v in pairs(saved) do config[k] = v end

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.temperature_unit)@")
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, {{"@i18n(app.modules.settings.celcius)@", 0}, {"@i18n(app.modules.settings.fahrenheit)@", 1}}, function() return config.temperature_unit or 0 end, function(newValue) config.temperature_unit = newValue end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.altitude_unit)@")
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, {{"@i18n(app.modules.settings.meters)@", 0}, {"@i18n(app.modules.settings.feet)@", 1}}, function() return config.altitude_unit or 0 end, function(newValue) config.altitude_unit = newValue end)

    for i, field in ipairs(inavadmin.app.formFields) do if field and field.enable then field:enable(true) end end
    inavadmin.app.navButtons.save = true
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
    return true
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavadmin.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do inavadmin.preferences.localizations[key] = value end
                inavadmin.ini.save_ini_file("SCRIPTS:/" .. inavadmin.config.preferences .. "/preferences.ini", inavadmin.preferences)

                inavadmin.widgets.dashboard.reload_themes()

                inavadmin.app.triggers.closeSave = true
                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
        return true
    end
end

return {event = event, openPage = openPage, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
