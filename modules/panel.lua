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

        -- local t1 = hs.timer.secondsSinceEpoch() * 1000
        self.baseCanvas:show()
        -- local t2 = hs.timer.secondsSinceEpoch() * 1000
        self.selectedRowCanvas:createSelectedRow()
        -- local t3 = hs.timer.secondsSinceEpoch() * 1000

        self.selectedRowCanvas:replaceSelectedRow(self.selectedRowCanvas.position)
        -- local t4 = hs.timer.secondsSinceEpoch() * 1000

        -- utils.log(t2-t1) -- 130ms -> 90ms -> 30ms
        -- utils.log(t3-t2) -- 50ms -> 2ms
        -- utils.log(t4-t3) -- 10ms -> 4ms
    end

    obj.close = function(self)
        self.isOpen = false

        self.baseCanvas:hide()
        self.selectedRowCanvas:hide()
    end

    return obj
end

return Panel