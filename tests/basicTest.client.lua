--!strict

local Signal = require(path.to.signal) -- Replace with actual path
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a new signal instance
local mySignal = Signal.new<string, number>()

-- Connect a persistent listener
local conn1 = mySignal:Connect(function(msg, count)
	print("Persistent:", msg, count)
end)

-- Connect a one-time listener
mySignal:Once(function(msg, count)
	print("Once:", msg, count)
end)

-- Create a dummy instance to use for DisconnectOn
local testPart = Instance.new("Part")
testPart.Name = "TestPart"
testPart.Parent = ReplicatedStorage

-- Connect a listener that disconnects when the part is destroyed
local conn2 = mySignal:Connect(function(msg, count)
	print("DisconnectOn:", msg, count)
end)
conn2:DisconnectOn(testPart)

-- Fire the signal
mySignal:Fire("Hello", 1)

-- Output:
-- > Persistent: Hello 1
-- > Once: Hello 1
-- > DisconnectOn: Hello 1

-- Destroy the instance (triggers DisconnectOn)
testPart:Destroy()

-- Fire again
mySignal:Fire("World", 2)

-- Output:
-- > Persistent: World 2

-- Disconnect the remaining persistent connection
conn1:Disconnect()

-- Fire again (no output expected)
mySignal:Fire("Final", 3)
