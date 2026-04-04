AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Assault Rifle"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 280*4

SWEP.Slot = 2
SWEP.m_WeaponDeploySpeed = 1

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 60

SWEP.ViewModel = Model("models/weapons/jma/jma_arifle.mdl")
SWEP.WorldModel = Model("models/weapons/w_rif_galil.mdl")

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
	Damage = 19,
	Delay = 60 / 670,
	Accuracy = 9,
	Range = 200,
	Count = 1,

	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.8, 0.5, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_ARIFLE.Loop",
	
	
	
	Reload = {
		Time = 2.4
	},
	
	
	TracerName = "Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

SWEP.ViewOffset = Vector(5, 0, 0)

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
		return "Simple_Weapons_JCORP_ARIFLE.FireBurst"
	else
		return "Simple_Weapons_JCORP_ARIFLE.Loop"
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
	self:SetLowerTime(0)
	BaseClass.Deploy(self)

	self:SetIsFiring(false)
	self:SetZoomed(false)

	self.Primary.Delay = self.UnscopedStats.Delay
	self.Primary.Accuracy = self.UnscopedStats.Accuracy
	self.Primary.Range = self.UnscopedStats.Range

	self:SetNextIdle(CurTime() + 0.2)
	self:SetNextFire(CurTime() + 0.2)

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
	
	if self:GetZoomed() then
		self:EmitSound("Simple_Weapons_JCORP_ARIFLE.FireBurst")
		self.LastSoundZoomedState = self:GetZoomed()
		return
	end

	if not self:GetIsFiring() then
		self:EmitSound(currentSound)
		self:SetIsFiring(true)
		self.LastSoundZoomedState = self:GetZoomed()
		return
	end

	if self.LastSoundZoomedState ~= self:GetZoomed() then
		self:StopSound(self.LastSoundZoomedState and "Simple_Weapons_JCORP_ARIFLE.Loop")
		self:EmitSound(currentSound)
		self.LastSoundZoomedState = self:GetZoomed()
	end
end


SWEP.UnscopedStats = {
	Damage = 19,
	Delay = 60 / 670,
	Accuracy = 9,
	Range = 400,
	Cost = 1,
	Count = 1,

	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.8, 0.5, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_ARIFLE.Loop",
}

SWEP.ScopedStats = {
	Damage = 24,
	Delay = 60 / 135,
	Accuracy = 4,
	Range = 600,
	Cost = 3,
	Count = 3,

	Recoil = {
		MinAng = Angle(1.3, -0.2, 0),
		MaxAng = Angle(1.6, 0.2, 0),
		Punch = 0.3,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_ARIFLE.FireBurst",
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

		if wantsZoom ~= self:GetZoomed() then
			self:SetZoomed(wantsZoom)

			if wantsZoom then
				-- self.Primary.Damage = self.ScopedStats.Damage
				self.Primary.Delay = self.ScopedStats.Delay
				self.Primary.Accuracy = self.ScopedStats.Accuracy
				self.Primary.Range = self.ScopedStats.Range
				self.Primary.Recoil = self.ScopedStats.Recoil
				self.Primary.Sound = self.ScopedStats.Sound
				self.Primary.Count = self.ScopedStats.Count
				self.Primary.Cost = self.ScopedStats.Cost
				self.Primary.Automatic = False
		-- return "Simple_Weapons_JCORP_ARIFLE.FireBurst"
			else
				-- self.Primary.Damage = self.UnscopedStats.Damage
				self.Primary.Delay = self.UnscopedStats.Delay
				self.Primary.Accuracy = self.UnscopedStats.Accuracy
				self.Primary.Range = self.UnscopedStats.Range
				self.Primary.Recoil = self.UnscopedStats.Recoil
				self.Primary.Sound = self.UnscopedStats.Sound
				self.Primary.Count = self.UnscopedStats.Count
				self.Primary.Cost = self.UnscopedStats.Cost
				self.Primary.Automatic = True
			end
		end
		
	end

	-- self:EmitSound("Simple_Weapons_JCORP_ARIFLE.FireBurst")
	
	if not self:GetZoomed() then
		if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then			
					if IsValid(self) then
						self:EmitSound("Simple_Weapons_JCORP_ARIFLE.LoopEnd")
						self:StopSound(self.Primary.Sound)
						self:SetIsFiring(false)
						self:SetNextFire(CurTime() + 0.03)
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

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

    local aiming = self:GetZoomed()
    local vm = self:GetViewModel()

	if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
	
	self:PrimaryFire()
	
	    if IsValid(vm) then
        if aiming then    
            vm:SendViewModelMatchingSequence(vm:LookupSequence("fireburst"))
        else    
            vm:SendViewModelMatchingSequence(vm:LookupSequence("fire1"))
        end
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
        vm:SetPlaybackRate(1)
    end

    local duration = self:GetReloadTime()

    self:SetFinishReload(CurTime() + duration)
    self:SetNextIdle(CurTime() + duration)
end



sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.Loop",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {108,115},
	sound = {
	"weapons/ctx_jcorp_assaultrifle/new/fire_loop1.wav",
	"weapons/ctx_jcorp_assaultrifle/new/fire_loop2.wav",
	"weapons/ctx_jcorp_assaultrifle/new/fire_loop3.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.FireBurst",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {90,95},
	sound = {
	"weapons/ctx_jcorp_assaultrifle/new/fire_burst_1.wav",
	"weapons/ctx_jcorp_assaultrifle/new/fire_burst_2.wav",
	"weapons/ctx_jcorp_assaultrifle/new/fire_burst_3.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.LoopEnd",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {90, 110},
	sound = {
	"weapons/ctx_jcorp_assaultrifle/new/fire_end1.wav",
	"weapons/ctx_jcorp_assaultrifle/new/fire_end2.wav",
	"weapons/ctx_jcorp_assaultrifle/new/fire_end3.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.Magout",
	channel = CHAN_ITEM,
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "weapons/ctx_jcorp_assaultrifle/new/magout.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.Magin",
	channel = CHAN_ITEM,
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "weapons/ctx_jcorp_assaultrifle/new/magin.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.Draw",
	channel = CHAN_ITEM,
	volume = 1,
	level = 80,
	pitch = {85, 90},
	sound = "weapons/ctx_jcorp_smg/draw_empty.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.Boltopen",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/new/boltopen.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_ARIFLE.Boltclose",
	channel = CHAN_ITEM,
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "weapons/ctx_jcorp_assaultrifle/new/boltclose.wav"
})


function SWEP:FireWeapon()
	local ply = self:GetOwner()
	local primary = self.Primary

	self:EmitFireSound()
	self:SendTranslatedWeaponAnim(ACT_VM_PRIMARYATTACK)
	ply:SetAnimation(PLAYER_ATTACK1)

	local damage = self:GetDamage()

	local bullet = {
		Inflictor = self,
		Num = primary.Count,
		Src = ply:GetShootPos(),
		Dir = self:GetShootDir(),
		Spread = self:GetSpread(),
		TracerName = primary.TracerName,
		Tracer = primary.TracerName == "" and 0 or primary.TracerFrequency,
		Force = damage * 0.25,
		Damage = damage,
		Callback = function(attacker, tr, dmginfo)
			dmginfo:SetDamageType(DMG_BULLET)
			dmginfo:ScaleDamage(self:GetDamageFalloff(tr.StartPos:Distance(tr.HitPos)))

			-- Add dynamic light effect
			if SERVER then
				net.Start("JImpactLight")
				net.WriteVector(tr.HitPos)
				net.Send(attacker)
			end
		end
	}

	self:ModifyBulletTable(bullet)
	ply:FireBullets(bullet)
end