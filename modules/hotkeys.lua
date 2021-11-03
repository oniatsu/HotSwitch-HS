local util = require("hotswitch-hs/modules/util")

local Windows = require("hotswitch-hs/modules/windows")
local SettingsProvider = require("hotswitch-hs/modules/settings_provider")
local Panel = require("hotswitch-hs/modules/panel")

-- Sometimes, some special keys don't work
local ALL_KEYS = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m",
                  "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
                  "-", "[", "]", ",", ".", "/"}

local SHIFTABLE_KEYS = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l",
                        "z", "x", "c", "v", "b", "n", "m"}

local Hotkeys = {}
Hotkeys.new = function()
    local obj = {}

    obj.isRegistrationMode = false

    obj.windows = Windows.new()

    obj.panel = Panel.new(obj.windows)
    obj.settingsProvider = SettingsProvider.new()

    obj.allHotkeys = {}

    obj.applicationWatcher = nil

    obj.create = function(self)
        if #self.allHotkeys == 0 then
            self:createSpecialKeys()
            self:createCharacterKeys(ALL_KEYS, false)
            self:createCharacterKeys(SHIFTABLE_KEYS, true)
        end
    end

    obj.enable = function(self)
        -- local checkTime = util.checkTime.new()
        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:enable()
            end)
            if status == false then
                util.log("ERROR: enabling hotkey")
                util.log(self.allHotkeys[i])
                util.log("i: " .. i)
                util.log(self.allHotkeys[i])
                util.log(err)
            end
        end
        -- checkTime:diff() -- 40ms - necessary
    end

    obj.disable = function(self)
        if self.allHotkeys == nil then
            util.log("ERROR: hotkeys.lua (obj.disable) : self.allHotkeys is null")
        end

        for i = 1, #self.allHotkeys do
            self.allHotkeys[i]:disable()
        end
    end

    obj.createSpecialKeys = function(self)
        table.insert(self.allHotkeys, hs.hotkey.new({}, "down", function() self:next() end, nil, function() self:next() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "up", function() self:previous() end, nil, function() self:previous() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "tab", function() self:next() end, nil, function() self:next() end))
        table.insert(self.allHotkeys, hs.hotkey.new({"shift"}, "tab", function() self:previous() end, nil, function() self:previous() end))
        
        table.insert(self.allHotkeys, hs.hotkey.new({}, "return", function() self:returnAction() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "space", function() self:spaceAction() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "delete", function() self:deleteAction() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "escape", function() self:escapeAction() end))
    end

    obj.next = function(self)
        self.isRegistrationMode = false

        self.panel.selectedRowCanvas.position = self:calcNextRowPosition(self.panel.selectedRowCanvas.position)

        self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
    end

    obj.previous = function(self)
        self.isRegistrationMode = false

        self.panel.selectedRowCanvas.position = self:calcPreviousRowPosition(self.panel.selectedRowCanvas.position)

        self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
    end

    obj.calcNextRowPosition = function(self, position)
        position = position + 1
        if position > #self.windows:getCachedOrderedWindowsOrFetch() then
            position = 1
        end
        return position
    end

    obj.calcPreviousRowPosition = function(self, position)
        position = position - 1
        if position <= 0 then
            position = #self.windows:getCachedOrderedWindowsOrFetch()
        end
        return position
    end

    obj.returnAction = function(self)
        self.isRegistrationMode = false

        self.focusWindow(self.windows:getCachedOrderedWindowsOrFetch()[self.panel.selectedRowCanvas.position])

        self:finish()
    end

    obj.spaceAction = function(self)
        if self.isRegistrationMode then
            self.isRegistrationMode = false
            self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
        else
            self.isRegistrationMode = true
            self.panel.selectedRowCanvas:replaceAndEmphasisSelectedRow(self.panel.selectedRowCanvas.position)
        end
    end

    obj.escapeAction = function(self)
        if self.isRegistrationMode then
            self.isRegistrationMode = false
            self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
        else
            self:focusWindowForCancel()

            self:finish()
        end
    end

    obj.deleteAction = function(self)
        self.isRegistrationMode = false
        local window = self.windows:getCachedOrderedWindowsOrFetch()[self.panel.selectedRowCanvas.position]

        local appName = window:application():name()

        local settings = self.settingsProvider.get()
        for i = 1, #settings do
            local setting = settings[i]

            if setting.app == appName then
                local windowId = window:id()

                for j = 1, #self.panel.baseCanvas.keyStatuses do
                    local keyStatus = self.panel.baseCanvas.keyStatuses[j]
                    if keyStatus.windowId == windowId then
                        local targetKey = keyStatus.key

                        for k = 0, #setting.keys do
                            if setting.keys[k] == targetKey then
                                table.remove(setting.keys, k)
                                break
                            end
                        end
                        break
                    end
                end
                break
            end
        end

        for i = 1, #settings do
            if #settings[i].keys == 0 then
                table.remove(settings, i)
                break
            end
        end

        self.settingsProvider.set(settings)

        self:open()
        self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
    end

    obj.createCharacterKeys = function(self, keys, isShiftable)
        local keybindModifier
        if isShiftable then
            keybindModifier = {"shift"}
        else
            keybindModifier = {}
        end

        for i = 1, #keys do
            local key = keys[i]

            table.insert(self.allHotkeys, hs.hotkey.new(keybindModifier, key, function()
                if isShiftable then
                    key = key:upper()
                end

                if self.isRegistrationMode then
                    self.isRegistrationMode = false

                    local window = self.windows:getCachedOrderedWindowsOrFetch()[self.panel.selectedRowCanvas.position]

                    local appName = window:application():name()

                    local hasAppSetting = false
                    local settings = self.settingsProvider.get()
                    for i = 1, #settings do
                        local setting = settings[i]

                        if setting.app == appName then
                            hasAppSetting = true

                            local windowId = window:id()

                            local targetKey
                            for j = 1, #self.panel.baseCanvas.keyStatuses do
                                local keyStatus = self.panel.baseCanvas.keyStatuses[j]
                                if keyStatus.windowId == windowId then
                                    targetKey = keyStatus.key
                                    break
                                end
                            end

                            if targetKey == nil then
                                table.insert(setting.keys, key)
                            else
                                local newKeys = {}
                                for j = 1, #setting.keys do
                                    local settingKey = setting.keys[j]
                                    if settingKey == targetKey then
                                        newKeys[j] = key
                                    else
                                        newKeys[j] = settingKey
                                    end
                                end
                                setting.keys = newKeys
                            end
                        else
                            local targetKey = key
                            for j = 1, #setting.keys do
                                local settingKey = setting.keys[j]
                                if settingKey == targetKey then
                                    table.remove(setting.keys, j)
                                    break
                                end
                            end
                        end
                    end

                    for i = 1, #settings do
                        if #settings[i].keys == 0 then
                            table.remove(settings, i)
                            break
                        end
                    end

                    if hasAppSetting == false then
                        table.insert(settings, {
                            app = appName,
                            keys = {key}
                        })
                    end

                    self.settingsProvider.set(settings)

                    self:open()
                    self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
                else
                    local targetWindow
                    for j = 1, #self.panel.baseCanvas.keyStatuses do
                        local keyStatus = self.panel.baseCanvas.keyStatuses[j]
                        if keyStatus.key == key then
                            targetWindow = keyStatus.window
                            break
                        end
                    end

                    if targetWindow ~= nil then
                        self:finish()

                        self.focusWindow(targetWindow)
                    end
                end
            end))
        end
    end

    obj.finish = function(self)
        self.panel:close()
        self:disable()
        self:unwatchAppliationDeactivated()
    end

    obj.focusWindowForCancel = function(self)
        if self.windows.previousWindow ~= nil then
            self.focusWindow(self.windows.previousWindow)
        else
            self.focusWindow(self.windows:getCachedOrderedWindowsOrFetch()[1])
        end
    end

    obj.watchAppliationDeactivated = function(self)
        if self.applicationWatcher == nil then
            self.applicationWatcher = hs.application.watcher.new(function(appName, eventType, app)
                if appName == "Hammerspoon" and eventType == hs.application.watcher.deactivated then
                    self:finish()
                end
            end)
            self.applicationWatcher:start()
        end
    end

    obj.unwatchAppliationDeactivated = function(self)
        if self.applicationWatcher ~= nil then
            self.applicationWatcher:stop()
            self.applicationWatcher = nil
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
                    -- This process is workaround way.

                    -- util.log(targetWindow:title())
                    targetWindow:focus()
                    hs.timer.doAfter(0.2, function()
                        targetWindow:focus()
                    end)
                end
            end
        end
    end

    return obj
end

return Hotkeys
