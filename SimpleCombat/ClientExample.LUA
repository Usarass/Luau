--!strict
local player = game:GetService('Players').LocalPlayer
local character = player.Character
local humanoidRootPart = character:WaitForChild('HumanoidRootPart')

local ragdollTrigger = character:WaitForChild('RagdollTrigger')

local UserInputService = game:GetService('UserInputService')

local Warp = require(game:GetService('ReplicatedStorage').NetworkRelated.Warp)
local RequestAnimationsTable = Warp.Client('RequestAnimationsTable')
local RequestCooldowns = Warp.Client('RequestCooldowns')
local RequestMouseCombo = Warp.Client('RequestMouseCombo')
local RequestForwardDash = Warp.Client('RequestForwardDash')

local ServerRequestChangeBoolean = Warp.Client('ServerRequestChangeBoolean')
local ServerRequestApplyKnockback = Warp.Client('ServerRequestApplyKnockback')
local ServerRequestChangeAlignPosition = Warp.Client('ServerRequestChangeAlignPosition')

local ContextActionService = game:GetService('ContextActionService')

local MOUSE_ONE_COMBO = 'Mouse_Combo'
local mouseComboButton = Enum.UserInputType.MouseButton1
local gamepadMouseComboButton = Enum.KeyCode.ButtonR1

local MOVE_INITIATED_ONE = 'Move_initiated_1'
local MOVE_INITIATED_TWO = 'Move_initiated_2'
local MOVE_INITIATED_THREE = 'Move_initiated_3'
local MOVE_INITIATED_FOUR = 'Move_initiated_4'
local moveOneButton = Enum.KeyCode.One
local moveTwoButton = Enum.KeyCode.Two
local moveThreeButton = Enum.KeyCode.Three
local moveFourButton = Enum.KeyCode.Four

local gamepadMoveOne = Enum.KeyCode.ButtonX
local gamepadMoveTwo = Enum.KeyCode.ButtonB
local gamepadMoveThree = Enum.KeyCode.ButtonA
local gamepadMoveFour = Enum.KeyCode.ButtonY

local DASH = 'DASH_MOVE'
local dashButton = Enum.KeyCode.Q
local gamepadDashButton = Enum.KeyCode.ButtonR2

local inputObjectToMove = {
	[moveOneButton] = 1,
	[moveTwoButton] = 2,
	[moveThreeButton] = 3,
	[moveFourButton] = 4,

	[gamepadMoveOne] = 1,
	[gamepadMoveTwo] = 2,
	[gamepadMoveThree] = 3,
	[gamepadMoveFour] = 4,
}

local cooldownsClient = {
	mouse = false,
	dash = false,
	forwardDash = false,
	stunned = false
}

local mouseHeld = false
local mouseTick = tick()
local mouseCombo = 1
local RESET_MOUSE_COMBO_TIME = 3
local mouseCooldownTick = tick()

--local nameToAnimationId = {
--	M1 = 'rbxassetid://108228888899504'
--}

local animationsTable = RequestAnimationsTable:Invoke(4)
print(animationsTable)
if animationsTable == nil then return end

local humanoid : Humanoid = character:WaitForChild('Humanoid')
local animator : Animator = humanoid:WaitForChild('Animator')

--local walkspeedResetTime = .5
local walkspeedResetTick = tick()
local walkspeedDefault = humanoid.WalkSpeed
local walkspeedSlowed = 3

local function MakeWalkspeedSlower(resetTime : number, walkspeedSpecefied : number?)
	coroutine.wrap(function()
		humanoid.WalkSpeed = walkspeedSpecefied or walkspeedSlowed
		
		task.wait(resetTime)
		if (tick() - walkspeedResetTick) < resetTime then coroutine.wrap(MakeWalkspeedSlower)(resetTime, walkspeedSpecefied) return end
		
		humanoid.WalkSpeed = walkspeedDefault
	end)()
end

