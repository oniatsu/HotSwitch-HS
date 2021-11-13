local Debugger = require("hotswitch-hs/lib/common/Debugger")

local PREFERENCE_KEY = "hotswitch-hs-preference"

--[[
data format:

preferences = {
    autoUpdate = {
        lastCheckedDate = "2021/11/13",
        lastCheckedVersion = "v2.0.1",
    },
}
]]

local getPreferences = function()
    local preferences = hs.settings.get(PREFERENCE_KEY)
    if preferences == nil then
        preferences = {}
    end
    return preferences
end

local setPreferences = function(value)
    hs.settings.set(PREFERENCE_KEY, value)
end

local clearPreferences = function()
    hs.settings.clear(PREFERENCE_KEY)
end

local getAutoUpdate = function()
    local preferences = getPreferences()
    local autoUpdate
    if preferences.autoUpdate == nil then
        autoUpdate = {}
    else
        autoUpdate = preferences.autoUpdate
    end
    return autoUpdate
end

local setAutoUpdate = function(autoUpdate)
    local preferences = getPreferences()
    preferences.autoUpdate = autoUpdate
    setPreferences(preferences)
end

local obj = {}

obj.clearPreferences = clearPreferences

obj.autoUpdate = {}

obj.autoUpdate.getLastCheckedDate = function()
    return getAutoUpdate().lastCheckedDate
end

obj.autoUpdate.setLastCheckedDate = function(date)
    local autoUpdate = getAutoUpdate()
    autoUpdate.lastCheckedDate = date
    setAutoUpdate(autoUpdate)
end

obj.autoUpdate.getLastCheckedVersion = function()
    return getAutoUpdate().lastCheckedVersion
end

obj.autoUpdate.setLastCheckedVersion = function(version)
    local autoUpdate = getAutoUpdate()
    autoUpdate.lastCheckedVersion = version
    setAutoUpdate(autoUpdate)
end

return obj