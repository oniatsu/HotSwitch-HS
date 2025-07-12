local Debugger = require("hotswitch-hs/lib/common/Debugger")
local TimeChecker = require("hotswitch-hs/lib/common/TimeChecker")
local Model = require("hotswitch-hs/lib/model/Model")

-- local SUBSCRIPTION_TARGET = { hs.window.filter.windowAllowed, hs.window.filter.windowCreated, hs.window.filter.windowsChanged, hs.window.filter.windowTitleChanged }
-- local SUBSCRIPTION_TARGET = { hs.window.filter.hasWindow }
local SUBSCRIPTION_TARGET = { hs.window.filter.windowVisible }

local FINDER_BUNDLE_ID = "com.apple.finder"

local WindowModel = {}
WindowModel.new = function()
    local obj = Model.new()

    obj.cachedOrderedWindows = nil
    obj.previousWindow = nil
    obj.lastFinderWindowId = 0

    obj.windowFilter = hs.window.filter.defaultCurrentSpace
    -- obj.windowFilter = hs.window.filter.default
    obj.subscriptionCallback = function()
    end

    obj.init = function(self)
        -- Workaround:
        -- This is necessaary to make it faster to get all windows.
        -- If the `subscribe` is not set, the getting windows is slow.
        obj.windowFilter:subscribe(SUBSCRIPTION_TARGET, self.subscriptionCallback)
    end

    obj.enableAllSpaceWindows = function(self)
        obj.windowFilter:unsubscribe(SUBSCRIPTION_TARGET, self.subscriptionCallback)
        obj.windowFilter = hs.window.filter.default
        obj.windowFilter:subscribe(SUBSCRIPTION_TARGET, self.subscriptionCallback)
    end

    obj.getCachedOrderedWindowsOrFetch = function(self)
        if self.cachedOrderedWindows == nil then
            return self:refreshOrderedWindows()
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

    obj.getCreatedOrderedWindows = function(self)
        local windows = self.windowFilter:getWindows(hs.window.filter.sortByCreated)
        windows = self.removeInvalidWindows(windows)
        windows = self:removeUnusableFinderWindowsForCreatedOrderedWindows(windows)
        return windows

        -- Another way: sorting by window id
        -- local windowIdBasedOrderedWindows = self:copyCachedOrderedWindows()
        -- table.sort(windowIdBasedOrderedWindows, function(a, b)
        --     return (a:id() < b:id())
        -- end)
        -- return windowIdBasedOrderedWindows
    end

    -- Note: "hs.window.orderedWindows()" cannot get "Hammerspoon Console" window. I don't know why that.
    obj.refreshOrderedWindows = function(self)
        -- Sometimes, getting window is failed.
        local orderedWindows = self.windowFilter:getWindows(hs.window.filter.sortByFocusedLast)

        -- Here is another way, but it's slow.
        -- local orderedWindows = hs.window.orderedWindows()

        orderedWindows = self.removeInvalidWindows(orderedWindows)
        orderedWindows = self:removeUnusableFinderWindows(orderedWindows)

        self.cachedOrderedWindows = orderedWindows
        return orderedWindows
    end

    obj.removeInvalidWindows = function(orderedWindows)
        local cleanedOrderedWindows = {}
        for i = 1, #orderedWindows do
            local window = orderedWindows[i]
            -- local role = window:role()
            local subrole = window:subrole()
            -- local id = window:id()
            -- local isVisible = window:isVisible()
            -- local isStandard = window:isStandard()
            -- Debugger.log(window:application():name() .. " | " .. role ..
            --     " : " ..
            --     subrole ..
            --     " | " .. id .. " | " .. tostring(isVisible) .. " | " .. tostring(isStandard) .. " | " .. tabCount)
            if subrole ~= "AXUnknown" and subrole ~= "AXSystemDialog" and subrole ~= "" then
                table.insert(cleanedOrderedWindows, window)

                -- not work
                -- local applicationName = window:application():name()
                -- if applicationName == "Finder" then
                --     local tabCount = window:tabCount()
                --     Debugger.log(applicationName .. " | " .. tabCount)
                --     table.insert(cleanedOrderedWindows, window)
                --     if tabCount > 0 then
                --         table.insert(cleanedOrderedWindows, window)
                --     end
                -- else
                --     table.insert(cleanedOrderedWindows, window)
                -- end
            end
        end
        return cleanedOrderedWindows
    end

    obj.removeUnusableFinderWindows = function(self, orderedWindows)
        local cleanedOrderedWindows = {}
        local finderWindowsCount = 0
        for i = 1, #orderedWindows do
            local window = orderedWindows[i]
            local bundleID = window:application():bundleID()
            if bundleID == FINDER_BUNDLE_ID then
                finderWindowsCount = finderWindowsCount + 1
                if finderWindowsCount == 1 then
                    self.lastFinderWindowId = window:id()
                    table.insert(cleanedOrderedWindows, window)
                end
            else
                table.insert(cleanedOrderedWindows, window)
            end
        end
        return cleanedOrderedWindows
    end

    obj.removeUnusableFinderWindowsForCreatedOrderedWindows = function(self, orderedWindows)
        local cleanedOrderedWindows = {}
        local finderWindowsCount = 0
        for i = 1, #orderedWindows do
            local window = orderedWindows[i]
            local bundleID = window:application():bundleID()
            if bundleID == FINDER_BUNDLE_ID then
                local windowId = window:id()
                if finderWindowsCount == 0 and windowId == self.lastFinderWindowId then
                    table.insert(cleanedOrderedWindows, window)
                    finderWindowsCount = finderWindowsCount + 1
                end
            else
                table.insert(cleanedOrderedWindows, window)
            end
        end
        return cleanedOrderedWindows
    end

    obj.focusPreviousWindowForCancel = function(self)
        if self.previousWindow ~= nil then
            self:focusWindow(self.previousWindow)
        else
            self:focusWindow(self.getCachedOrderedWindowsOrFetch(self)[1])
        end
    end

    obj.focusNextWindow = function(self)
        self:focusWindow(self:refreshOrderedWindows()[2])
    end

    -- TODO: window:focus() don't work correctly, when a application has 2 windows and each windows are on different screen.
    obj.focusWindow = function(self, targetWindow)
        -- if Finder window should be focused, then focus Finder application not but the specific window.
        -- that is because Finder window is not created collectively by HammerSpoon.
        if targetWindow:application():bundleID() == FINDER_BUNDLE_ID then
            hs.application.launchOrFocusByBundleID(FINDER_BUNDLE_ID)
            return
        end

        local targetAppliation = targetWindow:application()
        local applicationMainWindow = targetAppliation:mainWindow()
        if applicationMainWindow == nil then
            return
        end

        local applicationVisibleWindows = targetAppliation:visibleWindows()
        if #applicationVisibleWindows == 1 then
            targetWindow:focus()
        else
            -- Do not need to check the screen
            -- local applicationMainWindowScreen = applicationMainWindow:screen()
            -- local applicationMainWindowScreenId = applicationMainWindowScreen:id()
            -- local targetWindowScreen = targetWindow:screen()
            -- local targetWindowScreenId = targetWindowScreen:id()
            -- if targetWindowScreenId == applicationMainWindowScreenId then

            local previousWindow = self.getCachedOrderedWindowsOrFetch(self)[1]

            -- local previousWindowScreen = previousWindow:screen()
            -- local previousWindowScreenId = previousWindowScreen:id()
            -- local targetWindowScreen = targetWindow:screen()
            -- local targetWindowScreenId = targetWindowScreen:id()

            local focusedWindow = hs.window.focusedWindow()

            -- Do not need to check the screen
            -- if targetWindowScreenId == previousWindowScreenId then
            --     -- If the target window is on the same screen as the previous window, focus it directly.
            --     targetWindow:focus()

            if focusedWindow and focusedWindow:application():pid() == targetAppliation:pid() then
                targetWindow:focus()
            else
                -- Hammerspoon bug: window:focus() don't work correctly, when a application has 2 windows and each windows are on different screen.
                -- Issue: https://github.com/Hammerspoon/hammerspoon/issues/2978

                -- This way is workaround.

                -- First focus another window of the same application, then focus the target window
                -- targetAppliation:activate(false)
                -- applicationMainWindow:focus()

                targetWindow:focus()
                targetWindow:focus()
                previousWindow:raise()
                hs.timer.doAfter(0.15, function()
                    targetWindow:focus()
                    previousWindow:raise()
                end)

                -- Another way is to move the target window to the main screen, then focus it.
                -- targetWindow:moveToScreen(applicationMainWindowScreen)
                -- targetWindow:focus()
                -- targetWindow:moveToScreen(targetWindowScreen)

                -- If you need time delay, you can use `hs.timer.doAfter`.
                -- hs.timer.doAfter(0.15, function()
                -- end)
            end
        end
    end

    return obj
end
return WindowModel
