--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local settings = {}
local settings_model = {}

local themeList = inavadmin.widgets.dashboard.listThemes()
local formattedThemes = {}
local formattedThemesModel = {}

local enableWakeup = false
local prevConnectedState = nil

local function generateThemeList()

    settings = inavadmin.preferences.dashboard

    if inavadmin.session.modelPreferences then
        settings_model = inavadmin.session.modelPreferences.dashboard
    else
        settings_model = {}
    end

    for i, theme in ipairs(themeList) do table.insert(formattedThemes, {theme.name, theme.idx}) end

    table.insert(formattedThemesModel, {"@i18n(app.modules.settings.dashboard_theme_panel_model_disabled)@", 0})
    for i, theme in ipairs(themeList) do table.insert(formattedThemesModel, {theme.name, theme.idx}) end
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    inavadmin.app.triggers.closeProgressLoader = true
    form.clear()

    inavadmin.app.lastIdx = pageIdx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_theme)@")
    inavadmin.app.formLineCnt = 0

    local formFieldCount = 0

    generateThemeList()

    local global_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_global)@")
    global_panel:open(true)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")

    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, formattedThemes, function()
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local folderName = settings.theme_preflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_preflight = theme.source .. "/" .. theme.folder end
        end
    end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")

    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, formattedThemes, function()
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local folderName = settings.theme_inflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_inflight = theme.source .. "/" .. theme.folder end
        end
    end)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = global_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")

    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, formattedThemes, function()
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local folderName = settings.theme_postflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then settings.theme_postflight = theme.source .. "/" .. theme.folder end
        end
    end)

    local model_panel = form.addExpansionPanel("@i18n(app.modules.settings.dashboard_theme_panel_model)@")
    model_panel:open(false)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_preflight)@")

    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, formattedThemesModel, function()
        if inavadmin.session.modelPreferences and inavadmin.session.modelPreferences then
            local folderName = settings_model.theme_preflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavadmin.session.modelPreferences and inavadmin.session.modelPreferences then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_preflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_preflight = "nil"
            end
        end
    end)
    inavadmin.app.formFields[formFieldCount]:enable(false)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_inflight)@")

    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, formattedThemesModel, function()
        if inavadmin.session.modelPreferences and inavadmin.session.modelPreferences then
            local folderName = settings_model.theme_inflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavadmin.session.modelPreferences and inavadmin.session.modelPreferences then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_inflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_inflight = "nil"
            end
        end
    end)
    inavadmin.app.formFields[formFieldCount]:enable(false)

    formFieldCount = formFieldCount + 1
    inavadmin.app.formLineCnt = inavadmin.app.formLineCnt + 1
    inavadmin.app.formLines[inavadmin.app.formLineCnt] = model_panel:addLine("@i18n(app.modules.settings.dashboard_theme_postflight)@")

    inavadmin.app.formFields[formFieldCount] = form.addChoiceField(inavadmin.app.formLines[inavadmin.app.formLineCnt], nil, formattedThemesModel, function()
        if inavadmin.session.modelPreferences and inavadmin.session.modelPreferences then
            local folderName = settings_model.theme_postflight
            for _, theme in ipairs(themeList) do if (theme.source .. "/" .. theme.folder) == folderName then return theme.idx end end
        end
        return nil
    end, function(newValue)
        if inavadmin.preferences and inavadmin.preferences.dashboard then
            local theme = themeList[newValue]
            if theme then
                settings_model.theme_postflight = theme.source .. "/" .. theme.folder
            else
                settings_model.theme_postflight = "nil"
            end
        end
    end)
    inavadmin.app.formFields[formFieldCount]:enable(false)

end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
    return true
end

local function onSaveMenu()
    local buttons = {
        {
            label = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavadmin.app.ui.progressDisplaySave(msg:gsub("%?$", "."))

                for key, value in pairs(settings) do inavadmin.preferences.dashboard[key] = value end
                inavadmin.ini.save_ini_file("SCRIPTS:/" .. inavadmin.config.preferences .. "/preferences.ini", inavadmin.preferences)

                if inavadmin.session.isConnected and inavadmin.session.mcu_id and inavadmin.session.modelPreferencesFile then
                    for key, value in pairs(settings_model) do inavadmin.session.modelPreferences.dashboard[key] = value end
                    inavadmin.ini.save_ini_file(inavadmin.session.modelPreferencesFile, inavadmin.session.modelPreferences)
                end

                inavadmin.widgets.dashboard.reload_themes(true)

                inavadmin.app.triggers.closeSave = true
                return true
            end
        }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
    }

    form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
        return true
    end
end

local function wakeup()
    if not enableWakeup then return end

    local currState = (inavadmin.session.isConnected and inavadmin.session.mcu_id) and true or false

    if currState ~= prevConnectedState then

        if currState then
            generateThemeList()
            for i = 4, 6 do inavadmin.app.formFields[i]:values(formattedThemesModel) end
        end

        for i = 4, 6 do inavadmin.app.formFields[i]:enable(currState) end

        prevConnectedState = currState
    end
end

return {event = event, openPage = openPage, wakeup = wakeup, onNavMenu = onNavMenu, onSaveMenu = onSaveMenu, navButtons = {menu = true, save = true, reload = false, tool = false, help = false}, API = {}}
