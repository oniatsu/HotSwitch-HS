local function log(value)
    local message = value

    message = hs.inspect.inspect(message)
    -- if type(value) == 'table' then
    -- message = serializeTable(value)
    -- end

    local debugLog = hs.logger.new("=========", "debug")

    debugLog.i(message)
    print(message)
    hs.alert.show(message)
end

return {
    log = log
}
