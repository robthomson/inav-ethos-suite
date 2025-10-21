--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")
local themesBasePath = "SCRIPTS:/" .. inavadmin.config.baseDir .. "/widgets/dashboard/themes/"
local themesUserPath = "SCRIPTS:/" .. inavadmin.config.preferences .. "/dashboard/"

local enableWakeup = false
local prevConnectedState = nil

local function openPage(pidx, title, script)

    local themeList = inavadmin.widgets.dashboard.listThemes()

    inavadmin.app.dashboardEditingTheme = nil
    enableWakeup = true
    inavadmin.app.triggers.closeProgressLoader = true
    form.clear()

    for i in pairs(inavadmin.app.gfx_buttons) do if i ~= "settings_dashboard_themes" then inavadmin.app.gfx_buttons[i] = nil end end

    inavadmin.app.lastIdx = pageIdx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_settings)@")

    local buttonW, buttonH, padding, numPerRow
    if inavadmin.preferences.general.iconsize == 0 then
        padding = inavadmin.app.radio.buttonPaddingSmall
        buttonW = (inavadmin.app.lcdWidth - padding) / inavadmin.app.radio.buttonsPerRow - padding
        buttonH = inavadmin.app.radio.navbuttonHeight
        numPerRow = inavadmin.app.radio.buttonsPerRow
    elseif inavadmin.preferences.general.iconsize == 1 then
        padding = inavadmin.app.radio.buttonPaddingSmall
        buttonW = inavadmin.app.radio.buttonWidthSmall
        buttonH = inavadmin.app.radio.buttonHeightSmall
        numPerRow = inavadmin.app.radio.buttonsPerRowSmall
    else
        padding = inavadmin.app.radio.buttonPadding
        buttonW = inavadmin.app.radio.buttonWidth
        buttonH = inavadmin.app.radio.buttonHeight
        numPerRow = inavadmin.app.radio.buttonsPerRow
    end

    if inavadmin.app.gfx_buttons["settings_dashboard_themes"] == nil then inavadmin.app.gfx_buttons["settings_dashboard_themes"] = {} end
    if inavadmin.preferences.menulastselected["settings_dashboard_themes"] == nil then inavadmin.preferences.menulastselected["settings_dashboard_themes"] = 1 end

    local lc, bx, y = 0, 0, 0

    local n = 0

    for idx, theme in ipairs(themeList) do

        if theme.configure then

            if lc == 0 then
                if inavadmin.preferences.general.iconsize == 0 then y = form.height() + inavadmin.app.radio.buttonPaddingSmall end
                if inavadmin.preferences.general.iconsize == 1 then y = form.height() + inavadmin.app.radio.buttonPaddingSmall end
                if inavadmin.preferences.general.iconsize == 2 then y = form.height() + inavadmin.app.radio.buttonPadding end
            end
            if lc >= 0 then bx = (buttonW + padding) * lc end

            if inavadmin.app.gfx_buttons["settings_dashboard_themes"][idx] == nil then

                local icon
                if theme.source == "system" then
                    icon = themesBasePath .. theme.folder .. "/icon.png"
                else
                    icon = themesUserPath .. theme.folder .. "/icon.png"
                end
                inavadmin.app.gfx_buttons["settings_dashboard_themes"][idx] = lcd.loadMask(icon)
            end

            inavadmin.app.formFields[idx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = theme.name,
                icon = inavadmin.app.gfx_buttons["settings_dashboard_themes"][idx],
                options = FONT_S,
                paint = function() end,
                press = function()

                    inavadmin.preferences.menulastselected["settings_dashboard_themes"] = idx
                    inavadmin.app.ui.progressDisplay(nil, nil, true)
                    local configure = theme.configure
                    local source = theme.source
                    local folder = theme.folder

                    local themeScript
                    if theme.source == "system" then
                        themeScript = themesBasePath .. folder .. "/" .. configure
                    else
                        themeScript = themesUserPath .. folder .. "/" .. configure
                    end

                    local wrapperScript = "settings/tools/dashboard_settings_theme.lua"

                    inavadmin.app.ui.openPage(idx, theme.name, wrapperScript, source, folder, themeScript)
                end
            })

            if not theme.configure then inavadmin.app.formFields[idx]:enable(false) end

            if inavadmin.preferences.menulastselected["settings_dashboard_themes"] == idx then inavadmin.app.formFields[idx]:focus() end

            lc = lc + 1
            n = lc + 1
            if lc == numPerRow then lc = 0 end
        end
    end

    if n == 0 then
        local w, h = lcd.getWindowSize()
        local msg = "@i18n(app.modules.settings.no_themes_available_to_configure)@"
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        local btnH = inavadmin.app.radio.navbuttonHeight
        form.addStaticText(nil, {x = x, y = y, w = tw, h = btnH}, msg)
    end

    inavadmin.app.triggers.closeProgressLoader = true

    enableWakeup = true
    return
end

inavadmin.app.uiState = inavadmin.app.uiStatus.pages

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
        return true
    end
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
    return true
end

local function wakeup()
    if not enableWakeup then return end

    local currState = (inavadmin.session.isConnected and inavadmin.session.mcu_id) and true or false

    if currState ~= prevConnectedState then

        if currState == false then onNavMenu() end

        prevConnectedState = currState
    end
end

return {pages = pages, openPage = openPage, API = {}, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}, event = event, onNavMenu = onNavMenu, wakeup = wakeup}
