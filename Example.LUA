local module = {}
module.__index = module

--When adding new zombies don't forget about adding them to these tables below! And most important add them to ServerStorage ZombiesModels!

function module.new()
	local self = setmetatable({}, module)
	
	local bindableEvents = game:GetService('ServerStorage').BindableEvents
	
	self.player = {}
	self.gameStatus = require(game.ServerStorage.Modules.GameStatus)
	
	self.allies = {}
	self.ZombieDied = bindableEvents.ZombieDied
	
	self._locationToReach = workspace.SpawnLocation.Position
	self._spawnLocation = workspace.GameLocation["Stone Portal"].Front.CFrame
	
	local friendlyNPCS = workspace.FriendlyNPCS
	local players = workspace.Players
	
	local arrow = game:GetService('ReplicatedStorage').PlayersWeapon.Bow.Arrow
	
	self._zombiesModels = game:GetService('ServerStorage').ZombiesModels
	self._zombies = {}
	self._zombiesParameters = require(game.ServerStorage.Modules.ZombieParameters)
	self._zombiesAttacks = {
		[self._zombiesParameters.Names.BasicMeleeName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 0, 0)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				self._zombiesValues[zombie].zombieHumanoid.WalkSpeed = 0

				ZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 0, 0)
			end)()
		end,
		
		[self._zombiesParameters.Names.BasicFlyingName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 7, 10)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				zombie.HumanoidRootPart.Anchored = true
								
				FlyZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 7, 10)
			end)()
		end,
		
		[self._zombiesParameters.Names.BasicShootingName] = function(zombie, allie)		
			coroutine.wrap(function()
				if allie == nil then return end

				if self._zombiesValues[zombie].Cooldown == true then return end
				if allie:FindFirstChildOfClass('Humanoid').Health <= 0 then return end

				local zombieName = zombie.Name
				local zombieHumanoidRootPart = zombie.HumanoidRootPart
				local zombieHumanoid = zombie:FindFirstChildOfClass("Humanoid")
				local defaultWalkSpeed = zombieHumanoid.WalkSpeed

				local distance = (allie.HumanoidRootPart.Position - zombieHumanoidRootPart.Position).Magnitude

				if distance > self._zombiesParameters.AttackDistance[zombieName] then return end

				local damage = self._zombiesParameters.DamageAmount[zombieName]
				local CooldownAfterAttack = self._zombiesParameters.CooldownAfterAttack[zombieName] 

				self._zombiesValues[zombie].Cooldown = true

				zombieHumanoid.WalkSpeed = 0

				local arrowClone = arrow:Clone()
				arrowClone.Parent = zombieHumanoidRootPart
				arrowClone.CFrame = zombieHumanoidRootPart.CFrame + zombieHumanoidRootPart.CFrame.lookVector * 3

				arrowClone.Anchored = false

				arrowClone.Touched:Connect(function(touchedPart)
					local targetHumanoid = touchedPart.Parent:FindFirstChildOfClass('Humanoid')

					if targetHumanoid == nil then return end
					if targetHumanoid.Parent:IsDescendantOf(workspace.Zombies) then return end
					arrowClone:Destroy()

					targetHumanoid:TakeDamage(damage)
				end)

				local allieHumanoidRootPart = allie.HumanoidRootPart

				local position1 = arrowClone.Position
				local position2 = allieHumanoidRootPart.Position			

				local hitDirection = position2 - position1
				local duration = math.log(1 + hitDirection.Magnitude * 0.01)
				position2 = allieHumanoidRootPart.Position * allieHumanoidRootPart.AssemblyLinearVelocity * hitDirection
				local force = hitDirection / duration + Vector3.new(0, game.Workspace.Gravity * duration * .5, 0)

				coroutine.wrap(function()
					while arrowClone do
						task.wait()
						arrowClone.CFrame = CFrame.new(arrowClone.Position, arrowClone.Position + arrowClone.AssemblyLinearVelocity)
					end
				end)()

				arrowClone:ApplyImpulse(force * arrowClone.AssemblyMass)
				arrowClone:SetNetworkOwner(nil)

				coroutine.wrap(function()
					task.wait(CooldownAfterAttack)

					arrowClone:Destroy()
					if self._zombiesValues[zombie] == nil then return end

					zombieHumanoid.WalkSpeed = defaultWalkSpeed

					self._zombiesValues[zombie].Cooldown = false
				end)()
			end)()
		end,
		
		[self._zombiesParameters.Names.BasicSpearmanName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 0, 0)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				self._zombiesValues[zombie].zombieHumanoid.WalkSpeed = 0

				ZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 0, 0)
			end)()
		end,
		
		[self._zombiesParameters.Names.SlowerZombieName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 0, 0)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				self._zombiesValues[zombie].zombieHumanoid.WalkSpeed = 0

				ZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 0, 0)
			end)()
		end,
		
		[self._zombiesParameters.Names.CreeperName] = function(zombie, allie)			
			if allie:FindFirstChildOfClass('Humanoid').Health <= 0 then return end
			
			local zombieName = zombie.Name
			local zombieHumanoid = zombie:FindFirstChildOfClass('Humanoid')
			local zombieDamage = self._zombiesParameters.DamageAmount[zombieName]
			local zombieAttackDistance = self._zombiesParameters.AttackDistance[zombieName]
			local delayBeforeAttack = self._zombiesParameters.DelayBeforeAttack[zombieName]
			local zombieHumanoidRootPart = zombie.HumanoidRootPart
			
			local distance = (allie.HumanoidRootPart.Position - zombieHumanoidRootPart.Position).Magnitude
			
			if distance > zombieAttackDistance then return end
			table.remove(self._zombies, table.find(self._zombies, zombie))
			print(self._zombies)
			
			coroutine.wrap(function()
				zombieHumanoid.WalkSpeed = 0
				local particleEmitter = zombie.Particle:FindFirstChildOfClass("ParticleEmitter")
				
				particleEmitter.Transparency = NumberSequence.new(0)
				task.wait(delayBeforeAttack)
				particleEmitter.Transparency = NumberSequence.new(1)				
				
				for _, allieLoop in next, workspace.FriendlyNPCS:GetChildren() do
					local distance = (allie.HumanoidRootPart.Position - zombieHumanoidRootPart.Position).Magnitude

					if distance > zombieAttackDistance then continue end

					allieLoop:FindFirstChildOfClass('Humanoid').Health -= zombieDamage
				end
				
				
				local playerCharacter = self.player[1].Character
				local distance = (playerCharacter.HumanoidRootPart.Position - zombieHumanoidRootPart.Position).Magnitude
				if distance < zombieAttackDistance then playerCharacter:FindFirstChildOfClass('Humanoid').Health -= zombieDamage end
				
				print('nulified')
				
				zombieHumanoid.Health = 0
			end)()
			
			return true
		end,
		
		[self._zombiesParameters.Names.WheelName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 0, 0)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				self._zombiesValues[zombie].zombieHumanoid.WalkSpeed = 0

				ZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 0, 0)
			end)()
		end,
		
		[self._zombiesParameters.Names.AngryRedName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 0, 0)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				self._zombiesValues[zombie].zombieHumanoid.WalkSpeed = 0

				ZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 0, 0)
			end)()
		end,
		
		[self._zombiesParameters.Names.AngryRedFlyingName] = function(zombie)
			coroutine.wrap(function()
				local target, targetHumanoid = raycastToFindHumanoid(self._zombiesValues[zombie].zombieHumanoidRootPart.Position, self._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * self._zombiesParameters.AttackDistance[zombie.Name], 7, 7, 10)

				if self._zombiesValues[zombie].Cooldown then return end
				if targetHumanoid == nil then return end
				if not target:IsDescendantOf(friendlyNPCS) and not target:IsDescendantOf(players) then return end

				zombie.HumanoidRootPart.Anchored = true

				FlyZombiePunch(zombie, players, self._zombiesValues[zombie].zombieAnimator, self, targetHumanoid, 7, 7, 10)
			end)()
		end,
	}
	
	local animations = script.Animations

	self._zombiesAnimations = {
		['BasicPunch'] = animations.DefaultPunch 
	}
	self._zombiesValues = {}
	self._specialZombies = {self._zombiesParameters.Names.BasicShootingName, self._zombiesParameters.Names.CreeperName}
	self._flyingZombies = {[self._zombiesParameters.Names.BasicFlyingName] = true, [self._zombiesParameters.Names.AngryRedFlyingName] = true}
	
	return self
