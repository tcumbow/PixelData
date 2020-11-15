local ADDON_NAME = "PixelData"
local ADDON_VERSION = "1.0"
local ADDON_AUTHOR = "Tom Cumbow"

local Mounted = false
local MajorSorcery, MajorProphecy, MinorSorcery, MajorResolve, MinorMending, MeditationActive, ImbueWeaponActive, DamageShield = false, false, false, false, false, false, false, false
local InputReady = true
local InCombat = false
local InputReady = true
local HealingNeeded = false
local MagickaPercent = 1.00
local StaminaPercent = 1.00
local LowestGroupHealthPercentWithoutRegen = 1.00
local LowestGroupHealthPercentWithRegen = 1.00
local Feared = false
local Stunned = false
local MustDodge = false
local MustInterrupt = false
local MustBreakFree = false
local MustBlock = false

local TargetNotTaunted = false
local TargetMaxHealth = 0
local TargetIsNotPlayer = false
local TargetIsEnemy = false
local TargetIsBoss

local TargetNotVampBane = false
local FrontBar, BackBar = false, false
local InBossBattle = false
local ReelInFish = false

local BurstHealSlotted = false
local HealOverTimeSlotted = false
local DegenerationSlotted = false
local RitualSlotted = false
local RemoteInterruptSlotted = false
local TauntSlotted = false
local SunFireSlotted = false
local FocusSlotted = false
local MeditationSlotted = false
local ImbueWeaponSlotted = false




local RawPlayerName = GetRawUnitName("player")


local function PD_SetPixel(x)
	PDL:SetColor(0,0,(x/255))
end








local function UpdatePixel()
	if InputReady == false or Mounted == true or IsUnitDead("player") then
		PD_SetPixel(0)
		return
	end
	if Stunned or Feared and StaminaPercent > 0.49 then
		PD_SetPixel(8)
		return
	end
	if BurstHealSlotted and LowestGroupHealthPercentWithRegen < 0.40 then
		PD_SetPixel(BurstHealSlotted)
		return
	end
	if BurstHealSlotted and LowestGroupHealthPercentWithoutRegen < 0.40 then
		PD_SetPixel(BurstHealSlotted)
		return
	end
	if HealOverTimeSlotted and LowestGroupHealthPercentWithoutRegen < 0.90 then
		PD_SetPixel(HealOverTimeSlotted)
		return
	end
	if RemoteInterruptSlotted and MustInterrupt and MagickaPercent > 0.49 then
		PD_SetPixel(RemoteInterruptSlotted)
		return
	end
	if MustInterrupt and StaminaPercent > 0.49 then
		PD_SetPixel(8)
		return
	end
	if TauntSlotted and TargetIsBoss and TargetNotTaunted and MagickaPercent > 0.30 and TargetIsEnemy and TargetIsNotPlayer and InCombat then
		PD_SetPixel(TauntSlotted)
		return
	end
	if MustBlock and StaminaPercent > 0.99 then
		PD_SetPixel(9)
		return
	end
	if MustDodge and FrontBar and StaminaPercent > 0.99 then
		PD_SetPixel(7)
		return
	end
	if RitualSlotted and not MinorMending and InCombat and MagickaPercent > 0.55 then
		PD_SetPixel(RitualSlotted)
		return
	end
	if DegenerationSlotted and not MajorSorcery and MagickaPercent > 0.60 and InCombat and TargetIsEnemy then
		PD_SetPixel(4)
		return
	end
	if ImbueWeaponActive == true and InCombat and TargetIsEnemy then
		PD_SetPixel(6) -- todo, this needs to be a light attack, not a heavy attack
		return
	end
	if FocusSlotted and MajorResolve == false and MagickaPercent > 0.50 and InCombat then
		PD_SetPixel(FocusSlotted)
		return
	end
	if ImbueWeaponSlotted and InCombat == true and ImbueWeaponActive == false and MagickaPercent > 0.70 then
		PD_SetPixel(ImbueWeaponSlotted)
		return
	end
	if DamageShieldSlotted and InCombat == true and DamageShield == false and MagickaPercent > 0.50 then
		PD_SetPixel(DamageShieldSlotted)
		return
	end
	if SunFireSlotted and (MajorProphecy == false or MinorSorcery == false) and MagickaPercent > 0.60 and TargetIsEnemy and InCombat then
		PD_SetPixel(SunFireSlotted)
		return
	end
	if InCombat and (MagickaPercent < 0.98 or StaminaPercent < 0.98) and MeditationActive == true then
		PD_SetPixel(0)
		return
	end
	if MeditationSlotted and (MagickaPercent < 0.93 or StaminaPercent < 0.93) and MeditationActive == false and InCombat then
		PD_SetPixel(4)
		return
	end
	if InCombat == true then
		PD_SetPixel(6)
		return
	end
	if ReelInFish and not InCombat then
		PD_SetPixel(10)
		zo_callLater(PD_StopReelInFish, 2000)
		return
	end
	PD_SetPixel(0)
