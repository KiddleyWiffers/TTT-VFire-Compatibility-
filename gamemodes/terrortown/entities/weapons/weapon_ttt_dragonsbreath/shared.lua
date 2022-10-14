SWEP.Spawnable             = true
SWEP.AdminSpawnable        = true
SWEP.Base				   = "weapon_tttbase"
SWEP.UseHands			   = true

SWEP.BounceWeaponIcon  = false
SWEP.ShowHelp = false

if CLIENT then

    SWEP.HoldType = "shotgun"
    SWEP.PrintName = "Dragon Breath"            
	
	SWEP.Category  = "vFire Weapons"
	SWEP.ViewModelFOV = 60
	SWEP.ViewModelFlip = false
	SWEP.Slot = 2
    SWEP.SlotPos = 0
	SWEP.ViewModel = "models/weapons/c_shotgun.mdl"
	SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
	SWEP.ShowViewModel = true
	SWEP.ShowWorldModel = true
	SWEP.ViewModelBoneMods = {}

    SWEP.DrawAmmo            = true
    SWEP.DrawCrosshair        = true
    SWEP.CSMuzzleFlashes    = true

end
SWEP.Kind = WEAPON_HEAVY
SWEP.AmmoEnt = "item_box_buckshot_ttt"

SWEP.NoSights = true
SWEP.AutoSpawnable = true

SWEP.Purpose = "Kill a target and barbeque it at the same time."
SWEP.ViewModel            = "models/weapons/c_shotgun.mdl"
SWEP.WorldModel            = "models/weapons/w_shotgun.mdl"

SWEP.Primary.Sound             = Sound("weapons/shotgun/shotgun_fire7.wav")
SWEP.Primary.Damage            = 3
SWEP.Primary.Force             = 0
SWEP.Primary.NumShots          = 5
SWEP.Primary.Delay             = 1
SWEP.Primary.Ammo              = "buckshot"
SWEP.Primary.Spread 		   = .1

if game.SinglePlayer() then
	SWEP.RoundsPerShot = 4
else
	SWEP.RoundsPerShot = 3
end


SWEP.Primary.ClipSize        = 4
SWEP.Primary.DefaultClip    = 4
SWEP.Primary.Automatic        = false

SWEP.Secondary.Sound        = Sound("weapons/shotgun/shotgun_dbl_fire7.wav")
SWEP.Secondary.NumShots          = 10
SWEP.Secondary.Damage            = 3
SWEP.Secondary.Spread 		   = .05
SWEP.Secondary.Delay             = 1
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "buckshot"

SWEP.IronSightsPos   = Vector(-6.881, -9.214, 2.66)
SWEP.IronSightsAng   = Vector(-0.101, -0.7, -0.201)

SWEP.LastPrimaryAttack = 0

function SWEP:Initialize()
	self:SetWeaponHoldType( "shotgun" )
end

if SERVER then
	util.AddNetworkString("DragonBreathCustomEffect")
end

if CLIENT then
	net.Receive("DragonBreathCustomEffect", function()
		local aimVec = net.ReadVector()
		local aimPos = net.ReadVector()
		local canLOD = true
		local count = math.random(5, 7)
		for i = 1, count do
			local life = 5
			local vel = aimVec * math.Rand(500, 4000) + VectorRand() * 50
			local lifeTime = math.Rand(1, 4)
			CreateCSVFireBall(life, aimPos, vel, lifeTime, canLOD)
		end


		local life = 20
		local vel = aimVec * 1500
		local lifeTime = 0.7
		CreateCSVFireBall(life, aimPos, vel, lifeTime, canLOD)
	end)
end

