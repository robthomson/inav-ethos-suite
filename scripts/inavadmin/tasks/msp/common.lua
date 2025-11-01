--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

-- Toggle ultra-verbose logging (kept always-on per your request for "very detailed")
local VERBOSE_DEBUG = true

local MSPV_DEFAULT = 1
local MSPV = MSPV_DEFAULT

-- ===== Debug helpers =====
local function log(msg, lvl)
    print(msg)
    --if inavadmin and inavadmin.utils and inavadmin.utils.log then
    --    inavadmin.utils.log(msg, lvl or "debug")
    --end
end

local function tohex(n, width)
    width = width or 2
    n = (n or 0) & 0xFF
    return string.format("%0" .. tostring(width) .. "X", n)
end

local function hexdump_bytes(tbl, max_len)
    if type(tbl) ~= "table" then return "<not-table>" end
    local n = #tbl
    local limit = max_len or n
    local parts = {}
    local last = math.min(n, limit)
    for i = 1, last do
        parts[#parts + 1] = tohex((tbl[i] or 0) & 0xFF)
    end
    local s = table.concat(parts, " ")
    if n > limit then s = s .. string.format(" …(+%d bytes)", n - limit) end
    return s
end

local function hexdump_table(tbl, label, max_len)
    label = label or "BYTES"
    return string.format("%s [%d]: %s", label, #tbl, hexdump_bytes(tbl, max_len))
end

local function hexdump_slice(tbl, from_idx, to_idx)
    local out = {}
    for i = from_idx, to_idx do
        out[#out + 1] = tbl[i]
    end
    return hexdump_table(out, string.format("SLICE %d..%d", from_idx, to_idx))
end

local function dbg(fmt, ...)
    if VERBOSE_DEBUG then log(string.format(fmt, ...), "debug") end
end

-- ===== Protocol constants/state =====
local function version_bit()
    if MSPV == 2 then
        return (1 << 6)
    else
        return (1 << 5)
    end
end

local MSP_STARTFLAG = (1 << 4)

local mspSeq = 0
local mspRemoteSeq = 0
local mspLastReq = 0
local mspStarted = false

local mspTxBuf = {}
local mspTxIdx = 1
local mspTxCRC = 0

local mspRxBuf = {}
local mspRxReq = 0
local mspRxSize = 0
local mspRxError = false
local mspRxCRC = 0

local function maxTx() return inavadmin.tasks.msp.protocol.maxTxBufferSize end
local function maxRx() return inavadmin.tasks.msp.protocol.maxRxBufferSize end

-- ===== TX =====
local function mspSendRequest(cmd, payload)
    if (type(cmd) ~= "number") or (type(payload) ~= "table") then
        log("mspSendRequest: bad args", "debug");
        return nil
    end
    if #mspTxBuf ~= 0 then
        log("mspSendRequest: busy (pending frame for cmd " .. tostring(mspLastReq) .. ")", "debug")
        return nil
    end

    local len = #payload
    mspTxBuf = {}
    mspTxIdx = 1
    mspTxCRC = 0

    if MSPV == 2 then
        local flags = 0
        mspTxBuf[1] = flags
        mspTxBuf[2] = (cmd & 0xFF)
        mspTxBuf[3] = ((cmd >> 8) & 0xFF)
        mspTxBuf[4] = (len & 0xFF)
        mspTxBuf[5] = ((len >> 8) & 0xFF)
        for i = 1, len do mspTxBuf[5 + i] = (payload[i] or 0) & 0xFF end

        dbg("[MSPv2] Build TX: cmd=0x%04X len=%d flags=0x%02X", cmd & 0xFFFF, len, flags & 0xFF)
        if VERBOSE_DEBUG then
            dbg("%s", hexdump_table(mspTxBuf, "TX-FRAME(v2)"))
        end
    else
        -- v1: len, cmd, payload..., XOR
        mspTxBuf[1] = (len & 0xFF)
        mspTxBuf[2] = (cmd & 0xFF)
        mspTxCRC = (mspTxBuf[1] ~ mspTxBuf[2])
        for i = 1, len do
            local b = (payload[i] or 0) & 0xFF
            mspTxBuf[2 + i] = b
            mspTxCRC = (mspTxCRC ~ b)
        end
        mspTxBuf[#mspTxBuf + 1] = (mspTxCRC & 0xFF)

        dbg("[MSPv1] Build TX: cmd=0x%02X len=%d xor=0x%02X", cmd & 0xFF, len, mspTxCRC & 0xFF)
        if VERBOSE_DEBUG then
            dbg("%s", hexdump_table(mspTxBuf, "TX-FRAME(v1)"))
        end
    end

    mspLastReq = cmd
    return true
end

local function mspProcessTxQ()
    if #mspTxBuf == 0 then return false end

    dbg("TX-Q: size=%d idx=%d lastReq=0x%X", #mspTxBuf, mspTxIdx, mspLastReq & 0xFFFF)

    local payload = {}
    payload[1] = (mspSeq + version_bit())
    local header_before = payload[1]
    mspSeq = (mspSeq + 1) & 0x0F
    if mspTxIdx == 1 then payload[1] = payload[1] + MSP_STARTFLAG end

    local i = 2
    local max = maxTx()
    while (i <= max) and (mspTxIdx <= #mspTxBuf) do
        payload[i] = mspTxBuf[mspTxIdx]
        mspTxIdx = mspTxIdx + 1
        i = i + 1
    end

    if i <= max then
        for j = i, max do payload[j] = 0 end
    end

    local more = (mspTxIdx <= #mspTxBuf)
    if not more then
        -- Final chunk sent; clear TX buffer
        mspTxBuf = {}
        mspTxIdx = 1
        mspTxCRC = 0
    end

    local startflag = ((payload[1] & MSP_STARTFLAG) ~= 0)
    local seq = payload[1] & 0x0F
    local ver = ((payload[1] & 0x60) >> 5)

    dbg("TX-CHUNK: ver=%d seq=%d start=%s maxTx=%d more=%s hdr(wo start)=0x%02X",
        ver, seq, tostring(startflag), max, tostring(more), header_before & 0xFF)

    if VERBOSE_DEBUG then
        dbg("%s", hexdump_table(payload, "TX-CHUNK BYTES"))
        if more then
            dbg("%s", hexdump_slice(mspTxBuf, mspTxIdx, math.min(mspTxIdx + 31, #mspTxBuf)))
        end
    end

    inavadmin.tasks.msp.protocol.mspSend(payload)
    return more
end

-- ===== RX =====
local function mspReceivedReply(payload)
    if (type(payload) ~= "table") or (#payload == 0) then return nil end

    if VERBOSE_DEBUG then
        dbg("%s", hexdump_table(payload, "RX-RAW"))
    end

    local idx = 1
    local status = payload[idx]; idx = idx + 1
    local err = ((status & 0x80) ~= 0)
    local start = ((status & MSP_STARTFLAG) ~= 0)
    local seq = (status & 0x0F)
    local ver = ((status & 0x60) >> 5)

    dbg("RX-STATUS: ver=%d seq=%d start=%s err=%s", ver, seq, tostring(start), tostring(err))

    if start then
        mspRxBuf = {}
        mspRxError = err

        if ver == 2 then
            local flags = payload[idx]; idx = idx + 1
            local cmdLo = payload[idx]; idx = idx + 1
            local cmdHi = payload[idx]; idx = idx + 1
            local lenLo = payload[idx]; idx = idx + 1
            local lenHi = payload[idx]; idx = idx + 1

            mspRxReq = ((cmdHi << 8) | cmdLo)
            mspRxSize = ((lenHi << 8) | lenLo)
            mspRxCRC = 0

            dbg("[MSPv2] RX-START: cmd=0x%04X len=%d flags=0x%02X", mspRxReq & 0xFFFF, mspRxSize, (flags or 0) & 0xFF)
        elseif ver == 1 then
            mspRxSize = payload[idx]; idx = idx + 1
            mspRxReq = payload[idx]; idx = idx + 1
            mspRxCRC = (mspRxSize ~ mspRxReq)

            dbg("[MSPv1] RX-START: cmd=0x%02X len=%d initXOR=0x%02X", mspRxReq & 0xFF, mspRxSize, mspRxCRC & 0xFF)
        else
            log("Unsupported MSP version in RX: " .. tostring(ver), "debug")
            return nil
        end

        if mspRxReq == mspLastReq then mspStarted = true end
    else
        if (not mspStarted) or (((mspRemoteSeq + 1) & 0x0F) ~= seq) then
            mspStarted = false
            log("RX out of sequence (exp " .. tostring((mspRemoteSeq + 1) & 0x0F) .. " got " .. tostring(seq) .. ")", "debug")
            return nil
        end
    end

    local before_bytes = #mspRxBuf
    while (idx <= #payload) and (#mspRxBuf < mspRxSize) do
        local b = payload[idx]
        mspRxBuf[#mspRxBuf + 1] = b
        if ver == 1 then
            mspRxCRC = (mspRxCRC ~ (b or 0))
        end
        idx = idx + 1
    end
    local copied = #mspRxBuf - before_bytes
    if copied > 0 then
        dbg("RX-COPY: copied=%d total=%d/%d", copied, #mspRxBuf, mspRxSize)
        if VERBOSE_DEBUG then
            local show = math.min(#mspRxBuf, 64)
            dbg("%s", hexdump_slice(mspRxBuf, math.max(1, #mspRxBuf - copied + 1), math.min(#mspRxBuf, #mspRxBuf)))
            dbg("%s", hexdump_table(mspRxBuf, "RX-ACCUM SNAPSHOT", show))
        end
    end

    if #mspRxBuf < mspRxSize then
        mspRemoteSeq = seq
        dbg("RX-PARTIAL: awaiting more (seq=%d) remaining=%d", seq, mspRxSize - #mspRxBuf)
        return false
    end

    -- We gathered the full payload
    mspStarted = false

    if ver == 1 then
        if idx <= #payload then
            local tail = payload[idx]
            if mspRxCRC ~= tail then
                log(string.format("MSP v1 XOR mismatch (calc=0x%02X tail=0x%02X)", mspRxCRC & 0xFF, (tail or 0) & 0xFF), "debug")
                if VERBOSE_DEBUG then
                    dbg("%s", hexdump_table(mspRxBuf, "RX-PAYLOAD(v1)"))
                end
                return nil
            else
                dbg("RX-CRC(v1): OK (xor=0x%02X)", mspRxCRC & 0xFF)
            end
        else
            dbg("RX-CRC(v1): no tail byte present to verify")
        end
    else
        -- v2 CRC (if any) would be handled by the protocol layer; just dump payload
        if VERBOSE_DEBUG then
            dbg("%s", hexdump_table(mspRxBuf, "RX-PAYLOAD(v2)"))
        end
    end

    dbg("RX-COMPLETE: cmd=0x%X len=%d err=%s", mspRxReq & 0xFFFF, #mspRxBuf, tostring(mspRxError))
    return true
end

local function mspPollReply()
    local startTime = os.clock()
    local deadline = 0.1
    dbg("POLL: start=%.6f window=%.3fs", startTime, deadline)

    while (os.clock() - startTime) < deadline do
        local mspData = inavadmin.tasks.msp.protocol.mspPoll()
        if mspData then
            dbg("POLL: got data (len=%d)", #mspData)
            if mspReceivedReply(mspData) then
                dbg("POLL: reply complete for cmd=0x%X len=%d err=%s",
                    mspRxReq & 0xFFFF, #mspRxBuf, tostring(mspRxError))
                mspLastReq = 0
                return mspRxReq, mspRxBuf, mspRxError
            end
        end
    end
    dbg("POLL: timeout (no complete reply within %.3fs)", deadline)
    return nil, nil, nil
end

-- ===== Utilities =====
local function mspClearTxBuf()
    dbg("TX-BUF: cleared (discarded %d bytes)", #mspTxBuf)
    mspTxBuf = {}
    mspTxIdx = 1
    mspTxCRC = 0
end

local function setMSPVersion(v)
    if v == 1 or v == 2 then
        MSPV = v
        log("MSP version set to v" .. tostring(v), "debug")
    else
        log("setMSPVersion: ignored invalid value " .. tostring(v), "debug")
    end
end

local function getMSPVersion() return MSPV end

return {
    mspProcessTxQ = mspProcessTxQ,
    mspSendRequest = mspSendRequest,
    mspReceivedReply = mspReceivedReply,
    mspPollReply = mspPollReply,
    mspClearTxBuf = mspClearTxBuf,
    setMSPVersion = setMSPVersion,
    getMSPVersion = getMSPVersion
}
