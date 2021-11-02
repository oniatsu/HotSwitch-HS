local isEnabledDebug = false

local function enableDebug()
    isEnabledDebug = true
end

local function log(value)
    local message = hs.inspect.inspect(value)

    local status, err = pcall(function()
        local debugLog = hs.logger.new("=========", "debug")
        debugLog.i(message)
    end)
    if status == false then
        print("ERROR: debugLog")
    end

    print(message)

    if isEnabledDebug then
        hs.alert.show(message)
    end
end

local checkTime = {}
checkTime.new = function()
    local obj = {}

    obj.previousTime = hs.timer.secondsSinceEpoch() * 1000

    obj.diff = function(self)
        if self.debug == false then return end

        local currentTime = hs.timer.secondsSinceEpoch() * 1000
        local timeDiff = currentTime - self.previousTime

        if isEnabledDebug then
            log(math.floor(timeDiff + 0.5))
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
