--!strict
-- Connection.lua

local internalTypings = require(script.Parent.internalTypings)

export type Connection = internalTypings.Connection

--[=[
	@class Connection
	Represents a connection to a Signal that can be manually or automatically disconnected.
]=]

local Connection = {}
Connection.__index = Connection

-- Internal private fields
type InternalConnection = Connection & {
	_signal: {
		_head: InternalConnection?,
	},
	_callback: (...any) -> (),
	_connected: boolean,
	_next: InternalConnection?,
}

--[=[
	Creates a new connection instance.
	@param signal any -- The signal this connection is bound to
	@param callback (...any) -> () -- The callback to invoke when the signal fires
	@return Connection
]=]
function Connection.new(signal: { _head: InternalConnection? }, callback: (...any) -> ()): Connection
	local self: InternalConnection = setmetatable({
		_signal = signal,
		_callback = callback,
		_connected = true,
		_next = nil,
	}, Connection)

	return self
end

--[=[
	Disconnects the connection from the signal.
]=]
function Connection:Disconnect()
	local self = self :: InternalConnection
	if not self._connected then return end
	self._connected = false

	local head = self._signal._head
	if head == self then
		self._signal._head = self._next
	else
		local prev = head
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

--[=[
	Automatically disconnects this connection when the given Instance is destroyed.
	@param instance Instance -- The instance to monitor for destruction
]=]
function Connection:DisconnectOn(instance: Instance)
	local self = self :: InternalConnection

	local conn: RBXScriptConnection = instance.Destroying:Connect(function()
		self:Disconnect()
	end)

	if not instance:IsDescendantOf(game) then
		self:Disconnect()
	end
end

--[=[
	Automatically disconnects this connection when the given token is triggered.
	@param token any -- A token with a `__connectionCleanupCallbacks` table
]=]
function Connection:UntilDestroyed(token: { __connectionCleanupCallbacks: { () -> () } }?)
	local self = self :: InternalConnection

	if typeof(token) ~= "table" then
		error("UntilDestroyed token must be a table", 2)
	end

	if not token.__connectionCleanupCallbacks then
		token.__connectionCleanupCallbacks = {}
	end

	table.insert(token.__connectionCleanupCallbacks, function()
		self:Disconnect()
	end)
end

return Connection
