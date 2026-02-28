local Debugger = require("hotswitch-hs/lib/common/Debugger")
local TimeChecker = require("hotswitch-hs/lib/common/TimeChecker")
local Updater = require("hotswitch-hs/lib/common/Updater")
local Controller = require("hotswitch-hs/lib/controller/Controller")
local WindowModel = require("hotswitch-hs/lib/model/WindowModel")
local SettingsModel = require("hotswitch-hs/lib/model/SettingModel")
local KeyStatusModel = require("hotswitch-hs/lib/model/KeyStatusModel")
local AppWatchModel = require("hotswitch-hs/lib/model/AppWatchModel")
local PanelLayoutView = require("hotswitch-hs/lib/view/PanelLayoutView")
local HotkeyController = require("hotswitch-hs/lib/controller/HotkeyController")
local FrameCulculator = require("hotswitch-hs/lib/common/FrameCulculator")

local MainController = {}
MainController.new = function()
    local obj = Controller.new()

    obj.isRegistrationMode = false
    obj.openedByOpenOrSelectNext = false
    obj.showPanelTimer = nil
    obj.modifierEventTap = nil

    obj.windowModel = WindowModel.new()
    obj.settingModel = SettingsModel.new()
    obj.keyStatusModel = KeyStatusModel.new(obj.windowModel, obj.settingModel)
    obj.appWatchModel = AppWatchModel.new()

    obj.panelLayoutView = PanelLayoutView.new(obj.windowModel, obj.settingModel, obj.keyStatusModel)

    obj.hotkeyController = HotkeyController.new(obj)

    obj.panelLayoutView:setClickCallback(function(position)
        obj.windowModel:focusWindow(obj.windowModel:getCachedOrderedWindowsOrFetch()[position])
        obj:finish()
    end)

    obj.open = function(self)
        -- local t1 = TimeChecker.new()

        self.windowModel.previousWindow = hs.window.frontmostWindow()

        -- Enable hotkeys before refresh windows,
        -- because refreshing windows is sometimes slow and take time.
        -- local t2 = TimeChecker.new()
        self.hotkeyController:enableHotkeys()
        -- t2:diff("MainController:enableHotkeys")
        self.panelLayoutView:activateHammerspoonWindow()
        -- t2:diff("MainController:activateHammerspoonWindow")

        self.windowModel:refreshOrderedWindows()
        -- t2:diff("MainController:refreshOrderedWindows")
        self.keyStatusModel:createKeyStatuses()
        -- t2:diff("MainController:createKeyStatuses")
        self.panelLayoutView:show()
        -- t2:diff("MainController:show")
        self.appWatchModel:watchAppliationDeactivated(function() self:finish() end)
        -- t2:diff("MainController:watchAppliationDeactivated")

        -- t1:diff("All")
    end

    obj.openOrClose = function(self)
        if self.panelLayoutView.isOpen then
            self.windowModel:focusPreviousWindowForCancel()
            self:finish()
        else
            self:open()
        end
    end

    local function openOrSelectRowHelper(self, selectFn)
        if self.panelLayoutView.isOpen then
            selectFn()
        elseif self.showPanelTimer then
            -- While deferred-open is pending, additional cycle keys should
            -- still move selection.
            selectFn()
        else
            self.openedByOpenOrSelectNext = true

            -- Prepare data immediately (needed by focusOpenOrSelectNextWindow)
            self.windowModel.previousWindow = hs.window.frontmostWindow()
            self.windowModel:refreshOrderedWindows()
            self.keyStatusModel:createKeyStatuses()
            self.panelLayoutView:resetSelectedRowPosition()

            -- Watch for app deactivation immediately, even during the timer delay
            self.appWatchModel:watchAppliationDeactivated(function() self:finish() end)

            -- Defer panel rendering; if focusOpenOrSelectNextWindow is called first, skip it
            -- Stop any previously scheduled timer to avoid leaked timers opening the panel late.
            if self.showPanelTimer then
                self.showPanelTimer:stop()
                self.showPanelTimer = nil
            end
            self.showPanelTimer = hs.timer.doAfter(0.1, function()
                self.showPanelTimer = nil
                self.hotkeyController:enableHotkeys()
                self.panelLayoutView:activateHammerspoonWindow()
                self.panelLayoutView:show()
            end)
        end
    end

    obj.openOrSelectNext = function(self)
        openOrSelectRowHelper(self, function()
            self.panelLayoutView:selectNextRow(self.windowModel)
        end)
    end

    obj.openOrSelectPrevious = function(self)
        openOrSelectRowHelper(self, function()
            self.panelLayoutView:selectPreviousRow(self.windowModel)
        end)
    end

    obj.focusOpenOrSelectNextWindow = function(self)
        if not self.openedByOpenOrSelectNext then return end

        -- Cancel deferred panel rendering if still pending
        if self.showPanelTimer then
            self.showPanelTimer:stop()
            self.showPanelTimer = nil
        end

        self.windowModel:focusWindow(self.windowModel:getCachedOrderedWindowsOrFetch()[
            self.panelLayoutView:getSelectedRowPosition()])
        self:finish()
    end

    obj.switchToNextWindow = function(self)
        self.windowModel:focusNextWindow()
    end

    obj.switchToPreviousWindow = function(self)
        self.windowModel:focusPreviousWindow()
    end

    obj.clearSettings = function(self)
        self.settingModel.clear()
    end

    obj.setAutoGeneratedKeys = function(self, specifiedAutoGeneratedKeys)
        self.keyStatusModel:setSpecifiedAutoGeneratedKeys(specifiedAutoGeneratedKeys)
        self.keyStatusModel:resetAutoGeneratedKeys()
    end

    obj.enableAllSpaceWindows = function(self)
        self.windowModel:enableAllSpaceWindows()
    end

    obj.finish = function(self)
        if self.showPanelTimer then
            self.showPanelTimer:stop()
            self.showPanelTimer = nil
        end
        if self.modifierEventTap then
            self.modifierEventTap:stop()
            self.modifierEventTap = nil
        end
        self.openedByOpenOrSelectNext = false
        self.panelLayoutView:hide()
        self.hotkeyController:disableHotkeys()
        self.appWatchModel:unwatchAppliationDeactivated()
    end

    -- Map from hs.hotkey modifier names to hs.eventtap flag names
    local modifierFlagMap = {
        option  = "alt",
        command = "cmd",
        control = "ctrl",
        shift   = "shift",
        alt     = "alt",
        cmd     = "cmd",
        ctrl    = "ctrl",
    }

    -- Opens/cycles the panel on press, and focuses the selected window when the
    -- modifier is released. Also handles key repeat internally via eventtap, so
    -- the caller does not need to pass a repeatFn.
    -- Pass {"option", "shift"} to go in reverse (previous); {"option"} to go forward (next).
    -- Usage in init.lua:
    --   hs.hotkey.bind({"option"}, "tab",
    --       function() hotswitchHs.openWithModifier({"option"}, "tab") end)
    --   hs.hotkey.bind({"option", "shift"}, "tab",
    --       function() hotswitchHs.openWithModifier({"option", "shift"}, "tab") end)
    obj.openWithModifier = function(self, modifiers, key)
        self:openOrSelectNext()

        if self.modifierEventTap == nil then
            self.modifierEventTap = hs.eventtap.new(
                { hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown },
                function(event)
                    if event:getType() == hs.eventtap.event.types.keyDown then
                        if event:getKeyCode() == hs.keycodes.map[key] then
                            if event:getFlags().shift then
                                self.panelLayoutView:selectPreviousRow(self.windowModel)
                            else
                                self.panelLayoutView:selectNextRow(self.windowModel)
                            end
                            return true  -- consume the repeat keyDown
                        end
                    else
                        -- Release when non-shift modifiers are all released.
                        -- Shift only controls direction, so it does not keep the panel open.
                        local flags = event:getFlags()
                        local anyHeld = false
                        for _, mod in ipairs(modifiers) do
                            if mod ~= "shift" and flags[modifierFlagMap[mod] or mod] then
                                anyHeld = true
                                break
                            end
                        end
                        if not anyHeld then
                            self.modifierEventTap:stop()
                            self.modifierEventTap = nil
                            self:focusOpenOrSelectNextWindow()
                        end
                    end
                end
            )
            self.modifierEventTap:start()
        end
    end

    obj.checkUpdate = function()
        Updater.check();
    end

    obj.addJapaneseKeyboardLayoutSymbolKeys = function(self)
        self.hotkeyController:addJapaneseKeyboardLayoutSymbolKeys()
    end

    obj.setPanelToAlwaysShowOnPrimaryScreen = function(self)
        FrameCulculator.setShowingOnMainScreen(false)
    end

    obj.addKeyModifier = function(self)
        self.hotkeyController:addKeyModifier()
    end

    ---  * loglevel - can be 'nothing', 'error', 'warning', 'info', 'debug', or 'verbose', or a corresponding number
    ---    between 0 and 5
    obj.setLogLevel = function(self, logLevel)
        hs.logger.setModulesLogLevel(logLevel)
        Debugger.setLogLevel(logLevel)
    end

    --- init
    obj:setLogLevel("nothing")
    obj.hotkeyController:createHotkeys()
    obj.keyStatusModel:resetAutoGeneratedKeys()
    obj.windowModel:init()

    return obj
end
return MainController
