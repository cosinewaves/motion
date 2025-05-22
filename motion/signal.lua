--!strict
-- signal.lua

local internalTypings = require(script.Parent.internalTypings)
local Connection = require(script.Connection)

local signal = {}

--[=[
	@class Signal<T...>
	A custom signal implementation that mimics RBXScriptSignal behavior with additional control.
]=]

local Signal = {}
Signal.__index = Signal

--[=[
	@within Signal
	@function new
	@return Signal<T...>
	Creates a new signal instance.
]=]
function signal.new<T...>(): internalTypings.Signal<T...>
	return setmetatable({
		_head = nil :: internalTypings.Connection?,
	}, Signal) :: any
end

--[=[
	@within Signal
	@method Connect
	@param callback (T...) -> ()
	@return Connection
	Connects a function to be fired every time the signal is emitted.
]=]
function Signal:Connect<T...>(callback: (T...) -> ()): internalTypings.Connection
	local conn = Connection.new(self, callback)
	conn._next = self._head
	self._head = conn
	return conn
end

--[=[
	@within Signal
	@method Once
	@param callback (T...) -> ()
	@return Connection
	Connects a function to be fired once, then automatically disconnects.
]=]
function Signal:Once<T...>(callback: (T...) -> ()): internalTypings.Connection
	local conn: internalTypings.Connection
	conn = self:Connect(function(...: T...)
		conn:Disconnect()
		callback(...)
	end)
	return conn
end

--[=[
	@within Signal
	@method Wait
	@param timeoutSeconds number?
	@return T... | (nil, true)
	Yields until the signal fires and returns the fired arguments.
]=]
function Signal:Wait<T...>(timeoutSeconds: number?): ...any
	local thread = coroutine.running()
	local conn: internalTypings.Connection
	conn = self:Connect(function(...: T...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)

	if timeoutSeconds then
		local timeoutThread = task.delay(timeoutSeconds, function()
			conn:Disconnect()
			task.spawn(thread, nil, true)
		end)
	end

	return coroutine.yield()
end

--[=[
	@within Signal
	@method Fire
	@param ... T
	Fires the signal, invoking all connected callbacks.
]=]
function Signal:Fire<T...>(...: T...)
	local current = self._head
	while current do
		if current._connected then
			task.spawn(current._callback, ...)
		end
		current = current._next
	end
end

--[=[
	@within Signal
	@method DisconnectAll
	Disconnects all active connections on the signal.
]=]
function Signal:DisconnectAll()
	self._head = nil
end

setmetatable(signal, {
	--__call = nil,
	__index = Signal
})

return signal
