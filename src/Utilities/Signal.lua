--[[
    Black UI Library
    Utilities/Signal.lua

    Mini event system (pub/sub) usado internamente pelos componentes
    para expor eventos como :OnChanged(), :OnClick(), etc.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _handlers = {},
    }, Signal)
end

function Signal:Connect(fn)
    local handler = { fn = fn }
    table.insert(self._handlers, handler)

    local connection = {}
    function connection:Disconnect()
        local idx = table.find(self._handlers, handler)
        if idx then
            table.remove(self._handlers, idx)
        end
    end
    setmetatable(connection, { __index = function(_, k)
        if k == "Disconnect" then
            return connection.Disconnect
        end
    end })

    return connection
end

function Signal:Fire(...)
    -- copia pra evitar problema se um handler se desconectar durante o Fire
    local handlers = table.clone(self._handlers)
    for _, handler in handlers do
        task.spawn(handler.fn, ...)
    end
end

function Signal:DisconnectAll()
    table.clear(self._handlers)
end

return Signal
