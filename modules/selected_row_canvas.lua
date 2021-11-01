local util = require("hotswitch-hs/modules/util")

local canvasConstants = require("hotswitch-hs/modules/canvas_constants")

local Windows = require("hotswitch-hs/modules/windows")

local SelectedRowCanvas = {}

SelectedRowCanvas.new = function(canvas, windows, position)
    local obj = {}
    obj.canvas = canvas
    obj.windows = windows
    obj.position = position

    obj.createSelectedRow = function(self)
        local orderedWindows = self.windows:getCachedOrderedWindowsOrFetch()
        local panelH = #orderedWindows * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 4

        local mainScreenFrame = hs.window.focusedWindow():screen():frame()
        local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - canvasConstants.PANEL_W / 2
        local panelY = mainScreenFrame.y + mainScreenFrame.h / 2 - panelH / 2

        if self.selectedRowCanvas == nil then
            self.selectedRowCanvas = canvas.new {
                x = panelX,
                y = panelY,
                h = panelH,
                w = canvasConstants.PANEL_W - canvasConstants.PADDING
            }
        end
    end

    obj.replaceSelectedRow = function(self, position)
        self.selectedRowCanvas:replaceElements({
            action = "fill",
            fillColor = {
                alpha = canvasConstants.SELECTED_ROW_ALPHA,
                blue = 1,
                green = 1,
                red = 1
            },
            frame = {
                x = canvasConstants.PADDING * 2,
                y = (position - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                h = canvasConstants.ROW_HEIGHT,
                w = canvasConstants.PANEL_W - canvasConstants.PADDING * 4
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
                x = canvasConstants.PADDING * 2,
                y = (position - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                h = canvasConstants.ROW_HEIGHT,
                w = canvasConstants.PANEL_W - canvasConstants.PADDING * 4
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

return SelectedRowCanvas