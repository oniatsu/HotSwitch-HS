local util = require("hotswitch-hs/modules/util")
local canvasConstants = require("hotswitch-hs/modules/canvas_constants")

local SettingsProvider = require("hotswitch-hs/modules/settings_provider")
local Windows = require("hotswitch-hs/modules/windows")

local BaseCanvas = {}
BaseCanvas.new = function(canvas, windows)
    local obj = {}

    obj.canvas = canvas
    obj.windows = windows
    obj.settingsProvider = SettingsProvider.new()

    obj.keyStatuses = {} -- { {app: "foo", windowId = 123, key = a, window = window} }

    obj.show = function(self)
        local orderedWindows = self.windows:getCachedOrderedWindowsOrFetch()

        -- local checkTime = util.checkTime.new()
        self:showRectangle(orderedWindows)
        -- checkTime:diff() -- 3ms - necessary
        self:showWindowInfo(orderedWindows)
        -- checkTime:diff() -- 35ms - necessary
    end

    obj.showRectangle = function(self, orderedWindows)
        local panelH = #orderedWindows * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 4

        local mainScreenFrame = hs.window.focusedWindow():screen():frame()
        local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - canvasConstants.PANEL_W / 2
        local panelY = mainScreenFrame.y + mainScreenFrame.h / 2 - panelH / 2

        if self.baseCanvas == nil then
            self.baseCanvas = self.canvas.new {
                x = panelX,
                y = panelY,
                h = panelH,
                w = canvasConstants.PANEL_W
            }

            -- TODO: treat canvas as a standart window

            -- self.baseCanvas:behavior("fullScreenPrimary")
            -- self.baseCanvas:level()
            -- utils.log(self.baseCanvas:behavior())
            -- utils.log(self.baseCanvas:level())
            -- self.baseCanvas:bringToFront()
            -- self.baseCanvas:bringToFront(false)
            -- self.baseCanvas:clickActivating(false)

            -- invisibleWindows = hs.window.invisibleWindows()[1]
            -- hs.window.invisibleWindows()[1]:focus()

            -- util.log(hs.timer.secondsSinceEpoch())
        end

        self.baseCanvas:replaceElements({
            action = "fill",
            fillColor = {
                alpha = canvasConstants.INLINE_RECTANGLE_ALPHA,
                blue = 0.5,
                green = 0.5,
                red = 0.5
            },
            frame = {
                x = "0",
                y = "0",
                h = "1",
                w = "1"
            },
            type = "rectangle",
            withShadow = true
        })

        self.baseCanvas:appendElements({
            action = "fill",
            fillColor = {
                alpha = canvasConstants.OUTLINE_RECTANGLE_ALPHA,
                blue = 0,
                green = 0,
                red = 0
            },
            frame = {
                x = canvasConstants.PADDING,
                y = canvasConstants.PADDING,
                h = #orderedWindows * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                w = canvasConstants.PANEL_W - canvasConstants.PADDING * 2
            },
            type = "rectangle"
        })
    end

    obj.getKeyStatuses = function(self)
        local settings = self.settingsProvider.get()

        local windowIdBasedOrderedWindows = self.windows:getWindowIdBasedOrderedWindows()

        local keyStatuses = {}
        for i = 1, #windowIdBasedOrderedWindows do
            local window = windowIdBasedOrderedWindows[i]

            local windowId = window:id()

            local appName = window:application():name()

            for j = 1, #settings do
                local setting = settings[j]
                if setting.app == appName then
                    if setting.keys[1] ~= nil then
                        table.insert(keyStatuses, {
                            app = appName,
                            windowId = windowId,
                            key = setting.keys[1],
                            window = window
                        })
                        table.remove(setting.keys, 1)
                    end
                    break
                end
            end
        end

        return keyStatuses
    end

    obj.showWindowInfo = function(self, orderedWindows)
        self.keyStatuses = self:getKeyStatuses()

        for i = 1, #orderedWindows do
            local window = orderedWindows[i]

            self:showEachKeyText(i, window)
            -- self:showEachAppName(i, window)
            self:showEachAppIcon(i, window)
            self:showEachWindowTitle(i, window)
        end

        self.baseCanvas:show()
    end

    obj.showEachKeyText = function(self, i, window)
        local windowId = window:id()

        local keyText = ""
        for j = 1, #self.keyStatuses do
            local keyStatus = self.keyStatuses[j]
            if keyStatus.windowId == windowId then
                keyText = keyStatus.key
                break
            end
        end

        self.baseCanvas:appendElements({
            frame = {
                x = canvasConstants.PADDING * 2 + canvasConstants.KEY_LEFT_PADDING,
                y = (i - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                h = canvasConstants.ROW_HEIGHT,
                w = canvasConstants.KEY_W
            },
            text = hs.styledtext.new(keyText, {
                font = {
                    name = ".AppleSystemUIFont",
                    size = canvasConstants.FONT_SIZE
                },
                color = {
                    alpha = canvasConstants.TEXT_ALPHA,
                    blue = canvasConstants.TEXT_WHITE_VALUE,
                    green = canvasConstants.TEXT_WHITE_VALUE,
                    red = canvasConstants.TEXT_WHITE_VALUE
                }
            }),
            type = "text"
        })
    end

    obj.showEachAppName = function(self, i, window)
        local appName = window:application():name()
        self.baseCanvas:appendElements({
            frame = {
                x = canvasConstants.PADDING * 2 + canvasConstants.KEY_LEFT_PADDING + canvasConstants.KEY_W,
                y = (i - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                h = canvasConstants.ROW_HEIGHT,
                w = canvasConstants.APP_NAME_W
            },
            text = hs.styledtext.new(appName, {
                font = {
                    name = ".AppleSystemUIFont",
                    size = canvasConstants.FONT_SIZE
                },
                color = {
                    alpha = canvasConstants.TEXT_ALPHA,
                    blue = canvasConstants.TEXT_WHITE_VALUE,
                    green = canvasConstants.TEXT_WHITE_VALUE,
                    red = canvasConstants.TEXT_WHITE_VALUE
                }
            }),
            type = "text"
        })
    end

    obj.showEachAppIcon = function(self, i, window)
        local bundleID = window:application():bundleID()
        self.baseCanvas:appendElements({
            frame = {
                x = canvasConstants.PADDING * 2 + canvasConstants.KEY_LEFT_PADDING + canvasConstants.KEY_W,
                y = (i - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                h = canvasConstants.ROW_HEIGHT - 3,
                w = canvasConstants.APP_ICON_W - 3
            },
            image = hs.image.imageFromAppBundle(bundleID),
            imageScaling = "scaleToFit",
            type = "image"
        })
    end

    obj.showEachWindowTitle = function(self, i, window)
        local windowName = window:title()
        self.baseCanvas:appendElements({
            frame = {
                x = canvasConstants.PADDING * 3 + canvasConstants.KEY_W + canvasConstants.KEY_LEFT_PADDING + canvasConstants.APP_ICON_W,
                y = (i - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
                h = canvasConstants.ROW_HEIGHT,
                w = canvasConstants.PANEL_W - canvasConstants.KEY_W - canvasConstants.APP_ICON_W - canvasConstants.PADDING * 6
            },
            text = hs.styledtext.new(windowName, {
                font = {
                    name = ".AppleSystemUIFont",
                    size = canvasConstants.FONT_SIZE
                },
                color = {
                    alpha = canvasConstants.TEXT_ALPHA,
                    blue = canvasConstants.TEXT_WHITE_VALUE,
                    green = canvasConstants.TEXT_WHITE_VALUE,
                    red = canvasConstants.TEXT_WHITE_VALUE
                }
            }),
            type = "text"
        })
    end

    obj.hide = function(self)
        if self.baseCanvas ~= nil then
            self.baseCanvas:delete()
            self.baseCanvas = nil
        end
    end

    return obj
end

return BaseCanvas
