--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local apiversion = {}

local mspCallMade = false

function apiversion.wakeup()
    if inavadmin.session.apiVersion == nil and mspCallMade == false then

        mspCallMade = true

        local API = inavadmin.tasks.msp.api.load("API_VERSION")
        API.setCompleteHandler(function(self, buf)
            local version = API.readVersion()

            if version then
                local apiVersionString = tostring(version)
                if not inavadmin.utils.stringInArray(inavadmin.config.supportedMspApiVersion, apiVersionString) then
                    inavadmin.utils.log("Incompatible API version detected: " .. apiVersionString, "info")
                    inavadmin.session.apiVersionInvalid = true
                    return
                end
            end

            inavadmin.session.apiVersion = version
            inavadmin.session.apiVersionInvalid = false

            if inavadmin.session.apiVersion then inavadmin.utils.log("API version: " .. inavadmin.session.apiVersion, "info") end
        end)
        API.setUUID("22a683cb-db0e-439f-8d04-04687c9360f3")
        API.read()
    end
end

function apiversion.reset()
    inavadmin.session.apiVersion = nil
    inavadmin.session.apiVersionInvalid = nil
    mspCallMade = false
end

function apiversion.isComplete() if inavadmin.session.apiVersion ~= nil then return true end end

return apiversion
