--Player locals
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character.Humanoid 
local PlayerGUI = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local RightArm = Character:WaitForChild("Right Arm")
local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()
local Mouse = Player:GetMouse()
local EndingActive = script.Parent:WaitForChild("EndingInAction")

--Animations/Load Animations
local Bed = script:WaitForChild("Bed")
local ArmAnim = script:WaitForChild("ArmAnim")
local PickFile = script:WaitForChild("Pick")
local C1Bed = Humanoid:LoadAnimation(Bed)
local HumArm = Humanoid:LoadAnimation(ArmAnim)
local PickAnimation = Humanoid:LoadAnimation(PickFile)
PickAnimation.Priority = Enum.AnimationPriority.Action
--
local TextGUI = script:WaitForChild("Text")
local UndetaleS = script:WaitForChild("UndertaleSound")
local OpenSound = script:WaitForChild("OpenSound")
local DedSound = script:WaitForChild("DedSound")
local Trying = script:WaitForChild("Trying")
local TOpen = 1--It's for tick on present
local Tryings = 0
--Usage of Camera
local Camera = workspace.Camera
Character.HumanoidRootPart.Anchored = true
--Services
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
--Events
local EventToStartGame = PlayerGUI.Events:WaitForChild("EventToGame")
local EToPick = PlayerGUI.Events:WaitForChild("EventToPick")
local EToDown = PlayerGUI.Events:WaitForChild("EventToPrintDown")
local EndE = game.ReplicatedStorage:WaitForChild("EventToEnd")
local BuggedEnd = game.ReplicatedStorage:WaitForChild("BuggedEnd")
local UnAnchor = game.ReplicatedStorage:WaitForChild("UnAnchored")
local BEvent = script.Bevent
--Booleans
local CanPick = false
local PhoneHere = false
local First = true
local FirstOpen = true
local CutsceneInAction = false
--
 
local RepPhone = game.ReplicatedStorage:WaitForChild("Model"):WaitForChild("RightArm")
local PickUpS = Instance.new("Sound")
PickUpS.SoundId = "rbxassetid://2848703459"

--Event that allows u to G item
EToPick.Event:Connect(function()
	CanPick = true
end)
--Tweens
local Tween = TweenService:Create(Camera , TweenInfo.new(0.5) , {CFrame = workspace.Location1.Bed:WaitForChild("Meshes/Location1_1_Cube.002").CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(45, 0, 0)  * CFrame.Angles(0,math.rad(120), 0) * CFrame.new(1, 0, 0)})
local Tween2 = TweenService:Create(Camera , TweenInfo.new(0.5) , {CFrame = workspace.Location1.Bed:WaitForChild("Meshes/Location1_1_Cube.002").CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(45, 0, 0)})
--
local Phone = workspace.Location1.Phone


local function TimeOut()
	Controls:Disable()
	local TextClone = TextGUI:Clone()
	TextClone.TextLabel.Text = "What?"
	TextClone.Parent = PlayerGUI
	DedSound:Play()
	wait(1)
	Player:Kick("Bad ending(Your time to escape is up)")
end

local function StartTimer()
	delay(600, TimeOut)
	print("Timer Started")
end

