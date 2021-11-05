local util = require("hotswitch-hs/modules/util")

local keyConstants = require("hotswitch-hs/modules/key_constants")
local canvasConstants = require("hotswitch-hs/modules/canvas_constants")

local SettingsProvider = require("hotswitch-hs/modules/settings_provider")
local Windows = require("hotswitch-hs/modules/windows")

local BaseCanvas = {}
BaseCanvas.new = function(canvas, windows)
    local obj = {}

    obj.canvas = canvas
    obj.windows = windows
    obj.settingsProvider = SettingsProvider.new()

    --[[
    data format:

    keyStatuses = {
        {
            app: "Google Chrome",
            windowId = 123,
            key = a,
            window = hs.window object,
            isAutoGenerated = false,
        },
        {
            app: "Mail",
            windowId = 456,
            key = b,
            window = hs.window object,
            isAutoGenerated = false,
        },
        {
            app: "Calendar",
            windowId = 789,
            key = x,
            window = hs.window object,
            isAutoGenerated = true,
        }
    }
    ]]
    obj.registeredKeyStatuses = {}
    obj.registeredAndAutoGeneratedKeyStatuses = {}

    obj.specifiedAutoGeneratedKeys = nil
    obj.autoGeneratedKeys = keyConstants.DEFAULT_AUTO_GENERATED_KEYS

    obj.baseCanvasFrame = nil

    obj.toastCanvas = nil
    obj.timer = nil

    obj.clickCallback = nil

    obj.show = function(self)
        local orderedWindows = self.windows:getCachedOrderedWindowsOrFetch()

        self:showRectangle(orderedWindows)
        self:showWindowInfo(orderedWindows)
    end

    obj.showRectangle = function(self, orderedWindows)
        local panelH = #orderedWindows * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 4

        local mainScreenFrame = hs.window.frontmostWindow():screen():frame()
        local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - canvasConstants.PANEL_W / 2
        local panelY = mainScreenFrame.y + mainScreenFrame.h / 2 - panelH / 2

        self.baseCanvasFrame = {
            x = panelX,
            y = panelY,
            h = panelH,
            w = canvasConstants.PANEL_W
        }

        if self.baseCanvas == nil then
            self.baseCanvas = self.canvas.new(self.baseCanvasFrame)
        end

        self:setElements(orderedWindows)

        -- self:activateHammerspoonWindow()
        -- self.baseCanvas:level("normal") -- don't need
        -- self.baseCanvas:bringToFront()

        self:initializeMouseEvent(orderedWindows)
    end

    obj.initializeMouseEvent = function(self, orderedWindows)
        self.baseCanvas:canvasMouseEvents(false, true, false, false)
        self.baseCanvas:mouseCallback(function(canvas, type, elementId, x, y)
            if self.clickCallback == nil then
                return
            end

            if type == "mouseUp" then
                local position = math.floor((y - canvasConstants.PADDING * 2) / canvasConstants.ROW_HEIGHT + 1)
                if position < 1 then
                    position = 1
                elseif position > #orderedWindows then
                    position = #orderedWindows
                end

                self.clickCallback(position)
            end
        end)
    end

    -- clickCallback = function(position) end
    obj.setClickCallback = function(self, clickCallback)
        self.clickCallback = clickCallback
    end
    
    obj.activateHammerspoonWindow = function(self)
        local app = hs.application.get("Hammerspoon")
        app:setFrontmost()
    end

    obj.setElements = function(self, orderedWindows)
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

    obj.createKeyStatuses = function(self)
        local settings = self.settingsProvider.get()

        local windowIdBasedOrderedWindows = self.windows:getWindowIdBasedOrderedWindows()

        local registeredKeyStatuses = {}
        local registeredAndAutoGeneratedKeyStatuses = {}

        local usedIndexOfAutoGeneratedKeys = 0
        for i = 1, #windowIdBasedOrderedWindows do
            local window = windowIdBasedOrderedWindows[i]

            local windowId = window:id()

            local appName = window:application():name()

            local hasSettingKey = false
            for j = 1, #settings do
                local setting = settings[j]
                if setting.app == appName then
                    if setting.keys[1] ~= nil then
                        hasSettingKey = true

                        local keyStatus = {
                            app = appName,
                            windowId = windowId,
                            key = setting.keys[1],
                            window = window,
                            isAutoGenerated = false,
                        }

                        table.insert(registeredKeyStatuses, keyStatus)
                        table.insert(registeredAndAutoGeneratedKeyStatuses, keyStatus)

                        table.remove(setting.keys, 1)
                    end
                    break
                end
            end

            if hasSettingKey == false then
                if usedIndexOfAutoGeneratedKeys < #self.autoGeneratedKeys then
                    usedIndexOfAutoGeneratedKeys = usedIndexOfAutoGeneratedKeys + 1
                    table.insert(registeredAndAutoGeneratedKeyStatuses, {
                        app = appName,
                        windowId = windowId,
                        key = self.autoGeneratedKeys[usedIndexOfAutoGeneratedKeys],
                        window = window,
                        isAutoGenerated = true,
                    })
                end
            end
        end

        self.registeredKeyStatuses = registeredKeyStatuses
        self.registeredAndAutoGeneratedKeyStatuses = registeredAndAutoGeneratedKeyStatuses
    end

    obj.showWindowInfo = function(self, orderedWindows)
        self:createKeyStatuses()

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
        local isAutoGeneratedKey
        for j = 1, #self.registeredAndAutoGeneratedKeyStatuses do
            local keyStatus = self.registeredAndAutoGeneratedKeyStatuses[j]
            if keyStatus.windowId == windowId then
                keyText = keyStatus.key
                isAutoGeneratedKey = keyStatus.isAutoGenerated
                break
            end
        end

        local textColor
        if isAutoGeneratedKey then
            textColor = {
                alpha = canvasConstants.TEXT_ALPHA,
                blue = 0.1,
                green = 0.9,
                red = 0.9
            }
        else
            textColor = {
                alpha = canvasConstants.TEXT_ALPHA,
                blue = canvasConstants.TEXT_WHITE_VALUE,
                green = canvasConstants.TEXT_WHITE_VALUE,
                red = canvasConstants.TEXT_WHITE_VALUE
            }
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
                color = textColor
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
        local frame = {
            x = canvasConstants.PADDING * 2 + canvasConstants.KEY_LEFT_PADDING + canvasConstants.KEY_W,
            y = (i - 1) * canvasConstants.ROW_HEIGHT + canvasConstants.PADDING * 2,
            h = canvasConstants.ROW_HEIGHT - 3,
            w = canvasConstants.APP_ICON_W - 3
        }

        local bundleID = window:application():bundleID()
        if bundleID then
            self.baseCanvas:appendElements({
                frame = frame,
                image = hs.image.imageFromAppBundle(bundleID),
                imageScaling = "scaleToFit",
                type = "image",
            })
        else
            local radius = frame.w / 2

            self.baseCanvas:appendElements({
                center = { x = frame.x + radius, y = frame.y + radius },
                action = "fill",
                fillColor = { alpha = 1, blue = 0.5, green = 0.5, red = 0.5 },
                radius = radius - 1,
                type = "circle",
            })
        end
    end

    obj.showEachWindowTitle = function(self, i, window)
        local windowName = window:title()
        if windowName == "" then
            windowName = window:application():name()
        end
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

    obj.setSpecifiedAutoGeneratedKeys = function(self, specifiedAutoGeneratedKeys)
        self.specifiedAutoGeneratedKeys = specifiedAutoGeneratedKeys
    end

    obj.resetAutoGeneratedKeys = function(self)
        local specifiedAutoGeneratedKeys
        if self.specifiedAutoGeneratedKeys ~= nil then
            specifiedAutoGeneratedKeys = self.specifiedAutoGeneratedKeys
        else
            specifiedAutoGeneratedKeys = keyConstants.DEFAULT_AUTO_GENERATED_KEYS
        end

        local settings = self.settingsProvider.get()

        local allSettingKeys = {}
        for i, setting in ipairs(settings) do
            local keys = setting.keys
            for j, key in ipairs(keys) do
                table.insert(allSettingKeys, key)
            end
        end

        local autoGeneratedKeys = {}
        for i, specifiedAutoGeneratedKey in ipairs(specifiedAutoGeneratedKeys) do
            local hasSettingKey = false
            for j, settingKey in ipairs(allSettingKeys) do
                if settingKey == specifiedAutoGeneratedKey then
                    hasSettingKey = true
                    break
                end
            end
            if hasSettingKey == false then
               table.insert(autoGeneratedKeys, specifiedAutoGeneratedKey)
            end
        end

        self.autoGeneratedKeys = autoGeneratedKeys
    end

    obj.toast = function(self, message)
        if self.toastCanvas ~= nil then
            self.toastCanvas:delete()
        end

        self.toastCanvas = self.canvas.new {
            x = self.baseCanvasFrame.x + self.baseCanvasFrame.w / 2 - canvasConstants.TOAST_W / 2,
            y = self.baseCanvasFrame.y - canvasConstants.TOAST_H - canvasConstants.PADDING * 2,
            h = canvasConstants.TOAST_H,
            w = canvasConstants.TOAST_W
        }

        self.toastCanvas:appendElements({
            action = "fill",
            fillColor = {
                alpha = canvasConstants.TOAST_ALPHA,
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
                x = canvasConstants.PADDING,
                y = canvasConstants.PADDING,
                h = "1",
                w = "1",
            },
            text = hs.styledtext.new(message, {
                font = {
                    name = ".AppleSystemUIFont",
                    size = canvasConstants.TOAST_FONT_SIZE
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

        self.toastCanvas:show(0.2)
        self.timer = hs.timer.doAfter(2, function()
            self.toastCanvas:delete(0.2)
            self.toastCanvas = nil
        end)
    end

    return obj
end

return BaseCanvas
