local serverStorage = game:GetService('ServerStorage')
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')

local bindableEvents = serverStorage.BindableEvents
local FriendlyNPCSearch = bindableEvents.FriendlyNPCSearch
local ZombieDied = bindableEvents.ZombieDied
local SummonFriend = bindableEvents.SummonFriend
local PlayerStartGame = bindableEvents.PlayerStartGame
local GiveLoot = bindableEvents.GiveLoot
local EndGamePlayerSide = bindableEvents.EndGamePlayerSide

local remoteEvents = replicatedStorage.RemoteEvents
local StartGame = remoteEvents.StartGame
local ChangeWaveCompletionPercent = remoteEvents.ChangeWaveCompletionPercent
local updateBackups = remoteEvents.UpdateBackups

local alliesFolder = workspace.FriendlyNPCS
local zombiesFolder = workspace.Zombies

local modules = serverStorage.Modules
local zombies = require(modules.Zombies).new()
local friendlyNPCS  = require(modules.Allies).new()
local gameStatus = require(modules.GameStatus)
local playerData = require(modules.PlayerData)
local levelsData = require(modules.LevelsData)
local backupsData = require(modules.DataBackups)
local alliesParameters = require(modules.AlliesParameters)
local zombieParameters = require(modules.ZombieParameters)


players.PlayerAdded:Connect(function(player)
	zombies.player = players:GetPlayers()
	friendlyNPCS.player = player
end)

alliesFolder.ChildAdded:Connect(function(friendNPC)
	table.insert(zombies.allies, friendNPC)
end)

alliesFolder.ChildRemoved:Connect(function(friendNPC)
	table.remove(zombies.allies, table.find(zombies.allies, friendNPC))
end)

zombiesFolder.ChildAdded:Connect(function(zombie)
	table.insert(friendlyNPCS.zombies, zombie)
end)

zombiesFolder.ChildRemoved:Connect(function(zombie)
	table.remove(friendlyNPCS.zombies, table.find(friendlyNPCS.zombies, zombie))
end)

SummonFriend.Event:Connect(function(friendName, special)
	friendlyNPCS:SpawnFriendNPC(friendName, special)
end)

updateBackups.OnServerEvent:Connect(function()
	backupsData:DataBackupUpdate()
end)

local zombiesWave = {
	{ --FIRST WAVE
		['AmountOfZombies'] = 6,
		['ZombiesAmountSpecificly'] = {
			[zombieParameters.Names.BasicMeleeName] = 3,
			[zombieParameters.Names.BasicFlyingName] = 1,
			[zombieParameters.Names.CreeperName] = 2
		},
		['ZombiesOnWave'] = {zombieParameters.Names.BasicMeleeName, zombieParameters.Names.BasicFlyingName, zombieParameters.Names.CreeperName},
		
		['DelayBeforeSpawn'] = 5,
	},

	{
		['AmountOfZombies'] = 2,
		['ZombiesAmountSpecificly'] = {
			[zombieParameters.Names.BasicMeleeName] = 2,
			--['FlyingZombie'] = 2
		},
		['ZombiesOnWave'] = {zombieParameters.Names.BasicMeleeName},

		['DelayBeforeSpawn'] = 2,
	}
}



local currentZombiesAlive
local currentZombieMaxAmount

local function deepCopy(original)
	local copy = {}

	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end

		copy[k] = v
	end

	return copy
end