UIS.InputBegan:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.G then
		if CanPick == true then
			CanPick = false
			EToDown:Fire() --Destory text
			
			--Tween:Play() --Tween to rotate camera
			--Camera.CameraSubject = workspace.Location1.SL 
			wait(1)
			C1Bed:AdjustSpeed(1)
			PickUpS.Parent = Character.HumanoidRootPart --Sound Parent
			PickUpS:Play()
			Debris:AddItem(Phone, 0.4) --Destroy phone 
			wait(0.5)
			C1Bed:AdjustSpeed(0)
			--Tween2:Play() 
			wait(2)
			BEvent:Fire()
			wait(2)
			--Returning Camera and Controls 
			Camera.CameraType = Enum.CameraType.Custom
			Camera.CameraSubject = Humanoid
			Character.HumanoidRootPart.Anchored = false
			Player.CameraMode = Enum.CameraMode.LockFirstPerson
			C1Bed:AdjustSpeed(10)
			Controls:Enable()
			PhoneHere = true
			StartTimer()
			CutsceneInAction = false
			--
		end
	end
	if Input.KeyCode == Enum.KeyCode.Q then
		if PhoneHere == true and First == true then
			First = false
			local PClone = RepPhone:Clone()
			PClone.Parent = RightArm
			local WeldPhone = Instance.new("Weld")
			WeldPhone.Parent = RightArm
			WeldPhone.Part0 = RightArm
			WeldPhone.Part1 = PClone
			PickAnimation:Play()
			wait(3)
			PickAnimation:AdjustSpeed(0)
		elseif First == false then
			local Weld = RightArm.Weld
			local RightArm = RightArm.RightArm
			PickAnimation:AdjustSpeed(100)
			wait(0.5)
			RightArm:Destroy()
			Weld:Destroy()
			wait(2)
			First = true
		end
	end
	
	if Input.KeyCode == Enum.KeyCode.E then
		for _, x in pairs(PlayerGUI:GetDescendants()) do
			if x.Name == "FNote" or x.Name == "Password" then
				x:Destroy()
			end
		end
	end
	

	
	if Input.KeyCode == Enum.KeyCode.T then
		for _, x in pairs(PlayerGUI:GetDescendants()) do
			if x:IsA("ScreenGui") and x.Name == "SText" then
				local bb = tick() - TOpen
				TOpen = tick()
				if bb > 5 then
					Tryings = 0
				end
				print(bb)
				Trying:Play()
				print(Tryings)
				Tryings = Tryings + 1
			end
		end
		if Tryings > 10 and FirstOpen == true and EndingActive.Value == false then
			EndingActive.Value = true
			print(EndingActive.Value)
			print("Ending Activated")
			FirstOpen = false
			local TextClone = TextGUI:Clone()
			TextClone.TextLabel.Text = "It opened?"
			OpenSound:Play()
			TextClone.Parent = PlayerGUI
			TextClone.TextLabel.Position = UDim2.new(0.35, 0, 0.5, 0)
			Debris:AddItem(TextClone, 3)
			local TopPresent = workspace.Location1.MainPresent:WaitForChild("Meshes/Location1_1_Cover")
			TopPresent:SetAttribute("Borrow", 0)
			UnAnchor:FireServer(TopPresent)
			wait(1)
			UnAnchor:FireServer(TopPresent)
			wait(4)
			UndetaleS:Play()
			PlayerGUI.End.Enabled = true
			Character.HumanoidRootPart.Anchored = true
			wait(5)
			Player:Kick("You was too curious(Persistent ending)")
		end
	end
	
	if Input.KeyCode == Enum.KeyCode.P then
		if CanPick == true and EndingActive.Value == false then
			for _, gui in pairs(PlayerGUI:GetDescendants()) do
				if gui:IsA("TextLabel") and gui.Name ~= "Text" then
					print("delet")
					gui:Destroy()
				end
			end
			local TextClone = TextGUI:Clone()
			TextClone.TextLabel.Text = "I don't know where I am. But i don't even care, so good night"
			TextClone.Parent = PlayerGUI
			wait(5)
			UndetaleS:Play()
			PlayerGUI.End.Enabled = true
			wait(3)
			Player:Kick("Nighty")
		end
	end
end)

local RightShoulder = Character.Torso:WaitForChild("Right Shoulder");
local YOffset = RightShoulder.C0.Y



RunService.Stepped:Connect(function()
	if First == false then
		local cameraD = Character.HumanoidRootPart.CFrame:toObjectSpace(Camera.CFrame).lookVector
		RightShoulder.C0 = CFrame.new(0, YOffset, 0)  * CFrame.Angles(math.asin(cameraD.y), 0, 0)  * CFrame.Angles(0, 140, 0)  * CFrame.new(0, 0, 1)
	end
end)


Camera.CameraType = Enum.CameraType.Scriptable
coroutine.wrap(function()
	wait(5)
	while true do 
		Camera.CFrame = CFrame.new(Character.Head.Position, Character.Head.Position + Character.Head.CFrame.lookVector)  * CFrame.Angles(0, 0, 1.5) * CFrame.new(1, 0, 0)
		wait()
	end 
end)()

-------------------------------------------------------- BED CUTSCENE ------------------------------------------------
--Disable Controls

Controls:Disable()
CutsceneInAction = true
EventToStartGame.Event:Connect(function()
	print("Game Started")
	wait(5)
	BEvent:Fire()
end)

--

--Placing Player at right place
Character.HumanoidRootPart.CFrame = workspace.Location1.SL.CFrame
wait(0.5)
--

wait(3)

--Placing camera 
wait(1)
--Camera.CFrame = Character.Head.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(45, 0, 0)
C1Bed:Play()
wait(0.5)
C1Bed:AdjustSpeed(0)




-------------------------------------------------------- BED CUTSCENE ------------------------------------------------

EndE.OnClientEvent:Connect(function(player)
	if EndingActive.Value == true then
		Player:Kick("...")
	else
		EndingActive.Value = true
		local PL = player
		local HRP = Player.Character.HumanoidRootPart
		local UI = Player.PlayerGui
		local TextClone = TextGUI:Clone()
		TextClone.Parent = UI
		wait(3)
		UndetaleS:Play()
		UI.End.Enabled = true
		wait(3)
		Player:Kick("Unusual Ending")
	end
end)

BuggedEnd.OnClientEvent:Connect(function(player)
	if EndingActive.Value == true then
		Player:Kick("Hey!")
	else
		EndingActive.Value = true
		local PL = player
		local HRP = Player.Character.HumanoidRootPart
		local UI = Player.PlayerGui
		local TextClone = TextGUI:Clone()
		TextClone.TextLabel.Text = "It worked"
		TextClone.Parent = UI
		wait(3)
		UndetaleS:Play()
		UI.End.Enabled = true
		wait(2)
		Player:Kick("Bugged Ending")
	end
end)
