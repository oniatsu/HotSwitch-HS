local Debugger = require("hotswitch-hs/lib/common/Debugger")
local View = require("hotswitch-hs/lib/view/View")
local CanvasConstants = require("hotswitch-hs/lib/common/CanvasConstants")
local WindowModel = require("hotswitch-hs/lib/model/WindowModel")

local SelectedRowCanvasView = {}
SelectedRowCanvasView.new = function(canvas, windows, position)
    local obj = View.new()

    obj.canvas = canvas
    obj.windows = windows
    obj.position = position

    obj.createSelectedRow = function(self)
        local orderedWindows = self.windows:getCachedOrderedWindowsOrFetch()
        local panelH = #orderedWindows * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 4

        local mainScreenFrame = hs.window.frontmostWindow():screen():frame()
        local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - CanvasConstants.PANEL_W / 2
        local panelY = mainScreenFrame.y + mainScreenFrame.h / 2 - panelH / 2

        if self.selectedRowCanvas == nil then
            self.selectedRowCanvas = canvas.new {
                x = panelX,
                y = panelY,
                h = panelH,
                w = CanvasConstants.PANEL_W - CanvasConstants.PADDING
            }
        end
    end

    obj.replaceSelectedRow = function(self, position)
        self.selectedRowCanvas:replaceElements({
            action = "fill",
            fillColor = {
                alpha = CanvasConstants.SELECTED_ROW_ALPHA,
                blue = 1,
                green = 1,
                red = 1
            },
            frame = {
                x = CanvasConstants.PADDING * 2,
                y = (position - 1) * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 2,
                h = CanvasConstants.ROW_HEIGHT,
                w = CanvasConstants.PANEL_W - CanvasConstants.PADDING * 4
            },
            type = "rectangle"
        })

        self.selectedRowCanvas:show()
    end

    obj.replaceAndEmphasisSelectedRow = function(self, position)
        self.selectedRowCanvas:replaceElements({
            action = "fill",
            fillColor = {
                alpha = 0.3,
                blue = 0.3,
                green = 1,
                red = 1
            },
            frame = {
                x = CanvasConstants.PADDING * 2,
                y = (position - 1) * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 2,
                h = CanvasConstants.ROW_HEIGHT,
                w = CanvasConstants.PANEL_W - CanvasConstants.PADDING * 4
            },
            type = "rectangle"
        })

        self.selectedRowCanvas:show()
    end

    obj.hide = function(self)
        if self.selectedRowCanvas ~= nil then
            self.selectedRowCanvas:delete()
            self.selectedRowCanvas = nil
        end
    end

    return obj
end
return SelectedRowCanvasView