end

local function MoveToLocation(zombie, module)
	local zombieHumanoid = zombie:FindFirstChildOfClass('Humanoid')
	
	coroutine.wrap(function()
		while zombie do
			zombieHumanoid:MoveTo(module._locationToReach)
			
			task.wait()
		end
	end)()
end

local function flyToLocation(zombie, module)	
	local zombieBody = zombie.Body
	
	local linearVelocity = Instance.new('LinearVelocity', zombieBody)
	linearVelocity.Attachment0 = zombieBody.Attachment
	linearVelocity.MaxForce = math.huge
	print(module._zombiesParameters.DefaultSpeed[zombie.Name])
	linearVelocity.VectorVelocity = Vector3.new(0, 0, module._zombiesParameters.DefaultSpeed[zombie.Name])
end

local zombieRaycastParams = RaycastParams.new()
zombieRaycastParams.FilterDescendantsInstances = workspace.Zombies:GetChildren()
zombieRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

function raycastToFindHumanoid(rayOrigin, rayDirection, xValueAppend, yValueAppend, zValueAppend)		
	zombieRaycastParams.FilterDescendantsInstances = workspace.Zombies:GetChildren()
	
	local raycastResult
	
	if yValueAppend ~= 0 then
		raycastResult = workspace:Raycast(rayOrigin, Vector3.new(0, -50, rayDirection.Z + zValueAppend), zombieRaycastParams)
	else
		raycastResult = workspace:Raycast(rayOrigin, rayDirection, zombieRaycastParams)
	end
	
	local additionalRaycastOne = workspace:Raycast(rayOrigin, Vector3.new(rayDirection.X+xValueAppend, rayDirection.Y-yValueAppend, rayDirection.Z+zValueAppend), zombieRaycastParams)
	local additionalRaycastTwo = workspace:Raycast(rayOrigin, Vector3.new(rayDirection.X-xValueAppend, rayDirection.Y-yValueAppend, rayDirection.Z+zValueAppend), zombieRaycastParams)
	
	if yValueAppend ~= 0 then 
		additionalRaycastOne = workspace:Raycast(rayOrigin, Vector3.new(rayDirection.X+xValueAppend, -50, rayDirection.Z+zValueAppend), zombieRaycastParams)
		additionalRaycastTwo = workspace:Raycast(rayOrigin, Vector3.new(rayDirection.X-xValueAppend, -50, rayDirection.Z+zValueAppend), zombieRaycastParams)
	end
	
	if raycastResult == nil and additionalRaycastOne == nil and additionalRaycastTwo == nil then return nil end
	
	local targetHumanoid = nil
	local targetHumanoidAdditionalOne = nil
	local targetHumanoidAdditionalTwo = nil
	
	if raycastResult then targetHumanoid = raycastResult.Instance.Parent:FindFirstChildOfClass('Humanoid') end
	if additionalRaycastOne then targetHumanoidAdditionalOne = additionalRaycastOne.Instance.Parent:FindFirstChildOfClass('Humanoid') end
	if additionalRaycastTwo then targetHumanoidAdditionalTwo = additionalRaycastTwo.Instance.Parent:FindFirstChildOfClass('Humanoid') end
		
	local returnHumanoid = targetHumanoid or targetHumanoidAdditionalOne or targetHumanoidAdditionalTwo or nil
			
	if returnHumanoid == nil then return nil end
	
	return returnHumanoid.Parent, returnHumanoid
