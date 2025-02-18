local _, ns = ...
local oUF = ns.oUF or oUF

local _G = _G
local addon = {}

ns.oUF_RaidDebuffs = addon
_G.oUF_RaidDebuffs = ns.oUF_RaidDebuffs
if not _G.oUF_RaidDebuffs then
	_G.oUF_RaidDebuffs = addon
end

local format, floor = format, floor
local type, pairs, wipe = type, pairs, wipe

local GetActiveSpecGroup = GetActiveSpecGroup
local GetSpecialization = GetSpecialization
local GetSpellInfo = GetSpellInfo
local UnitCanAttack = UnitCanAttack
local UnitIsCharmed = UnitIsCharmed
local GetTime = GetTime

local debuff_data = {}
addon.DebuffData = debuff_data
addon.ShowDispellableDebuff = true
addon.FilterDispellableDebuff = true
addon.MatchBySpellName = false
addon.priority = 10

local function add(spell, priority, stackThreshold)
	if addon.MatchBySpellName and type(spell) == 'number' then
		spell = GetSpellInfo(spell)
	end

	if spell then
		debuff_data[spell] = {
			priority = (addon.priority + priority),
			stackThreshold = stackThreshold,
		}
	end
end

function addon:RegisterDebuffs(t)
	for spell, value in pairs(t) do
		if type(t[spell]) == 'boolean' then
			local oldValue = t[spell]
			t[spell] = { enable = oldValue, priority = 0, stackThreshold = 0 }
		else
			if t[spell].enable then
				add(spell, t[spell].priority or 0, t[spell].stackThreshold or 0)
			end
		end
	end
end

function addon:ResetDebuffData()
	wipe(debuff_data)
end

local DispelColor = {
	Magic   = {0.2, 0.6, 1.0},
	Curse   = {0.6, 0, 1.0},
	Disease = {0.6, 0.4, 0},
	Poison  = {0, 0.6, 0},
	none    = {0.2, 0.2, 0.2}
}

function addon:GetDispelColor()
	return DispelColor
end

local DispelPriority = {
	Magic   = 4,
	Curse   = 3,
	Disease = 2,
	Poison  = 1,
}

local DispelFilter
do
	local dispelClasses = {
		PRIEST = {
			Magic = true,
			Disease = true,
		},
		SHAMAN = {
			Magic = false,
			Curse = true,
		},
		PALADIN = {
			Poison = true,
			Magic = false,
			Disease = true,
		},
		DRUID = {
			Magic = false,
			Curse = true,
			Poison = true,
			Disease = false,
		},
		MONK = {
			Magic = false,
			Disease = true,
			Poison = true,
		},
		MAGE = {
			Curse = true
		}
	}

	DispelFilter = dispelClasses[select(2, UnitClass('player'))] or {}
end

local function CheckTalentTree(tree)
	local activeGroup = GetActiveSpecGroup()
	local activeSpec = activeGroup and GetSpecialization(false, false, activeGroup)
	if activeSpec then
		return tree == activeSpec
	end
end

local playerClass = select(2, UnitClass('player'))
local function CheckSpec(self, event, levels)
	-- Not interested in gained points from leveling
	if event == 'CHARACTER_POINTS_CHANGED' and levels > 0 then return end

	--Check for certain talents to see if we can dispel magic or not
	if playerClass == 'PALADIN' then
		DispelFilter.Magic = CheckTalentTree(1)
	elseif playerClass == 'SHAMAN' then
		DispelFilter.Magic = CheckTalentTree(3)
	elseif playerClass == 'DRUID' then
		DispelFilter.Magic = CheckTalentTree(4)
	elseif playerClass == 'MONK' then
		DispelFilter.Magic = CheckTalentTree(2)
	end
end

local function formatTime(s)
	if s > 60 then
		return format('%dm', s/60), s%60
	elseif s < 1 then
		return format('%.1f', s), s - floor(s)
	else
		return format('%d', s), s - floor(s)
	end
end

local abs = math.abs
local function OnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 0.1 then
		local timeLeft = self.endTime - GetTime()
		if self.reverse then timeLeft = abs((self.endTime - GetTime()) - self.duration) end
		if timeLeft > 0 then
			local text = formatTime(timeLeft)
			self.time:SetText(text)
		else
			self:SetScript('OnUpdate', nil)
			self.time:Hide()
		end
		self.elapsed = 0
	end
end

