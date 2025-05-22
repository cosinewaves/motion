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
end

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

function motion:FireDeferred<T...>(...: T...)
    task.defer(self.Fire, self, ...)
end

function motion:FireAsync<T...>(...: T...)
    task.spawn(self.Fire, self, ...)
end

function motion:FireBatched<T...>(...: T...)
    local batch = {...}
    task.spawn(function()
        for _, valueSet in ipairs(batch) do
            self:Fire(table.unpack(valueSet))
        end
    end)
end

function motion:FireWithMiddleware<T...>(...: T...)
    local current = self._head
    while current do
        if current._connected then
            local nextMiddleware = function(...) current._callback(...) end
            task.spawn(current._middleware or nextMiddleware, ...)
        end
        current = current._next
    end
end

function motion:Use<T...>(middleware: (next: (T...) -> (), T...) -> ()): MiddlewareHandle
    local handle = {
        Disconnect = function()
            self._middleware = nil
        end
    }

    self._middleware = function(next, ...)
        middleware(next, ...)
    end

    return handle
end

function motion:UseFilter<T...>(predicate: (T...) -> boolean): MiddlewareHandle
    return self:Use(function(next, ...)
        if predicate(...) then
            next(...)
        end
    end)
end

function motion:UseMap<U...>(mapper: (T...) -> U...): MiddlewareHandle
    return self:Use(function(next, ...)
        next(mapper(...))
    end)
end

function motion:UseThrottle<T...>(seconds: number): MiddlewareHandle
    local lastCall = 0
    return self:Use(function(next, ...)
        local now = tick()
        if now - lastCall >= seconds then
            lastCall = now
            next(...)
        end
    end)
end

function motion:UseDebounce<T...>(seconds: number): MiddlewareHandle
    local debounceTask
    return self:Use(function(next, ...)
        if debounceTask then
            task.cancel(debounceTask)
        end
        debounceTask = task.delay(seconds, function()
            next(...)
        end)
    end)
end

function motion:UseDelay<T...>(seconds: number): MiddlewareHandle
    return self:Use(function(next, ...)
        task.delay(seconds, function()
            next(...)
        end)
    end)
end

function motion:UseLog<T...>(prefix: string?): MiddlewareHandle
    return self:Use(function(next, ...)
        print((prefix or "[motion]"), ...)
        next(...)
    end)
end

function motion:UseCatch<T...>(handler: (any) -> ()): MiddlewareHandle
    return self:Use(function(next, ...)
        local success, err = pcall(function()
            next(...)
        end)
        if not success then
            handler(err)
        end
    end)
end

function motion:UseCancel<T...>(predicate: (T...) -> boolean): MiddlewareHandle
    return self:Use(function(next, ...)
        if not predicate(...) then
            next(...)
        end
    end)
end


return motion
