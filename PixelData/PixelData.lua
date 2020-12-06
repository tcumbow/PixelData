local ADDON_NAME = "PixelData"
local ADDON_VERSION = "1.0"
local ADDON_AUTHOR = "Tom Cumbow"

local RawPlayerName = GetRawUnitName("player")
local Mounted = false
local Moving = false
local MajorSorcery = false
local MajorProphecy = false
local MinorSorcery = false
local MajorResolve = false
local MinorMending = false
local MeditationActive = false
local ImbueWeaponActive = false
local DamageShieldActive = false
local MajorGallop = false
local MajorExpedition = false
local Empower = false
local FamiliarActive = false
local FamiliarAOEActive = false
local TwilightActive = false
local CrystalWeaver = false
local CrystalFragmentsProc = false
local EnergyOverloadActive = false

local MagickaPercent = 1.00
local StaminaPercent = 1.00
local HealthPercent = 1.00
local Stamina = 0
local StaminaPrevious = 0
local Health = 0
local HealthPrevious = 0
local Ultimate = 0
local UltimatePercent = 0.01

local LowestGroupHealthPercentWithoutRegen = 1.00
local LowestGroupHealthPercentWithRegen = 1.00
local LowestGroupHealthPercent = 1.00


local InputReady = true
local InCombat = false
local InventoryFull = false
local Feared = false
local Stunned = false
local MustDodge = false
local MustInterrupt = false
local MustBreakFree = false
local MustBlock = false
local Sprinting = false
local Hidden = false
local Crouching = false
local CrouchWasAuto = false
local CurrentBar = 0
local OtherBar = 0

local LastStealSightTime = 0
local LastEnemySightTime = 0
local LastStationaryTime = 0

local CurrentPixel = 0
local PreviousPixel = 0

local TargetNotTaunted = false
local TargetIsNotPlayer = false
local TargetIsEnemy = false
local TargetIsBoss = false
local TargetNotSunFired = false
local TargetNotMajorBreach = false
local TargetMaxHealth = 0
local TargetHealth = 0
local TargetHealthPercent = 0
local TargetIsNotSoulTrap = false
local TargetIsNotDestructiveTouched = false
local TargetNotFury = false

local AvailableReticleInteraction = nil
local AvailableReticleTarget = nil

local PickpocketPrime = false

local FrontBar, BackBar = false, false
local InBossBattle = false
local ReelInFish = false

local BurstHeal = { }
local HealOverTime = { }
local Degeneration = { }
local Ritual = { }
local RemoteInterrupt = { }
local Taunt = { }
local SunFire = { }
local Focus = { }
local Meditation = { }
local ImbueWeapon = { }
local DamageShield = { }
local RapidManeuver = { }
local Accelerate = { }
local WeaknessToElements = { }
local SoulTrap = { }
local DestructiveTouch = { }
local ForceShock = { }
local Pokes = { }
local SolarBarrage = { }
local VolatileFamiliar = { }
local TwilightMatriarch = { } 
local Surge = { }
local BoundlessStorm = { }
local CrystalFragments = { }
local Fury = { }

local EnergyOverload = { }

local DoNothing = 0
-- 1 thru 5 are used for doing abilities 1 thru 5, based on the number assigned in UpdateAbilitySlotInfo()
local DoHeavyAttack = 6
local DoRollDodge = 7
local DoBreakFreeInterrupt = 8
local DoBlock = 9
local DoReelInFish = 10
local DoLightAttack = 11
local DoInteract = 12
local DoSprint = 13
local DoMountSprint = 14
local DoCrouch = 15
local DoFrontBar = 16
local DoBackBar = 17
local DoStartBlock = 18
local DoStopBlock = 19
local DoUltimate = 20


local function SetPixel(x)
	PDL:SetColor(0,0,(x/255))
	PreviousPixel = CurrentPixel
	CurrentPixel = x
	-- d(x)
end

local function DoAbility(ability)
	if ability[CurrentBar] then return ability[CurrentBar]
	elseif ability[OtherBar] then return (16+OtherBar)
	else d("Impossible situation in DoAbility function")
	end
end

local function UpdateLastSights()
	if TargetIsEnemy then LastEnemySightTime = GetGameTimeMilliseconds() end
	if AvailableReticleInteraction == "Steal" or AvailableReticleInteraction == "BlockedSteal" then LastStealSightTime = GetGameTimeMilliseconds() end
	if not IsPlayerMoving() then LastStationaryTime = GetGameTimeMilliseconds() end
end

