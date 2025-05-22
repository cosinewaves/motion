
### Middleware Functions
- [X] Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] Until: (self: Signal<T...>, predicate: (T...) -> boolean, callback: (T...) -> ()) -> Connection  
- [X] WhileActive: (self: Signal<T...>, check: () -> boolean, callback: (T...) -> ()) -> Connection  
- [X] ConnectForked: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] ConnectDeferred: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  
- [X] ConnectAsync: (self: Signal<T...>, callback: (T...) -> ()) -> Connection  

- [X] Fire: (self: Signal<T...>, T...) -> ()  
- [ ] FireDeferred: (self: Signal<T...>, T...) -> ()  
- [ ] FireAsync: (self: Signal<T...>, T...) -> ()  
- [ ] FireBatched: (self: Signal<T...>, T...) -> ()  
- [ ] FireWithMiddleware: (self: Signal<T...>, T...) -> ()  

- [X] Wait: (self: Signal<T...>, timeoutSeconds: number?) -> any  

- [ ] Use: (self: Signal<T...>, middleware: (next: (T...) -> (), T...) -> ()) -> MiddlewareHandle  
- [ ] UseFilter: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle  
- [ ] UseMap: <U...>(self: Signal<T...>, mapper: (T...) -> U...) -> MiddlewareHandle  
- [ ] UseThrottle: (self: Signal<T...>, seconds: number) -> MiddlewareHandle  
- [ ] UseDebounce: (self: Signal<T...>, seconds: number) -> MiddlewareHandle  
- [ ] UseDelay: (self: Signal<T...>, seconds: number) -> MiddlewareHandle  
- [ ] UseLog: (self: Signal<T...>, prefix: string?) -> MiddlewareHandle  
- [ ] UseCatch: (self: Signal<T...>, handler: (any) -> ()) -> MiddlewareHandle  
- [ ] UseCancel: (self: Signal<T...>, predicate: (T...) -> boolean) -> MiddlewareHandle  

- [ ] GetListenerCount: (self: Signal<T...>) -> number  
- [ ] GetConnections: (self: Signal<T...>) -> { Connection }  
- [ ] DebugDescribe: (self: Signal<T...>) -> string  
- [ ] PrintDebugInfo: (self: Signal<T...>) -> ()  
- [ ] IsConnected: (self: Signal<T...>, callback: (T...) -> ()) -> boolean  
