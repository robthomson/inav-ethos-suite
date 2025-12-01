--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local S_PAGES = {[1] = {name = "@i18n(app.modules.settings.dashboard_theme)@", script = "dashboard_theme.lua", image = "dashboard_theme.png"}, [2] = {name = "@i18n(app.modules.settings.dashboard_settings)@", script = "dashboard_settings.lua", image = "dashboard_settings.png"}}

local enableWakeup = false
local prevConnectedState = nil
local initTime = os.clock()

local function openPage(pidx, title, script)

    inavsuite.tasks.msp.protocol.mspIntervalOveride = nil

    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState = inavsuite.app.uiStatus.mainMenu

    form.clear()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    for i in pairs(inavsuite.app.gfx_buttons) do if i ~= "settings_dashboard" then inavsuite.app.gfx_buttons[i] = nil end end

    if inavsuite.preferences.general.iconsize == nil or inavsuite.preferences.general.iconsize == "" then
        inavsuite.preferences.general.iconsize = 1
    else
        inavsuite.preferences.general.iconsize = tonumber(inavsuite.preferences.general.iconsize)
    end

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavsuite.app.radio.buttonPadding

    local sc
    local panel

    local buttonW = 100
    local x = windowWidth - buttonW - 10

    inavsuite.app.ui.fieldHeader("@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@")

    local buttonW
    local buttonH
    local padding
    local numPerRow

    if inavsuite.preferences.general.iconsize == 0 then
        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = (inavsuite.app.lcdWidth - padding) / inavsuite.app.radio.buttonsPerRow - padding
        buttonH = inavsuite.app.radio.navbuttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end

    if inavsuite.preferences.general.iconsize == 1 then

        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = inavsuite.app.radio.buttonWidthSmall
        buttonH = inavsuite.app.radio.buttonHeightSmall
        numPerRow = inavsuite.app.radio.buttonsPerRowSmall
    end

    if inavsuite.preferences.general.iconsize == 2 then

        padding = inavsuite.app.radio.buttonPadding
        buttonW = inavsuite.app.radio.buttonWidth
        buttonH = inavsuite.app.radio.buttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end

    if inavsuite.app.gfx_buttons["settings_dashboard"] == nil then inavsuite.app.gfx_buttons["settings_dashboard"] = {} end
    if inavsuite.preferences.menulastselected["settings_dashboard"] == nil then inavsuite.preferences.menulastselected["settings_dashboard"] = 1 end

    local Menu = assert(loadfile("app/modules/" .. script))()
    local pages = S_PAGES
    local lc = 0
    local bx = 0
    local y = 0

    for pidx, pvalue in ipairs(S_PAGES) do

        if lc == 0 then
            if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if inavsuite.preferences.general.iconsize ~= 0 then
            if inavsuite.app.gfx_buttons["settings_dashboard"][pidx] == nil then inavsuite.app.gfx_buttons["settings_dashboard"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            inavsuite.app.gfx_buttons["settings_dashboard"][pidx] = nil
        end

        inavsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = inavsuite.app.gfx_buttons["settings_dashboard"][pidx],
            options = FONT_S,
            paint = function() end,
            press = function()
                inavsuite.preferences.menulastselected["settings_dashboard"] = pidx
                inavsuite.app.ui.progressDisplay(nil, nil, true)
                inavsuite.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then inavsuite.app.formFields[pidx]:enable(false) end

        local currState = (inavsuite.session.isConnected and inavsuite.session.mcu_id) and true or false

        if inavsuite.preferences.menulastselected["settings_dashboard"] == pidx then inavsuite.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    inavsuite.app.triggers.closeProgressLoader = true

    enableWakeup = true
    return
end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
        return true
    end
end

local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil, nil, true)
    inavsuite.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.name)@", "settings/settings.lua")
    return true
end

local function wakeup()
    if not enableWakeup then return end

    if os.clock() - initTime < 0.25 then return end

    local currState = (inavsuite.session.isConnected and inavsuite.session.mcu_id) and true or false

    if currState ~= prevConnectedState then

        inavsuite.app.formFields[2]:enable(currState)

        if not currState then inavsuite.app.formNavigationFields['menu']:focus() end

        prevConnectedState = currState
    end
end

inavsuite.app.uiState = inavsuite.app.uiStatus.pages

return {pages = pages, openPage = openPage, onNavMenu = onNavMenu, event = event, wakeup = wakeup, API = {}, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}}
