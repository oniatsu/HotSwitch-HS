# What is HotSwitch-HS

![preview](https://user-images.githubusercontent.com/5919569/139591542-a4f22e7f-2f37-4c7d-a20f-7fa94df13acb.png)

HotSwitch-HS is a window switcher using 2 stroke hotkey for macOS.

It provides fastest window switching, no matter how many windows there are.

HotSwitch-HS uses Hammerspoon, and is rewrited for a substitution of [HotSwitch](https://github.com/oniatsu/HotSwitch).

# Installation

## 1. Install [Hammerspoon](https://www.hammerspoon.org/)

## 2. Download HotSwitch-HS

In terminal, execute a command.
```bash
git clone https://github.com/oniatsu/HotSwitch-HS.git ~/.hammerspoon/hotswitch-hs
```

Directory tree is like this:
```
~/.hammerspoon/
▾ hotswitch-hs/
  ▸ modules/
    hotswitch-hs.lua
    README.md
  init.lua
```

## 3. Put a code at your Hammerspoon's `~/.hammerspoon/init.lua`
If the file does not exist, create it.

```lua
local hotswitchHs = require("hotswitch-hs/hotswitch-hs")
hs.hotkey.bind({"command"}, ".", function() -- Set any keybind you like
  hotswitchHs.openOrClose()
end)
```

[Here](https://www.hammerspoon.org/docs/hs.hotkey.html#bind) is how to set `hs.hotkey.bind()`.

## 4. Run Hammerspoon

# Usage

It's same as [HotSwitch](https://oniatsu.github.io/HotSwitch/).

# Updating

Execute these command at terminal.
```
cd ~/.hammerspoon/hotswitch-hs
git pull
```

# Advanced usage

If you want to clear HotSwtich-HS's all settings, execute a code at `~/.hammerspoon/init.lua`.
```lua
hotswitchHs.clearSettings()
```

# Development note

- Pay attention to lua's gavage collection
