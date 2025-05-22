-- init.lua

local connection = require(script.connection)
local internalTypings = require(script.internalTypings)

export type Connection = internalTypings.Connection
export type MiddlewareHandle = internalTypings.MiddlewareHandle
export type Signal<T...> = internalTypings.Signal<T...>

--[=[
  @class motion

  Motion is a lightweight, modular signal system built for event-driven programming in Lua. This release introduces a complete set of connection management, middleware utilities, and event firing capabilities to streamline reactive workflows.
]=]
local motion = {} :: {new: <T...>() -> Signal<any>}
motion.__index = motion

local function output(msg: string): ()
  print(`[motion]: {msg}`)
  return
end

--[=[
  Create a new signal

  @within motion
  @return Signal<T...>
]=]
function motion.new<T...>(): Signal<T...>
    return setmetatable({
        _head = nil :: Connection?,
    }, motion)
end

--[=[
  Connect a signal to a callback function, which will automatically be called when your signal is Fired.

  @within motion
  @param callback T... -- Your callback function
  @return Connection
]=]
function motion:Connect<T...>(callback: (T...) -> ()): Connection
    local conn = connection.new(self, callback)
    conn._next = self._head
    self._head = conn
    return conn
end

--[=[
  Disconnect a callback function after it has been fired.

  @within motion
  @param callback T... -- Your callback function
  @return Connection
]=]
function motion:Once<T...>(callback: (T...) -> ()): Connection
    local conn: Connection
    conn = self:Connect(function(...: T...)
        conn:Disconnect()
        callback(...)
    end)
    return conn
end

--[=[
  Waits an amount of time before firing the signal.

  @within motion
  @param timeoutSeconds number? -- Defaults to one second if not provided
  @return ...T
]=]
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
      else
        task.delay(1, function()
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
        local args = {...} -- Capture varargs
        if debounceTask then
            task.cancel(debounceTask)
        end
        debounceTask = task.delay(seconds, function()
            next(table.unpack(args)) -- Ensure varargs persist after delay
        end)
    end)
end

function motion:UseDelay<T...>(seconds: number): MiddlewareHandle
    return self:Use(function(next, ...)
        local args = {...} -- Capture varargs explicitly
        task.delay(seconds, function()
            next(table.unpack(args)) -- Unpack varargs inside delayed function
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
        local success, err = pcall(function(...)
            next(...)
        end, ...) -- Pass varargs explicitly to `pcall`
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

function motion:GetListenerCount(): number
    local count = 0
    local current = self._head
    while current do
        if current._connected then
            count += 1
        end
        current = current._next
    end
    return count
end

function motion:GetConnections(): { Connection }
    local connections = {}
    local current = self._head
    while current do
        table.insert(connections, current)
        current = current._next
    end
    return connections
end

function motion:DebugDescribe(): string
    local description = `Motion Signal: Listener Count =  {self:GetListenerCount()} `
    return description
end

function motion:PrintDebugInfo(): ()
    output(self:DebugDescribe())
    local current = self._head
    while current do
        output(`- Connection: `, current._callback)
        current = current._next
    end
end

function motion:IsConnected(callback: (T...) -> ()): boolean
    local current = self._head
    while current do
        if current._connected and current._callback == callback then
            return true
        end
        current = current._next
    end
    return false
end


return motion
