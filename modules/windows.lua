local util = require("hotswitch-hs/modules/util")

local Windows = {}

Windows.new = function()
    local obj = {}

    obj.cachedOrderedWindows = nil

    obj.getCachedOrderedWindowsOrFetch = function(self)
        if self.cachedOrderedWindows == nil then
            self:refreshOrderedWindows()
        end
        return self.cachedOrderedWindows
    end

    obj.copyCachedOrderedWindows = function(self)
        if self.cachedOrderedWindows == nil then
            self:refreshOrderedWindows()
        end

        local copiedCachedOrderedWindows = {}
        for i = 1, #self.cachedOrderedWindows do
            table.insert(copiedCachedOrderedWindows, self.cachedOrderedWindows[i])
        end
        return copiedCachedOrderedWindows
    end

    obj.getWindowIdBasedOrderedWindows = function(self)
        local windowIdBasedOrderedWindows = self:copyCachedOrderedWindows()
        table.sort(windowIdBasedOrderedWindows, function(a, b)
            return (a:id() < b:id())
        end)
        return windowIdBasedOrderedWindows
    end

    obj.refreshOrderedWindows = function(self)
        -- local t1 = hs.timer.secondsSinceEpoch() * 1000
        local orderedWindows = hs.window.orderedWindows()
        -- local t2 = hs.timer.secondsSinceEpoch() * 1000
        local cleanedOrderedWindows = self.removeInvalidWindows(orderedWindows)
        -- local t3 = hs.timer.secondsSinceEpoch() * 1000
        -- utils.log("t2-t1: " .. t2-t1) -- 50ms : too late, but you can't avoid
        -- utils.log("t3-t2: " .. t3-t2) -- 3ms

        self.cachedOrderedWindows = cleanedOrderedWindows
        return cleanedOrderedWindows
    end

    obj.removeInvalidWindows = function(orderedWindows)
        -- Tips
        -- Google Chrome's finding box is treated as visible window.
        -- So you need remove such invalid windows.
        local cleanedOrderedWindows = {}
        for i = 0, #orderedWindows do
            local window = orderedWindows[i]
            if window ~= nil and window:subrole() ~= "AXUnknown" then
               table.insert(cleanedOrderedWindows, window)
            end
        end
        return cleanedOrderedWindows
    end

    return obj
end

return Windows