local function UpdateDebuff(self, name, icon, count, debuffType, duration, endTime, spellId, stackThreshold)
	local f = self.RaidDebuffs

	if name and (count >= stackThreshold) then
		f.icon:SetTexture(icon)
		f.icon:Show()
		f.duration = duration

		if f.count then
			if count and (count > 1) then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:SetText("")
				f.count:Hide()
			end
		end

		if spellId and ElvUI[1].ReverseTimer[spellId] then
			f.reverse = true
		else
			f.reverse = nil
		end

		if f.time then
			if duration and (duration > 0) then
				f.endTime = endTime
				f.nextUpdate = 0
				f:SetScript('OnUpdate', OnUpdate)
				f.time:Show()
			else
				f:SetScript('OnUpdate', nil)
				f.time:Hide()
			end
		end

		if f.cd then
			if duration and (duration > 0) then
				f.cd:SetCooldown(endTime - duration, duration)
				f.cd:Show()
			else
				f.cd:Hide()
			end
		end

		local c = DispelColor[debuffType] or DispelColor.none
		f:SetBackdropBorderColor(c[1], c[2], c[3])

		f:Show()
	else
		f:Hide()
	end
end

local blackList = {
	[105171] = true, -- Deep Corruption (Dragon Soul: Yor'sahj the Unsleeping)
	[108220] = true, -- Deep Corruption (Dragon Soul: Shadowed Globule)
	[116095] = true, -- Disable, Slow   (Monk: Windwalker)
}

local function Update(self, event, unit)
	if unit ~= self.unit then return end
	local _name, _icon, _count, _dtype, _duration, _endTime, _spellID
	local _stackThreshold, _priority, priority = 0, 0, 0

	--store if the unit its charmed, mind controlled units (Imperial Vizier Zor'lok: Convert)
	local isCharmed = UnitIsCharmed(unit)

	--store if we cand attack that unit, if its so the unit its hostile (Amber-Shaper Un'sok: Reshape Life)
	local canAttack = UnitCanAttack('player', unit)

	local index = 1
	local aura = ElvUI[1]:UnitAura(unit, index, 'HARMFUL')
	while aura do
		local name = aura.name
		local icon = aura.icon
		local count = aura.count
		local debuffType = aura.debuffType
		local duration = aura.duration
		local expirationTime = aura.expirationTime
		local spellID = aura.spellID

		--we coudln't dispel if the unit its charmed, or its not friendly
		if addon.ShowDispellableDebuff and (self.RaidDebuffs.showDispellableDebuff ~= false) and debuffType and (not isCharmed) and (not canAttack) then
			if addon.FilterDispellableDebuff then
				DispelPriority[debuffType] = (DispelPriority[debuffType] or 0) + addon.priority --Make Dispel buffs on top of Boss Debuffs

				priority = DispelFilter[debuffType] and DispelPriority[debuffType] or 0
				if priority == 0 then
					debuffType = nil
				end
			else
				priority = DispelPriority[debuffType] or 0
			end

			if priority > _priority then
				_priority, _name, _icon, _count, _dtype, _duration, _endTime, _spellID = priority, name, icon, count, debuffType, duration, expirationTime, spellID
			end
		end

		local debuff
		if self.RaidDebuffs.onlyMatchSpellID then
			debuff = debuff_data[spellID]
		else
			if debuff_data[spellID] then
				debuff = debuff_data[spellID]
			else
				debuff = debuff_data[name]
			end
		end

		priority = debuff and debuff.priority
		if priority and not blackList[spellID] and (priority > _priority) then
			_priority, _name, _icon, _count, _dtype, _duration, _endTime, _spellID = priority, name, icon, count, debuffType, duration, expirationTime, spellID
		end

		index = index + 1
		aura = ElvUI[1]:UnitAura(unit, index, 'HARMFUL')
	end

	if self.RaidDebuffs.forceShow then
		_spellID = 5782
		_name, _, _icon = GetSpellInfo(_spellID)
		_count, _dtype, _duration, _endTime, _stackThreshold = 5, 'Magic', 0, 60, 0
	end

	if _name then
		_stackThreshold = debuff_data[addon.MatchBySpellName and _name or _spellID] and debuff_data[addon.MatchBySpellName and _name or _spellID].stackThreshold or _stackThreshold
	end

	UpdateDebuff(self, _name, _icon, _count, _dtype, _duration, _endTime, _spellID, _stackThreshold)

	--Reset the DispelPriority
	DispelPriority.Magic = 4
	DispelPriority.Curse = 3
	DispelPriority.Disease = 2
	DispelPriority.Poison = 1
end

local function Enable(self)
	self:RegisterEvent('PLAYER_TALENT_UPDATE', CheckSpec, true)
	self:RegisterEvent('CHARACTER_POINTS_CHANGED', CheckSpec, true)

	if self.RaidDebuffs then
		ElvUI[1]:AuraInfo_SetFunction(self, Update, true)

		return true
	end
end

local function Disable(self)
	if self.RaidDebuffs then
		ElvUI[1]:AuraInfo_SetFunction(self, Update)

		self.RaidDebuffs:Hide()
	end

	self:UnregisterEvent('PLAYER_TALENT_UPDATE', CheckSpec)
	self:UnregisterEvent('CHARACTER_POINTS_CHANGED', CheckSpec)
end

oUF:AddElement('RaidDebuffs', Update, Enable, Disable)
