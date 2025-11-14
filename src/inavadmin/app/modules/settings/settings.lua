--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local S_PAGES = {
    {name = "@i18n(app.modules.settings.txt_general)@", script = "general.lua", image = "general.png"}, {name = "@i18n(app.modules.settings.dashboard)@", script = "dashboard.lua", image = "dashboard.png"}, {name = "@i18n(app.modules.settings.localizations)@", script = "localizations.lua", image = "localizations.png"}, {name = "@i18n(app.modules.settings.audio)@", script = "audio.lua", image = "audio.png"},
    {name = "@i18n(app.modules.settings.txt_development)@", script = "development.lua", image = "development.png"}
}

local function openPage(pidx, title, script)

    inavadmin.tasks.msp.protocol.mspIntervalOveride = nil

    inavadmin.app.triggers.isReady = false
    inavadmin.app.uiState = inavadmin.app.uiStatus.mainMenu

    form.clear()

    inavadmin.app.lastIdx = idx
    inavadmin.app.lastTitle = title
    inavadmin.app.lastScript = script

    for i in pairs(inavadmin.app.gfx_buttons) do if i ~= "settings" then inavadmin.app.gfx_buttons[i] = nil end end

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

    form.addLine(title)

    local buttonW = 100
    local x = windowWidth - buttonW - 10

    inavadmin.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = inavadmin.app.radio.linePaddingTop, w = buttonW, h = inavadmin.app.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function() end,
        press = function()
            inavadmin.app.lastIdx = nil
            inavadmin.session.lastPage = nil

            if inavadmin.app.Page and inavadmin.app.Page.onNavMenu then
                inavadmin.app.Page.onNavMenu(inavadmin.app.Page)
            else
                inavadmin.app.ui.progressDisplay(nil, nil, true)
            end
            inavadmin.app.ui.openMainMenu()
        end
    })
    inavadmin.app.formNavigationFields['menu']:focus()

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

    if inavadmin.app.gfx_buttons["settings"] == nil then inavadmin.app.gfx_buttons["settings"] = {} end
    if inavadmin.preferences.menulastselected["settings"] == nil then inavadmin.preferences.menulastselected["settings"] = 1 end

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
            if inavadmin.app.gfx_buttons["settings"][pidx] == nil then inavadmin.app.gfx_buttons["settings"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            inavadmin.app.gfx_buttons["settings"][pidx] = nil
        end

        inavadmin.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = inavadmin.app.gfx_buttons["settings"][pidx],
            options = FONT_S,
            paint = function() end,
            press = function()
                inavadmin.preferences.menulastselected["settings"] = pidx
                inavadmin.app.ui.progressDisplay(nil, nil, true)
                inavadmin.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then inavadmin.app.formFields[pidx]:enable(false) end

        if inavadmin.preferences.menulastselected["settings"] == pidx then inavadmin.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    inavadmin.app.triggers.closeProgressLoader = true

    return
end

inavadmin.app.uiState = inavadmin.app.uiStatus.pages

return {pages = pages, openPage = openPage, API = {}}
