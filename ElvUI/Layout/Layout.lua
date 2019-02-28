local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local LO = E:NewModule('Layout', 'AceEvent-3.0');

--Lua functions
local _G = _G
--WoW API / Variables
local UIFrameFadeIn, UIFrameFadeOut = UIFrameFadeIn, UIFrameFadeOut
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
-- GLOBALS: HideLeftChat, HideRightChat, HideBothChat

local PANEL_HEIGHT = 22
local SIDE_BUTTON_WIDTH = 16
E.Layout = LO

local function Panel_OnShow(self)
	self:SetFrameLevel(200)
	self:SetFrameStrata('BACKGROUND')
end

function LO:Initialize()
	self:CreateChatPanels()
	self:CreateChatButtonPanel()
	self:CreateMinimapPanels()
	self:SetDataPanelStyle()

	self.BottomPanel = CreateFrame('Frame', 'ElvUI_BottomPanel', E.UIParent)
	self.BottomPanel:SetTemplate('Transparent')
	self.BottomPanel:Point('BOTTOMLEFT', E.UIParent, 'BOTTOMLEFT', -1, -1)
	self.BottomPanel:Point('BOTTOMRIGHT', E.UIParent, 'BOTTOMRIGHT', 1, -1)
	self.BottomPanel:Height(PANEL_HEIGHT)
	self.BottomPanel:SetScript('OnShow', Panel_OnShow)
	E.FrameLocks['ElvUI_BottomPanel'] = true;
	Panel_OnShow(self.BottomPanel)
	self:BottomPanelVisibility()

	self.TopPanel = CreateFrame('Frame', 'ElvUI_TopPanel', E.UIParent)
	self.TopPanel:SetTemplate('Transparent')
	self.TopPanel:Point('TOPLEFT', E.UIParent, 'TOPLEFT', -1, 1)
	self.TopPanel:Point('TOPRIGHT', E.UIParent, 'TOPRIGHT', 1, 1)
	self.TopPanel:Height(PANEL_HEIGHT)
	self.TopPanel:SetScript('OnShow', Panel_OnShow)
	Panel_OnShow(self.TopPanel)
	E.FrameLocks['ElvUI_TopPanel'] = true;
	self:TopPanelVisibility()
end

function LO:BottomPanelVisibility()
	if E.db.general.bottomPanel then
		self.BottomPanel:Show()
	else
		self.BottomPanel:Hide()
	end
end

function LO:TopPanelVisibility()
	if E.db.general.topPanel then
		self.TopPanel:Show()
	else
		self.TopPanel:Hide()
	end
end

local function ChatPanelLeft_OnFade()
	_G.LeftChatPanel:Hide()
end

local function ChatPanelRight_OnFade()
	_G.RightChatPanel:Hide()
end

local function ChatButton_OnEnter(self)
	if E.db[self.parent:GetName()..'Faded'] then
		self.parent:Show()
		UIFrameFadeIn(self.parent, 0.2, self.parent:GetAlpha(), 1)
		UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1)
	end

	if not self.parent.editboxforced then
		local GameTooltip = _G.GameTooltip
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT', 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Left Click:"], L["Toggle Chat Frame"], 1, 1, 1)
		GameTooltip:AddLine('')
		GameTooltip:AddDoubleLine(L["Right Click:"], L["Toggle Chat Buttons"], 1, 1, 1)
		GameTooltip:Show()
	end
end

local function ChatButton_OnLeave(self)
	if E.db[self.parent:GetName()..'Faded'] then
		UIFrameFadeOut(self.parent, 0.2, self.parent:GetAlpha(), 0)
		UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		self.parent.fadeInfo.finishedFunc = self.parent.fadeFunc
	end
	_G.GameTooltip:Hide()
end

