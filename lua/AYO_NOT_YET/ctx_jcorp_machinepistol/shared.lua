AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Machine Pistol"
SWEP.Category = "JSMC Dedicated Equipments Division"

SWEP.JCMS_COSTOVERRIDE = 225*4

SWEP.Slot = 1

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 54

SWEP.ViewModel = Model("models/weapons/cstrike/c_pist_glock18.mdl")
SWEP.WorldModel = Model("models/weapons/cstrike/w_smg_ump45.mdl")

SWEP.HoldType = "smg"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = true

SWEP.Primary = {
	Ammo = "smg1",

	ClipSize = 25,
	DefaultClip = 200,

	RangeModifier = 1,
	Damage = 17,
	Delay = 60 / 800,
	Accuracy = 9,
	Range = 90,

	Recoil = {
		MinAng = Angle(-0.1, -0.5, 0),
		MaxAng = Angle(0.7, 0.5, 0),
		Punch = 1.5,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_SMG.Loop",
	
	
	Reload = {
		Time = 1.7
	},
	
	
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

	self:NetworkVar("Bool", "IsFiring")
	self:NetworkVar("Bool", "Zoomed")
end

function SWEP:Deploy()
	BaseClass.Deploy(self)
	self:StopSound(self.Primary.Sound)

	self:SetIsFiring(false)
	-- self:SetZoomed(false)

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
			
			timer.Simple(0.035, function()
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
	level = 130,
	pitch = 130,
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop.wav"
	-- sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_aim.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.LoopAlt",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = 110,
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_aim.wav"
})

sound.Add({
	name = "Simple_Weapons_JCORP_SMG.LoopEnd",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = 80,
	sound = "weapons/ctx_jcorp_assaultrifle/fire_loop_end.wav"
})



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
    self:SetIsFiring(false)

    -- Delay stopping the sound very slightly
    timer.Simple(0.02, function()
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
        vm:SetPlaybackRate(1.5) -- 1.5x faster
    end

    local duration = self:GetReloadTime()

    self:SetFinishReload(CurTime() + duration)
    self:SetNextIdle(CurTime() + duration)
end