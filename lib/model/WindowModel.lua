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
            local subrole = window:subrole()
            -- AXDialog windows are never "standard" (hs.window:isStandard() is false for any
            -- non-AXStandardWindow subrole by definition), so isStandard() can't distinguish a
            -- floating tool palette (e.g. Clip Studio Paint docked panels) from a real dialog
            -- (e.g. iTerm2 Settings). Use title instead: tool palettes are typically untitled,
            -- while real dialogs/settings windows have a title.
            local isFloatingToolPanel = subrole == "AXDialog" and window:title() == ""
            if subrole ~= "AXUnknown" and subrole ~= "AXSystemDialog" and subrole ~= "" and subrole ~= "AXFloatingWindow" and not isFloatingToolPanel then
                table.insert(cleanedOrderedWindows, window)
            end
        end
        return cleanedOrderedWindows
    end

    -- windowFilter's windowVisible-subscription cache can retain stale/phantom Finder
    -- window entries (Finder doesn't always fire proper AX notifications on tab merges).
    -- A tab group itself is a single real AXWindow (its tabs are children of an internal
    -- AXTabGroup, not separate windows), so a fresh accessibility query of the app's
    -- windows gives the true, currently-correct window list. Use that instead of trying
    -- to dedup whatever the filter cache handed us.
    --
    -- Deliberately not cached: caching this (tried and verified) reintroduces the same
    -- staleness problem at a different layer. This query is scoped to a single already-
    -- identified app (not a system-wide enumeration across all apps, which is why
    -- windowFilter itself needs the subscribe() workaround), so re-querying every call
    -- is cheap enough.
    obj.getFreshFinderWindows = function()
        local app = hs.application.get(FINDER_BUNDLE_ID)
        if app == nil then
            return {}
        end

        local freshWindows = {}
        for _, window in ipairs(app:allWindows()) do
            if window:subrole() == "AXStandardWindow" then
                table.insert(freshWindows, window)
            end
        end

        -- Sort by id, not by focus/AXMain: auto-generated keys are assigned by array
        -- position (see KeyStatusModel), so this order must stay stable regardless of
        -- which Finder window currently has focus, or the same key would end up
        -- pointing at a different window every time focus changes.
        table.sort(freshWindows, function(a, b)
            return a:id() < b:id()
        end)

        return freshWindows
    end

    obj.removeUnusableFinderWindows = function(self, orderedWindows)
        local cleanedOrderedWindows = {}
        local insertedFreshFinderWindows = false
        for i = 1, #orderedWindows do
            local window = orderedWindows[i]
            local bundleID = window:application():bundleID()
            if bundleID == FINDER_BUNDLE_ID then
                if not insertedFreshFinderWindows then
                    insertedFreshFinderWindows = true
                    for _, freshWindow in ipairs(self.getFreshFinderWindows()) do
                        table.insert(cleanedOrderedWindows, freshWindow)
                    end
                end
            else
                table.insert(cleanedOrderedWindows, window)
            end
        end
        return cleanedOrderedWindows
    end

    obj.removeUnusableFinderWindowsForCreatedOrderedWindows = function(self, orderedWindows)
        return self:removeUnusableFinderWindows(orderedWindows)
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

    obj.focusPreviousWindow = function(self)
        local orderedWindows = self:refreshOrderedWindows()
        self:focusWindow(orderedWindows[#orderedWindows])
    end

    -- TODO: window:focus() don't work correctly, when a application has 2 windows and each windows are on different screen.
    obj.focusWindow = function(self, targetWindow)
        -- Finder: use raise() + activate(true) instead of focus(). focus() calls becomeMain()
        -- internally, which makes Finder jump to the first tab of the window's tab group
        -- instead of preserving the tab the user actually selected.
        if targetWindow:application():bundleID() == FINDER_BUNDLE_ID then
            targetWindow:raise()
            targetWindow:application():activate(true)
            return
        end

        local targetAppliation = targetWindow:application()
        local applicationMainWindow = targetAppliation:mainWindow()
        if applicationMainWindow == nil then
            -- Some windows never become AXMain, so application:mainWindow() returns nil
            -- for them. Fall back to a direct raise() + activate() instead of silently
            -- doing nothing.
            targetWindow:raise()
            targetAppliation:activate(true)
            return
        end

        local applicationVisibleWindows = targetAppliation:visibleWindows()
        if #applicationVisibleWindows == 1 then
            targetWindow:focus()
        else
            -- Workaround for Hammerspoon bug:
            -- Hammerspoon bug: window:focus() don't work correctly, when a application has 2 windows and each windows are on different screen.
            -- Issue: https://github.com/Hammerspoon/hammerspoon/issues/370
            -- Other similar window switch apps solve this problem by using a private API.
            -- Hammerspoon does not use the private API and therefore cannot solve this problem.

            -- At the point when raising a window is necessary,
            -- there can be a cachedWindows-like difference from the actual window alignment,
            -- which can lead to unnecessary raising a window when refocusing a window in multi-window applications on multi-screens.
            -- This cannot be prevented as long as it raised a window.
            -- However, this situation is very limited, so it is acceptable.

            -- Non-standard windows (e.g. Settings/Preferences panels with subrole AXDialog or AXFloating)
            -- don't respond correctly to focus() because becomeMain() causes the app to redirect focus
            -- to its main window. Use raise() + activate(true) instead to avoid this side-effect.
            -- This must be checked before the same-app/cross-app branching below: it applies
            -- regardless of which app currently has focus, not just when switching within the
            -- same app (previously this check only ran in that one branch, so focusing a dialog
            -- directly from a different app fell through to the buggy focus() path below).
            if targetWindow:subrole() ~= "AXStandardWindow" then
                targetWindow:raise()
                targetAppliation:activate(true)
                return
            end

            local cachedWindows = self:getCachedOrderedWindowsOrFetch()
            local previousWindow = cachedWindows[1]

            if previousWindow:application():pid() == targetAppliation:pid() then
                if previousWindow:id() ~= targetWindow:id() then
                    -- First focus another window of the same application, then focus the target window
                    targetWindow:focus()
                    hs.timer.doAfter(0.01, function()
                        targetWindow:focus()
                    end)
                else
                    -- Find the first window on a different screen to raise
                    local targetWindowScreenId = targetWindow:screen():id()
                    local windowToRaise = nil
                    for i = 1, #cachedWindows do
                        local window = cachedWindows[i]
                        if targetAppliation:pid() ~= window:application():pid() and window:screen():id() ~= targetWindowScreenId then
                            windowToRaise = window
                            break
                        end
                    end
                
                    -- First focus another window of the same application, then focus the target window
                    targetWindow:focus()
                    hs.timer.doAfter(0.01, function()
                        targetWindow:focus()

                        -- Raise the first window on a different screen
                        if windowToRaise then
                            hs.timer.doAfter(0.01, function()
                                windowToRaise:raise()
                            end)
                        end
                    end)
                end
            else
                if previousWindow:screen():id() == targetWindow:screen():id() then
                    -- Find the first window on a different screen to raise
                    local targetWindowScreenId = targetWindow:screen():id()
                    local windowToRaise = nil
                    for i = 1, #cachedWindows do
                        local window = cachedWindows[i]
                        if targetAppliation:pid() ~= window:application():pid() and window:screen():id() ~= targetWindowScreenId then
                            windowToRaise = window
                            break
                        end
                    end
                
                    -- First focus another window of the same application, then focus the target window
                    targetWindow:focus()
                    hs.timer.doAfter(0.01, function()
                        targetWindow:focus()

                        -- Raise the first window on a different screen
                        if windowToRaise then
                            hs.timer.doAfter(0.01, function()
                                windowToRaise:raise()
                            end)
                        end
                    end)
                else
                    -- First focus another window of the same application, then focus the target window
                    targetWindow:focus()
                    hs.timer.doAfter(0.01, function()
                        targetWindow:focus()

                        -- Raise the previous window
                        hs.timer.doAfter(0.01, function()
                            previousWindow:raise()
                        end)
                    end)
                end
            end
        end
    end

    return obj
end
return WindowModel