local function ChatButton_OnClick(self)
	_G.GameTooltip:Hide()

	if E.db[self.parent:GetName()..'Faded'] then
		E.db[self.parent:GetName()..'Faded'] = nil
		UIFrameFadeIn(self.parent, 0.2, self.parent:GetAlpha(), 1)
		UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1)
	else
		E.db[self.parent:GetName()..'Faded'] = true
		UIFrameFadeOut(self.parent, 0.2, self.parent:GetAlpha(), 0)
		UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		self.parent.fadeInfo.finishedFunc = self.parent.fadeFunc
	end
end

function HideLeftChat()
	ChatButton_OnClick(_G.LeftChatToggleButton)
end

function HideRightChat()
	ChatButton_OnClick(_G.RightChatToggleButton)
end

function HideBothChat()
	ChatButton_OnClick(_G.LeftChatToggleButton)
	ChatButton_OnClick(_G.RightChatToggleButton)
end

function LO:ToggleChatTabPanels(rightOverride, leftOverride)
	if leftOverride or not E.db.chat.panelTabBackdrop then
		_G.LeftChatTab:Hide()
	else
		_G.LeftChatTab:Show()
	end

	if rightOverride or not E.db.chat.panelTabBackdrop then
		_G.RightChatTab:Hide()
	else
		_G.RightChatTab:Show()
	end
end

function LO:SetChatTabStyle()
	if E.db.chat.panelTabTransparency then
		_G.LeftChatTab:SetTemplate("Transparent")
		_G.RightChatTab:SetTemplate("Transparent")
	else
		_G.LeftChatTab:SetTemplate("Default", true)
		_G.RightChatTab:SetTemplate("Default", true)
	end
end

function LO:SetDataPanelStyle()
	local LeftMiniPanel = _G.LeftMiniPanel
	local RightMiniPanel = _G.RightMiniPanel
	local LeftChatDataPanel = _G.LeftChatDataPanel
	local RightChatDataPanel = _G.RightChatDataPanel
	local LeftChatToggleButton = _G.LeftChatToggleButton
	local RightChatToggleButton = _G.RightChatToggleButton
	if not E.db.datatexts.panelBackdrop then
		LeftChatDataPanel:SetTemplate("NoBackdrop")
		LeftChatToggleButton:SetTemplate("NoBackdrop")
		RightChatDataPanel:SetTemplate("NoBackdrop")
		RightChatToggleButton:SetTemplate("NoBackdrop")
	elseif E.db.datatexts.panelTransparency then
		LeftChatDataPanel:SetTemplate("Transparent")
		LeftChatToggleButton:SetTemplate("Transparent")
		LeftMiniPanel:SetTemplate("Transparent")
		RightChatDataPanel:SetTemplate("Transparent")
		RightChatToggleButton:SetTemplate("Transparent")
		RightMiniPanel:SetTemplate("Transparent")
	else
		LeftChatDataPanel:SetTemplate("Default", true)
		LeftChatToggleButton:SetTemplate("Default", true)
		LeftMiniPanel:SetTemplate("Default", true)
		RightChatDataPanel:SetTemplate("Default", true)
		RightChatToggleButton:SetTemplate("Default", true)
		RightMiniPanel:SetTemplate("Default", true)
	end
end

