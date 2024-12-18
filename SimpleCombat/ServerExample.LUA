--!strict 
local Players = game:GetService('Players')

local Warp = require(game:GetService('ReplicatedStorage').NetworkRelated.Warp)
local RequestAnimationsTable = Warp.Server('RequestAnimationsTable', {maxEntrance = 25, interval = 1})
local RequestMouseCombo = Warp.Server('RequestMouseCombo', {maxEntrance = 25, interval = 1})
local RequestCooldowns = Warp.Server('RequestCooldowns', {maxEntrance = 25, interval = 1})
local RequestForwardDash = Warp.Server('RequestForwardDash', {maxEntrance = 25, interval = 1})

local SignalRequestApplyStun = Warp.Signal('SignalRequestApplyStun')

local ServerRequestChangeBoolean = Warp.Server('ServerRequestChangeBoolean')

local PlayerProfiles = require(game:GetService('ServerStorage').Profiles.PlayerProfiles)
local MovesetsInit = require(game:GetService('ServerStorage').MovesetRelated.MovesetsInit)
local MovesetsAssets = require(game:GetService('ServerStorage').MovesetRelated.MovesetsAssets)

local playersMoveset = {}

local function Cooldown(waitTime : number, tickVariable : number, enemyCharacter : Model)
	if (tick() - tickVariable) < waitTime then return end
	
	enemyCharacter:SetAttribute('IsStunned', false)
	--PlayerProfiles[player.UserId].IsStunned = false
	return true
end

-- The function used for deep copying a table
local function deepCopy(original)
	-- Define the new table for the copy
	local copy = {}
	-- Loop through the original table to clone
	for key, value in original do
		-- If the type of the value is a table, deep copy it to the key (index)
		-- Else (or) the type isn't a table, assign the default value to the index instead
		copy[key] = type(value) == "table" and deepCopy(value) or value
	end
	-- Return the finalized copy of the deep cloned table
	return copy
end

Players.PlayerAdded:Connect(function(player)
	local profile = PlayerProfiles.new(player)
	playersMoveset[player.UserId] = MovesetsInit.new(player, MovesetsAssets.Test)
	
	local character = player.Character or player.CharacterAdded:Wait()
	character:SetAttribute('IsStunned', false)
	
	player.CharacterAdded:Connect(function(character)
		character:SetAttribute('IsStunned', false)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerProfiles[player.UserId]:EndExisting()
	task.wait(5)
	
	playersMoveset[player.UserId] = nil
	PlayerProfiles[player.UserId] = nil
end)

RequestAnimationsTable:Connect(function(player)
	--print(playersMoveset[player.UserId].movesetAssets.Animations)
	
	return deepCopy(playersMoveset[player.UserId].movesetAssets.Animations)
end)

RequestCooldowns:Connect(function(player)
	return playersMoveset[player.UserId].movesetAssets.Cooldowns
end)

RequestForwardDash:Connect(function(player, targetCharacter : CFrame | Model)
	local userId = player.UserId
	
	if player.Character and player.Character:FindFirstChild('RagdollTrigger') then 
		if player.Character:FindFirstChild('RagdollTrigger').Value then return end
	end
	
	if PlayerProfiles[userId].IsStunned or not targetCharacter then return end
	if typeof(targetCharacter) == 'CFrame' then 
	elseif typeof(targetCharacter) == 'Instance' then 
		if targetCharacter:IsA('Model') == false then return end
	else
		return
	end
	
	if PlayerProfiles[userId].ForwardDashCooldown > 0 then return end
	playersMoveset[userId]:DashInitiated('forward', targetCharacter)
end)

RequestMouseCombo:Connect(function(player, comboCount : number, jumpHold : boolean)
	local userId = player.UserId
	
	if player.Character and player.Character:FindFirstChild('RagdollTrigger') then 
		if player.Character:FindFirstChild('RagdollTrigger').Value then return end
	end
	
	if PlayerProfiles[userId].IsStunned then print('stunned') return end
	if not comboCount or jumpHold == nil then return end
	if typeof(comboCount) ~= 'number' or typeof(jumpHold) ~= 'boolean' then print('typa shi') return end
	
	if PlayerProfiles[userId].MOnesCooldown > 0 then return end
	
	print(jumpHold)
	playersMoveset[userId]:MOnesInitiated(comboCount, jumpHold)
end)

local defaultWalkSpeed = 16
local defaultJumpHeight = 5.2

SignalRequestApplyStun:Connect(function(enemyCharacter : Model, enemyPlayer : Player, stunnedTime : number)	
	local enemyHumanoid = enemyCharacter:FindFirstChildOfClass('Humanoid')
	if not enemyHumanoid then return end
	
	local userId = enemyPlayer.UserId	
	local stunnedAttribute = enemyCharacter:GetAttribute('IsStunned')
	if stunnedAttribute == nil then return end
	--print(PlayerProfiles[userId].IsStunned)
	
	if enemyCharacter:GetAttribute('IsStunned') then 
		PlayerProfiles[userId].StunnedTick = tick()
		
		task.wait(stunnedTime)
		coroutine.wrap(Cooldown)(stunnedTime, PlayerProfiles[userId].StunnedTick, enemyCharacter)
		
		return
	end
	
	enemyCharacter:SetAttribute('IsStunned', true)
	--PlayerProfiles[userId].IsStunned = true
	PlayerProfiles[userId].StunnedTick = tick()
	
	coroutine.wrap(function()
		task.wait(stunnedTime)
		Cooldown(stunnedTime, PlayerProfiles[userId].StunnedTick, enemyCharacter)
	end)()
	--coroutine.wrap(Cooldown)(stunnedTime, PlayerProfiles[userId].StunnedTick, enemyPlayer)
	
	while enemyCharacter:GetAttribute('IsStunned') do
		task.wait()
		enemyHumanoid.WalkSpeed = 0
		enemyHumanoid.JumpHeight = 0
	end
	print('to default')
	
	enemyHumanoid.WalkSpeed = defaultWalkSpeed
	enemyHumanoid.JumpHeight = defaultJumpHeight
	
	--ServerRequestChangeBoolean:Fire(true, enemyPlayer, 'stunned', false)
end)