if SERVER then

	local shotBalls = {}
	hook.Add("vFireBallStuckFire", "vFireDragonBreathImpact", function(ball, ent)
		if !IsValid(ball) then return end
		
		local ballID = shotBalls[ball]
		if ballID then
			local phys = ball:GetPhysicsObject()
			local owner = ball:GetOwner() or ent
			local pos = ball:GetPos()
			local vel = phys:GetVelocity()
			if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
				local physDamage = DamageInfo()
				physDamage:SetDamage(phys:GetEnergy() / 1500000)
				physDamage:SetInflictor(owner)
				physDamage:SetAttacker(owner)
				physDamage:SetDamageForce(vel)
				physDamage:SetDamagePosition(pos)
				physDamage:SetReportedPosition(pos)
				physDamage:SetDamageType(DMG_GENERIC)
				ent:TakeDamageInfo(physDamage)
			end

			if ballID == 1 then -- It's the first shot ball, make a fancy effect or some shit

				local ed = EffectData()
					ed:SetOrigin(pos)
					ed:SetNormal(vel)
					ed:SetMagnitude(4)
					ed:SetRadius(300)
					ed:SetScale(1)
				util.Effect("Sparks", ed)

			end

		end
	end)

	function SWEP:ShootFlames(count)

		if vFireInstalled then

			local aimVec = self.Owner:GetAimVector()
			local aimPos = self.Owner:GetShootPos()

			for i = 1, count do
				local life = 20
				local feedCarry = 0
				local vel = aimVec * math.Rand(3000, 4000) + VectorRand() * 70
				local ball = CreateVFireBall(life, feedCarry, aimPos, vel, self.Owner)

				ball:SetStickProbability(1)

				ball:GetPhysicsObject():SetMass(7)

				shotBalls[ball] = i -- Remember the ball 'ID' while we're at it...

				util.SpriteTrail(
					ball,
					0,
					Color(255, math.random(40, 200), 0),
					true,
					math.Rand(25, 85),
					0,
					math.Rand(0.135, 0.4),
					1,
					"trails/laser"
				)

			end

			sound.Play(
				"weapons/shotgun/shotgun_fire" .. math.random(6, 7) .. ".wav",		-- Sound
				aimPos,								-- Position
				90,									-- Level
				math.Rand(20, 50),					-- Pitch
				1									-- Volume
			)

			sound.Play(
				"physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav",				-- Sound
				aimPos,								-- Position
				90,									-- Level
				math.Rand(220, 255),				-- Pitch
				1									-- Volume
			)

			local ed = EffectData()
				ed:SetOrigin(aimPos + aimVec * 20)
				ed:SetNormal(aimVec)
			util.Effect("ManhackSparks", ed)

			if SERVER then
				if player.GetCount() > 0 then
					net.Start("DragonBreathCustomEffect", true)
						net.WriteVector(aimVec)
						net.WriteVector(aimPos)
					net.SendPVS(aimPos)
				end
			end

		end

	end

end

function SWEP:PrimaryAttack()
	if ( !self:CanPrimaryAttack() ) then return end
	
	if self.Owner.ViewPunch then
		self.Owner:ViewPunch(Angle( -0.3, -0.3, 0 ))
	end
	
	self:ShootEffects()
	
	self:TakePrimaryAmmo(1)
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	if CLIENT then return end
	self:ShootFlames(self.RoundsPerShot)

end
function SWEP:SecondaryAttack()
	if self.NoSights or (not self.IronSightsPos) or self:GetReloading() then return end

	self:SetIronsights(not self:GetIronsights()) 

	self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Reload()
	if !IsValid(self) or !IsValid(self.Weapon) then return end
	if self.Owner:IsPlayer() then
		if self:Clip1() >= self.Primary.ClipSize or self:Ammo1() <= 0 then return end
	end
	if self.Owner:IsNPC() then
		self:SetClip1(self.Primary.ClipSize)
	end

	self:DefaultReload(ACT_VM_RELOAD)
	self.Weapon:EmitSound("Weapon_Shotgun.Reload")
	timer.Create("idlesrrel" .. self:EntIndex(), self:SequenceDuration(), 2, function()
		if !IsValid(self) or !IsValid(self.Weapon) then return end
		self.Weapon:EmitSound("weapons/shotgun/shotgun_cock.wav")
		if not self.Weapon or not self.Owner then return end		
		self.Weapon:SendWeaponAnim(ACT_SHOTGUN_PUMP)
	end)

	self.Weapon:SetNextPrimaryFire( CurTime() + 1.5 )
	self.Weapon:SetNextSecondaryFire( CurTime() + 1.5 )

	return true
end