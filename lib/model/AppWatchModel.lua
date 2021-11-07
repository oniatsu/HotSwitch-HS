local Debugger = require("hotswitch-hs/lib/common/Debugger")
local Model = require("hotswitch-hs/lib/model/Model")

local AppWatchModel = {}
AppWatchModel.new = function(windowModel, settingModel, keyStatusModel)
    local obj = Model.new()

    obj.applicationWatcher = nil

    obj.watchAppliationDeactivated = function(self, callback)
        if self.applicationWatcher == nil then
            self.applicationWatcher = hs.application.watcher.new(function(appName, eventType, app)
                if appName == "Hammerspoon" and eventType == hs.application.watcher.deactivated then
                    callback()
                end
            end)
            self.applicationWatcher:start()
        end
    end

    obj.unwatchAppliationDeactivated = function(self)
        if self.applicationWatcher ~= nil then
            self.applicationWatcher:stop()
            self.applicationWatcher = nil
        end
    end

    return obj
end
return AppWatchModel