function LO:RepositionChatDataPanels()
	local LeftChatTab = _G.LeftChatTab
	local RightChatTab = _G.RightChatTab
	local LeftChatPanel = _G.LeftChatPanel
	local RightChatPanel = _G.RightChatPanel
	local LeftChatDataPanel = _G.LeftChatDataPanel
	local RightChatDataPanel = _G.RightChatDataPanel
	local LeftChatToggleButton = _G.LeftChatToggleButton
	local RightChatToggleButton = _G.RightChatToggleButton

	LeftChatDataPanel:ClearAllPoints()
	RightChatDataPanel:ClearAllPoints()

	local SPACING = E.Border*3 - E.Spacing
	local SIDE_BUTTON_SPACING = (E.PixelMode and E.Border*4) or SPACING*2

	--Left Chat Tab
	LeftChatTab:Point('TOPLEFT', LeftChatPanel, 'TOPLEFT', SPACING, -SPACING)
	LeftChatTab:Point('TOPRIGHT', LeftChatPanel, 'TOPRIGHT', -SPACING, -SPACING)
	LeftChatTab:Point('BOTTOMRIGHT', LeftChatPanel, 'TOPRIGHT', -SPACING, -(SPACING + PANEL_HEIGHT))
	LeftChatTab:Point('BOTTOMLEFT', LeftChatPanel, 'TOPLEFT', SPACING, -(SPACING + PANEL_HEIGHT))

	--Left Chat Data Panel
	LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SPACING + SIDE_BUTTON_WIDTH, SPACING)
	LeftChatDataPanel:Point('BOTTOMRIGHT', LeftChatPanel, 'BOTTOMRIGHT', -SPACING, SPACING)
	LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
	LeftChatDataPanel:Point('TOPLEFT', LeftChatPanel, 'BOTTOMLEFT', SIDE_BUTTON_SPACING+SIDE_BUTTON_WIDTH, (SPACING + PANEL_HEIGHT))

	--Left Chat Toggle Button
	LeftChatToggleButton:Point('TOPRIGHT', LeftChatDataPanel, 'TOPLEFT', E.Border - E.Spacing*3, 0)
	LeftChatToggleButton:Point('TOPLEFT', LeftChatDataPanel, 'TOPLEFT', -E.Border - E.Spacing*3 - SIDE_BUTTON_WIDTH, 0)
	LeftChatToggleButton:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
	LeftChatToggleButton:Point('BOTTOMRIGHT', LeftChatPanel, 'BOTTOMLEFT', SPACING+SIDE_BUTTON_WIDTH, SPACING)

	--Right Chat Tab
	RightChatTab:Point('TOPRIGHT', RightChatPanel, 'TOPRIGHT', -SPACING, -SPACING)
	RightChatTab:Point('TOPLEFT', RightChatPanel, 'TOPLEFT', SPACING, -SPACING)
	RightChatTab:Point('BOTTOMLEFT', RightChatPanel, 'TOPLEFT', SPACING, -(SPACING + PANEL_HEIGHT))
	RightChatTab:Point('BOTTOMRIGHT', RightChatPanel, 'TOPRIGHT', -SPACING, -(SPACING + PANEL_HEIGHT))

	--Right Chat Data Panel
	RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
	RightChatDataPanel:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SPACING-SIDE_BUTTON_WIDTH, SPACING)
	RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -(SIDE_BUTTON_SPACING + SIDE_BUTTON_WIDTH), SPACING + PANEL_HEIGHT)
	RightChatDataPanel:Point('TOPLEFT', RightChatPanel, 'BOTTOMLEFT', (SPACING), SPACING + PANEL_HEIGHT)

	--Right Chat Toggle Button
	RightChatToggleButton:Point('TOPLEFT', RightChatDataPanel, 'TOPRIGHT', -E.Border + E.Spacing*3, 0)
	RightChatToggleButton:Point('TOPRIGHT', RightChatDataPanel, 'TOPRIGHT', E.Border + E.Spacing*3 + SIDE_BUTTON_WIDTH, 0)
	RightChatToggleButton:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SPACING, SPACING)
	RightChatToggleButton:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMRIGHT', -SPACING-SIDE_BUTTON_WIDTH, SPACING)
end

