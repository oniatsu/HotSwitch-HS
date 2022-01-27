local Debugger = require("hotswitch-hs/lib/common/Debugger")
local TimeChecker = require("hotswitch-hs/lib/common/TimeChecker")
local CanvasConstants = require("hotswitch-hs/lib/common/CanvasConstants")

local doesShowOnMainScreen = true

local function calcBaseCanvasFrame(orderedWindows)
    local panelH = #orderedWindows * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 4

    local targetScreenFrame
    if doesShowOnMainScreen then
        targetScreenFrame = hs.screen.mainScreen():frame()
    else
        targetScreenFrame = hs.screen.primaryScreen():frame()
    end
    local panelX = targetScreenFrame.x + targetScreenFrame.w / 2 - CanvasConstants.PANEL_W / 2
    local panelY = targetScreenFrame.y + targetScreenFrame.h / 2 - panelH / 2

    local baseCanvasFrame = {
        x = panelX,
        y = panelY,
        h = panelH,
        w = CanvasConstants.PANEL_W
    }
    return baseCanvasFrame
end

local function setShowingOnMainScreen(flag)
    doesShowOnMainScreen = flag
end

return {
    calcBaseCanvasFrame = calcBaseCanvasFrame,
    setShowingOnMainScreen = setShowingOnMainScreen,
}