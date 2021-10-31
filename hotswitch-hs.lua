--[[

# What is HotSwitch-HS

HotSwitch-HS is a window switcher using 2 stroke hotkey for macOS.

It provides fastest window switching, no matter how many windows there are.

HotSwitch-HS uses Hammerspoon, and is rewrited for replacement of HotSwitch.


# Installation

1. Install [Hammerspoon](https://www.hammerspoon.org/)

2. Download [HotSwitch-HS](https://github.com/oniatsu/HotSwitch-HS/releases)

3. Move the `hotswitch-hs/` folder to your `~/.hammerspoon/`

Command: `$ mv hotswitch-hs/ ~/.hammerspoon/`

Directory tree is like this:
```
~/.hammerspoon/
▾ hotswitch-hs/
  ▸ modules/
    hotswitch-hs.lua
  init.lua
```

4. Put a code at your Hammerspoon's `~/.hammerspoon/init.lua`
```lua
local hotswitchHs = require("hotswitch-hs/hotswitch-hs")
hs.hotkey.bind({"command"}, ".", function()
  hotswitchHs.openOrClose()
end)
```


# Usage

It's same as [HotSwitch](https://oniatsu.github.io/HotSwitch/).


# Advanced usage

If you want to clear HotSwtich-HS's all settings, execute a code at `~/.hammerspoon/init.lua`.
```lua
hotswitchHs.clearSettings()
```


# Development note

- Pay attention to lua's gavage collection

]]

local utils = require("hotswitch-hs/modules/utils")

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

        -- utils.log(t2-t1) -- 70ms
        -- utils.log(t3-t2) -- 50ms
        -- utils.log(t4-t3) -- 30ms

        -- for debug
        -- hs.timer.doAfter(1, function()
        --     panel:close()
        -- end)
    end
end

local function clearSettings()
  SettingsProvider.new().clear()
end

main()

return {
    openOrClose = openOrClose,
    clearSettings = clearSettings,
}