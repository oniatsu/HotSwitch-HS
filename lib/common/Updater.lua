local Debugger = require("hotswitch-hs/lib/common/Debugger")
local PreferenceModel = require("hotswitch-hs/lib/model/PreferenceModel")

local TAGS_URL = "https://api.github.com/repos/oniatsu/HotSwitch-HS/tags"
local README_URL = "https://raw.githubusercontent.com/oniatsu/HotSwitch-HS/main/README.md"
local CHANGELOG_URL = "https://github.com/oniatsu/HotSwitch-HS#changelogs"
local APPLE_SCRIPT_FOR_GIT_TAG = 'do shell script "cd ~/.hammerspoon/hotswitch-hs && git describe --tags --abbrev=0"'
local APPLE_SCRIPT_FOR_UPDATE = 'do shell script "cd ~/.hammerspoon/hotswitch-hs && git pull"'

local obj = {}

local function parseVersion(version)
    if version == nil then return nil, nil, nil end
    local maj, min, pat = version:match("^v(%d+)%.(%d+)%.(%d+)")
    return tonumber(maj), tonumber(min), tonumber(pat)
end

local function parseMajor(version)
    local maj = select(1, parseVersion(version))
    return maj
end

local function isRemoteNewer(remoteVersion, localVersion)
    local rMaj, rMin, rPat = parseVersion(remoteVersion)
    local lMaj, lMin, lPat = parseVersion(localVersion)
    if rMaj == nil or lMaj == nil then return remoteVersion ~= localVersion end
    if rMaj ~= lMaj then return rMaj > lMaj end
    if rMin ~= lMin then return rMin > lMin end
    return rPat > lPat
end

local function extractChangelog(readmeContent, version)
    local escaped = version:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
    local start = readmeContent:find("- " .. escaped .. ":")
    if start == nil then return nil end
    local excerpt = readmeContent:sub(start, start + 400)
    local nextEntry = excerpt:find("\n- v%d")
    if nextEntry then
        excerpt = excerpt:sub(1, nextEntry - 1)
    end
    return excerpt:gsub("^%s+", ""):gsub("%s+$", "")
end

local function truncate(text, maxLen)
    if text == nil then return "" end
    if #text <= maxLen then return text end
    return text:sub(1, maxLen) .. "…"
end

local showDialog = function(remoteVersion, localVersion, changelog)
    local remoteMajor = parseMajor(remoteVersion)
    local localMajor  = parseMajor(localVersion)
    local majorBump   = (remoteMajor ~= nil and localMajor ~= nil and remoteMajor > localMajor)
    local keywordHit  = (changelog ~= nil and changelog:upper():find("BREAKING") ~= nil)
    local isBreaking  = majorBump or keywordHit

    local notes = truncate(changelog or "(No changelog found)", 250)
    local informativeText = (isBreaking and "⚠ BREAKING CHANGES DETECTED\n" or "")
        .. notes
        .. "\n\n[Click here for full changelog]"

    hs.notify.new(function(notify)
        local activationType = notify:activationType()
        if activationType == hs.notify.activationTypes.contentsClicked then
            hs.urlevent.openURL(CHANGELOG_URL)
        elseif activationType == hs.notify.activationTypes.actionButtonClicked then
            hs.notify.new(function() end, {
                title = "HotSwitch-HS",
                informativeText = "Updating ...",
                withdrawAfter = 0,
            }):send()
            local isSuccess = hs.osascript.applescript(APPLE_SCRIPT_FOR_UPDATE)
            if isSuccess then
                hs.notify.new(function() end, {
                    title = "HotSwitch-HS",
                    informativeText = "Updated to " .. remoteVersion .. ". Reloading...",
                    withdrawAfter = 0,
                }):send()
                hs.reload()
            else
                hs.notify.new(function() end, {
                    title = "HotSwitch-HS",
                    informativeText = "ERROR: Update failed. Check Hammerspoon Console.",
                    withdrawAfter = 0,
                }):send()
            end
        end
    end, {
        title = isBreaking
            and "HotSwitch-HS: Update Available (Breaking Changes!)"
            or  "New HotSwitch-HS is available! → " .. remoteVersion,
        informativeText = informativeText,
        hasActionButton = true,
        actionButtonTitle = "Update",
        autoWithdraw = false,
        withdrawAfter = 0,
    }):send()
end

local function doCheck(force)
    -- Step 1: Get latest version from tags API
    hs.http.asyncGet(TAGS_URL, nil, function(status, body, header)
        if status ~= 200 then Debugger.log("Error: http request") return end

        local tags = hs.json.decode(body)
        if tags == nil or #tags == 0 then Debugger.log("Error: no tags found") return end
        local remoteVersion = tags[1].name

        local isSuccess, localVersion = hs.osascript.applescript(APPLE_SCRIPT_FOR_GIT_TAG)
        if not isSuccess then Debugger.log("Error: getting git tag") return end

        Debugger.log("remote: " .. remoteVersion .. " / local: " .. localVersion)
        if not isRemoteNewer(remoteVersion, localVersion) then
            Debugger.log("This HotSwitch-HS " .. localVersion .. " is latest.")
            return
        end

        if not force and PreferenceModel.autoUpdate.getLastCheckedVersion() == remoteVersion then
            Debugger.log("The version update was already checked.")
            return
        end

        Debugger.log("This HotSwitch-HS can be updated.")
        PreferenceModel.autoUpdate.setLastCheckedVersion(remoteVersion)

        -- Step 2: Fetch README.md to extract changelog
        hs.http.asyncGet(README_URL, nil, function(rStatus, rBody, rHeader)
            local changelog = nil
            if rStatus == 200 then
                changelog = extractChangelog(rBody, remoteVersion)
            end
            showDialog(remoteVersion, localVersion, changelog)
        end)
    end)
end

obj.check = function()
    Debugger.log("start checking")
    -- if 1 == 1 then showDialog("v2.4.1", "v2.3.0", "- v2.4.1: Bug fixes\n  - Show all Finder windows") return end -- for debug

    local currentDate = os.date("%Y-%m-%d")
    if PreferenceModel.autoUpdate.getLastCheckedDate() == currentDate then
        Debugger.log("Today is same as last checked date.")
        return
    end
    PreferenceModel.autoUpdate.setLastCheckedDate(currentDate)

    doCheck()
end

obj.checkNow = function()
    Debugger.log("start checking (forced)")
    doCheck(true)
end

return obj
