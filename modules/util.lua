-- local DEBUG = false
local DEBUG = true

local previousTime

local function log(value)
    if DEBUG == false then return end

    local message = value

    message = hs.inspect.inspect(message)
    -- if type(value) == 'table' then
    -- message = serializeTable(value)
    -- end

    local debugLog = hs.logger.new("=========", "debug")

    debugLog.i(message)
    print(message)
    hs.alert.show(message)
end

local checkTime = {}
checkTime.new = function(debug)
    local obj = {}

    if debug ~= nil then
        obj.debug = debug
    else
        obj.debug = true
    end

    obj.previousTime = hs.timer.secondsSinceEpoch() * 1000

    obj.diff = function(self)
        if DEBUG == false then return end
        if self.debug == false then return end

        local currentTime = hs.timer.secondsSinceEpoch() * 1000
        local timeDiff = currentTime - self.previousTime
        log(math.floor(timeDiff + 0.5))

        self.previousTime = currentTime
        return timeDiff
    end

    return obj
end

return {
    log = log,
    checkTime = checkTime,
}
