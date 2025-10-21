--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local enableWakeup = false
local prevConnectedState = nil
local page

local function openPage(idx, title, script, source, folder, themeScript)

    inavadmin.app.uiState = inavadmin.app.uiStatus.pages
    inavadmin.app.triggers.isReady = false
    inavadmin.app.lastLabel = nil

    local app = inavadmin.app
    if app.formFields then for i = 1, #app.formFields do app.formFields[i] = nil end end
    if app.formLines then for i = 1, #app.formLines do app.formLines[i] = nil end end

    inavadmin.app.dashboardEditingTheme = source .. "/" .. folder

    local modulePath = themeScript

    page = assert(loadfile(modulePath))(idx)

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavadmin.app.radio.buttonPadding

    local sc
    local panel

    form.clear()

    form.addLine("@i18n(app.modules.settings.name)@" .. " / " .. title)
    local buttonW = 100
    local x = windowWidth - (buttonW * 2) - 15

    inavadmin.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = inavadmin.app.radio.linePaddingTop, w = buttonW, h = inavadmin.app.radio.navbuttonHeight}, {
        text = "@i18n(app.navigation_menu)@",
        icon = nil,
        options = FONT_S,
        paint = function() end,
        press = function()
            inavadmin.app.lastIdx = nil
            inavadmin.session.lastPage = nil

            if inavadmin.app.Page and inavadmin.app.Page.onNavMenu then inavadmin.app.Page.onNavMenu(inavadmin.app.Page) end

            inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard_settings.lua")
        end
    })
    inavadmin.app.formNavigationFields['menu']:focus()

    local x = windowWidth - buttonW - 10
    inavadmin.app.formNavigationFields['save'] = form.addButton(line, {x = x, y = inavadmin.app.radio.linePaddingTop, w = buttonW, h = inavadmin.app.radio.navbuttonHeight}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function() end,
        press = function()

            local buttons = {
                {
                    label = "@i18n(app.btn_ok_long)@",
                    action = function()
                        local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                        inavadmin.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                        if page.write then page.write() end

                        inavadmin.widgets.dashboard.reload_themes()
                        inavadmin.app.triggers.closeSave = true
                        return true
                    end
                }, {label = "@i18n(app.modules.profile_select.cancel)@", action = function() return true end}
            }

            form.openDialog({width = nil, title = "@i18n(app.modules.profile_select.save_settings)@", message = "@i18n(app.modules.profile_select.save_prompt_local)@", buttons = buttons, wakeup = function() end, paint = function() end, options = TEXT_LEFT})

        end
    })
    inavadmin.app.formNavigationFields['menu']:focus()

    inavadmin.app.uiState = inavadmin.app.uiStatus.pages
    enableWakeup = true

    if page.configure then
        page.configure(idx, title, script, extra1, extra2, extra3, extra5, extra6)
        inavadmin.utils.reportMemoryUsage(title)
        inavadmin.app.triggers.closeProgressLoader = true
        return
    end

end

local function event(widget, category, value, x, y)

    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavadmin.app.ui.openPage(pageIdx, "@i18n(app.modules.settings.dashboard)@", "settings/tools/dashboard.lua")
        return true
    end

    if page.event then page.event() end

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

    if page.wakeup then page.wakeup() end

end

return {pages = pages, openPage = openPage, API = {}, navButtons = {menu = true, save = false, reload = false, tool = false, help = false}, event = event, onNavMenu = onNavMenu, wakeup = wakeup}
