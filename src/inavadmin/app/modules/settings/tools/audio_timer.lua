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

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.audio)@" .. " / " .. "@i18n(app.modules.settings.txt_audio_timer)@")

    inavadmin.app.formLineCnt = 0
    local formFieldCount = 0

    local saved = inavadmin.preferences.timer or {}
    for k, v in pairs(saved) do config[k] = v end

    local intervalChoices = {{"10s", 10}, {"15s", 15}, {"30s", 30}}
    local periodChoices = {{"30s", 30}, {"60s", 60}, {"90s", 90}}

    local idxAudio, idxChoice, idxPre, idxPrePeriod, idxPreInterval, idxPost, idxPostPeriod, idxPostInterval

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.timer_alerting)@")
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, function() return config.timeraudioenable or false end, function(newValue)
        config.timeraudioenable = newValue
        inavadmin.app.formFields[idxChoice]:enable(newValue)
        inavadmin.app.formFields[idxPre]:enable(newValue)
        inavadmin.app.formFields[idxPost]:enable(newValue)
        inavadmin.app.formFields[idxPrePeriod]:enable(newValue and (config.prealerton or false))
        inavadmin.app.formFields[idxPreInterval]:enable(newValue and (config.prealerton or false))
        inavadmin.app.formFields[idxPostPeriod]:enable(newValue and (config.postalerton or false))
        inavadmin.app.formFields[idxPostInterval]:enable(newValue and (config.postalerton or false))
    end)
    idxAudio = formFieldCount

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.timer_elapsed_alert_mode)@")
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, {{"Beep", 0}, {"Multi Beep", 1}, {"Timer Elapsed", 2}, {"Timer Seconds", 3}}, function() return config.elapsedalertmode or 0 end, function(newValue) config.elapsedalertmode = newValue end)
    idxChoice = formFieldCount

    local prePanel = form.addExpansionPanel("@i18n(app.modules.settings.timer_prealert_options)@")
    prePanel:open(config.prealerton or false)

    formFieldCount = formFieldCount + 1
    idxPre = formFieldCount
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(prePanel:addLine("@i18n(app.modules.settings.timer_prealert)@"), nil, function() return config.prealerton or false end, function(newValue)
        config.prealerton = newValue
        local audioEnabled = config.timeraudioenable or false
        inavadmin.app.formFields[idxPrePeriod]:enable(audioEnabled and newValue)
        inavadmin.app.formFields[idxPreInterval]:enable(audioEnabled and newValue)
    end)

    formFieldCount = formFieldCount + 1
    idxPrePeriod = formFieldCount
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(prePanel:addLine("@i18n(app.modules.settings.timer_alert_period)@"), nil, periodChoices, function() return config.prealertperiod or 30 end, function(newValue) config.prealertperiod = newValue end)
    inavadmin.app.formFields[formFieldCount]:enable((config.timeraudioenable or false) and (config.prealerton or false))

    formFieldCount = formFieldCount + 1
    idxPreInterval = formFieldCount
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(prePanel:addLine("Alert Interval"), nil, intervalChoices, function() return config.prealertinterval or 10 end, function(newValue) config.prealertinterval = newValue end)
    inavadmin.app.formFields[formFieldCount]:enable((config.timeraudioenable or false) and (config.prealerton or false))

    local postPanel = form.addExpansionPanel("@i18n(app.modules.settings.timer_postalert_options)@")
    postPanel:open(config.postalerton or false)

    formFieldCount = formFieldCount + 1
    idxPost = formFieldCount
    inavadmin.app.formFields[formFieldCount] = form.addBooleanField(postPanel:addLine("@i18n(app.modules.settings.timer_postalert)@"), nil, function() return config.postalerton or false end, function(newValue)
        config.postalerton = newValue
        local audioEnabled = config.timeraudioenable or false
        inavadmin.app.formFields[idxPostPeriod]:enable(audioEnabled and newValue)
        inavadmin.app.formFields[idxPostInterval]:enable(audioEnabled and newValue)
    end)

    formFieldCount = formFieldCount + 1
    idxPostPeriod = formFieldCount
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(postPanel:addLine("@i18n(app.modules.settings.timer_alert_period)@"), nil, periodChoices, function() return config.postalertperiod or 60 end, function(newValue) config.postalertperiod = newValue end)
    inavadmin.app.formFields[formFieldCount]:enable((config.timeraudioenable or false) and (config.postalerton or false))

    formFieldCount = formFieldCount + 1
    idxPostInterval = formFieldCount
    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(postPanel:addLine("@i18n(app.modules.settings.timer_postalert_interval)@"), nil, intervalChoices, function() return config.postalertinterval or 10 end, function(newValue) config.postalertinterval = newValue end)
    inavadmin.app.formFields[formFieldCount]:enable((config.timeraudioenable or false) and (config.postalerton or false))

    inavadmin.app.formFields[idxChoice]:enable(config.timeraudioenable or false)
    inavadmin.app.formFields[idxPre]:enable(config.timeraudioenable or false)
    inavadmin.app.formFields[idxPrePeriod]:enable((config.timeraudioenable or false) and (config.prealerton or false))
    inavadmin.app.formFields[idxPreInterval]:enable((config.timeraudioenable or false) and (config.prealerton or false))
    inavadmin.app.formFields[idxPost]:enable(config.timeraudioenable or false)
    inavadmin.app.formFields[idxPostPeriod]:enable((config.timeraudioenable or false) and (config.postalerton or false))
    inavadmin.app.formFields[idxPostInterval]:enable((config.timeraudioenable or false) and (config.postalerton or false))
    inavadmin.app.navButtons.save = true
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavadmin.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do inavadmin.preferences.timer[key] = value end
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
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/tools/audio.lua")
        return true
    end
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/tools/audio.lua")
end

return {event = event, openPage = openPage, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
