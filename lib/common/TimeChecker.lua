local Debugger = require("hotswitch-hs/lib/common/Debugger")

local TimeChecker = {}
TimeChecker.new = function()
    local obj = {}

    obj.previousTime = hs.timer.secondsSinceEpoch() * 1000

    obj.diff = function(self, key)
        if Debugger.isDebugEnabled == false then return end

        local currentTime = hs.timer.secondsSinceEpoch() * 1000
        local timeDiff = currentTime - self.previousTime

        local roundedTimeDiff = math.floor(timeDiff + 0.5)
        if key then
            Debugger.log(key .. ": " .. roundedTimeDiff)
        else
            Debugger.log(roundedTimeDiff)
        end

        self.previousTime = currentTime
        return timeDiff
    end

    return obj
end
return TimeChecker