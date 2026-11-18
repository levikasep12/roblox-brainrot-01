-- Shared client/server protocol: every RemoteEvent the game uses, created once on
-- the server and looked up (never created) on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
local folder = nil

local names = {
	"StateSync",
	"BuyResult",
	"BuyBrainrot",
	"Rebirth",
	"ToggleLock",
	"StealRequest",
	"ShowToast",
	"Celebrate",
}

function Remotes.init()
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(names) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder
end

function Remotes.get(name)
	if not folder then
		folder = ReplicatedStorage:WaitForChild("Remotes", 30)
	end
	if not folder then
		return nil
	end
	return folder:WaitForChild(name, 30)
end

return Remotes
