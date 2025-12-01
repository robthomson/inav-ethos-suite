--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local apiversion = {}

local mspCallMade = false

function apiversion.wakeup()
    if inavsuite.session.apiVersion == nil and mspCallMade == false then

        mspCallMade = true

        local API = inavsuite.tasks.msp.api.load("API_VERSION")
        API.setCompleteHandler(function(self, buf)
            local version = API.readVersion()

            if version then
                local apiVersionString = tostring(version)
                if not inavsuite.utils.stringInArray(inavsuite.config.supportedMspApiVersion, apiVersionString) then
                    inavsuite.utils.log("Incompatible API version detected: " .. apiVersionString, "info")
                    inavsuite.session.apiVersionInvalid = true
                    return
                end
            end

            inavsuite.session.apiVersion = version
            inavsuite.session.apiVersionInvalid = false

            if inavsuite.session.apiVersion then inavsuite.utils.log("API version: " .. inavsuite.session.apiVersion, "info") end
        end)
        API.setUUID("22a683cb-db0e-439f-8d04-04687c9360f3")
        API.read()
    end
end

function apiversion.reset()
    inavsuite.session.apiVersion = nil
    inavsuite.session.apiVersionInvalid = nil
    mspCallMade = false
end

function apiversion.isComplete() if inavsuite.session.apiVersion ~= nil then return true end end

return apiversion
