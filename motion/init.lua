-- init.lua

local connection = require(script.connection)
local internalTypings = require(script.internalTypings)

export type Connection = internalTypings.Connection
export type MiddlewareHandle = internalTypings.MiddlewareHandle
export type Signal<T...> = internalTypings.Signal<T...>

local motion = {} :: {new: <T...>() -> Signal<any>}
motion.__index = motion

function motion.new<T...>(): Signal<T...>
    return setmetatable({
        _head = nil :: Connection?,
    }, motion)
end

function motion:Connect<T...>(callback: (T...) -> ()): Connection
    local conn = connection.new(self, callback)
    conn._next = self._head
    self._head = conn
    return conn
end

function motion:Once<T...>(callback: (T...) -> ()): Connection
    local conn: Connection
    conn = self:Connect(function(...: T...)
        conn:Disconnect()
        callback(...)
    end)
    return conn
end

function motion:Wait<T...>(timeoutSeconds: number?): ...T
    local thread = coroutine.running()
    local conn: Connection
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

function motion:DisconnectAll(): ()
    self._head = nil
    return
end

function motion:Until<T...>(
  predicate: ((T...) -> boolean),
  callback: ((T...) -> ())
): Connection

  local connection
  connection = self:Connect(function(...)
      if predicate(...) then
          callback(...)
          connection:Disconnect() -- Disconnect after firing
      end
  end)
return connection

function motion:WhileActive<T...>(check: () -> boolean, callback: (T...) -> ()): Connection
    local connection
    connection = self:Connect(function(...)
        if check() then
            callback(...)
        end
    end)
    return connection
end

function motion:ConnectForked<T...>(callback: (T...) -> ()): Connection
    return self:Connect(function(...)
        task.spawn(callback, ...)
    end)
end

function motion:ConnectDeferred<T...>(callback: (T...) -> ()): Connection
    return self:Connect(function(...)
        task.defer(callback, ...)
    end)
end

function motion:ConnectAsync<T...>(callback: (T...) -> ()): Connection
    return self:Connect(function(...)
        coroutine.wrap(callback)(...)
    end)
end


return motion