end








local function UnitHasRegen(unitTag)
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		for i = 1, numBuffs do
			local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo(unitTag, i)
			if name=="Rapid Regeneration" then
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

	if GroupSize > 0 then
		for i = 1, GroupSize do
			local unitTag = GetGroupUnitTagByIndex(i)
			local currentHp, maxHp, effectiveMaxHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
			local HpPercent = currentHp / maxHp
			local HasRegen = UnitHasRegen(unitTag)
			local InHealingRange = IsUnitInGroupSupportRange(unitTag)
			local IsAlive = not IsUnitDead(unitTag)
			local IsPlayer = GetUnitType(unitTag) == 1
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

		if GetUnitReaction('reticleover') == 1 then
			TargetIsEnemy = true
		else
			TargetIsEnemy = false
		end

		if GetUnitDifficulty("reticleover") == MONSTER_DIFFICULTY_DEADLY then
			TargetIsBoss = true
			InBossBattle = true
		else
			TargetIsBoss = false
		end

		local _, maxHp, _ = GetUnitPower('reticleover', POWERTYPE_HEALTH)
		TargetMaxHealth = maxHp
		
		numAuras = GetNumBuffs('reticleover')

		TargetNotVampBane = true
		TargetNotTaunted = true
		if (numAuras > 0) then
			for i = 1, numAuras do
				local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo('reticleover', i)
				if name=="Taunt" then
					TargetNotTaunted = false
				end
				if name=="Vampire's Bane" then
					TargetNotVampBane = false
				end
			end
		end
	else
		TargetNotTaunted = false
		TargetIsEnemy = false
		TargetIsNotPlayer = false
		TargetNotVampBane = false
		TargetIsBoss = false
	end
end





local function UpdateAbilitySlotInfo()

	d("Updating abilities")

	BurstHealSlotted = false
	HealOverTimeSlotted = false
	DegenerationSlotted = false
	RitualSlotted = false
	RemoteInterruptSlotted = false
	TauntSlotted = false
	SunFireSlotted = false
	FocusSlotted = false
	MeditationSlotted = false
	ImbueWeaponSlotted = false
	DamageShieldSlotted = false

	for i = 3, 7 do
		local AbilityName = GetAbilityName(GetSlotBoundId(i))
		if AbilityName == "Ritual of Rebirth" then
			BurstHealSlotted = i-2
		elseif AbilityName == "Rapid Regeneration" then
			HealOverTimeSlotted = i-2
		elseif AbilityName == "Inner Rage" then
			TauntSlotted = i-2
		elseif AbilityName == "Deep Thoughts" then
			MeditationSlotted = i-2
		elseif AbilityName == "Elemental Weapon" then
			ImbueWeaponSlotted = i-2
		elseif AbilityName == "Channeled Focus" then
			FocusSlotted = i-2
		elseif AbilityName == "Extended Ritual" then
			RitualSlotted = i-2
		elseif AbilityName == "Degeneration" then
			DegenerationSlotted = i-2
		elseif AbilityName == "Vampire's Bane" then
			SunFireSlotted = i-2
		elseif AbilityName == "Radiant Ward" or AbilityName == "Blazing Shield" then
			DamageShieldSlotted = i-2
		elseif AbilityName == "Inner Light" or AbilityName == "Radiant Aura" or AbilityName == "Puncturing Sweep" then -- do nothing, cuz we don't care about these abilities
		else 
			d("Unrecognized ability:"..AbilityName)
		end
	end

end





local function UpdateBarState()
	local BarNum = GetActiveWeaponPairInfo()
	if BarNum == 1 then
		FrontBar = true
		BackBar = false
	elseif BarNum == 2 then
		BackBar = true
		FrontBar = false
	end
end



function InitialInfoGathering()
	InCombat = IsUnitInCombat("player")
	UpdateBarState()
	UpdateAbilitySlotInfo()

end





