local mod	= DBM:NewMod("GeneralDrakkisath", "DBM-Party-Classic", 1)
local L		= mod:GetLocalizedStrings()

local BOSS_CREATURE_ID = 10363
local CONFLAGRATION_ID = 85980
local CONFLAGRATION_DURATION = 5
local CONFLAGRATION_CD = 11
local MOLTEN_ENGULFMENT_ID = 85990
local FLAMESTRIKE_ID = 85978

mod:SetRevision("20250911132619")
mod:SetCreatureID(BOSS_CREATURE_ID)
mod:SetUsedIcons(1)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 85980",
	"SPELL_AURA_REMOVED 85980",
	"SPELL_CAST_START 85990 85978",
	"UNIT_HEALTH"
)

local conflagrationWarn			= mod:NewTargetNoFilterAnnounce(CONFLAGRATION_ID, 2)
local conflagrationTimer		= mod:NewTargetTimer(CONFLAGRATION_DURATION, CONFLAGRATION_ID, nil, nil, nil, 3)
local conflagrationSay			= mod:NewYell(CONFLAGRATION_ID)
local conflagrationCDTimer		= mod:NewAITimer(CONFLAGRATION_CD, CONFLAGRATION_ID, nil, nil, nil, 3)

local moltenEngulfmentPreWarn	= mod:NewSoonAnnounce(MOLTEN_ENGULFMENT_ID, 2)
local moltenEngulfmentWarn		= mod:NewSpecialWarningSpell(MOLTEN_ENGULFMENT_ID, nil, nil, nil, 2, 2)

local flamestrikeWarn			= mod:NewSpecialWarningInterrupt(FLAMESTRIKE_ID, "HasInterrupt", nil, 2, 1, 2)

mod:AddSetIconOption("SetIconOnConflagration", CONFLAGRATION_ID, true, false, {1})

mod.vb.prewarn_engulfment_1 = false
mod.vb.prewarn_engulfment_2 = false
mod.vb.prewarn_engulfment_3 = false

function mod:OnCombatStart()
	self.vb.prewarn_engulfment_1 = false
	self.vb.prewarn_engulfment_2 = false
	self.vb.prewarn_engulfment_3 = false
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == CONFLAGRATION_ID then
		conflagrationWarn:Show(args.destName)
		conflagrationTimer:Start(args.destName)
		conflagrationCDTimer:Start()
		if args:IsPlayer() then
			conflagrationSay:Yell()
		end

		if self.Options.SetIconOnConflagration then
			self:SetIcon(args.destName, 1, CONFLAGRATION_DURATION)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == CONFLAGRATION_ID then
		conflagrationTimer:Stop(args.destName)
		if self.Options.SetIconOnConflagration then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == MOLTEN_ENGULFMENT_ID then
		moltenEngulfmentWarn:Show()
		moltenEngulfmentWarn:Play("useitem")
	elseif args.spellId == FLAMESTRIKE_ID and self:CheckInterruptFilter(args.sourceGUID) then
		flamestrikeWarn:Show(args.sourceName)
		flamestrikeWarn:Play("kickcast")
	end
end

function mod:UNIT_HEALTH(uId)
	if self:GetUnitCreatureId(uId) ~= BOSS_CREATURE_ID then
		return
	end

	local pct = UnitHealth(uId) / UnitHealthMax(uId)
	if pct <= 0.78 and not self.vb.prewarn_engulfment_1 then
		self.vb.prewarn_engulfment_1 = true
		moltenEngulfmentPreWarn:Show()
	elseif pct <= 0.53 and not self.vb.prewarn_engulfment_2 then
		self.vb.prewarn_engulfment_2 = true
		moltenEngulfmentPreWarn:Show()
	elseif pct <= 0.28 and not self.vb.prewarn_engulfment_3 then
		self.vb.prewarn_engulfment_3 = true
		moltenEngulfmentPreWarn:Show()
	end
end
