--//
--comments and code was made by usaras
--//

--//GAMEPLAY EXPLANATION
--Press this buttons to test gameplay

--1: Press this button to activate first move, you'll know it working when you'll see red lines
--2:Press this button to activate second move, you'll know it working when you'll see red lines
--3: Press this button to activate third move, you'll know it working when you'll see red lines (You will not see red lines when ultimate is active on this move!)
--4: Press this button to activate fourth move, you'll know it working when you'll see red lines (You will not see red lines when ultimate is active on this move!)

--G: Press this button to activate ultimate

--You will have ultimate in the start. Don't be fooled by empty ultimate bar because I send 0 as second argument in line 220

--//HOW WILL MOVES WORK: (They all do not have animations)

--NON-ULTIMATE: 
--1: basically a barrage. Touch a player to deal damage and stun
--2: meant to be a leg kick, touch a player to deal damage and stun (may be a hard job)
--3: touch a player to deal a damage(and stun) and launch him from you!
--4: touch a player to deal huge amount of damage and stun

--ULTIMATE:
--1: same barrage but with damage buff
--2: This move will cause you to dash. If you'll touch a player they will fly away and will be stunned
--3: Stuns nearby enemy and give them vulnerability
--4: Will give you a speed buff!


--//

--Services inizialization
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

--Modules inizialization
local Modules = ServerStorage.Modules
local RaycastHitbox = require(Modules.RaycastHitboxV4) --Module that contains hitbox logic using raycast
local PlayerParametersModule = require(Modules.PlayerParameters) --Module that will construct player params
local GameParameters = require(Modules.GameParameters) --Module that contains game parameters
local AttackParameters = require(Modules.AttackParameters) --Module that have params for attack moves
local AttackModule = require(Modules.AttackModule).new() --Module that contains attack moves logic

--Remote events inizialization
local RemoteEvents = ReplicatedStorage.RemoteEvents
local AttackAction = RemoteEvents.AttackAction
local EndUltimate = RemoteEvents.EndUltimate
local UpdateUIBar = RemoteEvents.UpdateUIBar

--Remote functions inizialization
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ActivateUltimate = RemoteFunctions.ActivateUltimate

--Tables inizialization
local playersParameters = {} --a table that contains players params (inizialization happens in playerAdded function)
local playersHitboxes = {} --a table that will contain hitboxes 
local playersCooldowns = {} --a table that will contain cooldowns for each action

--Constraint variables
local MAX_ULTIMATE_POINTS = GameParameters.MAX_ULTIMATE_POINTS
local DEFAULT_MOVEMENT_SPEED = GameParameters.DEFAULT_MOVEMENT_SPEED
local VULNERABILITY_DEBUFF = GameParameters.VULNERABILITY_DEBUFF 
local STUN_WALKSPEED = GameParameters.STUN_WALKSPEED

local hitboxes = { --A table that is used to create hitboxes. It take key as hitbox name and take value as hitbox parent.
	['RightArmHitbox'] = "Right Arm",
	['LeftArmHitbox'] = "Left Arm",
	['RightLegHitbox'] = "Right Leg",
	['LeftLegHitbox'] = "Left Leg",
	['TorsoHitBox'] = "Torso"
}

local hitboxesPointsPosition = { --Table which contain hitbox points relatively to hitbox parent
	['RightArmHitbox'] = {Vector3.new(0, -1, 0)}, --Point will be placed -1 on Y dimension relatively to it's parent
	['LeftArmHitbox'] = {Vector3.new(0, -1, 0)},
	['RightLegHitbox'] = {Vector3.new(0, -1, 0)},
	['LeftLegHitbox'] = {Vector3.new(0, -1, 0)},
	['TorsoHitBox'] = {Vector3.new(0, 0, 2), Vector3.new(2, 0, 2), Vector3.new(-2, 0, 2)}
}

local function clearHitboxes(hitboxesTable)
	for hitboxName, hitboxParams in next, hitboxesTable do
		hitboxParams[1]:Destroy() --A RaycastHitbox module method that clears hitbox.
		
		table.clear(hitboxParams) --a table method that clears hitboxParams to insert new params
	end
end

