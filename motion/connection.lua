--!strict
-- Connection.lua

local internalTypings = require(script.Parent.internalTypings)

export type Connection = internalTypings.Connection

--[=[
    @class Connection

    Represents a link between a signal and a listener callback.
    Calling `Disconnect()` will remove the listener from the signal.
]=]
local Connection = {}
Connection.__index = Connection

type InternalConnection = Connection & {
    _signal: {
        _head: InternalConnection?,
    },
    _callback: (...any) -> (),
    _connected: boolean,
    _next: InternalConnection?,
}

--[=[
    Creates a new connection object internally tied to a signal.

    @param signal { _head: Connection? } -- The signal the connection is associated with.
    @param callback (...any) -> () -- The listener function to be called on signal fire.
    @return Connection

    @within Connection
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
    Disconnects the connection, preventing the callback from being called again.

    @within Connection
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
    Automatically disconnects the connection when the given Instance is destroyed.

    @param instance Instance -- The Roblox instance to track for automatic disconnection.

    @within Connection
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
    Registers the connection to be cleaned up when a provided token object is disposed.

    The token should be a table that has or will have a `__connectionCleanupCallbacks` array field.
    This allows grouping multiple connections to clean up together.

    @param token { __connectionCleanupCallbacks: { () -> () } }? -- The cleanup token to register with.
    @within Connection
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
