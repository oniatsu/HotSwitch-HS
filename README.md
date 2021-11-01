# What is HotSwitch-HS

![preview](https://user-images.githubusercontent.com/5919569/139619210-b4215c01-a1f8-41db-ad41-34a1882f13bc.png)

HotSwitch-HS is a window switcher using **2 stroke hotkey** for macOS.

It provides fastest window switching, no matter how many windows there are.

HotSwitch-HS uses [Hammerspoon](https://www.hammerspoon.org/), and is rewritten for a substitution of [HotSwitch](https://github.com/oniatsu/HotSwitch).

# Installation

## 1. Install [Hammerspoon](https://www.hammerspoon.org/)

## 2. Download HotSwitch-HS

In terminal, execute a command. You need to place a directory to `hotswitch-hs`.
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

# If you have some probrems,

Check these.

- If a keybind you set is not enabled, open Hammerspoon console and check some error messages. First, click Hammerspoon's menubar icon. Second, click `Console...`.
- If you want to clear HotSwtich-HS's all settings, execute code `hotswitchHs.clearSettings()` at `~/.hammerspoon/init.lua`.
- Update HotSwtich-HS. `cd ~/.hammerspoon/hotswitch-hs && git pull`

# Updating

Execute these command at terminal.
```
cd ~/.hammerspoon/hotswitch-hs
git pull
```

# Development note

- Pay attention to lua's gavage collection