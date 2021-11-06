local View = {}
View.new = function()
    local obj = {}
    
    obj.show = function() end
    obj.hide = function() end

    return obj
end
return View