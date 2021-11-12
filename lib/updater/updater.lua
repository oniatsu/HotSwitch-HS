local Debugger = require("hotswitch-hs/lib/common/Debugger")

local URL = "https://api.github.com/repos/oniatsu/HotSwitch-HS/releases/latest"
local APPLE_SCRIPT_FOR_GIT_TAG = 'do shell script "cd ~/.hammerspoon/hotswitch-hs && git describe --tags --abbrev=0"'


local obj = {}

obj.check = function()
    hs.http.asyncGet(URL, nil, function(status, body, header)
        if status == 200 then
            local json = hs.json.decode(body)
            local tag = json.tag_name

            local isSuccess, parsedOutput, rawOutput = hs.osascript.applescript(APPLE_SCRIPT_FOR_GIT_TAG)
            if isSuccess then
                if parsedOutput == tag then
                    Debugger.log("This HotSwitch-HS is latest.")
                else
                    Debugger.log("This HotSwitch-HS can be updated.")
                    -- TODO: show dialog and update HotSwitch-HS.
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