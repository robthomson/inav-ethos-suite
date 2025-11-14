--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = {session = {}}
package.loaded.inavadmin = inavadmin

local _ENV = setmetatable({inavadmin = inavadmin}, {__index = _G, __newindex = function(_, k) print("attempt to create global '" .. tostring(k) .. "'", 2) end})

if not FONT_STD then FONT_STD = FONT_STD end

-- LuaFormatter off
local config = {
    toolName = "Inav",
    icon = lcd.loadMask("app/gfx/icon.png"),
    icon_logtool = lcd.loadMask("app/gfx/icon_logtool.png"),
    icon_unsupported = lcd.loadMask("app/gfx/unsupported.png"),
    version = {major = 0, minor = 0, revision = 0, suffix = "20251010"},
    ethosVersion = {1, 6, 2},
    supportedMspApiVersion = {"2.04", "2.05"},
    baseDir = "inavadmin",
    preferences = "inavadmin.user",
    defaultRateProfile = 4,
    watchdogParam = 10,
    mspProtocolVersion = 2,
}
-- LuaFormatter on

config.ethosVersionString = string.format("ETHOS < V%d.%d.%d", table.unpack(config.ethosVersion))

inavadmin.config = config

local performance = {cpuload = 0, freeram = 0, mainStackKB = 0, ramKB = 0, luaRamKB = 0, luaBitmapsRamKB = 0}

inavadmin.performance = performance

inavadmin.ini = assert(loadfile("lib/ini.lua", "t", _ENV))(config)

local userpref_defaults = {
    general = {iconsize = 2, syncname = false, gimbalsupression = 0.85, txbatt_type = 0, hs_loader = 0},
    localizations = {temperature_unit = 0, altitude_unit = 0},
    dashboard = {theme_preflight = "system/default", theme_inflight = "system/default", theme_postflight = "system/default"},
    events = {armflags = true, voltage = true, governor = true, pid_profile = true, rate_profile = true, esc_temp = false, escalertvalue = 90, smartfuel = true, smartfuelcallout = 0, smartfuelrepeats = 1, smartfuelhaptic = false, adj_v = false, adj_f = false},
    switches = {},
    developer = {compile = true, devtools = false, logtofile = false, loglevel = "off", logmsp = false, logobjprof = false, logmspQueue = false, memstats = false, taskprofiler = false, mspexpbytes = 8, apiversion = 2, overlaystats = false, overlaygrid = false, overlaystatsadmin = false},
    timer = {timeraudioenable = false, elapsedalertmode = 0, prealerton = false, postalerton = false, prealertinterval = 10, prealertperiod = 30, postalertinterval = 10, postalertperiod = 30},
    menulastselected = {}
}

local prefs_dir = "SCRIPTS:/" .. inavadmin.config.preferences
os.mkdir(prefs_dir)
local userpref_file = prefs_dir .. "/preferences.ini"

local master_ini = inavadmin.ini.load_ini_file(userpref_file) or {}
local updated_ini = inavadmin.ini.merge_ini_tables(master_ini, userpref_defaults)
inavadmin.preferences = updated_ini

if not inavadmin.ini.ini_tables_equal(master_ini, updated_ini) then inavadmin.ini.save_ini_file(userpref_file, updated_ini) end

inavadmin.config.bgTaskName = inavadmin.config.toolName .. " [Background]"
inavadmin.config.bgTaskKey = "inavbg"

inavadmin.utils = assert(loadfile("lib/utils.lua"))(inavadmin.config)

inavadmin.app = assert(loadfile("app/app.lua"))(inavadmin.config)

inavadmin.tasks = assert(loadfile("tasks/tasks.lua"))(inavadmin.config)

inavadmin.flightmode = {current = "preflight"}
inavadmin.utils.session()

inavadmin.simevent = {telemetry_state = true}

function inavadmin.version()
    local v = inavadmin.config.version
    return {version = string.format("%d.%d.%d-%s", v.major, v.minor, v.revision, v.suffix), major = v.major, minor = v.minor, revision = v.revision, suffix = v.suffix}
end

