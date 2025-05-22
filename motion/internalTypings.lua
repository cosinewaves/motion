--!strict
-- internalTypings.lua

export type Connection = {
    Disconnect: (self: Connection) -> (),
    DisconnectOn: (self: Connection, instance: Instance) -> (),
    UntilDestroyed: (self: Connection, token: any) -> (),
}

export type MiddlewareHandle = {
    Disconnect: () -> (),
}

export type Signal<T...> = {
    Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
    Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
    Until: (self: Signal<T...>, predicate: (T...) -> boolean, callback: (T...) -> ()) -> Connection,
    WhileActive: (self: Signal<T...>, check: () -> boolean, callback: (T...) -> ()) -> Connection,
    ConnectForked: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
    ConnectDeferred: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
    ConnectAsync: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,

    Fire: (self: Signal<T...>, T...) -> (),
    FireDeferred: (self: Signal<T...>, T...) -> (),
    FireAsync: (self: Signal<T...>, T...) -> (),
    FireBatched: (self: Signal<T...>, T...) -> (),
    FireWithMiddleware: (self: Signal<T...>, T...) -> (),

    Wait: (self: Signal<T...>, timeoutSeconds: number?) -> any,

    Use: (self: Signal<T...>, middleware: (next: (T...) -> (), T...) -> ()) -> MiddlewareHandle,
    UseFilter: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle,
    UseMap: <U...>(self: Signal<T...>, mapper: (T...) -> U...) -> MiddlewareHandle,
    UseThrottle: (self: Signal<T...>, seconds: number) -> MiddlewareHandle,
    UseDebounce: (self: Signal<T...>, seconds: number) -> MiddlewareHandle,
    UseDelay: (self: Signal<T...>, seconds: number) -> MiddlewareHandle,
    UseLog: (self: Signal<T...>, prefix: string?) -> MiddlewareHandle,
    UseCatch: (self: Signal<T...>, handler: (any) -> ()) -> MiddlewareHandle,
    UseCancel: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle,

    GetListenerCount: (self: Signal<T...>) -> number,
    GetConnections: (self: Signal<T...>) -> { Connection },
    DebugDescribe: (self: Signal<T...>) -> string,
    PrintDebugInfo: (self: Signal<T...>) -> (),
    IsConnected: (self: Signal<T...>, callback: (T...) -> ()) -> boolean,
}

return {}
