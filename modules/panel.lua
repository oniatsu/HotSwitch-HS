local canvas = require("hs.canvas")

local util = require("hotswitch-hs/modules/util")

local BaseCanvas = require("hotswitch-hs/modules/base_canvas")
local SelectedRowCanvas = require("hotswitch-hs/modules/selected_row_canvas")
local SettingsProvider = require("hotswitch-hs/modules/settings_provider")

local Panel = {}

local defaultRowPosition = 2

Panel.new = function(windows)
    local obj = {}

    obj.isOpen = false
    obj.baseCanvas = BaseCanvas.new(canvas, windows)
    obj.selectedRowCanvas = SelectedRowCanvas.new(canvas, windows, defaultRowPosition)
    obj.settingsProvider = SettingsProvider.new()

    obj.open = function(self)
        if self.isOpen == false then
            self.isOpen = true
            self.selectedRowCanvas.position = defaultRowPosition
        end

        -- local checkTime = util.checkTime.new(false)
        self.baseCanvas:show()
        -- checkTime:diff() -- 20ms - necessary
        self.selectedRowCanvas:createSelectedRow()
        -- checkTime:diff() -- 20ms - necessary

        self.selectedRowCanvas:replaceSelectedRow(self.selectedRowCanvas.position)
        -- checkTime:diff() -- 15ms - necessary
    end

    obj.close = function(self)
        self.isOpen = false

        self.baseCanvas:hide()
        self.selectedRowCanvas:hide()
    end

    return obj
end

return Panel
