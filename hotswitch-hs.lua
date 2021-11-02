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
        hotkeys:enable()
        hotkeys.windows:refreshOrderedWindows()
        hotkeys.panel:open()
        hotkeys:watchAppliationDeactivated()
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