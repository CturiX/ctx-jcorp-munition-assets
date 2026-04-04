AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "SMG"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 300*4

SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 70

SWEP.ViewModel = Model("models/weapons/jma/f/jma_smg.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg_ump45.mdl")

SWEP.HoldType = "smg"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = true

SWEP.Primary = {
	Ammo = "SMG1",

	ClipSize = 60,
	DefaultClip = 180,

	RangeModifier = 1,
	Damage = 12,
	Delay = 60 / 1200,
	Accuracy = 4,
	Range = 200,
	Count = 1,
	Cost = 1,

	Recoil = {
		MinAng = Angle(0.1, -0.2, 0),
		MaxAng = Angle(0.3, 0.2, 0),
		Punch = 0.5,
		Ratio = 0.2
	},
	
	Reload = {
		Time = 1.5
	},
	Draw = {
		Time = 0.7
	},
	Sound = "Simple_Weapons_JCORP_SMG.Loop",
	
	
	TracerName = "Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

SWEP.ViewOffset = Vector(2, 0, 0)

local transitions = {
	-- [ACT_VM_PRIMARYATTACK] = ACT_VM_RELOAD,
	-- [ACT_VM_RECOIL1] = ACT_VM_RELOAD,
	-- [ACT_VM_RECOIL2] = ACT_VM_RELOAD,
	-- [ACT_VM_RECOIL3] = ACT_VM_RELOAD,
	[ACT_VM_PRIMARYATTACK] = ACT_VM_RECOIL1,
	[ACT_VM_RECOIL1] = ACT_VM_RECOIL1,
}

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
    local vm = self:GetViewModel()
	local ply = self:GetOwner()
	local ammo = ply:GetAmmoCount("SMG1")
	self:SetLowerTime(0)
	BaseClass.Deploy(self)
	self:StopSound(self.Primary.Sound)
	self.ViewModelTargetFOV = 70
	self:SetIsFiring(false)

	if IsValid(vm) then
        if self:Clip1() == 0 and ammo > 0 then    
			self:SetNextFire(CurTime() + 1.6)
			local duration = (1.6)			
			vm:SendViewModelMatchingSequence(vm:LookupSequence("drawempty"))
			self:SetNextIdle(CurTime() + duration)
			self:SetFinishReload(CurTime() + duration)
     else
			vm:SendViewModelMatchingSequence(vm:LookupSequence("ACT_VM_DRAW"))	
			self:SetNextIdle(CurTime() + self:SequenceDuration())	
		end
	end
	
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

end

function SWEP:GetFireSound()
		return "Simple_Weapons_JCORP_SMG.Loop"
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

    local aiming = self:GetZoomed()
    local vm = self:GetViewModel()
	local ammo = ply:GetAmmoCount("SMG1")

	if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then	return end
	
    -- if CurTime() < self.AimReleasedTime + self.AimReleaseDelay then return end
	

	self:PrimaryFire()
	
	    if IsValid(vm) then
        if self:Clip1() == 0 and ammo > 0 then    
			self:SetNextFire(CurTime() + 2)
			local duration = (self:GetReloadTime() + 1.3)
			self:StopSound(self.Primary.Sound)
			self:EmitSound("Simple_Weapons_JCORP_SMG.LoopEnd")
			self:SetIsFiring(false)
			
            vm:SendViewModelMatchingSequence(vm:LookupSequence("reloadfire"))

			self:SetFinishReload(CurTime() + duration)
			self:SetNextIdle(CurTime() + duration)
        else
			vm:SendViewModelMatchingSequence(vm:LookupSequence("ACT_VM_PRIMARYATTACK"))
		
        end
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
			dmginfo:SetDamageType(DMG_BLAST)
			dmginfo:ScaleDamage(self:GetDamageFalloff(tr.StartPos:Distance(tr.HitPos)))

			-- Add dynamic light effect
			if SERVER then
				net.Start("JImpactLightSmall")
				net.WriteVector(tr.HitPos)
				net.Send(attacker)
			end
		end
	}

	self:ModifyBulletTable(bullet)
	ply:FireBullets(bullet)
end

