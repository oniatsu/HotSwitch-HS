local debuggable = false
local debugLog = hs.logger.new("hotswitch", "info")

local function setDebuggable(flag)
    debuggable = flag
end

local function getDebuggable()
    return debuggable
end

local function log(value)
    if debuggable == false then
        return
    end

    local message
    local status, err = pcall(function()
        message = hs.inspect.inspect(value)

        debugLog.w(message)
    end)
    if status == false then
        message = value
        -- print("ERROR: debugLog") -- it has error that same as above.
    end

    -- if debuggable then
    -- hs.alert.show(message)
    -- end
end

local function setLogLevel(level)
    debugLog.setLogLevel(level)
end

local function alert(value)
    if debuggable then
        hs.alert.show(value)
    end
end

return {
    log = log,
    setLogLevel = setLogLevel,
    alert = alert,
    setDebuggable = setDebuggable,
    getDebuggable = getDebuggable,
}
