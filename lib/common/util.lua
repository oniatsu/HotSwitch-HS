local isEnabledDebug = false

local function enableDebug()
    isEnabledDebug = true
end

local function log(value)
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

    if isEnabledDebug then
        hs.alert.show(message)
    end
end

local checkTime = {}
checkTime.new = function()
    local obj = {}

    obj.previousTime = hs.timer.secondsSinceEpoch() * 1000

    obj.diff = function(self, key)
        if isEnabledDebug == false then return end

        local currentTime = hs.timer.secondsSinceEpoch() * 1000
        local timeDiff = currentTime - self.previousTime

        local roundedTimeDiff = math.floor(timeDiff + 0.5)
        if key then
            log(key .. ": " .. roundedTimeDiff)
        else
            log(roundedTimeDiff)
        end

        self.previousTime = currentTime
        return timeDiff
    end

    return obj
end

return {
    log = log,
    checkTime = checkTime,
    enableDebug = enableDebug,
}