function LO:ToggleChatPanels()
	local LeftChatPanel = _G.LeftChatPanel
	local RightChatPanel = _G.RightChatPanel
	local LeftChatDataPanel = _G.LeftChatDataPanel
	local RightChatDataPanel = _G.RightChatDataPanel
	local LeftChatToggleButton = _G.LeftChatToggleButton
	local RightChatToggleButton = _G.RightChatToggleButton

	LeftChatDataPanel:ClearAllPoints()
	RightChatDataPanel:ClearAllPoints()

	local SPACING = E.Border*3 - E.Spacing
	local SIDE_BUTTON_SPACING = (E.PixelMode and E.Border*4) or SPACING*2

	if E.db.datatexts.leftChatPanel then
		LeftChatDataPanel:Show()
		LeftChatToggleButton:Show()
	else
		LeftChatDataPanel:Hide()
		LeftChatToggleButton:Hide()
	end

	if E.db.datatexts.rightChatPanel then
		RightChatDataPanel:Show()
		RightChatToggleButton:Show()
	else
		RightChatDataPanel:Hide()
		RightChatToggleButton:Hide()
	end

	local panelBackdrop = E.db.chat.panelBackdrop
	if panelBackdrop == 'SHOWBOTH' then
		LeftChatPanel.backdrop:Show()
		RightChatPanel.backdrop:Show()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SIDE_BUTTON_SPACING + SIDE_BUTTON_WIDTH, SPACING)
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -(SIDE_BUTTON_SPACING + SIDE_BUTTON_WIDTH), SPACING + PANEL_HEIGHT)
		LeftChatToggleButton:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		RightChatToggleButton:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SPACING, SPACING)
		LO:ToggleChatTabPanels()
	elseif panelBackdrop == 'HIDEBOTH' then
		LeftChatPanel.backdrop:Hide()
		RightChatPanel.backdrop:Hide()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SIDE_BUTTON_WIDTH, 0)
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', 0, PANEL_HEIGHT)
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT')
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SIDE_BUTTON_WIDTH, PANEL_HEIGHT)
		LeftChatToggleButton:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT')
		RightChatToggleButton:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT')
		LO:ToggleChatTabPanels(true, true)
	elseif panelBackdrop == 'LEFT' then
		LeftChatPanel.backdrop:Show()
		RightChatPanel.backdrop:Hide()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SIDE_BUTTON_SPACING + SIDE_BUTTON_WIDTH, SPACING)
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT')
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SIDE_BUTTON_WIDTH, PANEL_HEIGHT)
		LeftChatToggleButton:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		RightChatToggleButton:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT')
		LO:ToggleChatTabPanels(true)
	else
		LeftChatPanel.backdrop:Hide()
		RightChatPanel.backdrop:Show()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SIDE_BUTTON_WIDTH, 0)
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', 0, PANEL_HEIGHT)
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -(SIDE_BUTTON_SPACING + SIDE_BUTTON_WIDTH), SPACING + PANEL_HEIGHT)
		LeftChatToggleButton:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT')
		RightChatToggleButton:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SPACING, SPACING)
		LO:ToggleChatTabPanels(nil, true)
	end
end

function LO:ChatButtonPanel_OnClick()
	_G.GameTooltip:Hide()

	local ChatButtonHolder = _G.ChatButtonHolder
	if ChatButtonHolder:IsShown() then
		ChatButtonHolder:Hide()
	else
		ChatButtonHolder:Show()
	end
end

