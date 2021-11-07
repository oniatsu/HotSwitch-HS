local canvas = require("hs.canvas")

local Debugger = require("hotswitch-hs/lib/common/Debugger")
local View = require("hotswitch-hs/lib/view/View")
local CanvasConstants = require("hotswitch-hs/lib/common/CanvasConstants")

local SelectedRowCanvasView = {}
SelectedRowCanvasView.new = function(windowModel, position)
    local obj = View.new()

    obj.canvas = canvas
    obj.windowModel = windowModel
    obj.position = position

    obj.show = function(self)
        -- not be used
    end

    obj.hide = function(self)
        if self.selectedRowCanvas ~= nil then
            self.selectedRowCanvas:delete()
            self.selectedRowCanvas = nil
        end
    end

    obj.createSelectedRow = function(self)
        local orderedWindows = self.windowModel:getCachedOrderedWindowsOrFetch()
        local panelH = #orderedWindows * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 4

        local mainScreenFrame = hs.window.frontmostWindow():screen():frame() local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - CanvasConstants.PANEL_W / 2
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

    obj.replaceSelectedRow = function(self)
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
                y = (self.position - 1) * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 2,
                h = CanvasConstants.ROW_HEIGHT,
                w = CanvasConstants.PANEL_W - CanvasConstants.PADDING * 4
            },
            type = "rectangle"
        })

        self.selectedRowCanvas:show()
    end

    obj.replaceAndEmphasisSelectedRow = function(self)
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
                y = (self.position - 1) * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 2,
                h = CanvasConstants.ROW_HEIGHT,
                w = CanvasConstants.PANEL_W - CanvasConstants.PADDING * 4
            },
            type = "rectangle"
        })

        self.selectedRowCanvas:show()
    end

    obj.next = function(self, windowModel)
        self.isRegistrationMode = false

        self.position = self:calcNextRowPosition(self.position, windowModel)

        self:replaceSelectedRow()
    end

    obj.previous = function(self, windowModel)
        self.isRegistrationMode = false

        self.position = self:calcPreviousRowPosition(self.position, windowModel)

        self:replaceSelectedRow()
    end

    obj.calcNextRowPosition = function(self, position, windowModel)
        local newPosition = position + 1
        if newPosition > #windowModel:getCachedOrderedWindowsOrFetch() then
            newPosition = 1
        end
        return newPosition
    end

    obj.calcPreviousRowPosition = function(self, position, windowModel)
        local newPosition = position - 1
        if newPosition <= 0 then
            newPosition = #windowModel:getCachedOrderedWindowsOrFetch()
        end
        return newPosition
    end

    return obj
end
return SelectedRowCanvasView