function SWEP:Think()
	BaseClass.Think(self)

    if not self:IsValid() or self:GetOwner():GetActiveWeapon() ~= self then
        return
    end

	local owner = self:GetOwner()

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
		

	-- Stop firing sound if needed
	if self:GetIsFiring() and CurTime() > self:GetNextFire() + engine.TickInterval() then
			
			timer.Simple(0.0, function()
				if IsValid(self) then
					self:StopSound(self.Primary.Sound)
					self:EmitSound("Simple_Weapons_JCORP_SMG.LoopEnd")
					self:StopSound(self.Primary.Sound)
					self:SetIsFiring(false)
					self:SetNextFire(CurTime() + 0.03)
				end
			end)
	end
end


function SWEP:DoImpactEffect(tr, dmgtype)
	self:DoAR2Impact(tr)
end

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Loop",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 120,
	pitch = 100,
	sound = 				{
		"weapons/ctx_jcorp_smg/fire_loop_1.wav",
		"weapons/ctx_jcorp_smg/fire_loop_2.wav",
		"weapons/ctx_jcorp_smg/fire_loop_3.wav",
		"weapons/ctx_jcorp_smg/fire_loop_4.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.LoopEnd",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 120,
	pitch = {90, 100},
	sound = 				{
		-- "weapons/ctx_jcorp_smg/fire_end_1.wav",
		-- "weapons/ctx_jcorp_smg/fire_end_2.wav",
		-- "weapons/ctx_jcorp_smg/fire_end_3.wav",
		-- "weapons/ctx_jcorp_smg/fire_end_4.wav"
		"weapons/ctx_jcorp_smg/fire_end_n.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Single",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 120,
	pitch = {90, 100},
	sound = 				{
		"weapons/ctx_jcorp_smg/fire_single_1.wav",
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Empty",
	channel = CHAN_ITEM,
	volume = 1,
	level = 90,
	pitch = {120, 130},
	sound = "weapons/ctx_jcorp_smg/bolt_empty.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.MagoutEmpty",
	channel = CHAN_WEAPON,
	volume = {0.6, 0.8},
	level = 90,
	pitch = 100,
	sound = 				{
		"weapons/ctx_jcorp_smg/magoutempty_1.wav",
		"weapons/ctx_jcorp_smg/magoutempty_2.wav",
		"weapons/ctx_jcorp_smg/magoutempty_3.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Magout",
	channel = CHAN_ITEM,
	volume = {0.2, 0.4},
	level = 90,
	pitch = {100, 110},
	sound = 				{
		"weapons/ctx_jcorp_smg/magout_1.wav",
		"weapons/ctx_jcorp_smg/magout_2.wav",
		"weapons/ctx_jcorp_smg/magout_3.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Magin",
	channel = CHAN_ITEM,
	volume = {0.3, 0.4},
	level = 90,
	pitch = {85, 105},
	sound = 				{
		"weapons/ctx_jcorp_smg/magin_1.wav",
		"weapons/ctx_jcorp_smg/magin_2.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Slap",
	channel = CHAN_ITEM,
	volume = {0.6, 0.8},
	level = 90,
	pitch = {95, 105},
	sound = 				{
		"weapons/ctx_jcorp_smg/slap_1.wav",
		"weapons/ctx_jcorp_smg/slap_2.wav",
		"weapons/ctx_jcorp_smg/slap_3.wav"
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.Draw",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 90,
	pitch = 100,
	sound = "weapons/ctx_jcorp_smg/draw_flip.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.DrawEmpty",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 90,
	pitch = 100,
	sound = "weapons/ctx_jcorp_smg/draw_empty.wav"
})

function SWEP:SecondaryAttack()
	-- Enable zoom when secondary attack is held
	if CLIENT or not IsFirstTimePredicted() then return end

	-- self:SetZoomed(true)
end

function SWEP:Holster()
    self:SetIsFiring(false)

    -- Delay stopping the sound very slightly
    timer.Simple(0.02, function()
        if IsValid(self) then
            self:StopSound(self.Primary.Sound)
        end
    end)

    return BaseClass.Holster(self)
end

-- function SWEP:StartReload()
    -- local reload = self.Primary.Reload

    -- self:GetOwner():SetAnimation(PLAYER_RELOAD)


    -- local vm = self:GetOwner():GetViewModel()
    -- if IsValid(vm) then
        -- vm:SetPlaybackRate(1.0) -- 1.5x faster
    -- end

    -- local duration = self:GetReloadTime()

    -- self:SetFinishReload(CurTime() + duration)
    -- self:SetNextIdle(CurTime() + duration)
-- end