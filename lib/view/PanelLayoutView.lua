local canvas = require("hs.canvas")

local Debugger = require("hotswitch-hs/lib/common/Debugger")
local View = require("hotswitch-hs/lib/view/View")
local BaseCanvasView = require("hotswitch-hs/lib/view/BaseCanvasView")
local SelectedRowCanvasView = require("hotswitch-hs/lib/view/SelectedRowCanvasView")

local defaultRowPosition = 2

local PanelLayoutView = {}
PanelLayoutView.new = function(windowModel, settingModel)
    local obj = View.new()

    obj.isOpen = false
    obj.baseCanvasView = BaseCanvasView.new(canvas, windowModel, settingModel)
    obj.selectedRowCanvasView = SelectedRowCanvasView.new(canvas, windowModel, defaultRowPosition)
    obj.settingModel = settingModel

    obj.show = function(self)
        if self.isOpen == false then
            self.isOpen = true
            self.selectedRowCanvasView.position = defaultRowPosition
        end

        -- local checkTime = util.checkTime.new(false)
        self.baseCanvasView:show()
        -- checkTime:diff() -- 20ms - necessary
        self.selectedRowCanvasView:createSelectedRow()
        -- checkTime:diff() -- 20ms - necessary

        self.selectedRowCanvasView:replaceSelectedRow(self.selectedRowCanvasView.position)
        -- checkTime:diff() -- 15ms - necessary
    end

    obj.hide = function(self)
        self.isOpen = false

        self.baseCanvasView:hide()
        self.selectedRowCanvasView:hide()
    end

    return obj
end

return PanelLayoutView