local function BigLogicRoutine()
	-- Last-Minute Info Gathering
		UpdateLastSights()
		Moving = IsPlayerMoving()
		if not Moving then Sprinting = false end
		if (GetGameTimeMilliseconds() - LastEnemySightTime) > 3000 then EnemiesAround = false else EnemiesAround = true	end
	
	-- Mounted/Dead/InMenu
		if InputReady == false or IsUnitDead("player") then
			SetPixel(DoNothing)
		elseif AvailableReticleInteraction=="Mine" and AvailableReticleTarget=="Platinum Seam" then
			SetPixel(DoInteract)
		elseif RapidManeuver.Slotted and Mounted and not MajorGallop and StaminaPercent > 0.80 then
			SetPixel(DoAbility(RapidManeuver))
		elseif Mounted and Moving and not Sprinting then
			SetPixel(DoMountSprint)
		elseif Mounted then
			SetPixel(DoNothing)
	
	-- Combat: Healing
		elseif Stunned or Feared and StaminaPercent > 0.49 then
			SetPixel(DoBreakFreeInterrupt)
		elseif TwilightMatriarch.Slotted and not TwilightActive and (InCombat or EnemiesAround or LowestGroupHealthPercent < 0.90) then
			SetPixel(DoAbility(TwilightMatriarch))
		elseif BurstHeal.Slotted and LowestGroupHealthPercent < 0.40 then
			SetPixel(DoAbility(BurstHeal))
		elseif BurstHeal.Slotted and LowestGroupHealthPercent < 0.60 and MagickaPercent > 0.40 then
			SetPixel(DoAbility(BurstHeal))
		elseif HealOverTime.Slotted and LowestGroupHealthPercentWithoutRegen < 0.90 and InCombat then
			SetPixel(DoAbility(HealOverTime))
		elseif BurstHeal.Slotted and not HealOverTime.Slotted and LowestGroupHealthPercent < 0.80 and MagickaPercent > 0.50 then
			SetPixel(DoAbility(BurstHeal))
		elseif BurstHeal.Slotted and not HealOverTime.Slotted and LowestGroupHealthPercent < 0.90 and MagickaPercent > 0.60 then
			SetPixel(DoAbility(BurstHeal))
	
	-- Combat: High Priority (Procs, Interrupt, Dodge, Block)
		elseif RemoteInterrupt.Slotted and MustInterrupt and MagickaPercent > 0.49 then
			SetPixel(DoAbility(RemoteInterrupt))
		elseif Fury.Slotted and TargetNotFury and TargetHealthPercent < 0.50 and TargetHealthPercent > 0.20 and TargetIsEnemy and not TargetIsBoss then
			SetPixel(DoAbility(Fury))
		elseif MustInterrupt and StaminaPercent > 0.49 then
			SetPixel(DoBreakFreeInterrupt)
		-- elseif (not InCombat or StaminaPercent < 0.20) and IsBlockActive() then
		-- 	SetPixel(DoStopBlock)
		elseif Taunt.Slotted and TargetIsBoss and TargetNotTaunted and MagickaPercent > 0.30 and EnemiesAround and TargetIsNotPlayer and InCombat then
			SetPixel(DoAbility(Taunt))
		elseif MustBlock and StaminaPercent > 0.99 then
			SetPixel(DoBlock)
		elseif MustDodge and FrontBar and StaminaPercent > 0.99 then
			SetPixel(DoRollDodge)
		elseif ImbueWeaponActive == true and InCombat and EnemiesAround then
			SetPixel(DoLightAttack)
		elseif CrystalFragmentsProc and CrystalFragments.Slotted and MagickaPercent > 0.30 and EnemiesAround and InCombat then
			SetPixel(DoAbility(CrystalFragments))

	-- Combat: Medium Priority (Buffs, DoTs, Looting, Meditation)
		elseif EnergyOverload.Slotted and not EnergyOverloadActive and MagickaPercent < 0.40 and Ultimate > (EnergyOverload.Cost * 5) and InCombat then
			SetPixel(DoAbility(EnergyOverload))
		elseif Ritual.Slotted and not MinorMending and InCombat and MagickaPercent > 0.55 then
			SetPixel(DoAbility(Ritual))
		elseif Focus.Slotted and not MajorResolve and MagickaPercent > 0.50 and InCombat then
			SetPixel(DoAbility(Focus))
		elseif BoundlessStorm.Slotted and not MajorResolve and MagickaPercent > 0.50 and (InCombat or EnemiesAround) then
			SetPixel(DoAbility(BoundlessStorm))
		elseif (AvailableReticleInteraction=="Search" and not InventoryFull and AvailableReticleTarget~="Book Stack" and AvailableReticleTarget~="Bookshelf") then
			SetPixel(DoInteract)
		elseif VolatileFamiliar.Slotted and not FamiliarActive and MagickaPercent > 0.60 and (InCombat or EnemiesAround) then
			SetPixel(DoAbility(VolatileFamiliar))
		elseif VolatileFamiliar.Slotted and not FamiliarAOEActive and MagickaPercent > 0.60 and (InCombat or EnemiesAround) then
			SetPixel(DoAbility(VolatileFamiliar))
		elseif SoulTrap.Slotted and TargetIsNotSoulTrap and MagickaPercent > 0.50 and InCombat and TargetIsEnemy then
			SetPixel(DoAbility(SoulTrap))
		elseif SunFire.Slotted and TargetNotSunFired and MagickaPercent > 0.70 and InCombat and TargetIsEnemy then
			SetPixel(DoAbility(SunFire))
		elseif DestructiveTouch.Slotted and TargetIsNotDestructiveTouched and MagickaPercent > 0.70 and InCombat and TargetIsEnemy then
			SetPixel(DoAbility(DestructiveTouch))
		elseif Surge.Slotted and not MajorSorcery and MagickaPercent > 0.60 and (InCombat or EnemiesAround) then
			SetPixel(DoAbility(Surge))
		elseif Degeneration.Slotted and not MajorSorcery and MagickaPercent > 0.60 and InCombat and EnemiesAround then
			SetPixel(DoAbility(Degeneration))
		elseif WeaknessToElements.Slotted and TargetNotMajorBreach and TargetMaxHealth > 40000 and TargetIsEnemy and MagickaPercent > 0.60 then
			SetPixel(DoAbility(WeaknessToElements))
		elseif SunFire.Slotted and (MajorProphecy == false or MinorSorcery == false) and MagickaPercent > 0.60 and EnemiesAround and InCombat then
			SetPixel(DoAbility(SunFire))
		elseif DamageShield.Slotted and InCombat == true and DamageShieldActive == false and MagickaPercent > 0.50 then
			SetPixel(DoAbility(DamageShield))
		elseif MeditationActive and InCombat and (MagickaPercent < 0.98 or StaminaPercent < 0.98) then
			SetPixel(DoNothing)
		elseif Meditation.Slotted and (MagickaPercent < 0.80 or StaminaPercent < 0.80) and MeditationActive == false and InCombat then
			SetPixel(DoAbility(Meditation))

		elseif EnergyOverloadActive and MagickaPercent > 0.70 and UltimatePercent < 0.70 then
			SetPixel(DoAbility(EnergyOverload))
	-- Combat: Low Priority (Damage Spamming)
		-- elseif SunFire.Slotted and MagickaPercent > 0.80 and InCombat and EnemiesAround then
		-- 	SetPixel(DoAbility(SunFire))
		elseif ForceShock.Slotted and MagickaPercent > 0.70 and InCombat and EnemiesAround then
			SetPixel(DoAbility(ForceShock))
		elseif ImbueWeapon.Slotted and EnemiesAround and InCombat == true and ImbueWeaponActive == false and MagickaPercent > 0.70 then
			SetPixel(DoAbility(ImbueWeapon))
		elseif CrystalFragments.Slotted and EnemiesAround and InCombat == true and MagickaPercent > 0.70 then
			SetPixel(DoAbility(CrystalFragments))
		elseif Pokes.Slotted and MagickaPercent > 0.70 and InCombat and EnemiesAround then
			SetPixel(DoAbility(Pokes))
		elseif SolarBarrage.Slotted and MagickaPercent > 0.70 and InCombat and not Empower and EnemiesAround then
			SetPixel(DoAbility(SolarBarrage))
		elseif EnergyOverload.Slotted and UltimatePercent > 0.97 and EnemiesAround and not EnergyOverloadActive then
			SetPixel(DoAbility(EnergyOverload))
		elseif EnergyOverloadActive and TargetIsEnemy and InCombat then
			SetPixel(DoLightAttack)
		elseif InCombat and EnemiesAround and not ImbueWeaponActive and MagickaPercent < 0.85 and not EnergyOverloadActive then
				SetPixel(DoHeavyAttack)
		elseif InCombat and EnemiesAround and not EnergyOverloadActive then
				SetPixel(DoLightAttack)
	-- elseif InCombat and StaminaPercent > 0.50 then
		-- 	SetPixel(DoStartBlock)

	-- Environment Interaction (Looting, Stealing, Sprinting)
		elseif ReelInFish and not InCombat then
			SetPixel(DoReelInFish)
			zo_callLater(PD_StopReelInFish, 2000)
		elseif (AvailableReticleInteraction=="Disarm" or AvailableReticleInteraction=="Cut" or AvailableReticleInteraction=="Mine" or AvailableReticleInteraction=="Collect" or AvailableReticleInteraction=="Loot" or (AvailableReticleInteraction=="Take" and not (AvailableReticleTarget=="Spoiled Food" or AvailableReticleTarget=="Greatsword" or AvailableReticleTarget=="Sword" or AvailableReticleTarget=="Axe" or AvailableReticleTarget=="Bow" or AvailableReticleTarget=="Shield" or AvailableReticleTarget=="Staff" or AvailableReticleTarget=="Sabatons" or AvailableReticleTarget=="Dagger" or AvailableReticleTarget=="Cuirass" or AvailableReticleTarget=="Pauldron" or AvailableReticleTarget=="Helm" or AvailableReticleTarget=="Gauntlets")) or (AvailableReticleInteraction=="Use" and (AvailableReticleTarget=="Chest" or AvailableReticleTarget=="Treasure Chest" or AvailableReticleTarget=="Giant Clam"))) then
			SetPixel(DoInteract)
		elseif (AvailableReticleInteraction=="Steal") and Hidden and not InCombat and not InventoryFull then
			SetPixel(DoInteract)
		elseif (AvailableReticleInteraction=="Steal") and not Crouching and not InCombat and not InventoryFull then
			SetPixel(DoCrouch)
			CrouchWasAuto = true
		elseif (GetGameTimeMilliseconds() - LastStealSightTime) > 3000 and CrouchWasAuto and Crouching and Moving then
			SetPixel(DoCrouch)
		elseif PickpocketPrime then
			SetPixel(DoInteract)
		-- elseif RapidManeuver.Slotted and not MajorExpedition and Moving and StaminaPercent > 0.90 then
		-- 	SetPixel(DoAbility(RapidManeuver))
		elseif Accelerate.Slotted and not MajorExpedition and MagickaPercent > 0.99 and Moving and not InCombat then
			SetPixel(DoAbility(Accelerate))
		elseif Moving and not Sprinting and not Crouching and StaminaPercent > 0.10 and (GetGameTimeMilliseconds() - LastStationaryTime) > 2000 then
			SetPixel(DoSprint)
	
	-- End of Logic
		else
			SetPixel(DoNothing)
		end

		if CurrentPixel ~= DoSprint and CurrentPixel ~= DoMountSprint and CurrentPixel ~= DoNothing then Sprinting = false end