function LO:CreateChatPanels()
	local SPACING = E.Border*3 - E.Spacing
	local SIDE_BUTTON_SPACING = (E.PixelMode and E.Border*4) or SPACING*2

	--Left Chat
	local lchat = CreateFrame('Frame', 'LeftChatPanel', E.UIParent)
	lchat:SetFrameStrata('BACKGROUND')
	lchat:SetFrameLevel(300)
	lchat:Size(E.db.chat.panelWidth, E.db.chat.panelHeight)
	lchat:Point('BOTTOMLEFT', E.UIParent, 4, 4)
	lchat:CreateBackdrop('Transparent', nil, true)
	lchat.backdrop:SetAllPoints()
	E:CreateMover(lchat, "LeftChatMover", L["Left Chat"], nil, nil, nil, nil, nil, 'chat,general')
	local LeftChatPanel = _G.LeftChatPanel

	--Background Texture
	lchat.tex = lchat:CreateTexture(nil, 'OVERLAY')
	lchat.tex:SetInside()
	lchat.tex:SetTexture(E.db.chat.panelBackdropNameLeft)
	lchat.tex:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--Left Chat Tab
	local lchattab = CreateFrame('Frame', 'LeftChatTab', LeftChatPanel)
	lchattab:Point('TOPLEFT', lchat, 'TOPLEFT', SPACING, -SPACING)
	lchattab:Point('TOPRIGHT', lchat, 'TOPRIGHT', -SPACING, -SPACING)
	lchattab:Point('BOTTOMRIGHT', lchat, 'TOPRIGHT', -SPACING, -(SPACING + PANEL_HEIGHT))
	lchattab:Point('BOTTOMLEFT', lchat, 'TOPLEFT', SPACING, -(SPACING + PANEL_HEIGHT))
	lchattab:SetTemplate(E.db.chat.panelTabTransparency == true and 'Transparent' or 'Default', true)

	--Left Chat Data Panel
	local lchatdp = CreateFrame('Frame', 'LeftChatDataPanel', LeftChatPanel)
	lchatdp:Point('BOTTOMLEFT', lchat, 'BOTTOMLEFT', SPACING + SIDE_BUTTON_WIDTH, SPACING)
	lchatdp:Point('BOTTOMRIGHT', lchat, 'BOTTOMRIGHT', -SPACING, SPACING)
	lchatdp:Point('TOPRIGHT', lchat, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
	lchatdp:Point('TOPLEFT', lchat, 'BOTTOMLEFT', SIDE_BUTTON_SPACING+SIDE_BUTTON_WIDTH, (SPACING + PANEL_HEIGHT))
	lchatdp:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)

	E:GetModule('DataTexts'):RegisterPanel(lchatdp, 3, 'ANCHOR_TOPLEFT', -17, 4)

	--Left Chat Toggle Button
	local lchattb = CreateFrame('Button', 'LeftChatToggleButton', E.UIParent)
	lchattb.parent = LeftChatPanel
	LeftChatPanel.fadeFunc = ChatPanelLeft_OnFade
	lchattb:Point('TOPRIGHT', lchatdp, 'TOPLEFT', E.Border - E.Spacing*3, 0)
	lchattb:Point('TOPLEFT', lchatdp, 'TOPLEFT', -E.Border - E.Spacing*3 - SIDE_BUTTON_WIDTH, 0)
	lchattb:Point('BOTTOMLEFT', lchat, 'BOTTOMLEFT', SPACING, SPACING)
	lchattb:Point('BOTTOMRIGHT', lchat, 'BOTTOMLEFT', SPACING+SIDE_BUTTON_WIDTH, SPACING)
	lchattb:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	lchattb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	lchattb:SetScript('OnEnter', ChatButton_OnEnter)
	lchattb:SetScript('OnLeave', ChatButton_OnLeave)
	lchattb:SetScript('OnClick', function(lcb, btn)
		if btn == "LeftButton" then
			ChatButton_OnClick(lcb)
		elseif btn == "RightButton" then
			LO:ChatButtonPanel_OnClick(lcb)
		end
	end)

	lchattb.text = lchattb:CreateFontString(nil, 'OVERLAY')
	lchattb.text:FontTemplate()
	lchattb.text:Point('CENTER')
	lchattb.text:SetJustifyH('CENTER')
	lchattb.text:SetText('<')

	--Right Chat
	local rchat = CreateFrame('Frame', 'RightChatPanel', E.UIParent)
	rchat:SetFrameStrata('BACKGROUND')
	rchat:SetFrameLevel(300)
	rchat:Size(E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth, E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight)
	rchat:Point('BOTTOMRIGHT', E.UIParent, -4, 4)
	rchat:CreateBackdrop('Transparent', nil, true)
	rchat.backdrop:SetAllPoints()
	E:CreateMover(rchat, "RightChatMover", L["Right Chat"], nil, nil, nil, nil, nil, 'chat,general')
	local RightChatPanel = _G.RightChatPanel

	--Background Texture
	rchat.tex = rchat:CreateTexture(nil, 'OVERLAY')
	rchat.tex:SetInside()
	rchat.tex:SetTexture(E.db.chat.panelBackdropNameRight)
	rchat.tex:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--Right Chat Tab
	local rchattab = CreateFrame('Frame', 'RightChatTab', RightChatPanel)
	rchattab:Point('TOPRIGHT', rchat, 'TOPRIGHT', -SPACING, -SPACING)
	rchattab:Point('TOPLEFT', rchat, 'TOPLEFT', SPACING, -SPACING)
	rchattab:Point('BOTTOMLEFT', rchat, 'TOPLEFT', SPACING, -(SPACING + PANEL_HEIGHT))
	rchattab:Point('BOTTOMRIGHT', rchat, 'TOPRIGHT', -SPACING, -(SPACING + PANEL_HEIGHT))
	rchattab:SetTemplate(E.db.chat.panelTabTransparency == true and 'Transparent' or 'Default', true)

	--Right Chat Data Panel
	local rchatdp = CreateFrame('Frame', 'RightChatDataPanel', RightChatPanel)
	rchatdp:Point('BOTTOMLEFT', rchat, 'BOTTOMLEFT', SPACING, SPACING)
	rchatdp:Point('BOTTOMRIGHT', rchat, 'BOTTOMRIGHT', -SPACING-SIDE_BUTTON_WIDTH, SPACING)
	rchatdp:Point('TOPRIGHT', rchat, 'BOTTOMRIGHT', -(SIDE_BUTTON_SPACING + SIDE_BUTTON_WIDTH), SPACING + PANEL_HEIGHT)
	rchatdp:Point('TOPLEFT', rchat, 'BOTTOMLEFT', (SPACING), SPACING + PANEL_HEIGHT)
	rchatdp:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	E:GetModule('DataTexts'):RegisterPanel(rchatdp, 3, 'ANCHOR_TOPRIGHT', 17, 4)

	--Right Chat Toggle Button
	local rchattb = CreateFrame('Button', 'RightChatToggleButton', E.UIParent)
	rchattb.parent = RightChatPanel
	RightChatPanel.fadeFunc = ChatPanelRight_OnFade
	rchattb:Point('TOPLEFT', rchatdp, 'TOPRIGHT', -E.Border + E.Spacing*3, 0)
	rchattb:Point('TOPRIGHT', rchatdp, 'TOPRIGHT', E.Border + E.Spacing*3 + SIDE_BUTTON_WIDTH, 0)
	rchattb:Point('BOTTOMRIGHT', rchat, 'BOTTOMRIGHT', -SPACING, SPACING)
	rchattb:Point('BOTTOMLEFT', rchat, 'BOTTOMRIGHT', -SPACING-SIDE_BUTTON_WIDTH, SPACING)
	rchattb:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	rchattb:RegisterForClicks('AnyUp')
	rchattb:SetScript('OnEnter', ChatButton_OnEnter)
	rchattb:SetScript('OnLeave', ChatButton_OnLeave)
	rchattb:SetScript('OnClick', function(rcb, btn)
		if btn == "LeftButton" then
			ChatButton_OnClick(rcb)
		elseif btn == "RightButton" then
			LO:ChatButtonPanel_OnClick(rcb)
		end
	end)

	rchattb.text = rchattb:CreateFontString(nil, 'OVERLAY')
	rchattb.text:FontTemplate()
	rchattb.text:Point('CENTER')
	rchattb.text:SetJustifyH('CENTER')
	rchattb.text:SetText('>')

	--Load Settings
	if E.db.LeftChatPanelFaded then
		_G.LeftChatToggleButton:SetAlpha(0)
		LeftChatPanel:Hide()
	end

	if E.db.RightChatPanelFaded then
		_G.RightChatToggleButton:SetAlpha(0)
		RightChatPanel:Hide()
	end

	self:ToggleChatPanels()
