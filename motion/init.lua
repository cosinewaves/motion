-- init.lua

local connection = require(script.connection)
local internalTypings = require(script.internalTypings)

export type Connection = internalTypings.Connection
export type MiddlewareHandle = internalTypings.MiddlewareHandle
export type Signal<T...> = internalTypings.Signal<T...>

--[=[
  @class Signal

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

  @within Signal
  @return Signal<T...>
]=]
function motion.new<T...>(): Signal<T...>
    return setmetatable({
        _head = nil :: Connection?,
    }, motion)
end

--[=[
  Connect a signal to a callback function, which will automatically be called when your signal is Fired.

  @within Signal
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

  @within Signal
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

  @within Signal
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

--[=[
  Dispatches the signal to all connected listeners.

  @within Signal
  @param ... T...
  @return ()
]=]
function motion:Fire<T...>(...: T...): ()
    local current = self._head
    while current do
        if current._connected then
            task.spawn(current._callback, ...)
        end
        current = current._next
    end
end

--[=[
  Disconnects all connected listeners.

  @within Signal
  @return ()
]=]
function motion:DisconnectAll(): ()
    self._head = nil
    return
end

--[=[
  Listens until the predicate evaluates to true, then disconnects.

  @within Signal
  @param predicate ((T...) -> boolean)
  @return Connection
]=]
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

--[=[
  Fires only when the check function evaluates to true.

  @within Signal
  @param check () -> boolean
  @param callback (T...) -> ()
  @return Connection
]=]
function motion:WhileActive<T...>(check: () -> boolean, callback: (T...) -> ()): Connection
    local connection
    connection = self:Connect(function(...)
        if check() then
            callback(...)
        end
    end)
    return connection
end

--[=[
  Fires the listener in a separate task using task.spawn, ensuring parallel execution.

  @within Signal
  @param callback (T...) -> ()
  @return Connection
]=]
function motion:ConnectForked<T...>(callback: (T...) -> ()): Connection
    return self:Connect(function(...)
        task.spawn(callback, ...)
    end)
end

--[=[
  Defers execution using task.defer, waiting until the current thread completes.

  @within Signal
  @param callback (T...) -> ()
  @return Connection
]=]
function motion:ConnectDeferred<T...>(callback: (T...) -> ()): Connection
    return self:Connect(function(...)
        task.defer(callback, ...)
    end)
end

--[=[
  Wraps the listener in a coroutine for concurrent execution.

  @within Signal
  @param callback (T...) -> ()
  @return Connection
]=]
function motion:ConnectAsync<T...>(callback: (T...) -> ()): Connection
    return self:Connect(function(...)
        coroutine.wrap(callback)(...)
    end)
end

--[=[
    Fires the signal using `task.defer`, ensuring it runs after the current execution thread completes.

    @within Signal
    @param ... T...
]=]
function motion:FireDeferred<T...>(...: T...)
    task.defer(self.Fire, self, ...)
end

--[=[
    Fires the signal asynchronously using `task.spawn`, reducing potential performance bottlenecks.

    @within Signal
    @param ... T...
]=]
function motion:FireAsync<T...>(...: T...)
    task.spawn(self.Fire, self, ...)
end

--[=[
    Fires multiple sets of arguments in batch mode. Each value set is dispatched in sequence using `task.spawn`.

    @within Signal
    @param ... T... Multiple tables of arguments (each a {T...})
]=]
function motion:FireBatched<T...>(...: T...)
    local batch = {...}
    task.spawn(function()
        for _, valueSet in ipairs(batch) do
            self:Fire(table.unpack(valueSet))
        end
    end)
end

--[=[
    Fires the signal through any registered middleware before invoking listeners.

    @within Signal
    @param ... T...
]=]
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

--[=[
    Applies a custom middleware to intercept signal execution. Only one middleware can be active at a time.

    @within Signal
    @param middleware (next: (T...) -> (), ...T) -> ()
    @return MiddlewareHandle
]=]
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

--[=[
    Filters events based on a predicate. Only events that return `true` are allowed through.

    @within Signal
    @param predicate (T...) -> boolean
    @return MiddlewareHandle
]=]
function motion:UseFilter<T...>(predicate: (T...) -> boolean): MiddlewareHandle
    return self:Use(function(next, ...)
        if predicate(...) then
            next(...)
        end
    end)
end

--[=[
    Transforms signal arguments before they are passed to listeners.

    @within Signal
    @param mapper (T...) -> U...
    @return MiddlewareHandle
]=]
function motion:UseMap<U...>(mapper: (T...) -> U...): MiddlewareHandle
    return self:Use(function(next, ...)
        next(mapper(...))
    end)
end

--[=[
    Throttles the signal, allowing it to fire at most once per given time interval.

    @within Signal
    @param seconds number
    @return MiddlewareHandle
]=]
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

--[=[
    Debounces the signal. Only fires after no new signal is received within the given time frame.

    @within Signal
    @param seconds number
    @return MiddlewareHandle
]=]
function motion:UseDebounce<T...>(seconds: number): MiddlewareHandle
    local debounceTask
    return self:Use(function(next, ...)
        local args = {...}
        if debounceTask then
            task.cancel(debounceTask)
        end
        debounceTask = task.delay(seconds, function()
            next(table.unpack(args))
        end)
    end)
end

--[=[
    Delays the signal by the specified amount of time before calling listeners.

    @within Signal
    @param seconds number
    @return MiddlewareHandle
]=]
function motion:UseDelay<T...>(seconds: number): MiddlewareHandle
    return self:Use(function(next, ...)
        local args = {...}
        task.delay(seconds, function()
            next(table.unpack(args))
        end)
    end)
end

--[=[
    Logs signal firings to the console for debugging purposes.

    @within Signal
    @param prefix string? Optional log prefix
    @return MiddlewareHandle
]=]
function motion:UseLog<T...>(prefix: string?): MiddlewareHandle
    return self:Use(function(next, ...)
        print((prefix or "[motion]"), ...)
        next(...)
    end)
end

--[=[
    Wraps signal execution in a `pcall`, catching and handling any runtime errors.

    @within Signal
    @param handler (any) -> () Error handler callback
    @return MiddlewareHandle
]=]
function motion:UseCatch<T...>(handler: (any) -> ()): MiddlewareHandle
    return self:Use(function(next, ...)
        local success, err = pcall(function(...)
            next(...)
        end, ...)
        if not success then
            handler(err)
        end
    end)
end

--[=[
    Cancels the signal if the given predicate returns `true`.

    @within Signal
    @param predicate (T...) -> boolean
    @return MiddlewareHandle
]=]
function motion:UseCancel<T...>(predicate: (T...) -> boolean): MiddlewareHandle
    return self:Use(function(next, ...)
        if not predicate(...) then
            next(...)
        end
    end)
end

--[=[
    Returns the number of active listeners connected to the signal.

    @within Signal
    @return number
]=]
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

--[=[
    Returns a list of all connection handles attached to this signal.

    @within Signal
    @return { Connection }
]=]
function motion:GetConnections(): { Connection }
    local connections = {}
    local current = self._head
    while current do
        table.insert(connections, current)
        current = current._next
    end
    return connections
end

--[=[
    Returns a string summary of the signal's current listener state.

    @within Signal
    @return string
]=]
function motion:DebugDescribe(): string
    local description = `Motion Signal: Listener Count =  {self:GetListenerCount()} `
    return description
end

--[=[
    Prints detailed debug information about the signal and its listeners.

    @within Signal
]=]
function motion:PrintDebugInfo(): ()
    output(self:DebugDescribe())
    local current = self._head
    while current do
        output(`- Connection: `, current._callback)
        current = current._next
    end
end

--[=[
    Checks if the given callback is currently connected to the signal.

    @within Signal
    @param callback (T...) -> ()
    @return boolean
]=]
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
