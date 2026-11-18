-- Net: creates the remote events both sides talk over, once, and exposes them
-- by name. Keeping construction here means the client only ever waits on one
-- folder and there is no stringly-typed remote scavenging in gameplay code.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local REMOTE_NAMES = {
	"BuyBrainrot",
	"BuyFromShop",
	"StealBrainrot",
	"BuyLock",
	"Rebirth",
	"RequestState",
	"ProfileUpdated",
	"Notice",
	"HazardUpdated",
	"EffectBurst",
}

function Net.init()
	if not RunService:IsServer() then
		return ReplicatedStorage:WaitForChild("Remotes")
	end
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(REMOTE_NAMES) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder
end

function Net.get(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name) :: RemoteEvent
end

return Net
