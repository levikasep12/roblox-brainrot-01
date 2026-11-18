-- Creates (server) and waits for (client) the RemoteEvents both sides talk over.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.RemoteNames = {
	StateSnapshot = "StateSnapshot",
	Notify = "Notify",
	Burst = "Burst",
	BuyFromConveyor = "BuyFromConveyor",
	BuyFromShop = "BuyFromShop",
	StealRequest = "StealRequest",
	SellSlot = "SellSlot",
	BuyLock = "BuyLock",
	RequestRebirth = "RequestRebirth",
	RequestDash = "RequestDash",
}

local function remotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

function Net.server(): Folder
	local folder = remotesFolder()
	for _, name in pairs(Net.RemoteNames) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder
end

return Net
