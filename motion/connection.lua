--!strict
-- Connection.lua

local internalTypings = require(script.Parent.internalTypings)

export type Connection = internalTypings.Connection

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

function Connection.new(signal: { _head: InternalConnection? }, callback: (...any) -> ()): Connection
    local self: InternalConnection = setmetatable({
        _signal = signal,
        _callback = callback,
        _connected = true,
        _next = nil,
    }, Connection)

    return self
end

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

function Connection:DisconnectOn(instance: Instance)
    local self = self :: InternalConnection

    local conn: RBXScriptConnection = instance.Destroying:Connect(function()
        self:Disconnect()
    end)

    if not instance:IsDescendantOf(game) then
        self:Disconnect()
    end
end

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
