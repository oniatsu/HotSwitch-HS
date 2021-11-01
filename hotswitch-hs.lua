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
        -- Enable hotkeys before refresh windows,
        -- because refreshing windows is slow and take time.

        -- local checkTime = util.checkTime.new()
        hotkeys:enable()
        -- checkTime:diff() -- 50ms
        hotkeys.windows:refreshOrderedWindows()
        -- checkTime:diff() -- 50ms
        hotkeys.panel:open()
        -- checkTime:diff() -- 40ms
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