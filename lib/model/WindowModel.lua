local Debugger = require("hotswitch-hs/lib/common/Debugger")
local TimeChecker = require("hotswitch-hs/lib/common/TimeChecker")
local Model = require("hotswitch-hs/lib/model/Model")

local WindowModel = {}
WindowModel.new = function()
    local obj = Model.new()

    obj.cachedOrderedWindows = nil
    obj.previousWindow = nil

    -- Workaround:
    -- This is necessaary to make it faster to get all windows.
    -- If the `subscribe` is not set, the getting windows is slow.
    hs.window.filter.default:subscribe(hs.window.filter.windowsChanged, function(window, appName, callingEvent) end)

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
        local orderedWindows = hs.window.filter.default:getWindows(hs.window.filter.sortByFocusedLast)
        -- local orderedWindows = hs.window.orderedWindows() -- too slow
        self.cachedOrderedWindows = orderedWindows
        return orderedWindows
    end

    -- Deprecated
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
        local applicationMainWindow = targetAppliation:mainWindow()
        if applicationMainWindow == nil then
            return
        end

        local applicationVisibleWindows = targetAppliation:visibleWindows()
        if #applicationVisibleWindows == 1 then
            targetWindow:focus()
        else
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