end








local function UnitHasRegen(unitTag)
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		for i = 1, numBuffs do
			local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo(unitTag, i)
			if name=="Rapid Regeneration" or name=="Radiating Regeneration" then
				return true
			end
		end
	end
	return false
end

local function UpdateLowestGroupHealth()
	GroupSize = GetGroupSize()
	LowestGroupHealthPercentWithoutRegen = 1.00
	LowestGroupHealthPercentWithRegen = 1.00
	LowestGroupHealthPercent = 1.00

	if GroupSize > 0 then
		for i = 1, GroupSize do
			local unitTag = GetGroupUnitTagByIndex(i)
			local currentHp, maxHp, effectiveMaxHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
			local HpPercent = currentHp / maxHp
			local HasRegen = UnitHasRegen(unitTag)
			local InHealingRange = IsUnitInGroupSupportRange(unitTag)
			local IsAlive = not IsUnitDead(unitTag)
			local IsPlayer = GetUnitType(unitTag) == 1
			if HpPercent < LowestGroupHealthPercent and InHealingRange and IsAlive and IsPlayer then
				LowestGroupHealthPercent = HpPercent
			end
			if HpPercent < LowestGroupHealthPercentWithoutRegen and HasRegen == false and InHealingRange and IsAlive and IsPlayer then
				LowestGroupHealthPercentWithoutRegen = HpPercent
			elseif HpPercent < LowestGroupHealthPercentWithRegen and HasRegen and InHealingRange and IsAlive and IsPlayer then
				LowestGroupHealthPercentWithRegen = HpPercent
			end
		end
	else
		local unitTag = "player"
		local currentHp, maxHp, effectiveMaxHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
		local HpPercent = currentHp / maxHp
		LowestGroupHealthPercent = HpPercent
		local HasRegen = UnitHasRegen(unitTag)
		if HasRegen == false then
			LowestGroupHealthPercentWithoutRegen = HpPercent
		elseif HasRegen then
			LowestGroupHealthPercentWithRegen = HpPercent
		end
	end
