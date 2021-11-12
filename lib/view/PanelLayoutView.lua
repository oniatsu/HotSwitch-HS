local canvas = require("hs.canvas")

local Debugger = require("hotswitch-hs/lib/common/Debugger")
local TimeChecker = require("hotswitch-hs/lib/common/TimeChecker")
local View = require("hotswitch-hs/lib/view/View")
local BaseCanvasView = require("hotswitch-hs/lib/view/BaseCanvasView")
local SelectedRowCanvasView = require("hotswitch-hs/lib/view/SelectedRowCanvasView")

local defaultRowPosition = 2

local PanelLayoutView = {}
PanelLayoutView.new = function(windowModel, settingModel, keyStatusModel)
    local obj = View.new()

    obj.isOpen = false
    obj.baseCanvasView = BaseCanvasView.new(windowModel, settingModel, keyStatusModel)
    obj.selectedRowCanvasView = SelectedRowCanvasView.new(windowModel, defaultRowPosition)
    obj.settingModel = settingModel

    obj.show = function(self)
        if self.isOpen == false then
            self.isOpen = true
            self.selectedRowCanvasView.position = defaultRowPosition
        end

        local t = TimeChecker.new()
        self.baseCanvasView:show()
        t:diff("PanelLayoutView:baseCanvasView:show")
        self.selectedRowCanvasView:createSelectedRow()
        t:diff("PanelLayoutView:selectedRowCanvasView:createSelectedRow")

        self.selectedRowCanvasView:replaceSelectedRow()
        t:diff("PanelLayoutView:selectedRowCanvasView:replaceSelectedRow")
    end

    obj.hide = function(self)
        self.isOpen = false

        self.baseCanvasView:hide()
        self.selectedRowCanvasView:hide()
    end

    obj.getSelectedRowPosition = function(self)
        return self.selectedRowCanvasView.position
    end
    
    obj.selectNextRow = function(self, windowModel)
        self.selectedRowCanvasView:next(windowModel)
    end

    obj.selectPreviousRow = function(self, windowModel)
        self.selectedRowCanvasView:previous(windowModel)
    end

    obj.unemphasisRow = function(self)
        self.selectedRowCanvasView:replaceSelectedRow()
    end

    obj.emphasisRow = function(self)
        self.selectedRowCanvasView:replaceAndEmphasisSelectedRow()
    end

    obj.setClickCallback = function(self, clickCallback)
        self.baseCanvasView:setClickCallback(clickCallback)
    end

    obj.activateHammerspoonWindow = function(self)
        self.baseCanvasView:activateHammerspoonWindow()
    end

    return obj
end

return PanelLayoutView