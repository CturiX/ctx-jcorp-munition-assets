AddCSLuaFile()


DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Pistol"
SWEP.Category = "J-Corp Munition Acquisitions"

-- SWEP.JCMS_COSTOVERRIDE = 225*4

SWEP.Slot = 1

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 50

SWEP.ViewModel = Model("models/weapons/jma/jma_pistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_pist_glock18.mdl")

SWEP.HoldType = "revolver"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Secondary.Automatic = true

SWEP.Primary = {
	Ammo = "pistol",

	ClipSize = 12,
	DefaultClip = 90,

	RangeModifier = 1,
	Damage = 20,
	Delay = 60 / 260,
	Accuracy = 4,
	Range = 350,

	Recoil = {
		MinAng = Angle(0.7, -0.3, 0),
		MaxAng = Angle(0.7, 0.3, 0),
		Punch = 0.9,
		Ratio = 0.2
	},
	-- Sound = "Simple_Weapons_JCORP_PISTOL.Fire",
	Sound = "Simple_Weapons_JCORP_PISTOL.Fire",
	
	
	Reload = {
		Time = 0.6
	},
	
	
	TracerName = "Tracer"
}

SWEP.ViewOffset = Vector(10, 0, 0)

-- ACT_VM_RECOIL support
local transitions = {
	-- [ACT_VM_PRIMARYATTACK] = ACT_VM_RECOIL1,
	-- [ACT_VM_RECOIL1] = ACT_VM_RECOIL2,
	-- [ACT_VM_RECOIL2] = ACT_VM_RECOIL3,
	-- [ACT_VM_RECOIL3] = ACT_VM_RECOIL3
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

	self:NetworkVar("Bool", "Zoomed")
end


sound.Add({
	name = "Simple_Weapons_JCORP_PISTOL.Fire",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 130,
	pitch = {100, 110},
	sound = 				{
		"^weapons/ctx_jcorp_pistol/fire1.wav",
		"^weapons/ctx_jcorp_pistol/fire2.wav",
		-- "^weapons/ctx_jcorp_pistol/fire3.wav",
	}
})


sound.Add({
	name = "Simple_Weapons_JCORP_PISTOL.Slide",
	channel = CHAN_ITEM,
	volume = {0.5, 1},
	level = 90,
	pitch = {120, 150},
	sound = 				{
		"weapons/ctx_jcorp_pistol/fire_slide.wav",
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_PISTOL.Magout",
	channel = CHAN_ITEM,
	volume = 1,
	level = 90,
	pitch = {100, 100},
	sound = 				{
		"weapons/ctx_jcorp_pistol/reload_sequence.wav",
	}
})

sound.Add({
	name = "Simple_Weapons_JCORP_PISTOL.Draw",
	channel = CHAN_WEAPON,
	volume = 1,
	level = 90,
	pitch = {100, 100},
	sound = 				{
		"weapons/ctx_jcorp_pistol/draw.wav",
	}
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
        vm:SetPlaybackRate(1.0) -- 1.5x faster
    end

    local duration = self:GetReloadTime()

    self:SetFinishReload(CurTime() + duration)
    self:SetNextIdle(CurTime() + duration)
end


function SWEP:PrimaryAttack()
	local ply = self:GetOwner()

	local owner = self:GetOwner()
	local cost = 1



	if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then
		return
	end

	self:PrimaryFire()
	-- owner:SetNWInt("jcms_cash", math.max(owner:GetNWInt("jcms_cash",0)-cost, 0))
end