end




local function UpdateTargetInfo()
	if (DoesUnitExist('reticleover') and not (IsUnitDead('reticleover'))) then -- have a target, scan for auras
		-- local unitName = zo_strformat("<<t:1>>",GetUnitName('reticleover'))

		if GetUnitType('reticleover') == 1 then
			TargetIsNotPlayer = false
		else
			TargetIsNotPlayer = true
		end

		if GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE then
			TargetIsEnemy = true
		else
			TargetIsEnemy = false
		end

		if GetUnitDifficulty("reticleover") >= 3 then
			TargetIsBoss = true
			InBossBattle = true
		else
			TargetIsBoss = false
		end

		local currentHp, maxHp, _ = GetUnitPower('reticleover', POWERTYPE_HEALTH)
		TargetHealth = currentHp
		TargetMaxHealth = maxHp
		TargetHealthPercent = currentHp/maxHp

		local numAuras = GetNumBuffs('reticleover')

		TargetNotSunFired = true
		TargetNotTaunted = true
		TargetNotMajorBreach = true
		TargetIsNotSoulTrap = true
		TargetIsNotDestructiveTouched = true
		TargetNotFury = true
		if (numAuras > 0) then
			for i = 1, numAuras do
				local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo('reticleover', i)
				if name=="Taunt" then
					TargetNotTaunted = false
				elseif name=="Vampire's Bane" or name=="Reflective Light" or name=="Sun Fire" then
					TargetNotSunFired = false
				elseif name=="Major Breach" then
					TargetNotMajorBreach = false
				elseif name=="Endless Fury" then
					TargetNotFury = false
				elseif name=="Soul Trap" or name=="Soul Splitting Trap" or name=="Consuming Trap" then
					TargetIsNotSoulTrap = false
				elseif name == "Destructive Touch" or name == "Shock Touch" or name == "Destructive Reach" or name == "Shock Reach" then
					TargetIsNotDestructiveTouched = false
				end
			end
		end
	else
		TargetNotTaunted = false
		TargetIsEnemy = false
		TargetIsNotPlayer = false
		TargetNotSunFired = false
		TargetIsBoss = false
		TargetNotMajorBreach = false
		TargetNotFury = false
		TargetIsNotSoulTrap = false
		TargetIsNotDestructiveTouched = false
	end
