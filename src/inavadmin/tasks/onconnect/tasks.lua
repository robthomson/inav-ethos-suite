--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local tasks = {}
local tasksList = {}
local tasksLoaded = false
local activeLevel = nil

local telemetryTypeChanged = false

local TASK_TIMEOUT_SECONDS = 10
local MAX_RETRIES = 3
local RETRY_BACKOFF_SECONDS = 1

local TYPE_CHANGE_DEBOUNCE = 1.0
local lastTypeChangeAt = 0

local BASE_PATH = "tasks/onconnect/tasks/"
local PRIORITY_LEVELS = {"high", "medium", "low"}

local function resetSessionFlags()
    inavsuite.session.onConnect = inavsuite.session.onConnect or {}
    for _, level in ipairs(PRIORITY_LEVELS) do inavsuite.session.onConnect[level] = false end

    inavsuite.session.isConnected = false
end

function tasks.findTasks()
    if tasksLoaded then return end

    resetSessionFlags()

    for _, level in ipairs(PRIORITY_LEVELS) do
        local dirPath = BASE_PATH .. level .. "/"
        local files = system.listFiles(dirPath) or {}
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                local fullPath = dirPath .. file
                local name = level .. "/" .. file:gsub("%.lua$", "")
                local chunk, err = loadfile(fullPath)
                if not chunk then
                    inavsuite.utils.log("Error loading task " .. fullPath .. ": " .. err, "error")
                else
                    local module = assert(chunk())
                    if type(module) == "table" and type(module.wakeup) == "function" then
                        tasksList[name] = {module = module, priority = level, initialized = false, complete = false, failed = false, attempts = 0, nextEligibleAt = 0, startTime = nil}
                    else
                        inavsuite.utils.log("Invalid task file: " .. fullPath, "info")
                    end
                end
            end
        end
    end

    tasksLoaded = true
end

function tasks.resetAllTasks()
    for _, task in pairs(tasksList) do
        if type(task.module.reset) == "function" then task.module.reset() end
        task.initialized = false
        task.complete = false
        task.startTime = nil
        task.failed = false
        task.attempts = 0
        task.nextEligibleAt = 0
    end

    resetSessionFlags()
    inavsuite.tasks.reset()
    inavsuite.session.resetMSPSensors = true
end

function tasks.wakeup()
    local telemetryActive = inavsuite.tasks.msp.onConnectChecksInit and inavsuite.session.telemetryState

    if telemetryTypeChanged then
        telemetryTypeChanged = false
        tasks.resetAllTasks()
        tasksLoaded = false
        return
    end

    if not telemetryActive then
        tasks.resetAllTasks()
        tasksLoaded = false
        return
    end

    if not tasksLoaded then tasks.findTasks() end

    activeLevel = nil
    for _, level in ipairs(PRIORITY_LEVELS) do
        if not inavsuite.session.onConnect[level] then
            activeLevel = level
            break
        end
    end

    if not activeLevel then return end

    local now = os.clock()

    for name, task in pairs(tasksList) do
        if task.priority == activeLevel then

            if task.failed then goto continue end

            if task.nextEligibleAt and task.nextEligibleAt > now then goto continue end

            if not task.initialized then
                task.initialized = true
                task.startTime = now
            end

            if not task.complete then
                inavsuite.utils.log("Waking up " .. name, "debug")
                task.module.wakeup()
                if task.module.isComplete and task.module.isComplete() then
                    task.complete = true
                    task.startTime = nil
                    task.nextEligibleAt = 0
                    inavsuite.utils.log("Completed " .. name, "debug")
                elseif task.startTime and (now - task.startTime) > TASK_TIMEOUT_SECONDS then

                    task.attempts = (task.attempts or 0) + 1
                    if task.attempts <= MAX_RETRIES then
                        local backoff = RETRY_BACKOFF_SECONDS * (2 ^ (task.attempts - 1))
                        task.nextEligibleAt = now + backoff
                        task.initialized = false
                        task.startTime = nil
                        inavsuite.utils.log(string.format("Task '%s' timed out. Re-queueing (attempt %d/%d) in %.1fs.", name, task.attempts, MAX_RETRIES, backoff), "info")
                    else
                        task.failed = true
                        task.startTime = nil
                        inavsuite.utils.log(string.format("Task '%s' failed after %d attempts. Skipping.", name, MAX_RETRIES), "info")
                    end
                end
            end
            ::continue::
        end
    end

    local levelDone = true
    for _, task in pairs(tasksList) do
        if task.priority == activeLevel and not task.complete then
            levelDone = false
            break
        end
    end

    if levelDone then
        inavsuite.session.onConnect[activeLevel] = true
        inavsuite.utils.log("All [" .. activeLevel .. "] tasks complete.", "info")

        if activeLevel == "high" then
            inavsuite.utils.playFileCommon("beep.wav")
            inavsuite.flightmode.current = "preflight"
            inavsuite.session.isConnectedHigh = true
            return
        elseif activeLevel == "medium" then
            inavsuite.session.isConnectedMedium = true
            return
        elseif activeLevel == "low" then
            inavsuite.session.isConnectedLow = true
            inavsuite.session.isConnected = true
            inavsuite.utils.log("Connection [established].", "info")
            return
        end
    end
end

function tasks.setTelemetryTypeChanged()
    telemetryTypeChanged = true
    lastTypeChangeAt = os.clock()
end

function tasks.active()
    if not activeLevel then return false end
    return true
end

return tasks
