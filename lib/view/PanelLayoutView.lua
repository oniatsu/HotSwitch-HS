local canvas = require("hs.canvas")

local util = require("hotswitch-hs/lib/common/util")
local View = require("hotswitch-hs/lib/view/View")
local BaseCanvasView = require("hotswitch-hs/lib/view/BaseCanvasView")
local SelectedRowCanvasView = require("hotswitch-hs/lib/view/SelectedRowCanvasView")
local SettingModel = require("hotswitch-hs/lib/model/SettingModel")

local defaultRowPosition = 2

local PanelLayoutView = {}
PanelLayoutView.new = function(windows)
    local obj = View.new()

    obj.isOpen = false
    obj.baseCanvas = BaseCanvasView.new(canvas, windows)
    obj.selectedRowCanvas = SelectedRowCanvasView.new(canvas, windows, defaultRowPosition)
    obj.settingsProvider = SettingModel.new()

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

return PanelLayoutView
