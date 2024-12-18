local playersService = game:GetService('Players')
local serverStorage = game:GetService('ServerStorage')
local replicatedStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')

local modulesFolder = serverStorage.Modules
local wallModule = require(modulesFolder.Wall).new()
local petModule = require(modulesFolder.Pet).new()
local dataManipulation = require(modulesFolder.DataManipulation).new()
local profileService = require(modulesFolder.ProfileService)

local remoteEventsFolder = replicatedStorage.RemoteEvents

local DisplayWallHealth = remoteEventsFolder.DisplayWallHealth
local PunchEvent = remoteEventsFolder.PunchEvent
local WallDisappearEvent = remoteEventsFolder.WallDisappear
local ChangeWallHealthDisplay = remoteEventsFolder.ChangeWallHealthDisplay
local EggOpenEvent = remoteEventsFolder.EggOpenEvent
local RenderPlayerPets = remoteEventsFolder.RenderPlayerPets
local PetEquip = remoteEventsFolder.PetEquip
local PetUnequip = remoteEventsFolder.UnequipPet

local remoteFunctionsFolder = replicatedStorage.RemoteFunctions

local checkEquipedValue = remoteFunctionsFolder.CheckEquipedValue

local playersDataStore = game:GetService('DataStoreService'):GetDataStore('PlayersData')

local playersWallHealths = {}
local playersValues = {}

local profileStore = profileService.GetProfileStore('TestServer', {['punchCooldown'] = false, ['Pets'] = {},['Strength'] = 500,['Wins'] = 0})

local function playerAdded(player)
	local playerUserId = player.UserId

	local profile = profileStore:LoadProfileAsync("Player_"..playerUserId)
	if profile == nil then
		player:Kick('Data issue, try again shortly. If smth contact us')
		return
	end

	profile:AddUserId(playerUserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		dataManipulation.profiles[player] = nil
		player:Kick('Data issue, try again shortly. If smth contact us')
	end)

	if player:IsDescendantOf(playersService) == true then
		dataManipulation.profiles[player] = profile
	else
		profile:Release()
	end
	
	playersWallHealths[playerUserId] = wallModule:AssignWallHealths()
	DisplayWallHealth:FireClient(player, playersWallHealths[playerUserId])
	
	print(profile.Data.Pets)
	RenderPlayerPets:FireClient(player, profile.Data.Pets, petModule.petsBoosts)
	
end

for _, player in next, playersService:GetPlayers() do
	task.spawn(playerAdded, player)
end

playersService.PlayerAdded:Connect(playerAdded)

playersService.PlayerRemoving:Connect(function(player)
	local profile = dataManipulation.profiles[player]
	if not profile then return end
	
	profile:Release()
	
	playersWallHealths[player.UserId] = nil
end)

PunchEvent.OnServerEvent:Connect(function(player, humanoidRootPart)
	local profile = dataManipulation.profiles[player]
	
	if profile.Data.PunchCooldown then return end
	profile.Data.PunchCooldown = true

	local rayOrigin = humanoidRootPart.Position
	local rayDirection = humanoidRootPart.CFrame.LookVector * 5

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection)

	if raycastResult then
		local hitPart = raycastResult.Instance; print(hitPart)
		if hitPart:GetAttribute("Breakable") then
			for level, levelTable in next, playersWallHealths[player.UserId] do
				local wallInTable = levelTable[hitPart.Name]
				wallInTable[1] -= profile.Data.Strength --Chaging wall health
				
				if wallInTable[1] <= 0 then
					WallDisappearEvent:FireClient(player, hitPart)
	
					wallInTable[1] = wallModule.wallSettings[level][hitPart.Name][1]
					
					ChangeWallHealthDisplay:FireClient(player, hitPart, level, wallInTable[1], true)
					break
				end
				
				ChangeWallHealthDisplay:FireClient(player, hitPart, level, wallInTable[1], false)
				
				break
			end
		end
	end
	
	wait(.5)
	profile.Data.PunchCooldown = false
end)

EggOpenEvent.OnServerEvent:Connect(function(player)
	local profile = dataManipulation.profiles[player]
	if not profile then return end
	
	local pet = petModule:ChooseRandomPet()
	
	local counter = 1
	
	for key, value in next, profile.Data.Pets do
		counter += 1
	end
	
	profile.Data.Pets[tostring(counter)] = {pet, false}
	
	RenderPlayerPets:FireClient(player, {[tostring(counter)] = {pet, false}} , petModule.petsBoosts)
end)

local tweenInfo = TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false, .1)

PetEquip.OnServerEvent:Connect(function(player, petName, petNumber)
	local profile = dataManipulation.profiles[player]
	if not profile then return end
	
	local humanoidRootPart = player.Character.HumanoidRootPart
	
	local clonnedPet = replicatedStorage.PetsModels[petName]:Clone()
	clonnedPet.Size = Vector3.new(2.5,2.5,2.5)
	
	if humanoidRootPart:FindFirstChild('Attachment') then
		humanoidRootPart:FindFirstChild('Attachment')
	end
	
	local attachmentCharacter = Instance.new('Attachment', humanoidRootPart); attachmentCharacter.Visible = false
	attachmentCharacter.Position = Vector3.new(2, -1, 3)
	
	local attachmentPet = Instance.new('Attachment', clonnedPet); attachmentPet.Visible = false
	attachmentPet.Parent = clonnedPet
	
	local alignPosition = Instance.new('AlignPosition', clonnedPet)
	alignPosition.MaxForce = math.huge
	alignPosition.Attachment0 = attachmentPet
	alignPosition.Attachment1 = attachmentCharacter
	alignPosition.Responsiveness = 25
	
	local alignOrientation = Instance.new('AlignOrientation', clonnedPet)
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Attachment0 = attachmentPet
	alignOrientation.Attachment1 = attachmentCharacter
	alignOrientation.Responsiveness = 25
	
	clonnedPet.Parent = humanoidRootPart
	
	profile.Data.Pets[petNumber][2] = true
end)

PetUnequip.OnServerEvent:Connect(function(player, pet, petNumber)
	local profile = dataManipulation.profiles[player]
	if not profile then return end
	
	profile.Data.Pets[petNumber][2] = false
	
	local humanoidRootPart = player.Character.HumanoidRootPart
	
	local petInsideCharacter = humanoidRootPart:FindFirstChild(pet)
	petInsideCharacter:Destroy()
end)

local function checkValue(player, petNumber)
	local profile = dataManipulation.profiles[player]
	if not profile then return end
	
	return profile.Data.Pets[petNumber][2]
end

checkEquipedValue.OnServerInvoke = checkValue
