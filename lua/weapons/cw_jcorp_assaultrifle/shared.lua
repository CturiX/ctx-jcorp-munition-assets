AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Assault Rifle"
SWEP.Category = "JSMC Dedicated Equipments Division"

SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 54

SWEP.ViewModel = Model("models/weapons/cstrike/c_rif_galil.mdl")
SWEP.WorldModel = Model("models/weapons/cstrike/w_rif_galil.mdl")

SWEP.HoldType = "smg"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = false

SWEP.Primary = {
	Ammo = "AR2",

	ClipSize = 45,
	DefaultClip = 180,

	RangeModifier = 1,
	Damage = 17,
	Delay = 60 / 650,
	Accuracy = 9,
	Range = 200,

	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.8, 0.5, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR.Loop",
	
	
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
		return "Simple_Weapons_JCORP_AR.LoopAlt"
	else
		return "Simple_Weapons_JCORP_AR.Loop"
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

	self:NetworkVar("Bool", "IsFiring")
	self:NetworkVar("Bool", "Zoomed")
end

function SWEP:Deploy()
	BaseClass.Deploy(self)

	self:SetIsFiring(false)
	self:SetZoomed(false)

	-- Ensure default stats are set
	self.Primary.Delay = self.UnscopedStats.Delay
	self.Primary.Accuracy = self.UnscopedStats.Accuracy
	self.Primary.Range = self.UnscopedStats.Range

	return true
end


function SWEP:OwnerChanged()
	BaseClass.OwnerChanged(self)

	self:StopSound(self.Primary.Sound)

	local ply = self:GetOwner()

	if IsValid(ply) and ply:IsNPC() then
		hook.Add("Think", self, self.NPCThink)
	else
		hook.Remove("Think", self)
	end
end

function SWEP:OnRemove()
	self:StopSound(self.Primary.Sound)
end

function SWEP:EmitFireSound()
	local currentSound = self:GetFireSound()

	-- If we're not already firing, play the correct loop
	if not self:GetIsFiring() then
		self:EmitSound(currentSound)
		self:SetIsFiring(true)
		self.LastSoundZoomedState = self:GetZoomed()
		return
	end

	-- Already firing, but zoom state changed — switch loop
	if self.LastSoundZoomedState ~= self:GetZoomed() then
		self:StopSound(self.LastSoundZoomedState and "Simple_Weapons_AR3.LoopAlt" or "Simple_Weapons_AR3.Loop")
		self:EmitSound(currentSound)
		self.LastSoundZoomedState = self:GetZoomed()
	end
end

-- function SWEP:Think()
	-- BaseClass.Think(self)

	-- if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then
		-- self:EmitSound("simple_weapons/weapons/ctx/fireend.ogg")
		-- self:StopSound(self.Primary.Sound)

		-- self:SetIsFiring(false)
		-- self:SetNextFire(CurTime() + 0.03)
	-- end
	

	-- if index == 0 then
		-- Sound = "Simple_Weapons_AR3.Loop"
	-- else
		-- Sound = "Simple_Weapons_AR3.LoopAlt"
	-- end
-- end


SWEP.UnscopedStats = {
	Damage = 17,
	Delay = 60 / 650,
	Accuracy = 9,
	Range = 200,

	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.8, 0.5, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR.Loop",
}

SWEP.ScopedStats = {
	Damage = 24,
	Delay = 60 / 400,
	Accuracy = 4,
	Range = 600,

	Recoil = {
		MinAng = Angle(0.3, -0.1, 0),
		MaxAng = Angle(0.6, 0.1, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR.LoopAlt",
}

function SWEP:Think()
	BaseClass.Think(self)

    if not self:IsValid() or self:GetOwner():GetActiveWeapon() ~= self then
        self:StopSound(self.Primary.Sound)
        return
    end

	local owner = self:GetOwner()

	if IsValid(owner) and owner:IsPlayer() then
		local wantsZoom = owner:KeyDown(IN_ATTACK2)

		-- Detect zoom changes and update Primary stats accordingly
		if wantsZoom ~= self:GetZoomed() then
			self:SetZoomed(wantsZoom)

			if wantsZoom then
				self.Primary.Damage = self.ScopedStats.Damage
				self.Primary.Delay = self.ScopedStats.Delay
				self.Primary.Accuracy = self.ScopedStats.Accuracy
				self.Primary.Range = self.ScopedStats.Range
				self.Primary.Recoil = self.ScopedStats.Recoil
				self.Primary.Sound = self.ScopedStats.Sound
			else
				self.Primary.Damage = self.UnscopedStats.Damage
				self.Primary.Delay = self.UnscopedStats.Delay
				self.Primary.Accuracy = self.UnscopedStats.Accuracy
				self.Primary.Range = self.UnscopedStats.Range
				self.Primary.Recoil = self.UnscopedStats.Recoil
				self.Primary.Sound = self.UnscopedStats.Sound
			end
		end
	end

	-- Stop firing sound if needed
	if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then
		self:EmitSound("Simple_Weapons_JCORP_AR.LoopEnd")
		self:StopSound(self.Primary.Sound)
		self:SetIsFiring(false)
		self:SetNextFire(CurTime() + 0.03)
	end
end

function SWEP:DoImpactEffect(tr, dmgtype)
	self:DoAR2Impact(tr)
end

sound.Add({
	name = "Simple_Weapons_JCORP_AR.Loop",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_loud.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_AR.LoopAlt",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_aim_loud.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_AR.LoopEnd",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_end_loud.wav"
})


function SWEP:SecondaryAttack()
	-- Enable zoom when secondary attack is held
	if CLIENT or not IsFirstTimePredicted() then return end

	self:SetZoomed(true)
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
			return 1 / self.ScopeZoom
		end

		return nil -- default sensitivity
	end
end

function SWEP:Holster()
    self:SetIsFiring(false)

    -- Delay stopping the sound very slightly
    timer.Simple(0, function()
        if IsValid(self) then
            self:StopSound(self.Primary.Sound)
        end
    end)

    return BaseClass.Holster(self)
end