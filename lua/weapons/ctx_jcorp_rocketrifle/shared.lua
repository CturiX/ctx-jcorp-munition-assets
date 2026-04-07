AddCSLuaFile()

DEFINE_BASECLASS("simple_base_scoped")

SWEP.Base = "simple_base_scoped"

SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.PrintName = "Rocket Rifle"
SWEP.Category = "JSMC Dedicated Equipments Division"

SWEP.JCMS_COSTOVERRIDE = 500*4

SWEP.Slot = 3

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 54

SWEP.ViewModel = Model("models/weapons/cstrike/c_shot_m3super90.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg_ump45.mdl")

SWEP.HoldType = "ar2"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = -1

SWEP.ScopeZoom = 1.3
SWEP.ScopeSound = "Simple_Weapons.CombineScope"

SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = true

SWEP.Primary = {
	Ammo = "Buckshot",

	ClipSize = 16,
	DefaultClip = 48,

	RangeModifier = 1,
	Damage = 80,
	Delay = 60 / 70,
	Accuracy = 9,
	Range = 225,
	Count = 5,

	Recoil = {
		MinAng = Angle(-0.1, -0.5, 0),
		MaxAng = Angle(0.7, 0.5, 0),
		Punch = 1.5,
		Ratio = 0.2
	},
	Sound = "Simple_Weapons_JCORP_Shotgun.Fire",
	
	
	TracerName = "Tracer"
	-- TracerName = "AirboatGunTracer"
	-- TracerName = "LaserTracer"
}

SWEP.ViewOffset = Vector(-1, 3, 0)

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
	self:NetworkVar("Bool", "Zoomed")
end

function SWEP:Deploy()
	BaseClass.Deploy(self)

	-- self:SetZoomed(false)

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

function SWEP:OnRemove()
end

function SWEP:Think()
	BaseClass.Think(self)

    if not self:IsValid() or self:GetOwner():GetActiveWeapon() ~= self then
        return
    end

	local owner = self:GetOwner()

    local owner = self:GetOwner()
    if not IsValid(owner) then return end 


end


function SWEP:DoImpactEffect(tr, dmgtype)
	-- self:DoAR2Impact(tr)
end


function SWEP:SecondaryAttack()
	-- Enable zoom when secondary attack is held
	if CLIENT or not IsFirstTimePredicted() then return end

	-- self:SetZoomed(true)
end


function SWEP:AltFire()
	-- self:CycleScope()
end

function SWEP:Holster()
    -- self:SetIsFiring(false)

    return BaseClass.Holster(self)
end


sound.Add({
	name = 			"Simple_Weapons_JCORP_RocketRifle.Rocket",
	channel = 		CHAN_STATIC,
	volume = 		0.5,
	pitch = 		140,
	level = 		130,
	sound = 				{
		"weapons/ctx_jcorp_rockets/rocket1.wav",
		"weapons/ctx_jcorp_rockets/rocket2.wav",
		"weapons/ctx_jcorp_rockets/rocket3.wav",
	}
})

sound.Add({
	name = 			"Simple_Weapons_JCORP_RocketRifle.Fire",
	channel = 		CHAN_AUTO,
	volume = 		0.6,
	pitch = 		90,
	level = 		130,
	sound = 				{
		"weapons/ctx_jcorp_rockets/fire_rifle1.wav",
	}
})

sound.Add({
	name = 			"Simple_Weapons_JCORP_RocketRifle.Explode",
	channel = 		CHAN_STATIC,
	volume = 		1.0,
	pitch = 		160,
	level = 		95,
	sound = 				{
		"CTX_Weps/explosions/new/rev-indoor1.wav",
		"CTX_Weps/explosions/new/rev-indoor2.wav",
		"CTX_Weps/explosions/new/rev-indoor3.wav",
		"CTX_Weps/explosions/new/rev-indoor4.wav",
		"CTX_Weps/explosions/new/rev-indoor5.wav",
		"CTX_Weps/explosions/new/rev-indoor6.wav",
	}
})

sound.Add({
	name = 			"Simple_Weapons_JCORP_RocketRifle.LFO",
	channel = 		CHAN_STATIC,
	volume = 		1.0,
	pitch = 		100,
	level = 		250,
	sound = 				{
		"#CTX_Weps/explosions/new/LFE1.wav",
		"#CTX_Weps/explosions/new/LFE2.wav",
		"#CTX_Weps/explosions/new/LFE3.wav",
		"#CTX_Weps/explosions/new/LFE4.wav",
	}
})


function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    self:SetNextPrimaryFire(CurTime() + 0.8)
    self:EmitSound("Simple_Weapons_JCORP_RocketRifle.Fire")
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:TakePrimaryAmmo(4)

    if SERVER then
        local owner = self:GetOwner()
        local aimVec = owner:GetAimVector()
        local srcPos = owner:GetShootPos() + aimVec * 30 + owner:GetRight() * 2 + owner:GetUp() * -3


        local rocket = ents.Create("ent_torguelike")
        if not IsValid(rocket) then return end

        rocket:SetPos(srcPos)
        rocket:SetAngles(aimVec:Angle())
        rocket:SetOwner(owner)
        rocket:Spawn()
    end
end