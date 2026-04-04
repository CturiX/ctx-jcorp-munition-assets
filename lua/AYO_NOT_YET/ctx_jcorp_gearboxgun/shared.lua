AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Gearbox Gun"
SWEP.Category = "JSMC Dedicated Equipments Division"

SWEP.JCMS_COSTOVERRIDE = 825*4

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

SWEP.Primary = {
	Ammo = "AR2",

	ClipSize = -1,
	DefaultClip = 200,

	RangeModifier = 1,
	Damage = 24,
	Delay = 60 / 800,
	Accuracy = 4,
	Range = 600,
	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.3, 0.5, 0),
		Punch = 1.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR1.Loop",
	
	
	
	Reload = {
		Time = 2.4
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
	-- if self:GetZoomed() then
		-- return "Simple_Weapons_JCORP_AR1.LoopAlt"
	-- else
		return "Simple_Weapons_JCORP_AR1.Loop"
	-- end
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
		-- self:StopSound(self.LastSoundZoomedState and "Simple_Weapons_AR3.LoopAlt" or "Simple_Weapons_AR3.Loop")
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
		end
		
		if self:GetZoomed() then
			TracerName = "AirboatGunTracer"
		else 
			TracerName = "Tracer"
		end

	-- Stop firing sound if needed
	if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then			
			timer.Simple(0.035, function()
				if IsValid(self) then
					self:EmitSound("Simple_Weapons_JCORP_AR1.LoopEnd")
					self:StopSound(self.Primary.Sound)
					self:SetIsFiring(false)
					self:SetNextFire(CurTime() + 0.03)
				end
			end)
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

    -- 🟡 Set playback speed
    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        vm:SetPlaybackRate(1.25) -- 1.5x faster
    end

    local duration = self:GetReloadTime()

    self:SetFinishReload(CurTime() + duration)
    self:SetNextIdle(CurTime() + duration)
end