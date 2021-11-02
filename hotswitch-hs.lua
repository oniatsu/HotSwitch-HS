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
        -- Enable hotkeys before refresh windows,
        -- because refreshing windows is slow and take time.

        hotkeys.windows.previousWindow = hs.window.frontmostWindow()

        -- local checkTime = util.checkTime.new()
        hotkeys:enable()
        -- checkTime:diff() -- 50ms
        hotkeys.windows:refreshOrderedWindows()
        -- checkTime:diff() -- 50ms
        hotkeys.panel:open()
        -- checkTime:diff() -- 120ms
        -- hotkeys:watchWindowChange()
        -- checkTime:diff() -- 200ms
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