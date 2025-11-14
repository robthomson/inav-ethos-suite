--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local S_PAGES = {{name = "@i18n(app.modules.settings.txt_audio_events)@", script = "audio_events.lua", image = "audio_events.png"}, {name = "@i18n(app.modules.settings.txt_audio_switches)@", script = "audio_switches.lua", image = "audio_switches.png"}, {name = "@i18n(app.modules.settings.txt_audio_timer)@", script = "audio_timer.lua", image = "audio_timer.png"}}

local function openPage(pidx, title, script)

    inavadmin.tasks.msp.protocol.mspIntervalOveride = nil

    inavadmin.app.triggers.isReady = false
    inavadmin.app.uiState = inavadmin.app.uiStatus.mainMenu

    form.clear()

    inavadmin.app.lastIdx = idx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    for i in pairs(inavadmin.app.gfx_buttons) do if i ~= "settings_dashboard_audio" then inavadmin.app.gfx_buttons[i] = nil end end

    if inavadmin.preferences.general.iconsize == nil or inavadmin.preferences.general.iconsize == "" then
        inavadmin.preferences.general.iconsize = 1
    else
        inavadmin.preferences.general.iconsize = tonumber(inavadmin.preferences.general.iconsize)
    end

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavadmin.app.radio.buttonPadding

    local sc
    local panel

    local buttonW = 100
    local x = windowWidth - buttonW - 10

    inavadmin.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.audio)@")

    local buttonW
    local buttonH
    local padding
    local numPerRow

    if inavadmin.preferences.general.iconsize == 0 then
        padding = inavadmin.app.radio.buttonPaddingSmall
        buttonW = (inavadmin.app.lcdWidth - padding) / inavadmin.app.radio.buttonsPerRow - padding
        buttonH = inavadmin.app.radio.navbuttonHeight
        numPerRow = inavadmin.app.radio.buttonsPerRow
    end

    if inavadmin.preferences.general.iconsize == 1 then

        padding = inavadmin.app.radio.buttonPaddingSmall
        buttonW = inavadmin.app.radio.buttonWidthSmall
        buttonH = inavadmin.app.radio.buttonHeightSmall
        numPerRow = inavadmin.app.radio.buttonsPerRowSmall
    end

    if inavadmin.preferences.general.iconsize == 2 then

        padding = inavadmin.app.radio.buttonPadding
        buttonW = inavadmin.app.radio.buttonWidth
        buttonH = inavadmin.app.radio.buttonHeight
        numPerRow = inavadmin.app.radio.buttonsPerRow
    end

    if inavadmin.app.gfx_buttons["settings_dashboard_audio"] == nil then inavadmin.app.gfx_buttons["settings_dashboard_audio"] = {} end
    if inavadmin.preferences.menulastselected["settings_dashboard_audio"] == nil then inavadmin.preferences.menulastselected["settings_dashboard_audio"] = 1 end

    local Menu = assert(loadfile("app/modules/" .. script))()
    local pages = S_PAGES
    local lc = 0
    local bx = 0
    local y = 0

    for pidx, pvalue in ipairs(S_PAGES) do

        if lc == 0 then
            if inavadmin.preferences.general.iconsize == 0 then y = form.height() + inavadmin.app.radio.buttonPaddingSmall end
            if inavadmin.preferences.general.iconsize == 1 then y = form.height() + inavadmin.app.radio.buttonPaddingSmall end
            if inavadmin.preferences.general.iconsize == 2 then y = form.height() + inavadmin.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if inavadmin.preferences.general.iconsize ~= 0 then
            if inavadmin.app.gfx_buttons["settings_dashboard_audio"][pidx] == nil then inavadmin.app.gfx_buttons["settings_dashboard_audio"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            inavadmin.app.gfx_buttons["settings_dashboard_audio"][pidx] = nil
        end

        inavadmin.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = inavadmin.app.gfx_buttons["settings_dashboard_audio"][pidx],
            options = FONT_S,
            paint = function() end,
            press = function()
                inavadmin.preferences.menulastselected["settings_dashboard_audio"] = pidx
                inavadmin.app.ui.progressDisplay(nil, nil, true)
                inavadmin.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then inavadmin.app.formFields[pidx]:enable(false) end

        if inavadmin.preferences.menulastselected["settings_dashboard_audio"] == pidx then inavadmin.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    inavadmin.app.triggers.closeProgressLoader = true

    return
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
        return true
    end
end

local function onNavMenu()
    inavadmin.app.ui.progressDisplay(nil, nil, true)
    inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
    return true
end

inavadmin.app.uiState = inavadmin.app.uiStatus.pages

return {pages = pages, openPage = openPage, onNavMenu = onNavMenu, API = {}, event = event, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}}