end





local function UpdateAbilitySlotInfo()

	BurstHeal = { }
	HealOverTime = { }
	Degeneration = { }
	Ritual = { }
	RemoteInterrupt = { }
	Taunt = { }
	SunFire = { }
	Focus = { }
	Meditation = { }
	ImbueWeapon = { }
	DamageShield = { }
	RapidManeuver = { }
	Accelerate = { }
	WeaknessToElements = { }
	SoulTrap = { }
	DestructiveTouch = { }
	ForceShock = { }
	Pokes = { }
	SolarBarrage = { }
	VolatileFamiliar = { }
	TwilightMatriarch = { } 
	Surge = { }
	BoundlessStorm = { }
	CrystalFragments = { }
	Fury = { }

	EnergyOverload = { }

	for barNumIterator = 0, 1 do
		for i = 3, 7 do
			local AbilityName = GetAbilityName(GetSlotBoundId(i,barNumIterator))
			if AbilityName == "Ritual of Rebirth" or AbilityName == "Twilight Matriarch Restore" then
				BurstHeal.Slotted = true
				BurstHeal[barNumIterator] = i-2
			elseif AbilityName == "Rapid Regeneration" or AbilityName == "Radiating Regeneration" then
				HealOverTime.Slotted = true
				HealOverTime[barNumIterator] = i-2
			elseif AbilityName == "Inner Rage" then
				Taunt.Slotted = true
				Taunt[barNumIterator] = i-2
			elseif AbilityName == "Deep Thoughts" then
				Meditation.Slotted = true
				Meditation[barNumIterator] = i-2
			elseif AbilityName == "Elemental Weapon" then
				ImbueWeapon.Slotted = true
				ImbueWeapon[barNumIterator] = i-2
			elseif AbilityName == "Channeled Focus" or AbilityName == "Restoring Focus" then
				Focus.Slotted = true
				Focus[barNumIterator] = i-2
			elseif AbilityName == "Extended Ritual" then
				Ritual.Slotted = true
				Ritual[barNumIterator] = i-2
			elseif AbilityName == "Degeneration" then
				Degeneration.Slotted = true
				Degeneration[barNumIterator] = i-2
			elseif AbilityName == "Vampire's Bane" or AbilityName == "Reflective Light" then
				SunFire.Slotted = true
				SunFire[barNumIterator] = i-2
			elseif AbilityName == "Radiant Ward" or AbilityName == "Blazing Shield" then
				DamageShield.Slotted = true
				DamageShield[barNumIterator] = i-2
			elseif AbilityName == "Explosive Charge" then
				RemoteInterrupt.Slotted = true
				RemoteInterrupt[barNumIterator] = i-2
			elseif AbilityName == "Rapid Maneuver" or AbilityName == "Charging Maneuver" then
				RapidManeuver.Slotted = true
				RapidManeuver[barNumIterator] = i-2
			elseif AbilityName == "Accelerate" or AbilityName == "Race Against Time" then
				Accelerate.Slotted = true
				Accelerate[barNumIterator] = i-2
			elseif AbilityName == "Elemental Susceptibility" or AbilityName == "Weakness to Elements" then
				WeaknessToElements.Slotted = true
				WeaknessToElements[barNumIterator] = i-2
			elseif AbilityName == "Soul Trap" or AbilityName == "Soul Splitting Trap" or AbilityName == "Consuming Trap" then
				SoulTrap.Slotted = true
				SoulTrap[barNumIterator] = i-2
			elseif AbilityName == "Destructive Touch" or AbilityName == "Shock Touch" or AbilityName == "Destructive Reach" or AbilityName == "Shock Reach" then
				DestructiveTouch.Slotted = true
				DestructiveTouch[barNumIterator] = i-2
			elseif AbilityName == "Force Shock" or AbilityName == "Force Pulse" or AbilityName == "Crushing Shock" then
				ForceShock.Slotted = true
				ForceShock[barNumIterator] = i-2
			elseif AbilityName == "Puncturing Sweep" then
				Pokes.Slotted = true
				Pokes[barNumIterator] = i-2
			elseif AbilityName == "Solar Barrage" then
				SolarBarrage.Slotted = true
				SolarBarrage[barNumIterator] = i-2
			elseif AbilityName == "Summon Volatile Familiar" then
				VolatileFamiliar.Slotted = true
				VolatileFamiliar[barNumIterator] = i-2
			elseif AbilityName == "Summon Twilight Matriarch" then
				TwilightMatriarch.Slotted = true
				TwilightMatriarch[barNumIterator] = i-2
			elseif AbilityName == "Boundless Storm" then
				BoundlessStorm.Slotted = true
				BoundlessStorm[barNumIterator] = i-2
			elseif AbilityName == "Crystal Fragments" then
				CrystalFragments.Slotted = true
				CrystalFragments[barNumIterator] = i-2
			elseif AbilityName == "Endless Fury" then
				Fury.Slotted = true
				Fury[barNumIterator] = i-2
			elseif AbilityName == "Surge" or AbilityName == "Power Surge" or AbilityName == "Critical Surge" then
				Surge.Slotted = true
				Surge[barNumIterator] = i-2
			elseif AbilityName == "Bound Aegis" or AbilityName == "Inner Light" or AbilityName == "Radiant Aura" or AbilityName == "Blockade of Storms" or AbilityName == "" then -- do nothing, cuz we don't care about these abilities
			else 
				d("Unrecognized ability:"..AbilityName)
			end
		end
		local AbilityId = GetSlotBoundId(8,barNumIterator)
		local UltimateName = GetAbilityName(AbilityId)
		if UltimateName == "Energy Overload" then
			EnergyOverload.Slotted = true
			EnergyOverload[barNumIterator] = DoUltimate
			EnergyOverload.Cost = GetAbilityCost(AbilityId)
		end
	end
