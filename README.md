# 🚦 Motion — A Type-Safe, Powerful Signal Library for Roblox

**Motion** is a modern, ergonomic signal/event system for Roblox, built with type safety, performance, and developer experience in mind. It goes beyond basic `BindableEvent` or `Signal` patterns, enabling expressive, reactive, and clean event-driven architecture.

---

## ✨ Features

- ✅ **Type-Safe Signals**  
  Define strict parameter types using Luau generics — catch errors at compile time.

- 🔍 **Connection Inspection & Debugging**  
  View active connections, listener counts, and source locations using built-in dev tools.

- 🔂 **One-Time and Conditional Listeners**  
  Expressive APIs like `.Once()`, `.Until(predicate)`, and `.WhileActive()` for flexible event handling.

- 🧹 **Automatic Cleanup**  
  Tie listeners to instances or tokens to automatically disconnect on destroy or custom cleanup.

- ⏱️ **Thread-Controlled Emission**  
  Choose how and when signals dispatch: synchronously, deferred, batched, or async with `task.spawn`.

- 🧩 **Middleware & Interception**  
  Add logic before listeners receive events. Filter, transform, or cancel emissions with `.Use()` middleware.

- 🔗 **Signal Composition**  
  Combine, merge, and filter signals — create reactive pipelines without a full Rx implementation.

---
