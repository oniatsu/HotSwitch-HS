local util = require("hotswitch-hs/modules/util")

local Hotkeys = require("hotswitch-hs/modules/hotkeys")
local SettingsProvider = require("hotswitch-hs/modules/settings_provider")

local hotkeys = Hotkeys.new()

local function main()
    hotkeys:create()
end

local function openOrClose()
    if hotkeys.panel.isOpen then
        hotkeys:focusWindowForCancel()
        hotkeys:finish()
    else
        hotkeys.windows.previousWindow = hs.window.frontmostWindow()

        -- Enable hotkeys before refresh windows,
        -- because refreshing windows is slow and take time.
        -- local checkTime = util.checkTime.new()
        hotkeys:enable()
        -- checkTime:diff("enable") -- 40ms
        hotkeys.windows:refreshOrderedWindows()
        -- checkTime:diff("refresh") -- 170ms
        hotkeys.panel:open()
        -- checkTime:diff("open") -- 170ms
        hotkeys:watchAppliationDeactivated()
        -- checkTime:diff("watch") -- 10ms
    end
end

local function clearSettings()
    SettingsProvider.new().clear()
end

local function enableDebug()
    util.enableDebug()
end

main()

return {
    openOrClose = openOrClose,
    clearSettings = clearSettings,
    enableDebug = enableDebug,
}