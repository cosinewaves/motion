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

## 🚀 Quick Example

```lua
local Motion = require(path.to.Motion)

-- Type-safe signal: Player and number parameters
local scored = Motion.new<(player: Player, points: number)>()

-- Standard connection
local connection = scored:Connect(function(player, points)
	print(player.Name, "scored", points, "points!")
end)

-- One-time listener
scored:Once(function(player)
	print(player.Name, "scored once!")
end)

-- Conditional listener
scored:Until(function(player)
	return player.Name == "CoolGuy42"
end, function(player)
	print("Only CoolGuy42 triggered this")
end)

-- Fire the signal
scored:Fire(player, 10)

-- Automatic cleanup on Instance removal
connection:DisconnectOn(player)
