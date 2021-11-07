local Debugger = require("hotswitch-hs/lib/common/Debugger")
local Controller = require("hotswitch-hs/lib/controller/Controller")
local KeyConstants = require("hotswitch-hs/lib/common/KeyConstants")
local ToastView = require("hotswitch-hs/lib/view/ToastView")

local HotkeyController = {}
HotkeyController.new = function(mainController)
    local obj = Controller.new()

    obj.windowModel = mainController.windowModel
    obj.settingModel = mainController.settingModel
    obj.keyStatusModel = mainController.keyStatusModel
    obj.appWatchModel = mainController.appWatchModel
    obj.panelLayoutView = mainController.panelLayoutView

    obj.allHotkeys = {}

    obj.createHotkeys = function(self)
        if #self.allHotkeys == 0 then
            self:createSpecialKeys()
            self:createCharacterKeys(KeyConstants.ALL_KEYS, false)
            self:createCharacterKeys(KeyConstants.SHIFTABLE_KEYS, true)
        end
    end

    obj.enableHotkeys = function(self)
        local hasError = false
        local lastError
        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:enable()
            end)
            if status == false then
                hasError = true
                lastError = err
            end
        end
        if hasError then
            Debugger.log("ERROR (enable Hotkeys) : " .. lastError)
        end
    end

    obj.disableHotkeys = function(self)
        local hasError = false
        local lastError
        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:disable()
            end)
            if status == false then
                hasError = true
                lastError = err
            end
        end
        if hasError then
            Debugger.log("ERROR (disable Hotkeys) : " .. lastError)
        end
    end

    obj.createSpecialKeys = function(self)
        table.insert(self.allHotkeys, hs.hotkey.new({}, "down", function()
            self.panelLayoutView:selectNextRow(self.windowModel)
        end, nil, function()
            self.panelLayoutView:selectNextRow(self.windowModel)
        end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "up", function()
            self.panelLayoutView:selectPreviousRow(self.windowModel)
        end, nil, function()
            self.panelLayoutView:selectPreviousRow(self.windowModel)
        end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "tab", function()
            self.panelLayoutView:selectNextRow(self.windowModel)
        end, nil, function()
            self.panelLayoutView:selectNextRow(self.windowModel)
        end))
        table.insert(self.allHotkeys, hs.hotkey.new({"shift"}, "tab", function()
            self.panelLayoutView:selectPreviousRow(self.windowModel)
        end, nil, function()
            self.panelLayoutView:selectPreviousRow(self.windowModel)
        end))
        
        table.insert(self.allHotkeys, hs.hotkey.new({}, "return", function() self:returnAction() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "space", function() self:spaceAction() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "delete", function() self:deleteAction() end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "escape", function() self:escapeAction() end))
    end

    obj.returnAction = function(self)
        self.isRegistrationMode = false

        self.windowModel.focusWindow(self.windowModel:getCachedOrderedWindowsOrFetch()[self.panelLayoutView.selectedRowCanvasView.position])

        self:finish()
    end

    obj.spaceAction = function(self)
        if self.isRegistrationMode then
            self.isRegistrationMode = false
            self.panelLayoutView:unemphasisRow()
        else
            self.isRegistrationMode = true
            self.panelLayoutView:emphasisRow()
        end
    end

    obj.escapeAction = function(self)
        if self.isRegistrationMode then
            self.isRegistrationMode = false
            self.panelLayoutView:unemphasisRow()
        else
            self.windowModel:focusPreviousWindowForCancel()

            self:finish()
        end
    end

    obj.deleteAction = function(self)
        self.isRegistrationMode = false
        local window = self.windowModel:getCachedOrderedWindowsOrFetch()[self.panelLayoutView:getSelectedRowPosition()]

        local appName = window:application():name()

        local settings = self.settingModel.get()
        for i = 1, #settings do
            local setting = settings[i]

            if setting.app == appName then
                local windowId = window:id()

                for j = 1, #self.keyStatusModel.registeredKeyStatuses do
                    local keyStatus = self.keyStatusModel.registeredKeyStatuses[j]
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

        self.settingModel.set(settings)
        self.keyStatusModel:resetAutoGeneratedKeys()

        self.keyStatusModel:createKeyStatuses()
        self.panelLayoutView:show()
        self.panelLayoutView:unemphasisRow()
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

                    local window = self.windowModel:getCachedOrderedWindowsOrFetch()[self.panelLayoutView.selectedRowCanvasView.position]
                    local windowId = window:id()

                    local appName = window:application():name()

                    local hasAppSetting = false
                    local settings = self.settingModel.get()
                    for i = 1, #settings do
                        local setting = settings[i]

                        if setting.app == appName then
                            hasAppSetting = true

                            local targetKey
                            for j = 1, #self.keyStatusModel.registeredKeyStatuses do
                                local keyStatus = self.keyStatusModel.registeredKeyStatuses[j]
                                if keyStatus.windowId == windowId then
                                    targetKey = keyStatus.key
                                    break
                                end
                            end

                            if targetKey == nil then
                                if self.checkTableHasTheValue(setting.keys, key) then
                                    -- It cannot find position to register the key.
                                    ToastView.new(self.windowModel:getCachedOrderedWindowsOrFetch()):toast("NOTICE: The key is already registered on the same app.")
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

                    self.settingModel.set(settings)
                    self.keyStatusModel:resetAutoGeneratedKeys()

                    self.keyStatusModel:createKeyStatuses()
                    self.panelLayoutView:show()
                    self.panelLayoutView:unemphasisRow()
                else
                    local targetWindow
                    for j = 1, #self.keyStatusModel.registeredAndAutoGeneratedKeyStatuses do
                        local keyStatus = self.keyStatusModel.registeredAndAutoGeneratedKeyStatuses[j]
                        if keyStatus.key == key then
                            targetWindow = keyStatus.window
                            break
                        end
                    end

                    if targetWindow ~= nil then
                        self:finish()

                        self.windowModel.focusWindow(targetWindow)
                    end
                end
            end))
        end
    end

    obj.finish = function(self)
        self.panelLayoutView:hide()
        self:disableHotkeys()
        self.appWatchModel:unwatchAppliationDeactivated()
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

    return obj
end
return HotkeyController