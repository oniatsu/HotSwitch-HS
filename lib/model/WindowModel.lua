local Debugger = require("hotswitch-hs/lib/common/Debugger")
local Model = require("hotswitch-hs/lib/model/Model")

local WindowModel = {}
WindowModel.new = function()
    local obj = Model.new()

    obj.cachedOrderedWindows = nil
    obj.previousWindow = nil

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

    -- Note: "hs.window.orderedWindows()" cannot get "Hammerspoon Console" window. I don't know why that.
    obj.refreshOrderedWindows = function(self)
        -- This method is slow. hs.window.switcher uses this way.
        -- local wins = hs.window.filter.default:getWindows(hs.window.filter.sortByFocusedLast)
        -- self.cachedOrderedWindows = wins
        -- return wins

        -- local checkTime = util.checkTime.new()
        local orderedWindows = hs.window.orderedWindows()
        -- checkTime:diff("get") --100ms ~ 300ms
        local cleanedOrderedWindows = self.removeInvalidWindows(orderedWindows)
        -- checkTime:diff("remove") -- 25ms

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

    obj.focusPreviousWindowForCancel = function(self)
        if self.previousWindow ~= nil then
            self.focusWindow(self.previousWindow)
        else
            self.focusWindow(self.getCachedOrderedWindowsOrFetch()[1])
        end
    end

    -- TODO: window:focus() don't work correctly, when a application has 2 windows and each windows are on different screen.
    obj.focusWindow = function(targetWindow)
        local targetAppliation = targetWindow:application()
        local applicationVisibleWindows = targetAppliation:visibleWindows()

        if #applicationVisibleWindows == 1 then
            targetWindow:focus()
        else
            local applicationMainWindow = targetAppliation:mainWindow()
            local applicationMainWindowScreen = applicationMainWindow:screen()
            local applicationMainWindowScreenId = applicationMainWindowScreen:id()

            local targetWindowScreen = targetWindow:screen()
            local targetWindowScreenId = targetWindowScreen:id()

            if targetWindowScreenId == applicationMainWindowScreenId then
                targetWindow:focus()
            else
                local focusedWindow = hs.window.focusedWindow()
                if focusedWindow and focusedWindow:application():pid() == targetAppliation:pid() then
                    targetWindow:focus()
                else
                    -- Hammerspoon bug: window:focus() don't work correctly, when a application has 2 windows and each windows are on different screen.
                    -- Issue: https://github.com/Hammerspoon/hammerspoon/issues/2978

                    -- This way is workaround.

                    targetWindow:focus()

                    local status, err = pcall(function()
                        hs.timer.doAfter(0.15, function()
                            targetWindow:focus()
                        end)
                    end)
                    if status == false then
                        Debugger.i(err)
                    end
                end
            end
        end
    end

    return obj
end
return WindowModel