local function PunchLanded(actionName, humanoid, playerUserId, inUltimate)
	local enemyPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)

	if enemyPlayer == nil then --Checking if player is actual player
		humanoid:TakeDamage(playersParameters[playerUserId].CurrentDamage) --Using humanoid TakeDamage method and as parameter I give varuable 'current damage' from table called playersParams

		return
	end
	
	local stunTime
	
	if inUltimate then --Checking if player in ultimate and sets different stun time depending on this
		stunTime = AttackParameters.ULTIMATE_MOVES[actionName].STUN_TIME 
	else
		stunTime = AttackParameters[actionName].STUN_TIME
	end
	
	if playersParameters[enemyPlayer.UserId].Vulnerable then playersParameters[playerUserId].CurrentDamage *= VULNERABILITY_DEBUFF end --Checking if vulnerable varuable is True and if so it multiplies Current Damage Varuable by const

	local enemyPlayerUserId = enemyPlayer.UserId
	humanoid:TakeDamage(playersParameters[playerUserId].CurrentDamage)
	
	playersParameters[enemyPlayerUserId].Stunned = true
	humanoid.WalkSpeed = STUN_WALKSPEED 
	task.wait(stunTime)
	humanoid.WalkSpeed = DEFAULT_MOVEMENT_SPEED
	playersParameters[enemyPlayerUserId].Stunned = false
end

local actionOnHitFunctions = {
	["ACTION_MOVE1"] = function(humanoid, playerUserId)
		PunchLanded("ACTION_MOVE1", humanoid, playerUserId)
	end,
	
	["ACTION_MOVE2"] = function(humanoid,playerUserId)
		coroutine.wrap(function() --Ragdoll logic. When ragdollTrigger value is true player will become ragdoll (Not working on NPCs)
			humanoid.Parent.RagdollTrigger.Value = true
			task.wait(AttackParameters.ACTION_MOVE2.RAGDOLL_TIME)
			humanoid.Parent.RagdollTrigger.Value = false
		end)()
		
		PunchLanded("ACTION_MOVE2", humanoid, playerUserId)
	end,
	
	["ACTION_MOVE3"] = function(humanoid, playerUserId)
		coroutine.wrap(function() --This function creates another thread and makes enemy fly away in other direction of his HRP lookVector
			local enemyHumanoidRootPart = humanoid.Parent.HumanoidRootPart
			
			local linearVelocity = Instance.new('LinearVelocity', enemyHumanoidRootPart) --Creating a linear velocity to move character and parenting it to character humanoid root part
			linearVelocity.Attachment0 = enemyHumanoidRootPart.RootAttachment --Attachment0 is 'center' of the linear velocity
			linearVelocity.MaxForce = math.huge --Setting  maxForce to math.huge so vector can apply much more magnitude 
			linearVelocity.VectorVelocity = enemyHumanoidRootPart.CFrame.lookVector * AttackParameters.ACTION_MOVE3.VELOCITY_MULTIPLIER --Vector of velocity basically in this direction character will move
			
			task.wait(AttackParameters.ACTION_MOVE3.VELOCITY_DESTROY_TIME)
			
			linearVelocity:Destroy() --Destroying velocity to stop it's affection on character humanoidRootPart
		end)()
		
		coroutine.wrap(function() --Creating a new 'thread' so the next 3 lines of code will be completed on other thread. That means 'punchLanded' will be called immediatly. 
			humanoid.Parent.RagdollTrigger.Value = true
			task.wait(AttackParameters.ACTION_MOVE3.RAGDOLL_TIME)
			humanoid.Parent.RagdollTrigger.Value = false
		end)() --This thread was created to bypass task.wait() and call 'punchLanded' immediatly
		
		PunchLanded("ACTION_MOVE3", humanoid, playerUserId)
	end,
	
	["ACTION_MOVE4"] = function(humanoid, playerUserId)
		PunchLanded("ACTION_MOVE4", humanoid, playerUserId)
	end,
	
	["Ultimate"] = {
		["ACTION_MOVE1"] = function(humanoid, playerUserId)
			PunchLanded("ACTION_MOVE1", humanoid, playerUserId, true)
		end,

		["ACTION_MOVE2"] = function(humanoid, playerUserId)
			local humanoidRootPart = Players:GetPlayerByUserId(playerUserId).Character.HumanoidRootPart
			
			coroutine.wrap(function()
				local enemyHumanoidRootPart = humanoid.Parent.HumanoidRootPart

				local linearVelocity = Instance.new('LinearVelocity', enemyHumanoidRootPart)
				linearVelocity.Attachment0 = enemyHumanoidRootPart.RootAttachment
				linearVelocity.MaxForce = math.huge
				linearVelocity.VectorVelocity = humanoidRootPart.CFrame.lookVector * AttackParameters.ULTIMATE_MOVES.ACTION_MOVE2.VELOCITY_MULTIPLIER

				task.wait(AttackParameters.ULTIMATE_MOVES.ACTION_MOVE2.VELOCITY_DESTROY_TIME - .5)

				linearVelocity:Destroy()
			end)()

			coroutine.wrap(function()
				humanoid.Parent.RagdollTrigger.Value = true
				task.wait(AttackParameters.ULTIMATE_MOVES.ACTION_MOVE2.RAGDOLL_TIME)
				humanoid.Parent.RagdollTrigger.Value = false
			end)()			
			
			PunchLanded("ACTION_MOVE2", humanoid, playerUserId, true)
		end
	}
}

