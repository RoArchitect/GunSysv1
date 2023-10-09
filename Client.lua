-- << GLOBAL >> --
local game , workspace = game , workspace
local Get = function(v : string)
	return game:GetService(tostring(v).."\000")
end

-- << DEFINED >> --

local Players = Get('Players');
local ReplicatedStorage = Get('ReplicatedStorage');
local Lighting = Get('Lighting');
local RunService = Get('RunService')
local UserInputService = Get('UserInputService')

local Spring = require(script:WaitForChild("SpringModule"))

local ARFramework = ReplicatedStorage:WaitForChild("ARFramework");
local Viewmodels = ARFramework:WaitForChild("Viewmodels");
local ViewmodelModules = ARFramework:WaitForChild("ViewmodelModules");

local Camera : Instance = workspace.Camera
local LocalCamera : Instance? = workspace.CurrentCamera

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

--- PLAYER INFO ---

local PlayerFramework = {
	Type = nil; -- primary or secondary : string
	
	CurrentlyEquipped = nil; -- gun name : string
	Viewmodel = nil; -- viewmodel : model / instance
	ViewmodelAnimator = nil; -- animator : animator?
	ViewmodelModule = nil; -- module : table
}

--- CFRAMES ---

local GunCFrame
local AimCF = CFrame.new()
local SwaySpring = Spring.new()
local BobSpring = Spring.new()
local Offset = CFrame.new()

--- BOOLEANS ---

local IsAiming = false
local IsShooting = false
local IsInspecting = false
local IsSafetyOn = false

--- ANIM TRACKS ---
-- VIEWMODEL TRACKS --
local VM_Safety
local VM_Shoot
local VM_Inspect

-- << FUNCTIONS >> --

local function FindViewmodelModule
(
	Gun : string	
)
	
	--<<>>--
	
	local Module = ViewmodelModules:FindFirstChild(Gun , true)
	
	if (Module) then
		return Module
	end
	
	--<<>>--
	
end

local function ReloadAnimations
(
	
)
	
	for index , inst in ipairs(PlayerFramework.Viewmodel:GetChildren()) do
		if inst:IsA("Animation") then
			
			if inst.Name == "Safety" then
				VM_Safety = PlayerFramework.ViewmodelAnimator:LoadAnimation(inst)
			elseif inst.Name == "Shoot" then
				VM_Shoot = PlayerFramework.ViewmodelAnimator:LoadAnimation(inst)
			elseif inst.Name == "Inspect" then
				VM_Inspect = PlayerFramework.ViewmodelAnimator:LoadAnimation(inst)
			end
			
		end
	end
	
end

local function Equip
(
	Gun : string
)
	
	--<<>>--
	
	local RequiredModule
	local Module = FindViewmodelModule(Gun)
	
	local Viewmodel = Viewmodels:FindFirstChild(Gun)
	
	if (Module and Viewmodel) then
		
		RequiredModule = require(Module)
		
		local ClonedViewmodel = Viewmodel:Clone()
		ClonedViewmodel.Parent = Camera
		
		PlayerFramework.Type = RequiredModule.Type
		PlayerFramework.ViewmodelModule = RequiredModule
		PlayerFramework.Viewmodel = ClonedViewmodel
		PlayerFramework.ViewmodelAnimator = ClonedViewmodel:WaitForChild("Animation"):WaitForChild("Animator")
		PlayerFramework.CurrentlyEquipped = Gun
		
		Offset = RequiredModule.Offset
		
		ReloadAnimations()
		
	else
		PlayerFramework.Type = nil
		PlayerFramework.Viewmodel = nil
		PlayerFramework.CurrentlyEquipped = nil
		PlayerFramework.ViewmodelModule = nil
		return nil
	end
	
	--<<>>--
	
end

local function Bob(addition)
	return math.sin(tick() * addition * 1.3) * 0.5
end

-- << Connections >> --

Equip('HK416')

RunService.RenderStepped:Connect(function(dt)
	if 
		PlayerFramework.ViewmodelModule and 
		PlayerFramework.Viewmodel
	then	
		
		local Delta = game.UserInputService:GetMouseDelta()
		SwaySpring:shove(Vector3.new(-Delta.X/500, Delta.Y/500, 0))
		BobSpring:shove(Vector3.new(Bob(5), Bob(10), Bob(5)) / 10 * (Character.PrimaryPart.Velocity.Magnitude) / 10)
		local UpdatedSway = SwaySpring:update(dt)
		local UpdatedBob = BobSpring:update(dt)
		
		if IsAiming then
			AimCF = (PlayerFramework.Viewmodel.GUN.AimPart.CFrame:ToObjectSpace(PlayerFramework.Viewmodel.HumanoidRootPart.CFrame))
		else
			AimCF = CFrame.new(0,0,0)
		end
		
		local UPS1 = CFrame.new(UpdatedSway.X, UpdatedSway.Y, 0)
		local UPS2 = CFrame.new(UpdatedBob.X, UpdatedBob.Y, 0)
		local LCC = LocalCamera.CFrame
		
		GunCFrame 	= 
			LCC  	*
			UPS1 	*
			UPS2 	*
			Offset  *
			AimCF
		
		PlayerFramework.Viewmodel:PivotTo(
			GunCFrame
		)
		
	end
end)

UserInputService.InputBegan:Connect(function(input : Enum , GameProcessed : boolean)
	
	if input.KeyCode == Enum.KeyCode.T then
		IsSafetyOn = not IsSafetyOn
		
		if VM_Safety then
			
			if IsSafetyOn then
				VM_Safety:Play()
			else
				VM_Safety:Stop()
			end
			
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		IsAiming = not IsAiming
	end
	
end)
