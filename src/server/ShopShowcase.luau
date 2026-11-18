-- Places three static showcase brainrots on the shop pedestals so the shop
-- reads as a shop in a screenshot, with their names and rates floating above.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local BrainrotModel = require(ReplicatedStorage.Shared.BrainrotModel)
local WorldRefs = require(ReplicatedStorage.Shared.WorldRefs)

local ShopShowcase = {}

local SHOWCASE_DEFS = { "croissant_cactus", "toilet_wizard", "mango_mafia_don" }

function ShopShowcase.build()
	local existing = Workspace:FindFirstChild("ShopShowcase")
	if existing then
		existing:Destroy()
	end
	local shop = WorldRefs.child("Shop")
	if not shop then
		return
	end

	local container = Instance.new("Folder")
	container.Name = "ShopShowcase"
	container.Parent = Workspace

	for index, defId in ipairs(SHOWCASE_DEFS) do
		local def = BrainrotDefs.get(defId)
		local pedestal = shop:FindFirstChild("DisplayPedestal" .. index)
		if def and pedestal and pedestal:IsA("BasePart") then
			local model = BrainrotModel.build(def)
			model.Name = "Showcase_" .. defId
			model:PivotTo(CFrame.new(pedestal.Position + Vector3.new(0, pedestal.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(-90), 0))
			BrainrotModel.addLabel(model, def, "Normal")
			model.Parent = container
		end
	end
end

return ShopShowcase
