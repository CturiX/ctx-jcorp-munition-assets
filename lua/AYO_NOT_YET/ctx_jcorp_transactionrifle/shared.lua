AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Transaction Rifle"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 300*4

SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 54

SWEP.ViewModel = Model("models/weapons/cstrike/c_rif_ak47.mdl")
SWEP.WorldModel = Model("models/weapons/cstrike/w_rif_ak47.mdl")

SWEP.HoldType = "smg"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = false

SWEP.Primary = {
	Ammo = "AirboatGun",

	ClipSize = -1,
	DefaultClip = 60,

	RangeModifier = 1,
	Damage = 16,
	Delay = 60 / 650,
	Accuracy = 9,
	Range = 300,
	Count = 3,

	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.8, 0.5, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR1.Loop",
	
	
	
	Reload = {
		Time = 1.6
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
	if self:GetZoomed() then
		return "Simple_Weapons_JCORP_AR1.LoopAlt"
	else
		return "Simple_Weapons_JCORP_AR1.Loop"
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
    local dmginfo = DamageInfo()

	self:SetIsFiring(false)
	self:SetZoomed(false)

	-- Ensure default stats are set
	self.Primary.Delay = self.UnscopedStats.Delay
	self.Primary.Accuracy = self.UnscopedStats.Accuracy
	self.Primary.Range = self.UnscopedStats.Range
	-- self.Owner:SetWalkSpeed(200)
	-- self.Owner:SetRunSpeed(400)
	
	
    dmginfo:SetDamageType(DMG_BURN)

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

	if not self:GetIsFiring() then
		self:EmitSound(currentSound)
		self:SetIsFiring(true)
		self.LastSoundZoomedState = self:GetZoomed()
		return
	end

	if self.LastSoundZoomedState ~= self:GetZoomed() then
		self:StopSound(self.LastSoundZoomedState and "Simple_Weapons_JCORP_AR1.LoopAlt" or "Simple_Weapons_JCORP_AR1.Loop")
		self:EmitSound(currentSound)
		self.LastSoundZoomedState = self:GetZoomed()
	end
end


SWEP.UnscopedStats = {
	Damage = 19,
	Delay = 60 / 650,
	Accuracy = 9,
	Range = 400,

	Recoil = {
		MinAng = Angle(-0.2, -0.5, 0),
		MaxAng = Angle(0.8, 0.5, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR1.Loop",
}

SWEP.ScopedStats = {
	Damage = 24,
	Delay = 60 / 430,
	Accuracy = 4,
	Range = 600,

	Recoil = {
		MinAng = Angle(0.3, -0.2, 0),
		MaxAng = Angle(0.6, 0.2, 0),
		Punch = 0.4,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_AR1.LoopAlt",
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
				self.Primary.Damage = self.ScopedStats.Damage
				self.Primary.Delay = self.ScopedStats.Delay
				self.Primary.Accuracy = self.ScopedStats.Accuracy
				self.Primary.Range = self.ScopedStats.Range
				self.Primary.Recoil = self.ScopedStats.Recoil
				self.Primary.Sound = self.ScopedStats.Sound
				-- self.Owner:SetWalkSpeed(180)
				-- self.Owner:SetRunSpeed(180)
			else
				self.Primary.Damage = self.UnscopedStats.Damage
				self.Primary.Delay = self.UnscopedStats.Delay
				self.Primary.Accuracy = self.UnscopedStats.Accuracy
				self.Primary.Range = self.UnscopedStats.Range
				self.Primary.Recoil = self.UnscopedStats.Recoil
				self.Primary.Sound = self.UnscopedStats.Sound
				-- self.Owner:SetWalkSpeed(200)
				-- self.Owner:SetRunSpeed(400)
			end
		end
		
		if owner:GetAmmoCount("AirboatGun") > 60 then -- i fogor how to get DefaultClip
				self.Primary.Cost = 3
				self.Primary.Count = 3
			else
				self.Primary.Cost = 1
				self.Primary.Count = 1
		end
		
	end

	if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then			
				if IsValid(self) then
					self:EmitSound("Simple_Weapons_JCORP_AR1.LoopEnd")
					self:StopSound(self.Primary.Sound)
					self:SetIsFiring(false)
					self:SetNextFire(CurTime() + 0.03)
				end
			-- end)
	end
end

function SWEP:DoImpactEffect(tr, dmgtype)
		if self:GetZoomed() then
			self:DoAR2Impact(tr) 
		else 
			-- self:DoAR2Impact(tr) 
		end
end

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
			dmginfo:SetDamageType(DMG_DISSOLVE)
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


function SWEP:Reload()
    local owner = self:GetOwner()	
	local cost = 1
	
	if self:GetNextFire() > CurTime() then
		return false
	end

	if self:IsReloading()  then
		return false
	end

	if owner:GetNWInt("jcms_cash") < cost  then
		return false
	end
	
	if owner:GetAmmoCount("AirboatGun") > 59 then return end
	
	self:StartReload()
end



function SWEP:StartReload()
    local reload = self.Primary.Reload

    self:GetOwner():SetAnimation(PLAYER_RELOAD)

	self:SendTranslatedWeaponAnim(ACT_VM_RELOAD)
	self:EmitReloadSound()

    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        vm:SetPlaybackRate(1.25)
    end

    local duration = self:GetReloadTime()

    self:SetFinishReload(CurTime() + duration)
    self:SetNextIdle(CurTime() + duration)
end



function SWEP:FinishReload()


	local primary = self.Primary
	local reload = primary.Reload
	local default = primary.DefaultClip
	local ply = self:GetOwner()
	local owner = self:GetOwner()
	local ammo = owner:GetAmmoCount("AirboatGun")
	-- local cost = 60	
	-- local total = math.Round(ammo/45/cost)
	
	
	local total = math.Round(default-ammo)

	local amount = math.min(primary.ClipSize - self:Clip1(), reload.Amount)
	local first = self:GetFirstReload()
	
	self:SetClip1(self:Clip1() + amount)
	self:SetFinishReload(0)
	
	owner:SetAmmo(default, "AirboatGun")
	
	
	-- owner:SetNWInt("jcms_cash", math.max(owner:GetNWInt("jcms_cash",0)+500, 0))
	
	owner:SetNWInt("jcms_cash", math.max(owner:GetNWInt("jcms_cash",0)-total, 0))
	
	
	
	primary.Automatic = true
end



function SWEP:CanReload()
	if self.AmmoType != AMMO_NORMAL then
		return false
	end

	if self:GetNextFire() > CurTime() then
		return false
	end

	if self:IsReloading() then
		return false
	end

	return true
end


sound.Add({
	name = "Simple_Weapons_JCORP_AR1.Loop",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_AR1.LoopAlt",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_aim.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_AR1.LoopEnd",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 100},
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_end.wav"
})