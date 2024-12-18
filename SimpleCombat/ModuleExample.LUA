local MovesetInit = require(script.Parent.MovesetsInit) 

local Warp = require(game:GetService('ReplicatedStorage').NetworkRelated.Warp)
local ServerRequestApplyKnockback = Warp.Server('ServerRequestApplyKnockback')

--||Test MOVESET ||--

local TestMoveset : MovesetInit.AssetsTable = {
	Animations = {
		M1 = 'rbxassetid://108228888899504',
		M2 = 'rbxassetid://70479577603567',
		M3 = 'rbxassetid://108228888899504',
		M4 = 'rbxassetid://70479577603567',
		M4Uppercut = '',
		M4Downslam = '',
		SideDashLeft = '',
		SideDashRight = '',
		ForwardDash = '',
		BackwardsDash = '',
		MoveOne = '',
		MoveTwo = '',
		MoveThree = '',
		MoveFour = '',
		Block = '',
		Evasive = '',
	},

	Cooldowns = {
		M1 = .3,
		M2 = .3,
		M3 = .3,
		M4 = .3,
		M4Uppercut = 2,
		M4Downslam = 2,
		SideDash = 1.5,
		ForwardDash = .5,
		MoveOne = 1,
		MoveTwo = 1,
		MoveThree = 1,
		MoveFour = 1,
		Block = .2,
		Evasive = 10,
		
		Additional = {ForwardDashLenght = .5}
	},

	Callbacks = {
		M1 = function() end,
		M2 = function() end,
		M3 = function() end,
		M4 = function(damagedPlayers, attackedCharacter, inAir : boolean, jumpHold : boolean)
			local players = game:GetService('Players')

			local playerHunter = players:GetPlayerFromCharacter(attackedCharacter)
			if playerHunter == nil then return end
			
			print(damagedPlayers)

			for _, character in next, damagedPlayers do	
				local player = players:GetPlayerFromCharacter(character)
				if player == nil then
					for _, part in next, character:GetChildren() do
						if part:IsA('Part') == false then continue end
						part:SetNetworkOwner(playerHunter)
					end
					
					character.RagdollTrigger.Value = true
					ServerRequestApplyKnockback:Fire(true, playerHunter, character, true, inAir, jumpHold) 

					continue 
				end

				if character:FindFirstChild('RagdollTrigger') ~= nil then character.RagdollTrigger.Value = true end

				ServerRequestApplyKnockback:Fire(true, player, attackedCharacter, false, inAir, jumpHold)
			end

			task.wait(2)
			for _, character in next, damagedPlayers do
				if character:FindFirstChild('RagdollTrigger') ~= nil then character.RagdollTrigger.Value = false end

				local player = players:GetPlayerFromCharacter(character)
				if player == nil then 
					for _, part in next, character:GetChildren() do
						if part:IsA('Part') == false then continue end
						part:SetNetworkOwner(nil)
					end
				end
			end
		end,
		M4Uppercut = function() end,
		M4Downslam = function() end,
		SideDash = function() end,
		ForwardDash = function() end,
		MoveOne = function() end,
		MoveTwo = function() end,
		MoveThree = function() end,
		MoveFour = function() end,
	},

	Damage = {
		M1 = 5,
		M2 = 5,
		M3 = 5,
		M4 = 7,
		M4Uppercut = 1,
		M4Downslam = 1,
		ForwardDash = 3,
		MoveOne = 1,
		MoveTwo = 1,
		MoveThree = 1,
		MoveFour = 1,
	},
	
	Stuns = {
		M1 = 2,
		M2 = 2,
		M3 = 2,
		M4 = 2,
		M4Uppercut = 2,
		M4Downslam = 2,
		ForwardDash = 2,
		MoveOne = 2,
		MoveTwo = 2,
		MoveThree = 2,
		MoveFour = 2,
	}
}

local module = {
	Test = TestMoveset
}

return module
