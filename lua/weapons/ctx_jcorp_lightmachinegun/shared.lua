AddCSLuaFile()

hook.Add( "SetupMove", "ReduceSpeedOverride", function( ply, mv, cmd )
  local wep = ply:GetActiveWeapon()
  if not IsValid(wep) or not wep.speedMultiplier then return end

  local mul = wep.speedMultiplier
  mv:SetForwardSpeed(mv:GetForwardSpeed() * mul)
  mv:SetSideSpeed(mv:GetSideSpeed() * mul)

end )

DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Light Machine Gun"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 380*4

SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.UseHands = true


SWEP.ViewModel = Model("models/weapons/jma/jma_lightmachinegun.mdl")
SWEP.WorldModel = Model("models/weapons/w_mach_m249para.mdl")

SWEP.HoldType = "smg"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.05
-- SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = false
-- SWEP.WalkSpeed = 100 -- default is 150
-- SWEP.RunSpeed = 200
SWEP.Aiming = false
SWEP.AimReleasedTime = 0
SWEP.AimReleaseDelay = 0.8

SWEP.Primary = {
	Ammo = "AR2",

	ClipSize = -1,
	DefaultClip = 100,

	RangeModifier = 1,
	Damage = 18,
	Count = 2,
	-- Delay = 60 / 1000,
	Delay = 0.09,
	Cost = 1,
	Accuracy = 20,
	Range = 400,
	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.3, 0.5, 0),
		Punch = 1.0,
		Ratio = 0.2
	},
	-- Sound = "Simple_Weapons_JCORP_LMG1.Loop",
	Sound = "Simple_Weapons_JCORP_HR1.Loop",
	
	
	
	Reload = {
		Time = 3.5
	},
	
	Deploy = {
		Time = 1
	},
	
	
	TracerName = "Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

SWEP.ViewModelTargetFOV = 90
SWEP.ViewModelFOV = 70
SWEP.ViewOffset = Vector(7, -2, 0)


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
		return "Simple_Weapons_JCORP_LMG1.Loop"
		-- return "Simple_Weapons_JCORP_HR1.Loop"
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
		MinAng = Angle(0.1, -0.3, 0),
		MaxAng = Angle(0.3, -0.1, 0),
		Punch = 1.8,
		Ratio = -0.4
	},
	Range = 400,
	Accuracy = 18,
}

SWEP.ScopedStats = {
	Recoil = {
		MinAng = Angle(-0.2, -0.2, 0),
		MaxAng = Angle(0.3, 0.1, 0),
		Punch = 0.6,
		Ratio = 0.2
	},
	Range = 1000,
	Accuracy = 10,
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
	
		-- self:EmitSound("Simple_Weapons_JCORP_LMG1.Sweetener2")
		-- self:EmitSound("Simple_Weapons_JCORP_LMG1.Sweetener2")

	-- If we're not already firing, play the correct loop
	if not self:GetIsFiring() then
		self:EmitSound("Simple_Weapons_JCORP_LMG1.LoopBegin")
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
	
		-- self:EmitSound("Simple_Weapons_JCORP_LMG1.Sweetener")
end


function SWEP:Think()
	BaseClass.Think(self)
	
    -- if wantsZoom and not self.Aiming then
        -- self.Aiming = true
        -- self:SetZoomed(true)
        -- self:PlayAimAnimation(true)
    -- elseif not wantsZoom and self.Aiming then
        -- self.Aiming = false
        -- self:SetZoomed(false)
        -- self:PlayAimAnimation(false)
    -- end
	
    if self.Aiming and not self.Owner:KeyDown(IN_ATTACK2) then
		self:PlayAimAnimation(aiming)
        self.Aiming = false
        self.AimReleasedTime = CurTime()
    end

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
				self.isinaimanim = true
				self.Primary.Recoil = self.ScopedStats.Recoil
				self.Primary.Range = self.ScopedStats.Range
				self.Primary.Accuracy = self.ScopedStats.Accuracy
				-- self.Owner:SetWalkSpeed(130)
				-- self.Owner:SetRunSpeed(130)
			else
				self.isinaimanim = false
				self.Primary.Recoil = self.UnscopedStats.Recoil
				self.Primary.Range = self.UnscopedStats.Range
				self.Primary.Accuracy = self.UnscopedStats.Accuracy
				-- self.Owner:SetWalkSpeed(180)
				-- self.Owner:SetRunSpeed(280)
			end
		

	-- Stop firing sound if needed
	if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then	
				if IsValid(self) then
					self:SetIsFiring(false)
					self:EmitSound("Simple_Weapons_JCORP_LMG1.End")
					-- self:EmitSound("Simple_Weapons_JCORP_HR1.End")
					self:SetNextFire(CurTime() + 0.1)
				end
			-- end)
	end
