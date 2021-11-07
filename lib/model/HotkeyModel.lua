local Debugger = require("hotswitch-hs/lib/common/Debugger")
local Model = require("hotswitch-hs/lib/model/Model")
local KeyConstants = require("hotswitch-hs/lib/common/KeyConstants")
local ToastView = require("hotswitch-hs/lib/view/ToastView")

-- TODO: It's not good to use panelLayoutView in this model.

local HotkeyModel = {}
HotkeyModel.new = function(windowModel, settingModel, keyStatusModel, appWatchModel)
    local obj = Model.new()

    obj.windowModel = windowModel
    obj.settingModel = settingModel
    obj.keyStatusModel = keyStatusModel
    obj.appWatchModel = appWatchModel

    obj.allHotkeys = {}

    obj.createHotkeys = function(self, panelLayoutView)
        if #self.allHotkeys == 0 then
            self:createSpecialKeys(panelLayoutView)
            self:createCharacterKeys(KeyConstants.ALL_KEYS, false, panelLayoutView)
            self:createCharacterKeys(KeyConstants.SHIFTABLE_KEYS, true, panelLayoutView)
        end
    end

    obj.enableHotkeys = function(self)
        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:enable()
            end)
            if status == false then
                Debugger.log("ERROR: enabling hotkey")
            end
        end
    end

    obj.disableHotkeys = function(self)
        for i = 1, #self.allHotkeys do
            local status, err = pcall(function()
                self.allHotkeys[i]:disable()
            end)
            if status == false then
                Debugger.log("ERROR: disabling hotkey")
            end
        end
    end

    obj.createSpecialKeys = function(self, panelLayoutView)
        table.insert(self.allHotkeys, hs.hotkey.new({}, "down", function()
            panelLayoutView:selectNextRow(self.windowModel)
        end, nil, function()
            panelLayoutView:selectNextRow(self.windowModel)
        end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "up", function()
            panelLayoutView:selectPreviousRow(self.windowModel)
        end, nil, function()
            panelLayoutView:selectPreviousRow(self.windowModel)
        end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "tab", function()
            panelLayoutView:selectNextRow(self.windowModel)
        end, nil, function()
            panelLayoutView:selectNextRow(self.windowModel)
        end))
        table.insert(self.allHotkeys, hs.hotkey.new({"shift"}, "tab", function()
            panelLayoutView:selectPreviousRow(self.windowModel)
        end, nil, function()
            panelLayoutView:selectPreviousRow(self.windowModel)
        end))
        
        table.insert(self.allHotkeys, hs.hotkey.new({}, "return", function() self:returnAction(panelLayoutView) end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "space", function() self:spaceAction(panelLayoutView) end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "delete", function() self:deleteAction(panelLayoutView) end))
        table.insert(self.allHotkeys, hs.hotkey.new({}, "escape", function() self:escapeAction(panelLayoutView) end))
    end

    obj.returnAction = function(self, panelLayoutView)
        self.isRegistrationMode = false

        self.windowModel.focusWindow(self.windowModel:getCachedOrderedWindowsOrFetch()[panelLayoutView.selectedRowCanvasView.position])

        self:finish(panelLayoutView)
    end

    obj.spaceAction = function(self, panelLayoutView)
        if self.isRegistrationMode then
            self.isRegistrationMode = false
            panelLayoutView:unemphasisRow()
        else
            self.isRegistrationMode = true
            panelLayoutView:emphasisRow()
        end
    end

    obj.escapeAction = function(self, panelLayoutView)
        if self.isRegistrationMode then
            self.isRegistrationMode = false
            panelLayoutView:unemphasisRow()
        else
            self.windowModel:focusPreviousWindowForCancel()

            self:finish(panelLayoutView)
        end
    end

    obj.deleteAction = function(self, panelLayoutView)
        self.isRegistrationMode = false
        local window = self.windowModel:getCachedOrderedWindowsOrFetch()[panelLayoutView:getSelectedRowPosition()]

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
        panelLayoutView:show()
        panelLayoutView:unemphasisRow()
    end

    obj.createCharacterKeys = function(self, keys, isShiftable, panelLayoutView)
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

                    local window = self.windowModel:getCachedOrderedWindowsOrFetch()[panelLayoutView.selectedRowCanvasView.position]
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
                    panelLayoutView:show()
                    panelLayoutView:unemphasisRow()
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
                        self:finish(panelLayoutView)

                        self.windowModel.focusWindow(targetWindow)
                    end
                end
            end))
        end
    end

    obj.finish = function(self, panelLayoutView)
        panelLayoutView:hide()
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
return HotkeyModel