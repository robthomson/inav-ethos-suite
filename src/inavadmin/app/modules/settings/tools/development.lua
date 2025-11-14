--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")
local settings = {}
local enableWakeup = false

local function openPage(pageIdx, title, script)
    enableWakeup = true
    inavadmin.app.triggers.closeProgressLoader = true
    form.clear()

    inavadmin.app.lastIdx = pageIdx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.txt_development)@")
    inavadmin.app.formLineCnt = 0

    local formFieldCount = 0

    settings = inavadmin.preferences.developer

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.txt_devtools)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['devtools'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.devtools = newValue end end)

    if system.getVersion().simulation then
        formFieldCount = formFieldCount + 1
        inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
        inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.txt_apiversion)@")
        inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, inavadmin.utils.msp_version_array_to_indexed(), function() return settings.apiversion end, function(newValue) settings.apiversion = newValue end)
    end

    local logpanel = form.addExpansionPanel("@i18n(app.modules.settings.txt_logging)@")
    logpanel:open(false)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_loglocation)@")
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, {{"@i18n(app.modules.settings.txt_console)@", 0}, {"@i18n(app.modules.settings.txt_consolefile)@", 1}}, function()
        if inavadmin.preferences and inavadmin.preferences.developer then
            if inavadmin.preferences.developer.logtofile == false then
                return 0
            else
                return 1
            end
        end
    end, function(newValue)
        if inavadmin.preferences and inavadmin.preferences.developer then
            local value
            if newValue == 0 then
                value = false
            else
                value = true
            end
            settings.logtofile = value
        end
    end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_loglevel)@")
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, {{"@i18n(app.modules.settings.txt_off)@", 0}, {"@i18n(app.modules.settings.txt_info)@", 1}, {"@i18n(app.modules.settings.txt_debug)@", 2}}, function()
        if inavadmin.preferences and inavadmin.preferences.developer then
            if settings['loglevel'] == "off" then
                return 0
            elseif settings['loglevel'] == "info" then
                return 1
            else
                return 2
            end
        end
    end, function(newValue)
        if inavadmin.preferences and inavadmin.preferences.developer then
            local value
            if newValue == 0 then
                value = "off"
            elseif newValue == 1 then
                value = "info"
            else
                value = "debug"
            end
            settings['loglevel'] = value
        end
    end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_mspdata)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['logmsp'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.logmsp = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_queuesize)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['logmspQueue'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.logmspQueue = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_memusage)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['memstats'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.memstats = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_taskprofiler)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['taskprofiler'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.taskprofiler = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_objectprofiler)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['logobjprof'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.logobjprof = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_overlaygrid)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['overlaygrid'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.overlaygrid = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_overlaystats)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['overlaystats'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.overlaystats = newValue end end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = logpanel:addLine("@i18n(app.modules.settings.txt_overlaystatsadmin)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() if inavadmin.preferences and inavadmin.preferences.developer then return settings['overlaystatsadmin'] end end, function(newValue) if inavadmin.preferences and inavadmin.preferences.developer then settings.overlaystatsadmin = newValue end end)

end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavadmin.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do inavadmin.preferences.developer[key] = value end
                inavadmin.ini.save_ini_file("SCRIPTS:/" .. inavadmin.config.preferences .. "/preferences.ini", inavadmin.preferences)

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

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
