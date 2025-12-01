--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local settings = {}
local settings_model = {}

local themeList = inavsuite.widgets.dashboard.listThemes()
local formattedThemes = {}
local formattedThemesModel = {}

local enableWakeup = false
local prevConnectedState = nil

local function generateThemeList()

    settings = inavsuite.preferences.dashboard

    if inavsuite.session.modelPreferences then
        settings_model = inavsuite.session.modelPreferences.dashboard
    else
        settings_model = {}
    end

    for i, theme in ipairs(themeList) do table.insert(formattedThemes, {theme.name, theme.idx}) end

    table.insert(formattedThemesModel, {"@i18n(app.modules.settings.dashboard_theme_panel_model_disabled)@", 0})
    for i, theme in ipairs(themeList) do table.insert(formattedThemesModel, {theme.name, theme.idx}) end
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    inavsuite.app.triggers.closeProgressLoader = true
    form.clear()

    inavsuite.app.lastIdx = pageIdx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    inavsuite.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_theme)@")
    inavsuite.app.formLineCnt = 0

    local formFieldCount = 0

    generateThemeList()

    local global_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_global)@")
    global_panel:open(true)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")

    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, formattedThemes, function()
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local folderName = settings.theme_preflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_preflight = theme.source .. "/" .. theme.folder end
        end
    end)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")

    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, formattedThemes, function()
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local folderName = settings.theme_inflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_inflight = theme.source .. "/" .. theme.folder end
        end
    end)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")

    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, formattedThemes, function()
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local folderName = settings.theme_postflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_postflight = theme.source .. "/" .. theme.folder end
        end
    end)

    local model_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_model)@")
    model_panel:open(false)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")

    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, formattedThemesModel, function()
        if inavsuite.session.modelPreferences and inavsuite.session.modelPreferences then
            local folderName = settings_model.theme_preflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavsuite.session.modelPreferences and inavsuite.session.modelPreferences then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_preflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_preflight = "nil"
            end
        end
    end)
    inavsuite.app.formFields[formFieldCount]:enable(false)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")

    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, formattedThemesModel, function()
        if inavsuite.session.modelPreferences and inavsuite.session.modelPreferences then
            local folderName = settings_model.theme_inflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavsuite.session.modelPreferences and inavsuite.session.modelPreferences then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_inflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_inflight = "nil"
            end
        end
    end)
    inavsuite.app.formFields[formFieldCount]:enable(false)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")

    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, formattedThemesModel, function()
        if inavsuite.session.modelPreferences and inavsuite.session.modelPreferences then
            local folderName = settings_model.theme_postflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavsuite.preferences and inavsuite.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_postflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_postflight = "nil"
            end
        end
    end)
    inavsuite.app.formFields[formFieldCount]:enable(false)

end

local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil, nil, true)
    inavsuite.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
    return true
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))

                for key, value in pairs(settings) do inavsuite.preferences.dashboard[key] = value end
                inavsuite.ini.save_ini_file("SCRIPTS:/" .. inavsuite.config.preferences .. "/preferences.ini", inavsuite.preferences)

                if inavsuite.session.isConnected and inavsuite.session.mcu_id and inavsuite.session.modelPreferencesFile then
                    for key, value in pairs(settings_model) do inavsuite.session.modelPreferences.dashboard[key] = value end
                    inavsuite.ini.save_ini_file(inavsuite.session.modelPreferencesFile, inavsuite.session.modelPreferences)
                end

                inavsuite.widgets.dashboard.reload_themes(true)

                inavsuite.app.triggers.closeSave = true
                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
        return true
    end
end

local function wakeup()
    if not enableWakeup then return end

    local currState = (inavsuite.session.isConnected and inavsuite.session.mcu_id) and true or false

    if currState ~= prevConnectedState then

        if currState then
            generateThemeList()
            for i = 4, 6 do inavsuite.app.formFields[i]:values(formattedThemesModel) end
        end

        for i = 4, 6 do inavsuite.app.formFields[i]:enable(currState) end

        prevConnectedState = currState
    end
end

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
