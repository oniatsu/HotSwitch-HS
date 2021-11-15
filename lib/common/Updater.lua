local Debugger = require("hotswitch-hs/lib/common/Debugger")
local PreferenceModel = require("hotswitch-hs/lib/model/PreferenceModel")

local URL = "https://api.github.com/repos/oniatsu/HotSwitch-HS/releases/latest"
local APPLE_SCRIPT_FOR_GIT_TAG = 'do shell script "cd ~/.hammerspoon/hotswitch-hs && git describe --tags --abbrev=0"'
local APPLE_SCRIPT_FOR_UPDATE = 'do shell script "cd ~/.hammerspoon/hotswitch-hs && git pull"'

local obj = {}

local showDialog = function(remoteVersion)
    hs.notify.new(function(notify)
        local activationTypes = notify:activationType()
        if activationTypes == hs.notify.activationTypes.contentsClicked then
            -- none
        elseif activationTypes == hs.notify.activationTypes.actionButtonClicked then
            hs.notify.new(function() end, {
                title = "HotSwitch-HS",
                informativeText = "Updating ...",
                withdrawAfter = 0,
            }):send()

            local isSuccess, parsedOutput, rawOutput = hs.osascript.applescript(APPLE_SCRIPT_FOR_UPDATE)
            if isSuccess then
                Debugger.log("SUCCESS: updating")
                hs.notify.new(function() end, {
                    title = "HotSwitch-HS",
                    informativeText = "Updating is finished!",
                    withdrawAfter = 0,
                }):send()
                hs.reload()
            else
                Debugger.log("ERROR: updating")
                hs.notify.new(function() end, {
                    title = "HotSwitch-HS",
                    informativeText = "ERROR: Updating HotSwitch-HS has something errors.",
                    withdrawAfter = 0,
                }):send()
            end
        end
    end, {
        title = "New HotSwitch-HS is available!",
        informativeText = "Click 'Update' button.\nIt will update to " .. remoteVersion,
        hasActionButton = true,
        actionButtonTitle = "Update",
        autoWithdraw = false,
        withdrawAfter = 0,
    }):send()
end

obj.check = function()
    Debugger.log("start checking")
    -- if 1 == 1 then showDialog("v3.0.0") return end -- for debug

    local currentDate = os.date("%Y-%m-%d")
    local lastCheckedDate = PreferenceModel.autoUpdate.getLastCheckedDate()
    -- lastCheckedDate = "2021-10-10" -- for debug
    if lastCheckedDate == currentDate then
        Debugger.log("Today is same as last checked date.")
        return
    end
    PreferenceModel.autoUpdate.setLastCheckedDate(currentDate)

    Debugger.log("HTTP request")
    hs.http.asyncGet(URL, nil, function(status, body, header)
        if status == 200 then
            local json = hs.json.decode(body)
            local remoteVersion = json.tag_name

            local isSuccess, localVersion, rawOutput = hs.osascript.applescript(APPLE_SCRIPT_FOR_GIT_TAG)
            if isSuccess then
                -- localVersion = "v1.9.9" -- for debug
                if localVersion == remoteVersion then
                    Debugger.log("This HotSwitch-HS " .. localVersion .. " is latest.")
                else
                    local lastCheckedVersion = PreferenceModel.autoUpdate.getLastCheckedVersion()
                    -- lastCheckedVersion = "v1.9.9" -- for debug
                    if lastCheckedVersion == remoteVersion then
                        Debugger.log("The version update was already checked.")
                    else
                        Debugger.log("This HotSwitch-HS can be updated.")

                        Debugger.log("setLastCheckedVersion(" .. remoteVersion .. ")")
                        PreferenceModel.autoUpdate.setLastCheckedVersion(remoteVersion)

                        showDialog(remoteVersion)
                    end
                end
            else
                Debugger.log("Error: getting git tag")
            end
        else
            Debugger.log("Error: http request")
        end
    end)
end

return obj