end

function ZombiePunch(zombie, players, zombieAnimator, zombieModule, npcHumanoid, xValueAppend, yValueAppend, zValueAppend)		
	local slowEffect

	local zombieName = zombie.Name
	
	if zombieName == zombieModule._zombiesParameters.Names.SlowerZombieName then slowEffect = true end
	
	local delayBeforeAttack = zombieModule._zombiesParameters.DelayBeforeAttack[zombieName]
	local cooldown = zombieModule._zombiesParameters.CooldownAfterAttack[zombieName]
	local attackRange = zombieModule._zombiesParameters.AttackDistance[zombieName]
	
	zombieModule._zombiesValues[zombie].Cooldown = true
	
	local punchAnimation = zombieModule._zombiesValues[zombie].Animations.BasicPunch

	punchAnimation:Play()
	task.wait(delayBeforeAttack)
					
	local target, targetHumanoid = raycastToFindHumanoid(zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.Position, zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * attackRange, xValueAppend, yValueAppend, zValueAppend)
	
	if targetHumanoid then
		
		zombieModule._zombiesValues[zombie].Cooldown = true
		if target:IsDescendantOf(workspace.FriendlyNPCS) or target:IsDescendantOf(players) then
			local damage = zombieModule._zombiesParameters.DamageAmount[zombieName]
			local onCooldown = false
			
			
			while targetHumanoid and zombie:FindFirstChildOfClass('Humanoid') do
				if zombie:FindFirstChildOfClass('Humanoid') == nil then break end

				coroutine.wrap(function()
					if onCooldown then return end
					onCooldown = true

					targetHumanoid:TakeDamage(damage)
					
					if slowEffect then 
						if targetHumanoid.WalkSpeed <= 4 then 
							targetHumanoid.WalkSpeed = 4
						else
							targetHumanoid.WalkSpeed -= 2
						end
					end

					task.wait(cooldown)
					punchAnimation:Play()
					task.wait(delayBeforeAttack)
					
					onCooldown = false
				end)()
				
				target, targetHumanoid = raycastToFindHumanoid(zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.Position, zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * attackRange, xValueAppend, yValueAppend, zValueAppend)
				task.wait()
			end
			
			cooldown = 0
		end
	end
		
	if zombie == nil then return end
		
	while punchAnimation.IsPlaying do
		task.wait()
	end
		
	zombieModule._zombiesValues[zombie].Cooldown = false
		
	local zombieHumanoid = zombie:FindFirstChildOfClass("Humanoid")
		
	if zombieHumanoid == nil then return end
		
	zombieHumanoid.WalkSpeed = zombieModule._zombiesParameters.DefaultSpeed[zombieName]
