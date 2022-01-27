# What is HotSwitch-HS

![top](https://raw.githubusercontent.com/oniatsu/HotSwitch-HS/main/doc/img/top.png)

HotSwitch-HS is a window switcher using **2 stroke hotkey** for macOS.

It provides fastest window switching, no matter how many windows there are.
HotSwitch-HS uses [Hammerspoon](https://www.hammerspoon.org/), and is rewritten for a substitution of [HotSwitch](https://github.com/oniatsu/HotSwitch).

You can switch any windows by like `command + .` + `x` (this key is always fixed).

HotSwitch-HS's window switching steps is these.

1. Register **a fixed key** to windows on list. (Press `Space`. It's easy and fast.)
2. Switch any windows by using the key you registered. (You can switch in a flash without thinking time.)

In addition, HotSwitch-HS provides auto generated keys before your key registration.
However, I highly recommend that you register keys, because it enable you to switch windows faster than ever.

# Usage

## Simple way

Try it. It's easy and fast to understand.

| Key | Action |
| --- | ------ |
| The key you set | Open or close the HotSwitch-HS panel |
| `Space` | Toggle registration mode |
| `Tab` or `Down` | Select a next window |
| `Shift+Tab` or `Up` | Select a previous window |
| `Delete` | Delete the key on the selected window |
| `Return` | Focus the selected window |
| `Escape` | Close the panal |
| `[a-zA-Z0-9]` | Focus the window or register the key |
| `-` or `[` or `]` or `.` or `/` | Focus the window or register the key |

## Details

Concretely, HotSwitch-HS's window switching steps is these.

1. Register **a fixed key** to windows on list.
2. Switch any windows by using the key you registered.

### 1. Register **a fixed key** to windows on list.

1. Open HotSwitch-HS panel. (Press `command + .` that you registered)
2. Select a window on lists. (Press `Tab` or cursor keys.)
3. Chanege the panel to registeration mode. (Press `Space`)
4. Register **a fixed key** to the window. (Press any character keys. `a`, `b`, `c`, etc.)

The registered key become a reserversion key, so the key doesn't appear as auto generated keys.

If you want to delete a registered key combined with the window, select the window on lists and press `Delete`.

### 2. Switch any windows by using the key you registered.

1. Open HotSwitch-HS panel. (Press `command + .` that you registered)
2. Switch the target window by using **a fixed key**. (Press the key you registered.)

It looks like that 2 stroke hotkey is working to focus any windows.
The important thing is that **the 2 stroke key bind is fixed anytime**.

That is why window switching by HotSwitch-HS is always fastest.

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
├── init.lua
└── hotswitch-hs/
  ├── lib/
  ├── LICENSE
  ├── README.md
  └── hotswitch-hs.lua
```

If you have installed Hammerspoon just right now, `~/.hammerspoon/init.lua` doesn't exist yet.

## 3. Put a code at your Hammerspoon's `~/.hammerspoon/init.lua`
If the file does not exist, create it and add the codes.

```lua
local hotswitchHs = require("hotswitch-hs/hotswitch-hs")
hotswitchHs.enableAutoUpdate() -- If you don't want to update automatically, remove this line.
hs.hotkey.bind({"command"}, ".", hotswitchHs.openOrClose) -- Set a keybind you like to open HotSwitch-HS panel.
```

For example, you can set the keybind to open HotSwitch-HS like these.

```lua
-- These are valid.
hs.hotkey.bind({"command"}, ".", hotswitchHs.openOrClose) -- command + .
hs.hotkey.bind({"command"}, ";", hotswitchHs.openOrClose) -- command + ;
hs.hotkey.bind({"option"}, "tab", hotswitchHs.openOrClose) -- option + tab
hs.hotkey.bind({"control"}, 'space', hotswitchHs.openOrClose) -- control + space
hs.hotkey.bind({"command", "shift"}, "a", hotswitchHs.openOrClose) -- command + shift + a

-- These are NOT valid normally. Hammerspoon cannot override the keys, because the keys may be registered and used by macOS.
hs.hotkey.bind({"command"}, "tab", hotswitchHs.openOrClose) -- command + tab
hs.hotkey.bind({"command"}, "space", hotswitchHs.openOrClose) -- command + space
```

[Here](https://www.hammerspoon.org/docs/hs.hotkey.html#bind) is how to set `hs.hotkey.bind()`.

### Advanced option

If you want to replace the macOS's app switcher `command + tab` with HotSwitch-HS, you can do forcibly by using [Karabiner-Elements](https://karabiner-elements.pqrs.org/).

#### `~/.config/karabiner/karabiner.json`

```json
{
    "from": {
        "key_code": "tab",
        "modifiers": { "mandatory": [ "command" ] }
    },
    "to": [ {
        "key_code": "f13"
    } ],
    "type": "basic"
}
```

#### `~/.hammerspoon/init.lua`

```lua
hs.hotkey.bind({}, "f13", hotswitchHs.openOrClose)
```

## 4. Run Hammerspoon

And open HotSwitch-HS panel by using the keybind you set.
If you have some probrems, [check these](https://github.com/oniatsu/HotSwitch-HS#if-you-have-some-probrems).

# Preferences

If you want to set some preferences, you can use some option by adding codes at `~/.hammerspoon/init.lua`.

For example:

```lua
local hotswitchHs = require("hotswitch-hs/hotswitch-hs")
hotswitchHs.enableAutoUpdate()
hotswitchHs.setAutoGeneratedKeys({"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"})
hotswitchHs.enableAllSpaceWindows()
hs.hotkey.bind({"command"}, ".", hotswitchHs.openOrClose)
```

See below to know what these means.

## Auto update

Add this. It will update HotSwitch-HS by `git pull` automatically when needed.

```lua
hotswitchHs.enableAutoUpdate()
```

## Auto generated keys

You can define auto generated keys.
The order you specified will be used to generate keys.

```lua
hotswitchHs.setAutoGeneratedKeys({"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"})
```

Default auto generated keys are [these](https://github.com/oniatsu/HotSwitch-HS/blob/main/lib/common/KeyConstants.lua#L24-L26).

## Showing all space windows

If you want to see all space windows on the lists, add this.

```lua
hotswitchHs.enableAllSpaceWindows()
```

Default: the current space windows are only shown.

## Additonal symbol keys

You can add symbol keys to register windows. (Only the [Japanese keyboard layout symbols](https://github.com/oniatsu/HotSwitch-HS/blob/main/lib/common/KeyConstants.lua#L31) are available now.)

```lua
hotswitchHs.addJapaneseKeyboardLayoutSymbolKeys()
```

## Always showing the panel on primary screen

To show the panel not on main screen but on primary screen.
Main screen is the one containing the currently focused window.

```lua
hotswitchHs.setPanelToAlwaysShowOnPrimaryScreen()
```

# If you have some probrems,

Check these.

- If the keybind you set is not enabled, open Hammerspoon console and check some error messages. First, click Hammerspoon's menubar icon. Second, click `Console...`.
- Update HotSwtich-HS. `cd ~/.hammerspoon/hotswitch-hs && git pull`

## Known issues

Sometimes, getting windows is failed after the macOS has woken up from sleep.

It would be fixed by reloading Hammerspoon config. It's possibly Hammerspoon's bug.
I recommend that you add a keybind to reload Hammerpoon config quickly.

```lua
-- For example: you can reload by "command + option + control + r".
hs.hotkey.bind({"command", "option", "control"}, "r", hs.reload)
hs.hotkey.bind({"command"}, ".", hotswitchHs.openOrClose)
-- It's message showing the completion of reloading.
hs.alert.show("Hammerspoon is reloaded")
```

# Update manually

```
cd ~/.hammerspoon/hotswitch-hs
git pull
```

# Uninstallation

```
rm -rf ~/.hammerspoon/hotswitch-hs
```

# Development

## Requirements

- Hammerspoon

## Steps

1. Edit codes.
2. Reload Hammerspoon config and check that it's working correctly.

### Owner's steps

3. Check latest git tag. (`git describe --tags --abbrev=0`)
4. Add a new git tag.
5. Push the tag. Then, the release on GitHub is automatically created.

### Option

If you would update the class diagram,
1. Install PlantUML. (`brew install graphviz && brew install plantuml`)
2. Edit `doc/uml/class_diagram.pu`.
3. Execute `plantuml doc/uml -o ../img` at your terminal.

## Directory structure

The class diagram is roughly like this.

![class_diagram](https://raw.githubusercontent.com/oniatsu/HotSwitch-HS/main/doc/img/class_diagram.png)

## Note

- Pay attention to Lua's garvage collection.

# Some ChangeLogs

- v2.2.5: Add option to always show the panel on primary screen
  - `hotswitchHs.setPanelToAlwaysShowOnPrimaryScreen()`
- v2.1.5: Change saving keys to use bundleID instead of app name
  - If you used this app before this version, you need register keys again.
- v2.1.0: Add auto updater
  - `hotswitchHs.enableAutoUpdate()`
- v2.0.0: Connect Git tag with GitHub Release
- v1.17: Add auto generated keys
- v1.4: Change app info text to app icon on panel
- v1.0: First release