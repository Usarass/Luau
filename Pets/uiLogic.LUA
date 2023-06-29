local replicatedStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local player = game:GetService('Players').LocalPlayer
local playerGui = script.Parent

local bildboardGui = playerGui:WaitForChild('EggBildboardGui')
local buyButton = bildboardGui:WaitForChild('EggsFrame'):WaitForChild('BuyButton')

local petsInventory = playerGui:WaitForChild('PetsInventory')
local propertiesFrame = petsInventory:WaitForChild('PropertiesFrame')
local closePropertiesFrameButton = propertiesFrame:WaitForChild('CloseButton')
local equipButton = propertiesFrame:WaitForChild('EquipButton')

local remoteEventsFolder = replicatedStorage:WaitForChild('RemoteEvents')
local EggOpenEvent = remoteEventsFolder:WaitForChild('EggOpenEvent')
local RenderPlayerPet = remoteEventsFolder:WaitForChild('RenderPlayerPets')
local EquipPet = remoteEventsFolder:WaitForChild('PetEquip')
local PetUnequip = remoteEventsFolder:WaitForChild('UnequipPet')

local remoteFunctionsFolder = replicatedStorage:WaitForChild('RemoteFunctions')

local CheckEquipedValue = remoteFunctionsFolder:WaitForChild('CheckEquipedValue')

buyButton.MouseButton1Up:Connect(function()
	EggOpenEvent:FireServer()
end)

local scrollingFrame = playerGui:WaitForChild('PetsInventory'):WaitForChild('ScrollingFrame')

local viewPortExample = replicatedStorage:WaitForChild('GuiExamples'):WaitForChild('ViewportFrame')

local petsViewportSettings = {
	['ObamaBall'] = {CFrame.new(0, 13, 9), Vector3.new(-40, 0, 0)},
	['ObamaBallCute'] = {CFrame.new(0, 13, 9), Vector3.new(-40, 0, 0)},
	['Obamid'] = {CFrame.new(0, 5, -0.1), Vector3.new(0, 180, 0)}
}

local function createNewPetFrame(petModel)
	local viewportClone = viewPortExample:Clone()
	
	viewportClone.Parent = scrollingFrame
	
	local clonnedPetModel = petModel:Clone()
	
	local petViewportSettings = petsViewportSettings[petModel.Name]
	
	clonnedPetModel.Parent = viewportClone
	clonnedPetModel.CFrame = petViewportSettings[1]
	clonnedPetModel.Rotation = petViewportSettings[2]
	
	return viewportClone, clonnedPetModel
end

local openButtonForPetsInventory = scrollingFrame.Parent:WaitForChild('OpenButton')
local inventoryShown = false

local petsModelsFolder = replicatedStorage:WaitForChild('PetsModels')

openButtonForPetsInventory.MouseButton1Up:Connect(function()
	if inventoryShown then 
		scrollingFrame.Visible = false
		
		inventoryShown = false
		propertiesFrame.Visible = false
		
		return
	end
	inventoryShown = true
	
	scrollingFrame.Visible = true
end)

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local currentEquipedValue

local function checkValue(Value)
	if Value then
		return 'Unequip'
	else
		return 'Equip'
	end
end

local currentPetNumber

RenderPlayerPet.OnClientEvent:Connect(function(pets, petsBoosts)
	for petNumber, petsValuesTable in next, pets do
		local petName = petsValuesTable[1]
		
		local petFrame, clonnedPetModel = createNewPetFrame(petsModelsFolder[petName])
		
		local currentPetRotation = clonnedPetModel.Rotation
		
		local petRotationTween = tweenService:Create(clonnedPetModel, tweenInfo, {Rotation = currentPetRotation + Vector3.new(0, 90, 0)})
		local petRotationBackTween = tweenService:Create(clonnedPetModel, tweenInfo, {Rotation = currentPetRotation})
		
		petFrame.TextButton.MouseButton1Up:Connect(function()
			propertiesFrame.Visible = true
			
			propertiesFrame.PetName.Text = petName
			propertiesFrame.BoostNumber.Text = petsBoosts[petName]
			
			equipButton.Text = checkValue(CheckEquipedValue:InvokeServer(petNumber))
			currentPetNumber = petNumber
		end)
		
		petFrame.TextButton.MouseEnter:Connect(function()
			petRotationTween:Play()
		end)
		
		petFrame.TextButton.MouseLeave:Connect(function()
			petRotationTween:Pause()
			petRotationBackTween:Play()
		end)
	end
end)

closePropertiesFrameButton.MouseButton1Up:Connect(function()
	propertiesFrame.Visible = false
end)

equipButton.MouseButton1Up:Connect(function()
	local petName = propertiesFrame.PetName.Text
	
	if CheckEquipedValue:InvokeServer(currentPetNumber) then
		equipButton.Text = 'Equip'
		PetUnequip:FireServer(petName, currentPetNumber)
	else
		EquipPet:FireServer(petName, currentPetNumber)
		equipButton.Text = 'Unequip'
	end
end)
