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
        local checkTime = util.checkTime.new(false)
        local orderedWindows = hs.window.orderedWindows()
        -- checkTime:diff() -- 45ms - necessary
        local cleanedOrderedWindows = self.removeInvalidWindows(orderedWindows)
        -- checkTime:diff() -- 20ms - necessary

        self.cachedOrderedWindows = cleanedOrderedWindows
        return cleanedOrderedWindows
    end

    obj.removeInvalidWindows = function(orderedWindows)
        -- Google Chrome's search box is treated as visible window.
        -- So you need remove such invalid windows.
        local cleanedOrderedWindows = {}
        for i = 1, #orderedWindows do
            local window = orderedWindows[i]
            if window:subrole() ~= "AXUnknown" then
                table.insert(cleanedOrderedWindows, window)
            end
        end
        return cleanedOrderedWindows
    end

    return obj
end

return Windows
