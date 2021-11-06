local canvas = require("hs.canvas")

local Debugger = require("hotswitch-hs/lib/common/Debugger")
local View = require("hotswitch-hs/lib/view/View")
local CanvasConstants = require("hotswitch-hs/lib/common/CanvasConstants")
local FrameCulculator = require("hotswitch-hs/lib/common/FrameCulculator")

local ToastView = {}
ToastView.new = function(orderedWindows)
    local obj = View.new()

    obj.toastCanvas = nil
    obj.timer = nil

    obj.show = function(self)
        self:toast("Set a message")
    end

    obj.hide = function(self)
        if self.toastCanvas ~= nil then
            self.toastCanvas:delete()
        end
    end

    obj.toast = function(self, message)
        if self.toastCanvas ~= nil then
            self.toastCanvas:delete()
        end

        local baseCanvasFrame = FrameCulculator.calcBaseCanvasFrame(orderedWindows)

        self.toastCanvas = canvas.new {
            x = baseCanvasFrame.x + baseCanvasFrame.w / 2 - CanvasConstants.TOAST_W / 2,
            y = baseCanvasFrame.y - CanvasConstants.TOAST_H - CanvasConstants.PADDING * 2,
            h = CanvasConstants.TOAST_H,
            w = CanvasConstants.TOAST_W
        }

        self.toastCanvas:appendElements({
            action = "fill",
            fillColor = {
                alpha = CanvasConstants.TOAST_ALPHA,
                blue = 0,
                green = 0,
                red = 0
            },
            frame = {
                x = 0,
                y = 0,
                h = "1",
                w = "1"
            },
            type = "rectangle"
        })

        self.toastCanvas:appendElements({
            frame = {
                x = CanvasConstants.PADDING,
                y = CanvasConstants.PADDING,
                h = "1",
                w = "1",
            },
            text = hs.styledtext.new(message, {
                font = {
                    name = ".AppleSystemUIFont",
                    size = CanvasConstants.TOAST_FONT_SIZE
                },
                color = {
                    alpha = CanvasConstants.TEXT_ALPHA,
                    blue = CanvasConstants.TEXT_WHITE_VALUE,
                    green = CanvasConstants.TEXT_WHITE_VALUE,
                    red = CanvasConstants.TEXT_WHITE_VALUE
                }
            }),
            type = "text"
        })

        self.toastCanvas:show(0.2)
        self.timer = hs.timer.doAfter(2, function()
            self.toastCanvas:delete(0.2)
            self.toastCanvas = nil
        end)
    end

    return obj
end
return ToastView