local function createHitboxes(character, playerUserId)
	local params = RaycastParams.new() --Create new params and makes ray to ignore character
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	clearHitboxes(playersHitboxes[playerUserId]) --Clear hitboxes so we can create new hitboxes
	
	for hitboxName, hitboxPart in next, hitboxes do --Loop that actually create hitboxes. 
		local part = character[hitboxPart]
		
		playersHitboxes[playerUserId][hitboxName] = {RaycastHitbox.new(part), part} --Takes hitboxName as key and value is a table which first element is hitbox and second is his parent
	end
	
	for hitboxName, hitboxParams in next, playersHitboxes[playerUserId] do --Iterates through playerHitboxes table
		hitboxParams[1]:SetPoints(hitboxParams[2], hitboxesPointsPosition[hitboxName]) --Set points where ray will be casted.
		hitboxParams[1].RaycastParams = params --Sets ray params so he will ignore character
		
		hitboxParams[1].OnHit:Connect(function(hit, humanoid)
			local actionFunction
			local CurrentAttackMove = playersParameters[playerUserId].CurrentAttackMove
			
			if playersParameters[playerUserId].UltimateActive then --Check if player in ULT
				actionFunction = actionOnHitFunctions.Ultimate[CurrentAttackMove] --Get function from "actionOnHitFunctions" table
			else
				actionFunction = actionOnHitFunctions[CurrentAttackMove] --Get function from "actionOnHitFunctions" table
			end
			
			playersParameters[playerUserId].UltimatePoints += GameParameters.ULTIMATE_POINTS_ADDED_PER_HIT --Give player points if hit was succesful
			if playersParameters[playerUserId].UltimatePoints > MAX_ULTIMATE_POINTS then playersParameters[playerUserId].UltimatePoints = MAX_ULTIMATE_POINTS end --Check if we have enought ultimate points to activate ultimate
			
			UpdateUIBar:FireClient(Players:GetPlayerByUserId(playerUserId), playersParameters[playerUserId].UltimatePoints, MAX_ULTIMATE_POINTS) --This event upgrade Ultimate bar 
			actionFunction(humanoid, playerUserId) --Call function from "actionOnHitFunctions" table
		end)
	end
end

