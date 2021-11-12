local Debugger = require("hotswitch-hs/lib/common/Debugger")
local TimeChecker = require("hotswitch-hs/lib/common/TimeChecker")
local CanvasConstants = require("hotswitch-hs/lib/common/CanvasConstants")

local function calcBaseCanvasFrame(orderedWindows)
    -- local t = TimeChecker.new()
    local panelH = #orderedWindows * CanvasConstants.ROW_HEIGHT + CanvasConstants.PADDING * 4
    -- t:diff("panelH")

    local mainScreenFrame = hs.screen.mainScreen():frame()
    -- t:diff("mainScreenFrame")
    local panelX = mainScreenFrame.x + mainScreenFrame.w / 2 - CanvasConstants.PANEL_W / 2
    -- t:diff("panelX")
    local panelY = mainScreenFrame.y + mainScreenFrame.h / 2 - panelH / 2
    -- t:diff("panelY")

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