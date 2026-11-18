-- Finds the map folders built by WorldBuilder no matter how deeply they sit.

local Workspace = game:GetService("Workspace")

local WorldRefs = {}

function WorldRefs.root(): Instance?
	return Workspace:FindFirstChild("BrainrotWorld")
end

function WorldRefs.child(name: string): Instance?
	local root = WorldRefs.root()
	if root then
		local found = root:FindFirstChild(name)
		if found then
			return found
		end
	end
	return Workspace:FindFirstChild(name)
end

function WorldRefs.plots(): Folder?
	return WorldRefs.child("Plots") :: Folder?
end

function WorldRefs.beltBrainrots(): Folder?
	return WorldRefs.child("BeltBrainrots") :: Folder?
end

return WorldRefs