local function unsupported_tool()
    return {
        name = inavadmin.config.toolName,
        icon = inavadmin.config.icon_unsupported,
        create = function() end,
        wakeup = function() lcd.invalidate() end,
        paint = function()
            local w, h = lcd.getWindowSize()
            lcd.color(lcd.RGB(255, 255, 255, 1))
            lcd.font(FONT_STD)
            local msg = inavadmin.config.ethosVersionString
            local tw, th = lcd.getTextSize(msg)
            lcd.drawText((w - tw) / 2, (h - th) / 2, msg)
        end,
        close = function() end
    }
end

local function unsupported_i18n()
    return {
        name = inavadmin.config.toolName,
        icon = inavadmin.config.icon_unsupported,
        create = function() end,
        wakeup = function() lcd.invalidate() end,
        paint = function()
            local w, h = lcd.getWindowSize()
            lcd.color(lcd.RGB(255, 255, 255, 1))
            lcd.font(FONT_STD)
            local msg = "i18n not compiled - download a release version"
            local tw, th = lcd.getTextSize(msg)
            lcd.drawText((w - tw) / 2, (h - th) / 2, msg)
        end,
        close = function() end
    }
end

local function register_main_tool() system.registerSystemTool({event = inavadmin.app.event, name = inavadmin.config.toolName, icon = inavadmin.config.icon, create = inavadmin.app.create, wakeup = inavadmin.app.wakeup, paint = inavadmin.app.paint, close = inavadmin.app.close}) end

local function register_bg_task() system.registerTask({name = inavadmin.config.bgTaskName, key = inavadmin.config.bgTaskKey, wakeup = inavadmin.tasks.wakeup, event = inavadmin.tasks.event, init = inavadmin.tasks.init, read = inavadmin.tasks.read, write = inavadmin.tasks.write}) end

local function load_widget_cache(cachePath)
    local loadf, loadErr = loadfile(cachePath)
    if not loadf then
        inavadmin.utils.log("[cache] loadfile failed: " .. tostring(loadErr), "info")
        return nil
    end
    local ok, cached = pcall(loadf)
    if not ok then
        inavadmin.utils.log("[cache] execution failed: " .. tostring(cached), "info")
        return nil
    end
    if type(cached) ~= "table" then
        inavadmin.utils.log("[cache] unexpected content; rebuilding", "info")
        return nil
    end
    inavadmin.utils.log("[cache] Loaded widget list from cache", "info")
    return cached
end

local function build_widget_cache(widgetList, cacheFile)
    inavadmin.utils.createCacheFile(widgetList, cacheFile, true)
    inavadmin.utils.log("[cache] Created new widgets cache file", "info")
end

local function register_widgets(widgetList)
    inavadmin.widgets = {}
    local dupCount = {}

    for _, v in ipairs(widgetList) do
        if v.script then
            local path = "widgets/" .. v.folder .. "/" .. v.script
            local scriptModule = assert(loadfile(path))(config)

            local base = v.varname or v.script:gsub("%.lua$", "")
            if inavadmin.widgets[base] then
                dupCount[base] = (dupCount[base] or 0) + 1
                base = string.format("%s_dup%02d", base, dupCount[base])
            end
            inavadmin.widgets[base] = scriptModule

            system.registerWidget({name = v.name, key = v.key, event = scriptModule.event, create = scriptModule.create, paint = scriptModule.paint, wakeup = scriptModule.wakeup, build = scriptModule.build, close = scriptModule.close, configure = scriptModule.configure, read = scriptModule.read, write = scriptModule.write, persistent = scriptModule.persistent or false, menu = scriptModule.menu, title = scriptModule.title})
        end
    end
end

local function init()
    local cfg = inavadmin.config

    if not inavadmin.utils.ethosVersionAtLeast() then
        system.registerSystemTool(unsupported_tool())
        return
    end

    local isCompiledCheck = "@i18n(iscompiledcheck)@"
    if isCompiledCheck ~= "true" then
        system.registerSystemTool(unsupported_i18n())
    else
        register_main_tool()
    end

    register_bg_task()

    local cacheFile = "widgets.lua"
    local cachePath = "cache/" .. cacheFile
    local widgetList = load_widget_cache(cachePath)

    if not widgetList then
        widgetList = inavadmin.utils.findWidgets()
        build_widget_cache(widgetList, cacheFile)
    end

    register_widgets(widgetList)
end

return {init = init}
