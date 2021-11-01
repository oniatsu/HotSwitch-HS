local util = require("hotswitch-hs/modules/util")

local Hotkeys = require("hotswitch-hs/modules/hotkeys")
local SettingsProvider = require("hotswitch-hs/modules/settings_provider")

local hotkeys = Hotkeys.new()

local function main()
    hotkeys:create()
end

local function openOrClose()
    if hotkeys.panel.isOpen then
        -- local checkTime = util.checkTime.new(false)
        hotkeys:disable()
        -- checkTime:diff() -- 40ms
        hotkeys.panel:close()
        -- checkTime:diff() -- 10ms
    else
        -- local checkTime = util.checkTime.new()
        hotkeys.windows:refreshOrderedWindows()
        -- checkTime:diff() -- 40ms - necessary

        hotkeys:enable()
        -- checkTime:diff() -- 50ms - necessary
        hotkeys.panel:open()
        -- checkTime:diff() -- 30ms - necessary
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