end

function LO:CreateChatButtonPanel()
	if E.private.chat.enable ~= true then return end

	local ChatButtonHolder = CreateFrame("Frame", "ChatButtonHolder", E.UIParent)
	ChatButtonHolder:ClearAllPoints()
	ChatButtonHolder:SetPoint("RIGHT", _G.LeftChatPanel, "LEFT", -4, 0)
	ChatButtonHolder:SetSize(33, LeftChatPanel:GetHeight()-2)

	--QuickJoinToastButton:Hide() -- DONT KILL IT! If we use hide we also hide the Toasts, which are used in other Plugins.

	ChatButtonHolder:CreateBackdrop('Transparent', nil, true)
	ChatButtonHolder.backdrop:SetPoint('TOPLEFT', ChatButtonHolder, E.PixelMode and 1 or 3, 1)
	ChatButtonHolder.backdrop:SetPoint('BOTTOMRIGHT', ChatButtonHolder, E.PixelMode and 1 or 3, -1)
	ChatButtonHolder.backdrop:SetBackdropColor(unpack(E.db.general.backdropfadecolor))
	ChatButtonHolder.backdrop:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--ChatButtonHolder:Hide()
	--E:CreateMover(ChatButtonHolder, "SocialMenuMover", _G.BINDING_HEADER_VOICE_CHAT)

	_G.ChatFrameChannelButton:ClearAllPoints()
	_G.ChatFrameChannelButton:SetPoint("TOP", ChatButtonHolder, "TOP", E.PixelMode and 1.1 or 3, -2)

	-- We have to reparent the buttons to our ChatButtonHolder
	_G.ChatFrameChannelButton:SetParent(ChatButtonHolder)
	_G.ChatFrameToggleVoiceDeafenButton:SetParent(ChatButtonHolder)
	_G.ChatFrameToggleVoiceMuteButton:SetParent(ChatButtonHolder)

	E:GetModule("Skins"):HandleButton(_G.ChatFrameChannelButton)
	E:GetModule("Skins"):HandleButton(_G.ChatFrameToggleVoiceDeafenButton)
	E:GetModule("Skins"):HandleButton(_G.ChatFrameToggleVoiceMuteButton)

	_G.ChatAlertFrame:ClearAllPoints()
	_G.ChatAlertFrame:SetPoint("BOTTOM", _G.ChatFrameChannelButton, "TOP", 1, 3)

	-- Skin the QuickJoinToastButton
	local QuickJoinToastButton = _G["QuickJoinToastButton"]
	QuickJoinToastButton:SetParent(ChatButtonHolder)
	QuickJoinToastButton:SetSize(24, 32)

	QuickJoinToastButton:CreateBackdrop()
	QuickJoinToastButton.backdrop:SetAllPoints()

	hooksecurefunc(QuickJoinToastButton, "UpdateQueueIcon", function(qjtb)
		qjtb.FriendsButton:SetTexture([[Interface\FriendsFrame\UI-Toast-FriendOnlineIcon]])

		if qjtb:GetButtonState() == "PUSHED" then
			if qjtb.isLFGList then
				qjtb.QueueButton:SetTexture([[Interface\FriendsFrame\UI-Toast-ChatInviteIcon]])
				qjtb.FlashingLayer:SetTexture([[Interface\FriendsFrame\UI-Toast-ChatInviteIcon]])
			else
				qjtb.QueueButton:SetTexture([[Interface\LFGFrame\BattlenetWorking0]])
				qjtb.FlashingLayer:SetTexture([[Interface\LFGFrame\BattlenetWorking0]])
			end
		else
			if qjtb.isLFGList then
				qjtb.QueueButton:SetTexture([[Interface\FriendsFrame\UI-Toast-ChatInviteIcon]])
				qjtb.FlashingLayer:SetTexture([[Interface\FriendsFrame\UI-Toast-ChatInviteIcon]])
			else
				qjtb.QueueButton:SetTexture([[Interface\LFGFrame\BattlenetWorking0]])
				qjtb.FlashingLayer:SetTexture([[Interface\LFGFrame\BattlenetWorking0]])
			end
		end
	end)

	QuickJoinToastButton.FriendsButton:SetTexture([[Interface\FriendsFrame\UI-Toast-FriendOnlineIcon]])
	QuickJoinToastButton.FriendsButton:ClearAllPoints()
	QuickJoinToastButton.FriendsButton:SetPoint("CENTER", 0, 3)
	QuickJoinToastButton.FriendsButton:SetSize(30, 30)

	QuickJoinToastButton.QueueButton:SetTexture([[Interface\FriendsFrame\UI-Toast-ChatInviteIcon]])
	QuickJoinToastButton.QueueButton:ClearAllPoints()
	QuickJoinToastButton.QueueButton:SetPoint("CENTER", 0, 3)
	QuickJoinToastButton.QueueButton:SetSize(28, 28)

	QuickJoinToastButton.FlashingLayer:SetTexture([[Interface\FriendsFrame\UI-Toast-ChatInviteIcon]])
	QuickJoinToastButton.FlashingLayer:ClearAllPoints()
	QuickJoinToastButton.FlashingLayer:SetPoint("CENTER", 0, 3)
	QuickJoinToastButton.FlashingLayer:SetSize(28, 28)
