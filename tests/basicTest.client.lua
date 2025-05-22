local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.motion) -- Replace with actual path

local mySignal = Signal.new()

mySignal:Connect(function()
	print("fired")
end)

while task.wait(2) do
	mySignal:Fire()
end