Players.PlayerAdded:Connect(function(player) --This function is called when player joining
	local playerUserId = player.UserId
	UpdateUIBar:FireClient(player, 0, MAX_ULTIMATE_POINTS) --Event upgrades ultimate bar second argument is current amount of ult points 
	
	playersParameters[playerUserId] = PlayerParametersModule.new() --creates player parameters using player parameters module
	playersHitboxes[playerUserId] = {} --creates a key-value with key of playerUserId and value of blank table
	
	playersCooldowns[playerUserId] = {
		["ACTION_MOVE1"] = false,
		["ACTION_MOVE2"] = false,
		["ACTION_MOVE3"] = false,
		["ACTION_MOVE4"] = false
	} --set up player cooldowns
	
	local character = player.Character or player.CharacterAdded:Wait() --Waitning for character
	createHitboxes(character, playerUserId)
	
	player.CharacterAdded:Connect(function(character)
		createHitboxes(character, playerUserId)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local playerUserId = player.UserId
	
	--We nullifying all variables because they are useless when player disconnected so we don't have memory leaks
	playersParameters[playerUserId] = nil 
	playersCooldowns[playerUserId] = nil
	
	clearHitboxes(playersHitboxes[playerUserId])
	playersHitboxes[playerUserId] = nil
end)

local function OnUltimateActivation(player)
	local playerUserId = player.UserId
	
	local parameters = playersParameters[playerUserId] --Get table with player parameters
	
	if parameters.UltimateActive == false and parameters.UltimatePoints >= GameParameters.MAX_ULTIMATE_POINTS  then
		coroutine.wrap(function()
			local playerLeft
			
			while playersParameters[playerUserId].UltimatePoints > 0 do --This loop will work until we have zero ult points
				playersParameters[playerUserId].UltimatePoints -= GameParameters.ULTIMATE_POINTS_DECREASE_RATE
				
				UpdateUIBar:FireClient(player, playersParameters[playerUserId].UltimatePoints, MAX_ULTIMATE_POINTS)
				
				
				task.wait(GameParameters.ULTIMATE_POINTS_DECREASE_TIME)
				
				if playersParameters[playerUserId] == nil then playerLeft = true break end --checks if player left
			end
			
			if playerLeft then return end
			
			playersParameters[playerUserId].UltimateActive = false
			EndUltimate:FireClient(player) --This event sends to client to end ultimate. This will change their moveset!
			print("Ultimate ended")
		end)()
		
		playersParameters[playerUserId].UltimateActive = true
		
		return true
	end
	
	print("Not enough points or ultimate Already active")
	
	return false
end

ActivateUltimate.OnServerInvoke = OnUltimateActivation

local existingActionsNames = {"ACTION_MOVE1", "ACTION_MOVE2", "ACTION_MOVE3", "ACTION_MOVE4"}

local actionNameToFunction = {
	["ACTION_MOVE1"] = "JabFury",
	["ACTION_MOVE2"] = "LegSweep",
	["ACTION_MOVE3"] = "GrappleThrow",
	["ACTION_MOVE4"] = "DemonBackhandStrike",
}

local actionNameToUltimateFunction = {
	["ACTION_MOVE1"] = "DemonsFury",
	["ACTION_MOVE2"] = "OgresRampage",
	["ACTION_MOVE3"] = "DragonsRoar",
	["ACTION_MOVE4"] = "TigersInstinct",
}

AttackAction.OnServerEvent:Connect(function(player, attackName)
	local playerUserId = player.UserId
	
	if table.find(existingActionsNames, attackName) == nil then print("Not found action name!") return end --Check if we have action name in "existingActionsNames" if not then return
	if playersCooldowns[playerUserId][attackName] then print("Ability on cooldown!") return end --Check if player ability not on cooldown
	if playersParameters[playerUserId].AttackOnProcess then print("Attack on process!") return end --Check if player have other attack on process
	if playersParameters[playerUserId].Stunned then print("Player stunned") return end --Check if player is stunned
	
	playersCooldowns[playerUserId][attackName] = true
	playersParameters[playerUserId].AttackOnProcess = true
	
	local ultimateActive = playersParameters[playerUserId].UltimateActive
	
	local abilityCooldown 
	local attackFunctionName
	local processTime
	
	if ultimateActive then
		attackFunctionName = actionNameToUltimateFunction[attackName]
		abilityCooldown = AttackParameters.ULTIMATE_MOVES[attackName].COOLDOWN
		processTime = AttackParameters.ULTIMATE_MOVES[attackName].PROCESS_TIME
		playersParameters[playerUserId].CurrentDamage = AttackParameters.ULTIMATE_MOVES[attackName].DAMAGE
	else
		attackFunctionName = actionNameToFunction[attackName]
		abilityCooldown = AttackParameters[attackName].COOLDOWN
		processTime = AttackParameters[attackName].PROCESS_TIME
		playersParameters[playerUserId].CurrentDamage = AttackParameters[attackName].DAMAGE
	end
	
	playersParameters[playerUserId].CurrentAttackMove = attackName
	
	AttackModule[attackFunctionName](AttackModule, playersHitboxes[playerUserId], player.Character, playersParameters) --Call a function from attack module!
	
	coroutine.wrap(function()
		task.wait(processTime)
		playersParameters[playerUserId].AttackOnProcess = false
	end)()
	
	task.wait(abilityCooldown)
	playersCooldowns[playerUserId][attackName] = false
end)