end
end


function SWEP:PlayAimAnimation(Aiming)
    if CLIENT then return end


	-- if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
    local vm = self:GetOwner():GetViewModel()
    if not IsValid(vm) then return end

        vm:SendViewModelMatchingSequence(vm:LookupSequence("aimtoidle"))
end
function SWEP:Leaveanim(Aiming)
    if CLIENT then return end


	-- if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
    local vm = self:GetOwner():GetViewModel()
    if not IsValid(vm) then return end

        vm:SendViewModelMatchingSequence(vm:LookupSequence("idletoaim"))
end



function SWEP:DoImpactEffect(tr, dmgtype)
			self:DoAR2Impact(tr) 
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

    local aiming = self:GetZoomed()
    local vm = self:GetViewModel()

	if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
	
    if CurTime() < self.AimReleasedTime + self.AimReleaseDelay then return end
	

	self:PrimaryFire()
	
	    if IsValid(vm) then
        if aiming then    
            vm:SendViewModelMatchingSequence(vm:LookupSequence("aimfire"))
        else    
            vm:SendViewModelMatchingSequence(vm:LookupSequence("fire1"))
        end
    end
end

function SWEP:SecondaryAttack()
	if CLIENT or not IsFirstTimePredicted() then return end
	
	if self:GetIsFiring() then 
		self.IsFiring = false
        self:StopSound(self.Primary.Sound)
		self:EmitSound("Simple_Weapons_JCORP_LMG1.End")
	end

	self:SetZoomed(true)
	
	self:SetNextFire(CurTime() + 1)
	self.Aiming = true
	self:Leaveanim(Aiming)
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
			return 1 / self.ScopeZoom * 0.3
		end

		return nil
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


sound.Add({
	name = "Simple_Weapons_JCORP_LMG1.Loop",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = 100,
	sound = "weapons/ctx_jcorp_lightmachinegun/fire2.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LMG1.End",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {110, 130},
	sound = "weapons/ctx_jcorp_lightmachinegun/fire-2end.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LMG1.Sweetener",
	channel = CHAN_STATIC,
	volume = {0.8, 1},
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/fire_sweeteneralso.wav"
})




sound.Add({
	name = "Simple_Weapons_JCORP_LMG1.Sweetener2",
	channel = CHAN_ITEM,
	volume = {0.5, 0.5},
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/fire_sweetener.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LMG1.LoopBegin",
	channel = CHAN_ITEM,
	volume = 0.6,
	level = 90,
	pitch = {90, 100},
	sound = {
	"weapons/ctx_jcorp_lightmachinegun/fire_loopbegin1.wav",
	"weapons/ctx_jcorp_lightmachinegun/fire_loopbegin2.wav",
	}
})


sound.Add({
	name = "Simple_Weapons_JCORP_LIGHTMACHINEGUN.ChainIn",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/chaininn.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LIGHTMACHINEGUN.Close",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/closen.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LIGHTMACHINEGUN.Bolt",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/boltn.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LIGHTMACHINEGUN.Bipoddown",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/bipoddown.wav"
})



sound.Add({
	name = "Simple_Weapons_JCORP_LIGHTMACHINEGUN.Bipodup",
	channel = CHAN_ITEM,
	volume = .8,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_lightmachinegun/bipodupp.wav"
})

