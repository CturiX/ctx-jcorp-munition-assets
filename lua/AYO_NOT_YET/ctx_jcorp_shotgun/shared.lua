AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Shotgun"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 260*4

SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 54

SWEP.ViewModel = Model("models/weapons/cstrike/c_shot_xm1014.mdl")
SWEP.WorldModel = Model("models/weapons/cstrike/w_smg_ump45.mdl")

SWEP.HoldType = "ar2"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = true
SWEP.Primary.Automatic = true

SWEP.Primary = {
	Ammo = "Buckshot",

	ClipSize = 8,
	DefaultClip = 26,

	RangeModifier = 1,
	Damage = 18,
	Delay = 60 / 160,
	Accuracy = 9,
	Range = 225,
	Count = 6,

	Recoil = {
		MinAng = Angle(-0.1, -0.5, 0),
		MaxAng = Angle(0.7, 0.5, 0),
		Punch = 1.5,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_Shotgun.Fire",
	
	
	TracerName = "Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

SWEP.ViewOffset = Vector(0, 0, 0)

SWEP.NPCData = {
	Burst = {10, 25},
	Delay = SWEP.Primary.Delay,
	Rest = {0.5, 1.5}
}

list.Add("NPCUsableWeapons", {class = "simple_hl2e_ar3", title = "Simple Weapons: " .. SWEP.PrintName})

local transitions = {
	-- [ACT_VM_PRIMARYATTACK] = ACT_VM_RELOAD,
	-- [ACT_VM_RECOIL1] = ACT_VM_RELOAD,
	-- [ACT_VM_RECOIL2] = ACT_VM_RELOAD,
	-- [ACT_VM_RECOIL3] = ACT_VM_RELOAD,
	-- [ACT_VM_PRIMARYATTACK] = ACT_VM_RECOIL1,
	-- [ACT_VM_RECOIL1] = ACT_VM_RECOIL2,
	-- [ACT_VM_RECOIL2] = ACT_VM_RECOIL3,
	-- [ACT_VM_RECOIL3] = ACT_VM_RECOIL3,
}

function SWEP:GetFireSound()
	if self:GetZoomed() then
		return "Simple_Weapons_JCORP_SMG.LoopAlt"
	else
		return "Simple_Weapons_JCORP_SMG.Loop"
	end
end

function SWEP:TranslateWeaponAnim(act)
	if act == ACT_VM_PRIMARYATTACK then
		local lookup = transitions[self:GetActivity()]

		if lookup then
			act = lookup
		end
	end

	return act
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	self:NetworkVar("Bool", "Zoomed")
end

function SWEP:Deploy()
	BaseClass.Deploy(self)

	-- self:SetZoomed(false)

	return true
end


function SWEP:OwnerChanged()
	BaseClass.OwnerChanged(self)

	local ply = self:GetOwner()

	if IsValid(ply) and ply:IsNPC() then
		hook.Add("Think", self, self.NPCThink)
	else
		hook.Remove("Think", self)
	end
end

function SWEP:OnRemove()
end

function SWEP:Think()
	BaseClass.Think(self)

    if not self:IsValid() or self:GetOwner():GetActiveWeapon() ~= self then
        return
    end

	local owner = self:GetOwner()

    local owner = self:GetOwner()
    if not IsValid(owner) then return end 


end


function SWEP:DoImpactEffect(tr, dmgtype)
	-- self:DoAR2Impact(tr)
end


function SWEP:SecondaryAttack()
	-- Enable zoom when secondary attack is held
	if CLIENT or not IsFirstTimePredicted() then return end

	-- self:SetZoomed(true)
end


function SWEP:AltFire()
	self.Primary.Automatic = true
	-- self:CycleScope()
end

function SWEP:Holster()
    -- self:SetIsFiring(false)

    return BaseClass.Holster(self)
end


sound.Add({
	name = 			"Simple_Weapons_JCORP_Shotgun.Fire",
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	pitch = 		{ 75, 85 },
	level = 		130,
	sound = 				{
		"CTX_Weps/shotgun/firepl1.wav",
		"CTX_Weps/shotgun/firepl2.wav",
		"CTX_Weps/shotgun/firepl3.wav",
		"CTX_Weps/shotgun/firepl4.wav",
	}
})