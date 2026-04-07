AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Bolt Pistol"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 225*4

SWEP.Slot = 1

SWEP.Spawnable = true

SWEP.UseHands = true


SWEP.ViewModel = Model("models/weapons/jma/jma_boltpistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg_ump45.mdl")

SWEP.HoldType = "pistol"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1
SWEP.m_WeaponDeploySpeed = 1

SWEP.ScopeZoom = 1.05
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = true

SWEP.Aiming = false

SWEP.Primary = {
	Ammo = "357",

	ClipSize = 8,
	DefaultClip = 24,

	RangeModifier = 1,
	Damage = 120,
	Delay = 1.07,
	Accuracy = 1,
	Range = 285,

	Recoil = {
		MinAng = Angle(2.5, -0.5, 0),
		MaxAng = Angle(2.7, 0.5, 0),
		Punch = 1.5,
		Ratio = 0.2
	},	
	
	Reload = {
		Time = 1.9
	},
	
	Sound = "Simple_Weapons_JCORP_BOLTPISTOL.Fire",
	
	
	-- TracerName = "ar2Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

-- SWEP.Delay = 1

SWEP.UnscopedStats = {
	Delay = 1.07,
	Range = 285,
}

SWEP.ScopedStats = {
	Delay = 0.4,
	Range = 50,
}

SWEP.ViewModelTargetFOV = 90
SWEP.ViewModelFOV = 75
SWEP.ViewOffset = Vector(-2, 0, 0)

list.Add("NPCUsableWeapons", {class = "simple_hl2e_ar3", title = "Simple Weapons: " .. SWEP.PrintName})

function SWEP:GetFireSound()
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	self:NetworkVar("Bool", "Zoomed")
    self:NetworkVar("Bool", 0, "Reloading")
end

function SWEP:Deploy()
	BaseClass.Deploy(self)
	self:SetZoomed(false)
	self.Primary.Delay = self.UnscopedStats.Delay
	self.Primary.Range = self.UnscopedStats.Range
	self:SetNextIdle(CurTime() + 0.2)
	self:SetNextFire(CurTime() + 0.2)
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

function SWEP:EmitFireSound()
	local currentSound = self:GetFireSound()
	self:EmitSound("Simple_Weapons_JCORP_BOLTPISTOL.Fire")

end

function SWEP:Think()
	BaseClass.Think(self)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	local wantsZoom = owner:KeyDown(IN_ATTACK2)

    -- Detect aim toggle
    if wantsZoom and not self.Aiming then
        -- Started aiming
        self.Aiming = true
        self:SetZoomed(true)
        self:PlayAimAnimation(true)

    elseif not wantsZoom and self.Aiming then
        -- Stopped aiming
        self.Aiming = false
        self:SetZoomed(false)
        self:PlayAimAnimation(false)
    end
	
    if self.Aiming and not self.Owner:KeyDown(IN_ATTACK2) then
        self.Aiming = false
    end

    if not self:IsValid() or self:GetOwner():GetActiveWeapon() ~= self then
        return
    end

	local owner = self:GetOwner()
	
	if IsValid(owner) and owner:IsPlayer() then
		local wantsZoom = owner:KeyDown(IN_ATTACK2)

		if wantsZoom ~= self:GetZoomed() then
			self:SetZoomed(wantsZoom)		
		end
	
		if wantsZoom then
			self.Primary.Delay = self.ScopedStats.Delay
			self.Primary.Range = self.ScopedStats.Range
		else
			self.Primary.Delay = self.UnscopedStats.Delay
			self.Primary.Range = self.UnscopedStats.Range
		end 
	end
end

function SWEP:PlayAimAnimation(aiming)
    if CLIENT then return end

	if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
    local vm = self:GetOwner():GetViewModel()
    if not IsValid(vm) then return end

    if aiming then
        -- Play aim animation
        vm:SendViewModelMatchingSequence(vm:LookupSequence("idletoaim"))
    else
        -- Play unaim animation
        vm:SendViewModelMatchingSequence(vm:LookupSequence("aimtoidle"))
    end
end


function SWEP:DoImpactEffect(tr, dmgtype)
	self:DoAR2Impact(tr)
end
function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

    local aiming = self:GetZoomed()
    local vm = self:GetViewModel()

	if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
	

	self:PrimaryFire()
	
	    if IsValid(vm) then
        if aiming then    
            vm:SendViewModelMatchingSequence(vm:LookupSequence("ACT_VM_SECONDARYATTACK"))
        else    
            vm:SendViewModelMatchingSequence(vm:LookupSequence("ACT_VM_PRIMARYATTACK"))
        end
    end
end

function SWEP:SecondaryAttack()
	if CLIENT or not IsFirstTimePredicted() then return end
	self:SetZoomed(true)
	self.Aiming = true
	-- self:SetNextFire(CurTime() + 0.5)
end



function SWEP:AltFire()
	self.Primary.Automatic = true
	self:CycleScope()
end

if CLIENT then
	local currentFOV = nil

	function SWEP:TranslateFOV(fov)
		local targetFOV = fov

		if self:GetZoomed() then
			targetFOV = fov / self.ScopeZoom
		end

		currentFOV = Lerp(FrameTime() * 2, currentFOV or fov, targetFOV)
		return currentFOV
	end

	function SWEP:AdjustMouseSensitivity()
		if self:GetZoomed() then
			return 1 / self.ScopeZoom * 0.5
		end

		return nil -- default sensitivity
	end
end

function SWEP:Holster()
    return BaseClass.Holster(self)
end


sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Fire",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = {
	"weapons/ctx_jcorp_boltpistol/fire_01.wav",
	"weapons/ctx_jcorp_boltpistol/fire_02.wav",
	"weapons/ctx_jcorp_boltpistol/fire_03.wav",
	"weapons/ctx_jcorp_boltpistol/fire_04.wav",
	}
	-- sound = {
	-- "weapons/ctx_jcorp_boltpistol/fire.wav",
	-- }
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Lever",
	channel = CHAN_ITEM,
	volume = {0.5, 0.5},
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_boltpistol/bolt_regular.wav"
	-- sound = "weapons/ctx_jcorp_boltpistol/firebolt.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.LeverFast",
	channel = CHAN_ITEM,
	volume = {0.5, 0.5},
	level = 80,
	pitch = {95, 105},
	sound = "weapons/ctx_jcorp_boltpistol/bolt_fast.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Draw",
	channel = CHAN_ITEM,
	volume = {0.8, 0.8},
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_boltpistol/draw.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Aim",
	channel = CHAN_ITEM,
	volume = {0.4, 0.4},
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_boltpistol/aim.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.AimOut",
	channel = CHAN_ITEM,
	volume = {0.4, 0.4},
	level = 80,
	pitch = {70, 70},
	sound = "weapons/ctx_jcorp_boltpistol/aim.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Magout",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 120},
	sound = "weapons/ctx_jcorp_boltpistol/reload_magout.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Magin",
	channel = CHAN_ITEM,
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "weapons/ctx_jcorp_boltpistol/reload_magin.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_BOLTPISTOL.Bolt",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_boltpistol/reload_bolt.wav"
})