end




local function UpdatePickpocketState()
	local isInBonus, isHostile, percentChance, _, isEmpty, prospectiveResult, _, _ = GetGameCameraPickpocketingBonusInfo()
	local cantInteract 	= isHostile or empty or not prospectiveResult == PROSPECTIVE_PICKPOCKET_RESULT_CAN_ATTEMPT 
	PickpocketPrime		= not cantInteract and percentChance == 100
end



local function UpdateBarState()
	local barNum = GetActiveWeaponPairInfo()
	if barNum == 1 then
		FrontBar = true
		BackBar = false
		CurrentBar = 0 --translating to match the zero-based bar numbering used by the ability routine above
		OtherBar = 1
	elseif barNum == 2 then
		BackBar = true
		FrontBar = false
		CurrentBar = 1
		OtherBar = 0
	end
end



local function DismissTwilight()
	-- All the abilityIDs for Twilights
	local PetList = { 24613, 30581, 30584, 30587, 24636, 30592, 30595, 30598, 24639, 30618, 30622, 30626 }

	local i, k, v
	
	-- Walk through the player's active buffs
	for i = 1, GetNumBuffs("player") do
		local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)
		-- Compare each buff's abilityID to the list of IDs we were given
		for k, v in pairs(PetList) do
			if abilityId == v then
				-- Cancel the buff if we got a match
				CancelBuff(buffSlot)
			end
		end
	end
	
end


local function PeriodicUpdate()
	UpdateLastSights()

	if TwilightActive and not InCombat and LowestGroupHealthPercent > 0.90 and (GetGameTimeMilliseconds() - LastEnemySightTime) > 60000 then
		DismissTwilight()
	end

	if Moving ~= IsPlayerMoving() then
		BigLogicRoutine()
	end

	zo_callLater(PeriodicUpdate,250)
end

local function OccasionalUpdate()
	if GetNumBagUsedSlots(BAG_BACKPACK) == GetBagSize(BAG_BACKPACK) then
		InventoryFull = true
	else
		InventoryFull = false
	end		

	zo_callLater(PeriodicUpdate,5000)
end



local function InitialInfoGathering()
	InCombat = IsUnitInCombat("player")
	Mounted = IsMounted()
	UpdateBarState()
	UpdateAbilitySlotInfo()
	PeriodicUpdate()
	OccasionalUpdate()
end





