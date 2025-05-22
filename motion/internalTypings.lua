--!strict
-- internalTypings.lua

--[=[
	@Module internalTypings
	Internal type definitions for Signal and Connection interfaces.
]=]

--[=[
	@interface Connection
	Represents a handle to a connection that can be disconnected or bound to a lifecycle.
]=]
export type Connection = {
	--[=[
		Disconnects this connection.
	]=]
	Disconnect: (self: Connection) -> (),

	--[=[
		Automatically disconnects this connection when the given Instance is destroyed.
	]=]
	DisconnectOn: (self: Connection, instance: Instance) -> (),

	--[=[
		Disconnects this connection when the given destruction token is triggered.
	]=]
	UntilDestroyed: (self: Connection, token: any) -> (),
}

--[=[
	@interface MiddlewareHandle
	Represents a handle returned from middleware that can be used to disconnect the middleware.
]=]
export type MiddlewareHandle = {
	--[=[
		Disconnects the middleware from the signal.
	]=]
	Disconnect: () -> (),
}

--[=[
	@interface Signal<T...>
	Represents a typed signal system that supports firing, listening, and middleware.
]=]
export type Signal<T...> = {
	-- Core
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Until: (self: Signal<T...>, predicate: (T...) -> boolean, callback: (T...) -> ()) -> Connection,
	WhileActive: (self: Signal<T...>, check: () -> boolean, callback: (T...) -> ()) -> Connection,
	ConnectForked: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	ConnectDeferred: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	ConnectAsync: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,

	-- Firing
	Fire: (self: Signal<T...>, T...) -> (),
	FireDeferred: (self: Signal<T...>, T...) -> (),
	FireAsync: (self: Signal<T...>, T...) -> (),
	FireBatched: (self: Signal<T...>, T...) -> (),
	FireWithMiddleware: (self: Signal<T...>, T...) -> (),

	-- Waiting
	Wait: (self: Signal<T...>, timeoutSeconds: number?) -> (...T...) | (nil, true),

	-- Middleware
	Use: (self: Signal<T...>, middleware: (next: (T...) -> (), T...) -> ()) -> MiddlewareHandle,
	UseFilter: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle,
	UseMap: <U...>(self: Signal<T...>, mapper: (T...) -> U...) -> MiddlewareHandle,
	UseThrottle: (self: Signal<T...>, seconds: number) -> MiddlewareHandle,
	UseDebounce: (self: Signal<T...>, seconds: number) -> MiddlewareHandle,
	UseDelay: (self: Signal<T...>, seconds: number) -> MiddlewareHandle,
	UseLog: (self: Signal<T...>, prefix: string?) -> MiddlewareHandle,
	UseCatch: (self: Signal<T...>, handler: (any) -> ()) -> MiddlewareHandle,
	UseCancel: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle,

	-- Debug
	GetListenerCount: (self: Signal<T...>) -> number,
	GetConnections: (self: Signal<T...>) -> { Connection },
	DebugDescribe: (self: Signal<T...>) -> string,
	PrintDebugInfo: (self: Signal<T...>) -> (),
	IsConnected: (self: Signal<T...>, callback: (T...) -> ()) -> boolean,
}

return "internalTypings"