for index : string, animationId : string in next, animationsTable do
	local animation = Instance.new('Animation', character)
	if animationId ~= '' then animation.AnimationId = animationId 
		animationsTable[index] = animator:LoadAnimation(animation)
	end
	--local animationId = nameToAnimationId[index]
	--if animationId == nil then continue end
	
	--animation.AnimationId = animationId
	
	--if animation.AnimationId == nil then continue end
	--animationsTable[index] = animator:LoadAnimation(animation)
end

ServerRequestChangeBoolean:Connect(function(cooldownName : 'mouse', currentBoolean : boolean, ...)
	cooldownsClient[cooldownName] = currentBoolean

	if ... ~= nil then 
		if cooldownName == 'mouse' then 
			local combo = ...
			--mouseCombo = mouseCombo
		end
	end
end)

local cooldowns = RequestCooldowns:Invoke(4)

local mouseCooldowns = {
	cooldowns.M1 + .05,
	cooldowns.M2 + .05,
	cooldowns.M3 + .05,
	cooldowns.M4 + .05
}

local jumpTick = tick()       
local defaultJumpHeightValue = humanoid.JumpHeight
local jumpReset = .4

local function JumpDisable()
	coroutine.wrap(function()
		humanoid.JumpHeight = 0
		task.wait(.6)

		if (tick() - jumpTick) < jumpReset then return end
		print('resettttted')
		humanoid.JumpHeight = defaultJumpHeightValue
	end)()
end

local jumpHold = false

UserInputService.InputBegan:Connect(function(input, inChat)
	if inChat then return end
	
	if input.KeyCode == Enum.KeyCode.Space then 
		jumpHold = true
	end
end)

UserInputService.InputEnded:Connect(function(input, inChat)
	if inChat then return end

	if input.KeyCode == Enum.KeyCode.Space then 
		jumpHold = false
	end
end)

local function Cooldown(waitTime : number, tickVariable : number, cooldownValue)
	task.wait(waitTime)
	if (tick() - tickVariable) < waitTime then coroutine.wrap(Cooldown)(waitTime, tickVariable, cooldownValue) return end
	cooldownValue = false
end

local currentComboAnimation = nil

local function MouseOneCombo(actionName, inputState, _inputObject) : Enum.ContextActionResult
	if actionName ~= MOUSE_ONE_COMBO or  inputState ~= Enum.UserInputState.Begin then mouseHeld = false return Enum.ContextActionResult.Pass end	
	mouseHeld = true

	while mouseHeld do 
		task.wait()
		
		if character:GetAttribute('IsStunned') or ragdollTrigger.Value == true then continue end

		if mouseCombo >= 5 then mouseCombo = 1 end
		if (tick() - mouseTick) > RESET_MOUSE_COMBO_TIME then mouseCombo = 1 end

		if cooldownsClient.mouse then continue end
		mouseTick = tick()
		mouseCooldownTick = tick()

		cooldownsClient.mouse = true
		if currentComboAnimation ~= nil then currentComboAnimation:Stop(); currentComboAnimation = nil end
		if animationsTable[`M{mouseCombo}`] ~= '' then animationsTable[`M{mouseCombo}`]:Play(); currentComboAnimation = animationsTable[`M{mouseCombo}`] end
		
		task.wait(.1)
		RequestMouseCombo:Fire(true, mouseCombo, jumpHold)
		
		coroutine.wrap(Cooldown)(mouseCooldowns[mouseCombo], mouseCooldownTick, cooldownsClient.mouse)
		
		jumpTick = tick()
		JumpDisable()
		
		mouseCombo += 1
		
		print(animationsTable)		--TODO: PLAY ANIMATION
	end

	return Enum.ContextActionResult.Pass
end

local function MoveInitiate(actionName, inputState, _inputObject) : Enum.ContextActionResult
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end	
	if actionName ~= MOVE_INITIATED_ONE and actionName ~= MOVE_INITIATED_TWO and actionName ~= MOVE_INITIATED_THREE and actionName ~= MOVE_INITIATED_FOUR then return Enum.ContextActionResult.Pass end 


	return Enum.ContextActionResult.Pass
end

local forwardDashCooldown = cooldowns.ForwardDash
local sideDashCooldown = cooldowns.SideDash

local forwardDashLenght = cooldowns.Additional.ForwardDashLenght

