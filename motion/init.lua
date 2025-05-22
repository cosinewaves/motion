--!strict
-- init.lua

local connection = require(script.connection)
local internalTypings = require(script.internalTypings)

export type Connection = internalTypings.Connection
export type MiddlewareHandle = internalTypings.MiddlewareHandle
export type Signal<T...> = internalTypings.Signal<T...>

export type Motion<T...> = {
  -- public
    new: () -> Signal<T...>,
    Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
    Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
    Wait: (self: Signal<T...>, timeoutSeconds: number?) -> ...any,
    Fire: (self: Signal<T...>, ...T) -> (),
    DisconnectAll: (self: Signal<T...>) -> (),
  -- private
  __index: Connection,

}

local motion = {} :: Motion<any>
motion.__index = motion

function motion.new<T...>(): internalTypings.Signal<T...>
    return setmetatable({
        _head = nil :: internalTypings.Connection?,
    }, motion) :: any
end

function motion:Connect<T...>(callback: (T...) -> ()): internalTypings.Connection
    local conn = connection.new(self, callback)
    conn._next = self._head
    self._head = conn
    return conn
end

function motion:Once<T...>(callback: (T...) -> ()): internalTypings.Connection
    local conn: internalTypings.Connection
    conn = self:Connect(function(...: T...)
        conn:Disconnect()
        callback(...)
    end)
    return conn
end

function motion:Wait<T...>(timeoutSeconds: number?): ...any
    local thread = coroutine.running()
    local conn: internalTypings.Connection
    conn = self:Connect(function(...: T...)
        conn:Disconnect()
        task.spawn(thread, ...)
    end)

    if timeoutSeconds then
        task.delay(timeoutSeconds, function()
            conn:Disconnect()
            task.spawn(thread, nil, true)
        end)
    end

    return coroutine.yield()
end

function motion:Fire<T...>(...: T...)
    local current = self._head
    while current do
        if current._connected then
            task.spawn(current._callback, ...)
        end
        current = current._next
    end
end

function motion:DisconnectAll()
    self._head = nil
end

return motion