end

function FlyZombiePunch(zombie, players, zombieAnimator, zombieModule, npcHumanoid, xValueAppend, yValueAppend, zValueAppend)	
	zombieRaycastParams.FilterDescendantsInstances = workspace.Zombies:GetChildren()
	
	local zombieName = zombie.Name

	local delayBeforeAttack = zombieModule._zombiesParameters.DelayBeforeAttack[zombieName]
	local cooldown = zombieModule._zombiesParameters.CooldownAfterAttack[zombieName]
	local attackRange = zombieModule._zombiesParameters.AttackDistance[zombieName]
	
	zombieModule._zombiesValues[zombie].Cooldown = true
	
	task.wait(delayBeforeAttack)
	
	local target, targetHumanoid = raycastToFindHumanoid(zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.Position, zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * attackRange, xValueAppend, yValueAppend, zValueAppend)

	local punchAnimation = zombieModule._zombiesValues[zombie].Animations.BasicPunch

	if targetHumanoid then
		local target = targetHumanoid.Parent

		zombieModule._zombiesValues[zombie].Cooldown = true
		if target:IsDescendantOf(workspace.FriendlyNPCS) or target:IsDescendantOf(players) then
			local damage = zombieModule._zombiesParameters.DamageAmount[zombieName]
			local onCooldown = false

			while targetHumanoid and zombie:FindFirstChildOfClass('Humanoid') do	
				if zombie:FindFirstChildOfClass('Humanoid') == nil then break end
				
				coroutine.wrap(function()
					if onCooldown then return end
					
					targetHumanoid:TakeDamage(damage)
					onCooldown = true

					task.wait(cooldown)
					
					punchAnimation:Play()
					print(punchAnimation.IsPlaying)
					task.wait(delayBeforeAttack)
					
					onCooldown = false
				end)()
				
				target, targetHumanoid = raycastToFindHumanoid(zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.Position, zombieModule._zombiesValues[zombie].zombieHumanoidRootPart.CFrame.lookVector * attackRange, xValueAppend, yValueAppend, zValueAppend)
				
				task.wait()
			end

			cooldown = 0
		end
	end

	if zombie == nil then return end
	
	task.wait(cooldown)
	
	local zombieHumanoid = zombie:FindFirstChildOfClass("Humanoid")
	if zombieHumanoid == nil then return end

	zombieModule._zombiesValues[zombie].Cooldown = false
	zombie.HumanoidRootPart.Anchored = false