local sideDashLength = .3
local dashActivated = false

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {character}

local function DashInitiate(actionName, inputState, _inputObject) : Enum.ContextActionResult
	if actionName ~= DASH or  inputState ~= Enum.UserInputState.Begin then mouseHeld = false return Enum.ContextActionResult.Pass end	
	if character:GetAttribute('IsStunned') or ragdollTrigger.Value == true then return Enum.ContextActionResult.Pass end
	
	local dashLenght = sideDashLength
	local isForward = false
	
	--humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
	
	if math.abs(humanoidRootPart.CFrame.LookVector:Dot(humanoid.MoveDirection)) > .89 then 
		if humanoidRootPart.CFrame.LookVector:Dot(humanoid.MoveDirection) > 0 then 
			--TODO: FORWARD ANIM
			dashLenght = forwardDashLenght
			isForward = true
		else
			--TODO: BACKWARDS ANIM
		end
	end
	
	if math.abs(humanoidRootPart.CFrame.RightVector:Dot(humanoid.MoveDirection)) > .89 then 
		if humanoidRootPart.CFrame.RightVector:Dot(humanoid.MoveDirection) > 0 then 
			--TODO: RIGHT ANIMATION
		else
			--TODO: LEFT ANIMATION
		end
	end
	
	if isForward and cooldownsClient.forwardDash then return Enum.ContextActionResult.Pass end
	if isForward == false and cooldownsClient.dash then return Enum.ContextActionResult.Pass end
	
	humanoid.JumpHeight = 0
	
	if isForward then cooldownsClient.forwardDash = true else cooldownsClient.dash = true end
	dashActivated = true
	
	local alignPosition = humanoidRootPart:FindFirstChildOfClass('AlignPosition') or Instance.new('AlignPosition', humanoidRootPart)
	alignPosition.Enabled = true
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = humanoidRootPart:FindFirstChildOfClass('Attachment')
	alignPosition.MaxForce = math.huge
	alignPosition.MaxVelocity = math.huge
	alignPosition.Responsiveness = 19
	
	local raycastResultToDown = workspace:Raycast(humanoidRootPart.Position, -(humanoidRootPart.CFrame.UpVector * 100000000000000000), raycastParams)
	if raycastResultToDown == nil then return Enum.ContextActionResult.Pass end
	
	local toAddToY = .5
	--if humanoid:GetState() == Enum.HumanoidStateType.Freefall then toAddToY = -3  end
	
	local yAxisVelocity = raycastResultToDown.Instance.Position.Y + character:GetExtentsSize().Y * 2
	print(humanoidRootPart.Position.Y)
	print(raycastResultToDown.Instance.Position.Y)
	
	if humanoidRootPart.Position.Y - raycastResultToDown.Instance.Position.Y > 30 then 
		yAxisVelocity = humanoidRootPart.Position.Y - 40	
	end
	
	if isForward then 
		local targetCharacter
		
		local found = false 
		
		--local velocityVector = ( (humanoidRootPart.CFrame + humanoid.MoveDirection * 4 * humanoidRootPart.Mass)).Position
		--yAxisVelocity = velocityVector.Y + toAddToY
		
		coroutine.wrap(function()
			while dashActivated == true do
				task.wait()
				local velocityVector = ( (humanoidRootPart.CFrame + humanoidRootPart.CFrame.LookVector * 4 * humanoidRootPart.Mass)).Position
				alignPosition.Position = Vector3.new(velocityVector.X, yAxisVelocity, velocityVector.Z)
				
				local raycastResult = workspace:Raycast(humanoidRootPart.Position, humanoidRootPart.CFrame.LookVector * 2, raycastParams)

				if raycastResult == nil then continue end

				targetCharacter = raycastResult.Instance:FindFirstAncestorOfClass('Model')
				if targetCharacter == nil then continue end

				local targetHumanoid = targetCharacter:FindFirstChildOfClass('Humanoid')
				if targetHumanoid == nil then continue end
				
				found = true 
				
				break
			end
			
			if found == false then
				--walkspeedResetTick = tick()
				
				coroutine.wrap(function()
					toAddToY = 1
					if humanoid:GetState() == Enum.HumanoidStateType.Freefall then toAddToY = -3  end
				end)()
				MakeWalkspeedSlower(.8, 0)
			else
				MakeWalkspeedSlower(.2, 0)
			end
			
			if targetCharacter ~= nil then RequestForwardDash:Fire(true, targetCharacter) else RequestForwardDash:Fire(true, humanoidRootPart.CFrame + (humanoidRootPart.CFrame.LookVector * 7)) end
			alignPosition.Enabled = false
		end)()
		
	else 
		local velocityVector = ( (humanoidRootPart.CFrame + humanoid.MoveDirection * 6 * humanoidRootPart.Mass)).Position

		alignPosition.Position = Vector3.new(velocityVector.X, yAxisVelocity, velocityVector.Z)
	end
	
	coroutine.wrap(function()
		task.wait(dashLenght)
		alignPosition.Enabled = false
		dashActivated = false
		
		humanoid.JumpHeight = defaultJumpHeightValue
	end)()
	
	if isForward then 
		cooldownsClient.dash = false
		task.wait(forwardDashCooldown)
		cooldownsClient.forwardDash = false
	else
		task.wait(sideDashCooldown)
		cooldownsClient.dash = false
	end 
	
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(MOUSE_ONE_COMBO, MouseOneCombo, true, mouseComboButton, gamepadMouseComboButton)