local function UpdateBuffs()
	MajorSorcery = false
	MajorProphecy = false
	MinorSorcery = false
	MajorResolve = false
	MinorMending = false
	MeditationActive = false
	ImbueWeaponActive = false
	DamageShieldActive = false
	MajorGallop = false
	MajorExpedition = false
	Empower = false
	FamiliarActive = false
	FamiliarAOEActive = false
	TwilightActive = false
	CrystalWeaver = false
	CrystalFragmentsProc = false
	EnergyOverloadActive = false
	-- MustBreakFree = false
	local numBuffs = GetNumBuffs("player")
	if numBuffs > 0 then
		local optimalBuffOverlap = 200 -- constant
		local msUntilBuffRecheckNeeded = 999999 -- if this value isn't replaced, then a buff recheck won't be scheduled
		for i = 1, numBuffs do
			local name, _, endTime, _, _, _, _, _, _, _, id, _ = GetUnitBuffInfo("player", i)
			local now = GetGameTimeMilliseconds()
			local timeLeft = (math.floor(endTime * 1000)) - now
			if name=="Major Sorcery" then
				MajorSorcery = true
			elseif name=="Major Prophecy" then
				MajorProphecy = true
			elseif name=="Minor Sorcery" then
				MinorSorcery = true
			elseif name=="Major Resolve" and timeLeft>optimalBuffOverlap then
				MajorResolve = true
				if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			elseif name=="Minor Mending" then
				MinorMending = true
			elseif name=="Deep Thoughts" then
				MeditationActive = true
			elseif name=="Elemental Weapon" and (timeLeft + 100) > optimalBuffOverlap then
				ImbueWeaponActive = true
				if timeLeft + 100 < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft + 100 end
			elseif name=="Blazing Shield" or name=="Radiant Ward" then
				DamageShieldActive = true
			elseif name=="Summon Volatile Familiar" and id==23316 then
				FamiliarActive = true
			elseif name=="Summon Volatile Familiar" and id==88933 then
				FamiliarAOEActive = true
			elseif name=="Summon Twilight Matriarch" then
				TwilightActive = true
			elseif name=="Crystal Weaver" then
				CrystalWeaver = true
			elseif name=="Crystal Fragments Proc" then
				CrystalFragmentsProc = true
			elseif name=="Energy Overload" then
				EnergyOverloadActive = true
			elseif name=="Dampen Magic" then
				DamageShieldActive = true
			elseif name=="Empower" then
				Empower = true
			elseif name=="Major Expedition" and timeLeft>optimalBuffOverlap then
				MajorExpedition = true
				if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			elseif name=="Major Gallop" and timeLeft>optimalBuffOverlap then
				MajorGallop = true
				if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			-- elseif name=="Rending Leap Ranged" or name=="Uppercut" or name=="Skeletal Smash" or name=="Stunning Shock" or name=="Discharge" or name=="Constricting Strike" or name=="Stun" then
			-- 	MustBreakFree = true


			-- elseif name=="Increased Experience" or name=="ESO Plus Member" or name=="Bound Aegis" or name=="Minor Resolve" or name=="Minor Slayer" or name=="Inner Light" or name=="Boon: The Steed" or name=="Critical Surge" or name=="Major Brutality" or name=="Minor Prophecy" or name=="Boundless Storm" then
			-- else
			-- 	d(name)
			end
		end
		if msUntilBuffRecheckNeeded < 999999 then
			zo_callLater(UpdateBuffs, msUntilBuffRecheckNeeded-optimalBuffOverlap)
		end
	end
	BigLogicRoutine()
end





local function OnEventMountedStateChanged(eventCode,mounted)
	Mounted = mounted
	Sprinting = false
	BigLogicRoutine()
end

local function OnEventInteractableTargetChanged()
	UpdateLastSights()
	local action, interactableName, blocked, mystery2, additionalInfo = GetGameCameraInteractableActionInfo()
	-- d(action)
	-- d(interactableName)
	-- d(blocked)
	-- d(mystery2)
	-- d(additionalInfo)
	if action == "Steal From" then action = "Steal" end
	if blocked or additionalInfo == 2 then
		if action == "Steal" then
			action = "BlockedSteal"
		else
			action = nil
		end
		interactableName = nil
	end
	if action == "Pickpocket" then UpdatePickpocketState() else PickpocketPrime = false end
	if AvailableReticleInteraction ~= action or AvailableReticleTarget ~= interactableName then
		AvailableReticleInteraction = action
		AvailableReticleTarget = interactableName
		BigLogicRoutine()
	end
	
end



local function OnEventEffectChanged(e, change, slot, auraName, unitTag, start, finish, stack, icon, buffType, effectType, abilityType, statusType, unitName, unitId, abilityId, sourceType)
	UpdateLowestGroupHealth()
	UpdateTargetInfo()
	if unitTag=="player" then
		UpdateBuffs()
	else
		BigLogicRoutine()
	end
end

local function OnEventPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	if unitTag=="player" and powerType==POWERTYPE_STAMINA then
		StaminaPrevious = Stamina
		Stamina = powerValue
		StaminaPercent = powerValue / powerMax
		if (powerValue == powerMax or Stamina > StaminaPrevious) and not Mounted then Sprinting = false
		elseif CurrentPixel == DoSprint and Stamina < StaminaPrevious and not Mounted then Sprinting = true end
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_MOUNT_STAMINA and powerValue==powerMax and Mounted then
		Sprinting = false
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_MOUNT_STAMINA and powerValue<(powerMax-3) and Mounted then
		Sprinting = true
		BigLogicRoutine()
	elseif powerType==POWERTYPE_HEALTH then
		if unitTag=="player" then
			HealthPrevious = Health
			Health = powerValue
			HealthPercent = powerValue / powerMax
		end
		UpdateLowestGroupHealth()
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_ULTIMATE then
		Ultimate = powerValue
		UltimatePercent = powerValue / powerMax
		BigLogicRoutine()
	end
