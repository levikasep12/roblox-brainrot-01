-- ClientState: the client's one view of server truth. It listens to the state
-- and hazard remotes, keeps the latest snapshot, and exposes a tiny observer
-- API so the HUD, shop and banner all render from the same numbers instead of
-- each wiring its own remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientState = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local state = {
	snapshot = nil,
	roster = {},
	hazard = { phase = "idle", left = 0, x2Left = 0 },
}

local listeners: { (string, any) -> () } = {}

local function fire(kind: string, payload: any)
	for _, listener in ipairs(listeners) do
		task.spawn(listener, kind, payload)
	end
end

function ClientState.get()
	return state
end

function ClientState.onChange(listener: (string, any) -> ())
	table.insert(listeners, listener)
end

function ClientState.init()
	remotes.ProfileUpdated.OnClientEvent:Connect(function(payload)
		if payload.self then
			state.snapshot = payload.self
		end
		if payload.roster then
			state.roster = payload.roster
		end
		fire("state", state)
	end)

	remotes.HazardUpdated.OnClientEvent:Connect(function(hazard)
		state.hazard = hazard
		fire("hazard", hazard)
	end)
end

function ClientState.request()
	remotes.RequestState:FireServer()
end

return ClientState
