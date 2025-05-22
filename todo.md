
### Middleware Functions
- [X] Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] Until: (self: Signal<T...>, predicate: (T...) -> boolean, callback: (T...) -> ()) -> Connection  
- [X] WhileActive: (self: Signal<T...>, check: () -> boolean, callback: (T...) -> ()) -> Connection  
- [X] ConnectForked: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] ConnectDeferred: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] ConnectAsync: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  

- [X] Fire: (self: Signal<T...>, T...) -> ()  
- [X] FireDeferred: (self: Signal<T...>, T...) -> ()  
- [X] FireAsync: (self: Signal<T...>, T...) -> ()  
- [X] FireBatched: (self: Signal<T...>, T...) -> ()  
- [X] FireWithMiddleware: (self: Signal<T...>, T...) -> ()  

- [X] Wait: (self: Signal<T...>, timeoutSeconds: number?) -> any  

- [X] Use: (self: Signal<T...>, middleware: (next: (T...) -> (), T...) -> ()) -> MiddlewareHandle  
- [X] UseFilter: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle  
- [X] UseMap: <U...>(self: Signal<T...>, mapper: (T...) -> U...) -> MiddlewareHandle  
- [X] UseThrottle: (self: Signal<T...>, seconds: number) -> MiddlewareHandle  
- [X] UseDebounce: (self: Signal<T...>, seconds: number) -> MiddlewareHandle  
- [X] UseDelay: (self: Signal<T...>, seconds: number) -> MiddlewareHandle  
- [X] UseLog: (self: Signal<T...>, prefix: string?) -> MiddlewareHandle  
- [X] UseCatch: (self: Signal<T...>, handler: (any) -> ()) -> MiddlewareHandle  
- [X] UseCancel: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle  

- [ ] GetListenerCount: (self: Signal<T...>) -> number  
- [ ] GetConnections: (self: Signal<T...>) -> { Connection }  
- [ ] DebugDescribe: (self: Signal<T...>) -> string  
- [ ] PrintDebugInfo: (self: Signal<T...>) -> ()  
- [ ] IsConnected: (self: Signal<T...>, callback: (T...) -> ()) -> boolean  