end

function LO:CreateMinimapPanels()
	local Minimap = _G.Minimap
	local lminipanel = CreateFrame('Frame', 'LeftMiniPanel', Minimap)

	lminipanel:Point('TOPLEFT', Minimap, 'BOTTOMLEFT', -E.Border, -E.Spacing*3)
	lminipanel:Point('BOTTOMRIGHT', Minimap, 'BOTTOM', 0, -(E.Spacing*3 + PANEL_HEIGHT))
	lminipanel:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	E:GetModule('DataTexts'):RegisterPanel(lminipanel, 1, 'ANCHOR_BOTTOMLEFT', lminipanel:GetWidth() * 2, -4)

	local rminipanel = CreateFrame('Frame', 'RightMiniPanel', Minimap)
	rminipanel:Point('TOPRIGHT', Minimap, 'BOTTOMRIGHT', E.Border, -(E.Spacing*3))
	rminipanel:Point('BOTTOMLEFT', lminipanel, 'BOTTOMRIGHT', -E.Border + (E.Spacing*3), 0)
	rminipanel:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	E:GetModule('DataTexts'):RegisterPanel(rminipanel, 1, 'ANCHOR_BOTTOM', 0, -4)

	if E.db.datatexts.minimapPanels then
		_G.LeftMiniPanel:Show()
		_G.RightMiniPanel:Show()
	else
		_G.LeftMiniPanel:Hide()
		_G.RightMiniPanel:Hide()
	end

	local f = CreateFrame("Frame", 'BottomMiniPanel', Minimap)
	f:SetPoint("BOTTOM", Minimap, "BOTTOM")
	f:Width(120)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOM', 0, -10)

	f = CreateFrame("Frame", 'TopMiniPanel', Minimap)
	f:SetPoint("TOP", Minimap, "TOP")
	f:Width(120)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOM', 0, -10)

	f = CreateFrame("Frame", 'TopLeftMiniPanel', Minimap)
	f:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMLEFT', 0, -10)

	f = CreateFrame("Frame", 'TopRightMiniPanel', Minimap)
	f:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMRIGHT', 0, -10)

	f = CreateFrame("Frame", 'BottomLeftMiniPanel', Minimap)
	f:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMLEFT', 0, -10)

	f = CreateFrame("Frame", 'BottomRightMiniPanel', Minimap)
	f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMRIGHT', 0, -10)
end

local function InitializeCallback()
	LO:Initialize()
end

E:RegisterModule(LO:GetName(), InitializeCallback)
