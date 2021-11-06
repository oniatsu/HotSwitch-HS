local Debugger = require("hotswitch-hs/lib/common/Debugger")
local CanvasConstants = require("hotswitch-hs/lib/common/CanvasConstants")

local function calcBaseCanvasFrame(orderedWindows)
    local panelH = #orderedWindows * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 4

    local mainScreenFrame = hs.window.frontmostWindow():screen():frame()
    local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - CanvasConstants.PANEL_W / 2
    local panelY = mainScreenFrame.y + mainScreenFrame.h / 2 - panelH / 2

    local baseCanvasFrame = {
        x = panelX,
        y = panelY,
        h = panelH,
        w = CanvasConstants.PANEL_W
    }
    return baseCanvasFrame
end

return {
    calcBaseCanvasFrame = calcBaseCanvasFrame,
}