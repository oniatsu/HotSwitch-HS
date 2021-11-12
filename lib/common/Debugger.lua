local debuggable = false

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
        local debugLog = hs.logger.new("=========", "debug")
        debugLog.i(message)
    end)
    if status == false then
        message = value
        -- print("ERROR: debugLog") -- it has error that same as above.
    end

    -- if debuggable then
        -- hs.alert.show(message)
    -- end
end

return {
    log = log,
    setDebuggable = setDebuggable,
    getDebuggable = getDebuggable,
}