end

function module:StartGlobalSearching()	
	local friendlyNPCS = workspace.FriendlyNPCS
	local players = workspace.Players
	
	while self.gameStatus.GameInProccess do
		for _, zombie in next, self._zombies do
			local specialZombie = table.find(self._specialZombies, zombie.Name)
			
			if specialZombie == nil then self._zombiesAttacks[zombie.Name](zombie) continue end
			
			local breakEvent = self._zombiesAttacks[zombie.Name](zombie, self.player[1].Character)
			
			if breakEvent then continue end
			
			for _, allie in next, self.allies do
				local breakEvent = self._zombiesAttacks[zombie.Name](zombie, allie)
				
				if breakEvent then break end
			end
		end
		
		task.wait()
	end
end

function module:SpawnZombie(zombieName, sideToSpawn)	
	local zombieModelClone : Model = self._zombiesModels:FindFirstChild(zombieName):Clone()
	zombieModelClone.Parent = workspace.Zombies
	
	zombieModelClone:PivotTo(self._spawnLocation + Vector3.new(math.random(-3, 3), 0, 0))
	
	local zombieHumanoid = zombieModelClone:FindFirstChildOfClass('Humanoid')
	local zombieAnimator = zombieHumanoid:FindFirstChildOfClass('Animator')
	
	self._zombiesValues[zombieModelClone] = {
		['zombieHumanoid'] = zombieHumanoid,
		['zombieAnimator'] = zombieAnimator,
		['zombieHumanoidRootPart'] = zombieModelClone.HumanoidRootPart,
		['Cooldown'] = false,
		['Animations'] = {['BasicPunch'] = zombieAnimator:LoadAnimation(self._zombiesAnimations.BasicPunch)}
	}
	
	table.insert(self._zombies, zombieModelClone)
	
	local flyingZombie = self._flyingZombies[zombieName]
		
	if flyingZombie then 
		zombieModelClone:PivotTo(self._spawnLocation + Vector3.new(0, 0, 2))
		flyToLocation(zombieModelClone, self)
	else
		MoveToLocation(zombieModelClone, self)
	end
	
	local zombieHumanoid = zombieModelClone:FindFirstChildOfClass('Humanoid')
	
	zombieHumanoid.Died:Connect(function()
		self.ZombieDied:Fire(zombieModelClone)
		
		if flyingZombie then
			zombieModelClone.Body.Transparency = 1
		end
		
		task.wait(3)
		
		self._zombiesValues[zombieModelClone] = nil
		table.remove(self._zombies, table.find(self._zombies, zombieModelClone))
		zombieModelClone:Destroy()
	end)
end

return module