local function OnEventMountedStateChanged(eventCode,mounted)
	Mounted = mounted
	UpdatePixel()
end

local function OnEventEffectChanged(e, change, slot, auraName, unitTag, start, finish, stack, icon, buffType, effectType, abilityType, statusType, unitName, unitId, abilityId, sourceType)
	if unitTag=="player" then
		MajorSorcery, MajorProphecy, MinorSorcery, MajorResolve, MinorMending, MeditationActive, ImbueWeaponActive, DamageShield = false, false, false, false, false, false, false, false
		-- MustBreakFree = false
		local numBuffs = GetNumBuffs("player")
		if numBuffs > 0 then
			for i = 1, numBuffs do
				local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo("player", i)
				if name=="Major Sorcery" then
					MajorSorcery = true
				elseif name=="Major Prophecy" then
					MajorProphecy = true
				elseif name=="Minor Sorcery" then
					MinorSorcery = true
				elseif name=="Major Resolve" then
					MajorResolve = true
				elseif name=="Minor Mending" then
					MinorMending = true
				elseif name=="Deep Thoughts" then
					MeditationActive = true
				elseif name=="Elemental Weapon" then
					ImbueWeaponActive = true
				elseif name=="Blazing Shield" or name=="Radiant Ward" then
					DamageShield = true
				elseif name=="Dampen Magic" then
					DamageShield = true
				-- elseif name=="Rending Leap Ranged" or name=="Uppercut" or name=="Skeletal Smash" or name=="Stunning Shock" or name=="Discharge" or name=="Constricting Strike" or name=="Stun" then
				-- 	MustBreakFree = true
				end
			end
		end
	end
	UpdateLowestGroupHealth()
	UpdateTargetInfo()
	UpdatePixel()
end

local function OnEventPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	if unitTag=="player" and powerType==POWERTYPE_STAMINA then
		StaminaPercent = powerValue / powerMax
		UpdatePixel()
		return
	end
	if powerType==POWERTYPE_HEALTH then
		UpdateLowestGroupHealth()
		UpdatePixel()
		return
	end
end

local function OnEventGroupSupportRangeUpdate()
	UpdateLowestGroupHealth()
	UpdatePixel()
end

local function OnEventCombatTipDisplay(_, tipId)
	if tipId == 2 then
		return
	elseif tipId == 4 or tipId == 19 then
		MustDodge = true
		UpdatePixel()
	elseif tipId == 3 then
		MustInterrupt = true
		UpdatePixel()
	elseif tipId == 1 then
		MustBlock = true
		UpdatePixel()
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
	UpdatePixel()
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
	UpdatePixel()
end




local function OnEventReticleChanged()
	UpdateTargetInfo()
	UpdatePixel()
end




local function OnEventBarSwap()
	UpdateBarState()
	UpdateAbilitySlotInfo()
	UpdatePixel()
end

local function OnEventAbilityChange()
	UpdateAbilitySlotInfo()
end




function PD_InputReady()
	InputReady = true
	UpdatePixel()
end

function PD_InputNotReady()
	InputReady = false
	UpdatePixel()
end

function PD_NotInCombat()
	InCombat = false
	InBossBattle = false
	UpdatePixel()
end

function PD_InCombat()
	InCombat = true
	UpdatePixel()
end

function PD_NotMounted()
	Mounted = false
	UpdatePixel()
end

function PD_Mounted()
	Mounted = true
	UpdatePixel()
end

function PD_MagickaPercent(x)
	MagickaPercent = x
	UpdatePixel()
end

function PD_ReelInFish()
	ReelInFish = true
	UpdatePixel()
end

function PD_StopReelInFish()
	ReelInFish = false
	UpdatePixel()
end







local function OnAddonLoaded(event, name)
	if name == ADDON_NAME then
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event)
		PixelDataWindow = WINDOW_MANAGER:CreateTopLevelWindow("PixelData")
		PixelDataWindow:SetDimensions(100,100)

		PDL = CreateControl(nil, PixelDataWindow,  CT_LINE)
		PDL:SetAnchor(TOPLEFT, PixelDataWindow, TOPLEFT, 0, 0)
		PDL:SetAnchor(TOPRIGHT, PixelDataWindow, TOPLEFT, 1, 1)
		PD_SetPixel(0)

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
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SKILL_BUILD_SELECTION_UPDATED, OnEventAbilityChange)
		-- EVENT_MANAGER:AddFilterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)

		
		zo_callLater(InitialInfoGathering, 1000)
		
	end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
