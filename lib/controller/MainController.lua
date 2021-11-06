local Debugger = require("hotswitch-hs/lib/common/Debugger")
local KeyConstants = require("hotswitch-hs/lib/common/KeyConstants")
local WindowModel = require("hotswitch-hs/lib/model/WindowModel")
local SettingsModel = require("hotswitch-hs/lib/model/SettingModel")
local PanelLayoutView = require("hotswitch-hs/lib/view/PanelLayoutView")

local MainController = {}
MainController.new = function()
    local obj = {}

    obj.isRegistrationMode = false

    obj.windows = WindowModel.new()

    obj.panel = PanelLayoutView.new(obj.windows)
    obj.settingmodel = SettingsModel.new()

    obj.allHotkeys = {}

    obj.applicationWatcher = nil

    obj.create = function(self)
        if #self.allHotkeys == 0 then
            self:createSpecialKeys()
            self:createCharacterKeys(KeyConstants.ALL_KEYS, false)
            self:createCharacterKeys(KeyConstants.SHIFTABLE_KEYS, true)
        end

        self.panel.baseCanvas:setClickCallback(function(position)
            self.focusWindow(self.windows:getCachedOrderedWindowsOrFetch()[position])
            self:finish()
        end)
    end

    obj.enable = function(self)
        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:enable()
            end)
            if status == false then
                Debugger.log("ERROR: enabling hotkey")
            end
        end
    end

    obj.disable = function(self)
        if self.allHotkeys == nil then
            Debugger.log("ERROR: hotkeys.lua (obj.disable) : self.allHotkeys is null")
        end

        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:disable()
            end)
            if status == false then
                Debugger.log("ERROR: disabling hotkey")
            end
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

        local settings = self.settingmodel.get()
        for i = 1, #settings do
            local setting = settings[i]

            if setting.app == appName then
                local windowId = window:id()

                for j = 1, #self.panel.baseCanvas.registeredKeyStatuses do
                    local keyStatus = self.panel.baseCanvas.registeredKeyStatuses[j]
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

        self.settingmodel.set(settings)
        self.panel.baseCanvas:resetAutoGeneratedKeys()

        self.panel:open()
        self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
    end

    obj.checkTableHasTheValue = function(table, value)
        for i, tableValue in ipairs(table) do
            if tableValue == value then
                return true
            end
        end
        return false
    end

    obj.getIndexOfTableHavingTheValue = function(table, value)
        for i, tableValue in ipairs(table) do
            if tableValue == value then
                return i
            end
        end
        return 0
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
                    local windowId = window:id()

                    local appName = window:application():name()

                    local hasAppSetting = false
                    local settings = self.settingmodel.get()
                    for i = 1, #settings do
                        local setting = settings[i]

                        if setting.app == appName then
                            hasAppSetting = true

                            local targetKey
                            for j = 1, #self.panel.baseCanvas.registeredKeyStatuses do
                                local keyStatus = self.panel.baseCanvas.registeredKeyStatuses[j]
                                if keyStatus.windowId == windowId then
                                    targetKey = keyStatus.key
                                    break
                                end
                            end

                            if targetKey == nil then
                                if self.checkTableHasTheValue(setting.keys, key) then
                                    -- It cannot find position to register the key.
                                    self.panel.baseCanvas:toast("NOTICE: The key is already registered on the same app.")
                                else
                                    table.insert(setting.keys, key)
                                end
                            else
                                local newKeys = {}
                                if self.checkTableHasTheValue(setting.keys, key) then
                                    local sameValueIndex = self.getIndexOfTableHavingTheValue(setting.keys, key)
                                    for j = 1, #setting.keys do
                                        local settingKey = setting.keys[j]
                                        if settingKey == targetKey then
                                            newKeys[j] = key
                                        elseif j == sameValueIndex then
                                            newKeys[j] = targetKey
                                        else
                                            newKeys[j] = settingKey
                                        end
                                    end
                                else
                                    for j = 1, #setting.keys do
                                        local settingKey = setting.keys[j]
                                        if settingKey == targetKey then
                                            newKeys[j] = key
                                        else
                                            newKeys[j] = settingKey
                                        end
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

                    self.settingmodel.set(settings)
                    self.panel.baseCanvas:resetAutoGeneratedKeys()

                    self.panel:open()
                    self.panel.selectedRowCanvas:replaceSelectedRow(self.panel.selectedRowCanvas.position)
                else
                    local targetWindow
                    for j = 1, #self.panel.baseCanvas.registeredAndAutoGeneratedKeyStatuses do
                        local keyStatus = self.panel.baseCanvas.registeredAndAutoGeneratedKeyStatuses[j]
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
                    -- Issue: https://github.com/Hammerspoon/hammerspoon/issues/2978

                    -- This process is workaround way.

                    -- util.log(targetWindow:title())
                    targetWindow:focus()
                    hs.timer.doAfter(0.15, function()
                        targetWindow:focus()
                    end)
                end
            end
        end
    end

    return obj
end
return MainController