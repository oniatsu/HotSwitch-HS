# What is HotSwitch-HS

![preview](https://user-images.githubusercontent.com/5919569/139591542-a4f22e7f-2f37-4c7d-a20f-7fa94df13acb.png)

HotSwitch-HS is a window switcher using 2 stroke hotkey for macOS.

It provides fastest window switching, no matter how many windows there are.

HotSwitch-HS uses Hammerspoon, and is rewrited for replacement of [HotSwitch](https://github.com/oniatsu/HotSwitch).

# Installation

## 1. Install [Hammerspoon](https://www.hammerspoon.org/)

## 2. Download [HotSwitch-HS](https://github.com/oniatsu/HotSwitch-HS/tags)

## 3. Move the `hotswitch-hs/` folder to your `~/.hammerspoon/`

Command: `$ mv hotswitch-hs/ ~/.hammerspoon/`

Directory tree is like this:
```
~/.hammerspoon/
▾ hotswitch-hs/
  ▸ modules/
    hotswitch-hs.lua
  init.lua
```

## 4. Put a code at your Hammerspoon's `~/.hammerspoon/init.lua`
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