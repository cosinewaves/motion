--!strict
-- init.lua

local signal = require(script.signal)
local internalTypings = require(script.internalTypings)

export type Connection = internalTypings.Connection
export type MiddlewareHandle = internalTypings.MiddlewareHandle
export type Signal<T...> = internalTypings.Signal<T...>

return {
  signal = signal,
}