ContextActionService:BindAction(MOVE_INITIATED_ONE, MoveInitiate, false, moveOneButton, gamepadMoveOne)
ContextActionService:BindAction(MOVE_INITIATED_TWO, MoveInitiate, false, moveTwoButton, gamepadMoveTwo)
ContextActionService:BindAction(MOVE_INITIATED_THREE, MoveInitiate, false, moveThreeButton, gamepadMoveThree)
ContextActionService:BindAction(MOVE_INITIATED_FOUR, MoveInitiate, false, moveFourButton, gamepadMoveFour)

ContextActionService:BindAction(DASH, DashInitiate, true, dashButton, gamepadDashButton)

ServerRequestApplyKnockback:Connect(function(attackedCharacter, notAPlayer : boolean, inAir : boolean, jumpHold : boolean)	
	if humanoidRootPart == nil then print('no hrp') return end

	local humanoidRootPart = humanoidRootPart

	local attackerRootPart = attackedCharacter:FindFirstChild('HumanoidRootPart')
	if attackerRootPart == nil then print('no enemy hrp') return end
	
	if notAPlayer then
		local pastAttacker = attackerRootPart

		attackerRootPart = humanoidRootPart
		humanoidRootPart = pastAttacker
	end
	
	if humanoidRootPart.Parent == nil then return end
	local targetHumanoid = humanoidRootPart.Parent:FindFirstChildOfClass('Humanoid')
	targetHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	local velocityVector = ( (attackerRootPart.CFrame + attackerRootPart.CFrame.LookVector * 8 * humanoidRootPart.Mass)).Position
	if inAir then velocityVector = ( (humanoidRootPart.CFrame + (-(Vector3.new(0, 5, 0))) * humanoidRootPart.Mass)).Position  end
	if jumpHold then velocityVector = ( (humanoidRootPart.CFrame + (Vector3.new(0, 5, 0) * humanoidRootPart.Mass))).Position  end

	local alignPosition = humanoidRootPart:FindFirstChildOfClass('AlignPosition') or Instance.new('AlignPosition', humanoidRootPart)
	alignPosition.Enabled = true
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = humanoidRootPart:FindFirstChildOfClass('Attachment')
	alignPosition.MaxForce = math.huge
	alignPosition.MaxVelocity = math.huge
	alignPosition.Responsiveness = 40
	alignPosition.Position = velocityVector

	task.delay(.01, function()
		print('disabled')
		alignPosition.Enabled = false
	end)
end)

ServerRequestChangeAlignPosition:Connect(function(condition : boolean)
	local alignPosition = humanoidRootPart:FindFirstChildOfClass('AlignPosition')
	if alignPosition == nil then return end
	
	alignPosition.Enabled = condition
end)
