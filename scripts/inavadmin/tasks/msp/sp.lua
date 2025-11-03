--[[
  Copyright (C) 2025 Rotorflight Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local transport = {}

local LOCAL_SENSOR_ID = 0x0D
local SPORT_REMOTE_SENSOR_ID = 0x1B
local FPORT_REMOTE_SENSOR_ID = 0x00
local REQUEST_FRAME_ID = 0x30
local REPLY_FRAME_ID = 0x32

-- ===== MSPv2 tracking (tolerate FW that repeats START headers) ==============
local v2_active         = false   -- true while a v2 reply is in-flight
local v2_last_status    = 0x50    -- last status byte observed/synthesized
local v2_expected_bytes = 0       -- remaining payload bytes according to START.len

local function _ver_from_status(st) return (st >> 5) & 0x03 end
local function _is_start(st) return (st & 0x10) ~= 0 end
local function _seq(st) return st & 0x0F end
local function _mk_cont_status(prev)
  local ver = _ver_from_status(prev) & 0x03
  local next_seq = (_seq(prev) + 1) & 0x0F
  -- Preserve version bits, clear START bit (bit4), set next sequence
  return (ver << 5) | next_seq
end

local sensor

local function ensure_sensor()
  if not sensor then sensor = sport.getSensor({primId = 0x32}) end
  return sensor
end

function transport.sportTelemetryPush(sensorId, frameId, dataId, value)
  ensure_sensor()
  return sensor:pushFrame({physId = sensorId, primId = frameId, appId = dataId, value = value})
end

function transport.sportTelemetryPop()
  ensure_sensor()
  local frame = sensor:popFrame()
  if frame == nil then return nil, nil, nil, nil end
  return frame:physId(), frame:primId(), frame:appId(), frame:value()
end

-- Pack 6-byte payload from common.lua to SmartPort (2B appId + 4B value)
transport.mspSend = function(payload)
  local dataId = (payload[1] or 0) | ((payload[2] or 0) << 8)
  local v0 = payload[3] or 0
  local v1 = payload[4] or 0
  local v2 = payload[5] or 0
  local v3 = payload[6] or 0
  local value = (v0 & 0xFF) | ((v1 & 0xFF) << 8) | ((v2 & 0xFF) << 16) | ((v3 & 0xFF) << 24)
  return transport.sportTelemetryPush(LOCAL_SENSOR_ID, REQUEST_FRAME_ID, dataId, value)
end

transport.mspRead  = function(cmd) return inavadmin.tasks.msp.common.mspSendRequest(cmd, {}) end
transport.mspWrite = function(cmd, payload) return inavadmin.tasks.msp.common.mspSendRequest(cmd, payload) end

-- NO de-dup while handling v2 continuations reliably (SmartPort may repeat values)
local function pop_no_dedup()
  local sensorId, frameId, dataId, value = transport.sportTelemetryPop()
  return sensorId, frameId, dataId, value
end

-- Map SmartPort reply frame to 6-byte window expected by common.lua
local function map_v2_frame_to_window(status, dataId, value)
  local app_hi = (dataId >> 8) & 0xFF
  local b0 =  value        & 0xFF
  local b1 = (value >> 8)  & 0xFF
  local b2 = (value >> 16) & 0xFF
  local b3 = (value >> 24) & 0xFF
  local isStart = _is_start(status)

  if isStart and not v2_active then
    -- First START for this reply: header only
    v2_active = true
    v2_last_status = status & 0xFF
    v2_expected_bytes = ((b2 | (b3 << 8)) & 0xFFFF)
    -- [status][flags][cmd1][cmd2][len1][len2]
    return { (status | 0x10) & 0xFF, app_hi, b0, b1, b2, b3 }
  end

  -- Continuation (or repeated START treated as CONT while in-flight)
  if v2_active then
    local cont_status
    if _ver_from_status(status) == 2 and not _is_start(status) then
      -- Proper CONT status provided
      cont_status = status & 0xFF
    else
      -- FW repeated START or didn't set CONT bit: synthesize
      cont_status = _mk_cont_status(v2_last_status)
    end
    v2_last_status = cont_status

    local out = { cont_status, app_hi, b0, b1, b2, b3 }

    -- Track remaining expected bytes; common.lua will also stop at len
    if v2_expected_bytes > 0 then
      local chunk = 5
      if v2_expected_bytes <= chunk then
        v2_expected_bytes = 0
        v2_active = false
      else
        v2_expected_bytes = v2_expected_bytes - chunk
      end
    end

    return out
  end

  -- Stray v2 frame with no active transfer; ignore
  return nil
end

transport.mspPoll = function()
  local sensorId, frameId, dataId, value = pop_no_dedup()
  if not sensorId then return nil end

  -- Only forward FC-origin REPLY frames (0x32) to MSP; never our 0x30 client frames.
  if (sensorId == SPORT_REMOTE_SENSOR_ID or sensorId == FPORT_REMOTE_SENSOR_ID)
     and (frameId == REPLY_FRAME_ID) then

    local status = dataId & 0xFF
    local ver = _ver_from_status(status)  -- 0/1=legacy, 2=MSPv2

    if ver == 2 then
      return map_v2_frame_to_window(status, dataId, value)
    end

    -- v1 / legacy path: pass-through 6 bytes
    return {
      dataId & 0xFF, (dataId >> 8) & 0xFF,
      value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF
    }
  end

  return nil
end

return transport
