AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Heavy Rifle"
SWEP.Category = "JSMC Dedicated Equipments Division"

SWEP.JCMS_COSTOVERRIDE = 550*4

SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 60

SWEP.ViewModel = Model("models/weapons/cstrike/c_mach_m249para.mdl")
SWEP.WorldModel = Model("models/weapons/cstrike/w_rif_galil.mdl")

SWEP.HoldType = "ar2"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.1
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = false
-- SWEP.WalkSpeed = 100 -- default is 150
-- SWEP.RunSpeed = 200

SWEP.Primary = {
	Ammo = "SMG1",

	ClipSize = 50,
	DefaultClip = 180,

	RangeModifier = 1,
	Damage = 12,
	Count = 2,
	Delay = 60 / 700,
	Accuracy = 20,
	Range = 600,
	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.3, 0.5, 0),
		Punch = 1.0,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_HR1.Loop",
	
	
	
	Reload = {
		Time = 3.5
	},
	
	
	TracerName = "Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

SWEP.ViewOffset = Vector(0, 0, 0)


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
		return "Simple_Weapons_JCORP_HR1.Loop"
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
	self.Primary.Recoil = self.UnscopedStats.Recoil
	return true
end

SWEP.UnscopedStats = {
	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.3, 0.5, 0),
		Punch = 1.0,
		Ratio = 0.2
	},
}

SWEP.ScopedStats = {
	Recoil = {
		MinAng = Angle(-0.2, -0.2, 0),
		MaxAng = Angle(0.3, 0.2, 0),
		Punch = 0.6,
		Ratio = 0.2
	},
}

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
		self:EmitSound(currentSound)
		self.LastSoundZoomedState = self:GetZoomed()
	end
end


function SWEP:Think()
	BaseClass.Think(self)

    if not self:IsValid() or self:GetOwner():GetActiveWeapon() ~= self then
        self:StopSound(self.Primary.Sound)
        return
    end

	local owner = self:GetOwner()

	if IsValid(owner) and owner:IsPlayer() then
		local wantsZoom = owner:KeyDown(IN_ATTACK2)

		if wantsZoom ~= self:GetZoomed() then
			self:SetZoomed(wantsZoom)		
		end
	
			if wantsZoom then
				self.Primary.Recoil = self.ScopedStats.Recoil
				-- self.Owner:SetWalkSpeed(130)
				-- self.Owner:SetRunSpeed(130)
			else
				self.Primary.Recoil = self.UnscopedStats.Recoil
				-- self.Owner:SetWalkSpeed(180)
				-- self.Owner:SetRunSpeed(280)
			end
		

	-- Stop firing sound if needed
	if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then	
				if IsValid(self) then
					self:SetIsFiring(false)
					self:EmitSound("Simple_Weapons_JCORP_HR1.End")
					self:SetNextFire(CurTime() + 0.7)
				end
			-- end)
	end
end
end

function SWEP:DoImpactEffect(tr, dmgtype)
		if self:GetZoomed() then
			self:DoAR2Impact(tr) 
		else 
			-- self:DoAR2Impact(tr) 
		end
end

function SWEP:SecondaryAttack()
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

    timer.Simple(0, function()
        if IsValid(self) then
            self:StopSound(self.Primary.Sound)
        end
    end)

    return BaseClass.Holster(self)
end

function SWEP:StartReload()
    local reload = self.Primary.Reload

    self:GetOwner():SetAnimation(PLAYER_RELOAD)

    if reload.Shotgun then
        self:SendTranslatedWeaponAnim(ACT_SHOTGUN_RELOAD_START)
        self:SetFirstReload(true)
    else
        self:SendTranslatedWeaponAnim(ACT_VM_RELOAD)
        self:EmitReloadSound()
    end

    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        vm:SetPlaybackRate(1.5)
    end

    local duration = self:GetReloadTime()

    self:SetFinishReload(CurTime() + duration)
    self:SetNextIdle(CurTime() + duration)
end




sound.Add({
	name = "Simple_Weapons_JCORP_HR1.Loop",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "^weapons/jcorp_emplacement/jcorp_emplacement_fire.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_HR1.End",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "^weapons/jcorp_emplacement/jcorp_emplacement_fire_end.wav"
})