end

local function OnEventGroupSupportRangeUpdate()
	UpdateLowestGroupHealth()
	BigLogicRoutine()
end

local function OnEventStealthChange(_,_,stealthState)
	if stealthState > 0 then
		Crouching = true
		if stealthState == 3 then
			Hidden = true
		else
			Hidden = false
		end
	else
		Crouching = false
		CrouchWasAuto = false
		Hidden = false
	end
	BigLogicRoutine()
end

local function OnEventCombatTipDisplay(_, tipId)
	if tipId == 2 then
		return
	elseif tipId == 4 or tipId == 19 then
		MustDodge = true
		BigLogicRoutine()
	elseif tipId == 3 then
		MustInterrupt = true
		BigLogicRoutine()
	elseif tipId == 1 then
		MustBlock = true
		BigLogicRoutine()
	elseif tipId == 18 then
	else
		local name, tipText, iconPath = GetActiveCombatTipInfo(tipId)
		d(name)
		d(tipText)
		d(tipId)
	end

end

local function OnEventCombatTipRemove()
	MustDodge = false
	MustInterrupt = false
	MustBlock = false
	Feared = false
	BigLogicRoutine()
end

local function OnEventCombatEvent(_,result,_,_,_,_,_,_,targetName)
	if targetName == RawPlayerName then 
		if result == ACTION_RESULT_FEARED then
			Feared = true
		end
	end
end

local function OnEventStunStateChanged(_,StunState)
	Stunned = StunState
	BigLogicRoutine()
end




local function OnEventReticleChanged()
	UpdateLastSights()
	UpdateTargetInfo()
	BigLogicRoutine()
end




local function OnEventBarSwap()
	UpdateBarState()
	UpdateAbilitySlotInfo()
	BigLogicRoutine()
end

local function OnEventAbilityChange()
	UpdateAbilitySlotInfo()
end





function PD_InputReady()
	InputReady = true
	UpdateAbilitySlotInfo()
	BigLogicRoutine()
end

function PD_InputNotReady()
	InputReady = false
	BigLogicRoutine()
end

function PD_NotInCombat()
	InCombat = false
	InBossBattle = false
	BigLogicRoutine()
end

function PD_InCombat()
	InCombat = true
	UpdateAbilitySlotInfo()
	BigLogicRoutine()
end

function PD_NotMounted()
	Mounted = false
	BigLogicRoutine()
end

function PD_Mounted()
	Mounted = true
	BigLogicRoutine()
end

function PD_MagickaPercent(x)
	MagickaPercent = x
	BigLogicRoutine()
end

function PD_ReelInFish()
	ReelInFish = true
	BigLogicRoutine()
end

function PD_StopReelInFish()
	ReelInFish = false
	BigLogicRoutine()
end







local function OnAddonLoaded(event, name)
	if name == ADDON_NAME then
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event)
		PixelDataWindow = WINDOW_MANAGER:CreateTopLevelWindow("PixelData")
		PixelDataWindow:SetDimensions(100,100)

		PDL = CreateControl(nil, PixelDataWindow,  CT_LINE)
		PDL:SetAnchor(TOPLEFT, PixelDataWindow, TOPLEFT, 0, 0)
		PDL:SetAnchor(TOPRIGHT, PixelDataWindow, TOPLEFT, 1, 1)
		SetPixel(DoNothing)

		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_MOUNTED_STATE_CHANGED, OnEventMountedStateChanged)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_EFFECT_CHANGED, OnEventEffectChanged)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_POWER_UPDATE, OnEventPowerUpdate)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_SUPPORT_RANGE_UPDATE, OnEventGroupSupportRangeUpdate)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_DISPLAY_ACTIVE_COMBAT_TIP, OnEventCombatTipDisplay)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_REMOVE_ACTIVE_COMBAT_TIP, OnEventCombatTipRemove)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_STUNNED_STATE_CHANGED, OnEventStunStateChanged)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, OnEventCombatEvent)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_RETICLE_TARGET_CHANGED, OnEventReticleChanged)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_WEAPON_PAIR_LOCK_CHANGED, OnEventBarSwap)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTION_SLOT_UPDATED, OnEventBarSwap)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_STEALTH_STATE_CHANGED, OnEventStealthChange)
		-- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SKILL_BUILD_SELECTION_UPDATED, OnEventAbilityChange) -- Turns out this isn't the right event, I'm just going to update abilities when combat begins
		-- EVENT_MANAGER:AddFilterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
		ZO_PreHookHandler(RETICLE.interact, "OnEffectivelyShown", OnEventInteractableTargetChanged)
		ZO_PreHookHandler(RETICLE.interact, "OnHide", OnEventInteractableTargetChanged)
		
		zo_callLater(InitialInfoGathering, 1000)

		PixelDataLoaded = true -- global variable to indicate this add-on has been loaded, used to enable integrations in other add-ons

		
	end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
