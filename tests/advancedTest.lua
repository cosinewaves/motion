local motion = require(ReplicatedStorage.motion)

-- Create a new signal instance
local signal = motion.new()

-- TEST: Connection Handling
local conn1 = signal:Connect(function(value) print("Connected:", value) end)
local conn2 = signal:Once(function(value) print("Once Trigger:", value) end)
local conn3 = signal:WhileActive(function() return true end, function(value) print("WhileActive:", value) end)

-- TEST: Conditional Connections
signal:Until(function(value) return value > 5 end, function(value) print("Until:", value) end)

-- TEST: Firing Events
signal:Fire(1)  -- Should trigger conn1, conn3 but not Until
signal:Fire(10) -- Should trigger conn1, conn3, Until

-- TEST: Fire Variants
signal:FireDeferred(20)
signal:FireAsync(30)
signal:FireBatched({ {40}, {50}, {60} })

-- TEST: FireWithMiddleware
signal:Use(function(next, value)
    print("Middleware - Modifying Value:", value * 2)
    next(value * 2)
end)
signal:FireWithMiddleware(5)

-- TEST: Middleware Utilities
signal:UseFilter(function(value) return value > 3 end)
signal:UseMap(function(value) return value * 2 end)
signal:UseThrottle(1)
signal:UseDebounce(1)
signal:UseDelay(1)
signal:UseLog("[TEST]")
signal:UseCatch(function(err) print("Caught Error:", err) end)
signal:UseCancel(function(value) return value < 5 end)

-- TEST: Debugging & Utility Functions
print("Listener Count:", signal:GetListenerCount())
print("Connections:", signal:GetConnections())
print("Debug Describe:", signal:DebugDescribe())
signal:PrintDebugInfo()

-- TEST: Connection Types
local connForked = signal:ConnectForked(function(value) print("Forked:", value) end)
local connDeferred = signal:ConnectDeferred(function(value) print("Deferred:", value) end)
local connAsync = signal:ConnectAsync(function(value) print("Async:", value) end)

-- TEST: IsConnected
print("Is conn1 connected?", signal:IsConnected(conn1._callback))

-- Cleanup
signal:DisconnectAll()
print("After DisconnectAll - Listener Count:", signal:GetListenerCount())
