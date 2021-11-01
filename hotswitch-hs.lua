local util = require("hotswitch-hs/modules/util")

local Hotkeys = require("hotswitch-hs/modules/hotkeys")
local SettingsProvider = require("hotswitch-hs/modules/settings_provider")

local hotkeys = nil
local function main()
    hotkeys = Hotkeys.new()
end

local function openOrClose()
    if hotkeys.panel.isOpen then
        hotkeys:unbind()
        hotkeys.panel:close()
    else
        -- local t1 = hs.timer.secondsSinceEpoch() * 1000
        hotkeys.windows:refreshOrderedWindows()
        -- local t2 = hs.timer.secondsSinceEpoch() * 1000

        hotkeys:bind()
        -- local t3 = hs.timer.secondsSinceEpoch() * 1000
        hotkeys.panel:open()
        -- local t4 = hs.timer.secondsSinceEpoch() * 1000

        -- Check these speed for opening panel
        -- utils.log(t2-t1) -- 70ms
        -- utils.log(t3-t2) -- 50ms
        -- utils.log(t4-t3) -- 30ms
    end
end

local function clearSettings()
    SettingsProvider.new().clear()
end

main()

return {
    openOrClose = openOrClose,
    clearSettings = clearSettings
}