StartGame.OnServerEvent:Connect(function(player)
	if gameStatus.GameInProccess == true then return end
	gameStatus.GameInProccess = true
	
	coroutine.wrap(function()
		zombies:StartGlobalSearching()
	end)()
	coroutine.wrap(function()
		friendlyNPCS:StartGlobalSearching()
	end)()

	local playerWave = playerData.profiles[player.UserId].Data.PlayerCurrentWave
	
	local waveTable = deepCopy(zombiesWave[playerWave])

	local maxAmountZombiesToSpawn = waveTable.AmountOfZombies
	local delayBeforeSpawn = waveTable.DelayBeforeSpawn
	local zombiesToSpawnAmount = maxAmountZombiesToSpawn
	local zombiesListToSpawn = waveTable.ZombiesOnWave
	local zombiesListLenght = #zombiesListToSpawn

	currentZombiesAlive = maxAmountZombiesToSpawn
	currentZombieMaxAmount = maxAmountZombiesToSpawn

	PlayerStartGame:Fire(player)
	
	local onCooldown = false

	while zombiesToSpawnAmount > 0 do
		task.wait()
		
		if gameStatus.GameInProccess == false then print('game ended reason: player died') break end
		if onCooldown then continue end

		local randomZombie = zombiesListToSpawn[math.random(zombiesListLenght)]
		
		waveTable.ZombiesAmountSpecificly[randomZombie] -= 1
		if waveTable.ZombiesAmountSpecificly[randomZombie] == 0 then table.remove(zombiesListToSpawn, table.find(zombiesListToSpawn, randomZombie)) zombiesListLenght -= 1 end
		
		local pair = math.random(1, 2)
		
		if pair == 2 and zombiesToSpawnAmount > 1 then 
			zombies:SpawnZombie(randomZombie) 
			
			local randomZombieSecond = zombiesListToSpawn[math.random(zombiesListLenght)]

			waveTable.ZombiesAmountSpecificly[randomZombieSecond] -= 1
			if waveTable.ZombiesAmountSpecificly[randomZombieSecond] == 0 then table.remove(zombiesListToSpawn, table.find(zombiesListToSpawn, randomZombieSecond)) zombiesListLenght -= 1 end
			
			zombies:SpawnZombie(randomZombieSecond)
			zombiesToSpawnAmount -= 2
		else
			zombies:SpawnZombie(randomZombie) 
			zombiesToSpawnAmount -= 1
		end
		
		coroutine.wrap(function()
			onCooldown = true
			task.wait(delayBeforeSpawn)
			onCooldown = false
		end)()
	end
end)

local lootTable = {
	['Silver'] = .9,
	['Charm'] = .1
}

local charms = {
	['Lucky Charm'] = .3,
	['Summon Charm'] = .2,
	['Wealth Charm'] = .8
}

local function randomLoot(exactTable, charms)
	local weight = 0
	
	for _, chance in next, exactTable do
		weight += (chance * 10)
	end
	
	local randomNumber = math.random(1, weight)
	
	weight = 0
	for prizeName, chance in next, exactTable do
		weight += (chance * 10)
		
		if weight >= randomNumber then
			return prizeName
		end
	end
end

local function clearAllMobs()
	local friendlyNPCS = workspace.FriendlyNPCS:GetChildren()
	local zombies = workspace.Zombies:GetChildren()

	for _, npc in next, friendlyNPCS do
		npc:FindFirstChildOfClass('Humanoid'):TakeDamage(100000)
		npc:Destroy()
	end

	for _, zombie in next, zombies do
		zombie:FindFirstChildOfClass('Humanoid'):TakeDamage(100000)
		zombie:Destroy()
	end
end

ZombieDied.Event:Connect(function(zombie)
	currentZombiesAlive -= 1

	local zombiesKilledPercent = 100 - ((currentZombiesAlive/currentZombieMaxAmount) * 100)
	ChangeWaveCompletionPercent:FireAllClients(zombiesKilledPercent)
	
	local zombieLoot = randomLoot(lootTable)
	
	if zombieLoot == 'Silver' then
		local silverAmount = math.random(10, 36)
		GiveLoot:Fire(friendlyNPCS.player, silverAmount, nil, charms, zombie.HumanoidRootPart.Position)
	elseif zombieLoot == 'Charm' then
		local charmName = randomLoot(charms)
		GiveLoot:Fire(friendlyNPCS.player, 1, charmName, charms, zombie.HumanoidRootPart.Position)
	end

	if currentZombiesAlive == 0 then 
		EndGamePlayerSide:Fire(friendlyNPCS.player , 'VICTORY!')
		gameStatus.GameInProccess = false
	end
end)
