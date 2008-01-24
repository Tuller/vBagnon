--[[
	BagnonBag
		A bag button object
--]]

--local msg = function(msg) ChatFrame1:AddMessage(msg or 'nil', 0.5, 0.5, 1) end

BagnonBag = CreateFrame('Button')
local Frame_mt = {__index = BagnonBag}

local SIZE = 32
local NORMAL_TEXTURE_SIZE = 64 * (SIZE / 37)
local KEY_WIDTH = 18 * (SIZE / 37)

--[[ Bag Constructor ]]--

local function OnEnter() this:OnEnter() end
local function OnLeave() this:OnLeave() end
local function OnShow()  this:OnShow()  end
local function OnClick() this:OnClick() end
local function OnDrag()  this:OnDrag() end

local function Bag_Create(lastCreated)
	local name = "BagnonBag" .. lastCreated
	local bag = CreateFrame("Button", name)
	setmetatable(bag, Frame_mt)

	bag:SetWidth(SIZE)
	bag:SetHeight(SIZE)

	local icon = bag:CreateTexture(name .. "IconTexture", "BORDER")
	icon:SetAllPoints(bag)

	local count = bag:CreateFontString(name .. "Count", "BORDER")
	count:SetFontObject("NumberFontNormal")
	count:SetJustifyH("RIGHT")
	count:SetPoint("BOTTOMRIGHT", bag, "BOTTOMRIGHT", -2, 2)

	local normalTexture = bag:CreateTexture(name .. "NormalTexture")
	normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	normalTexture:SetWidth(NORMAL_TEXTURE_SIZE)
	normalTexture:SetHeight(NORMAL_TEXTURE_SIZE)
	normalTexture:SetPoint("CENTER", bag, "CENTER", 0, -1)
	bag:SetNormalTexture(normalTexture)

	local pushedTexture = bag:CreateTexture()
	pushedTexture:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	pushedTexture:SetAllPoints(bag)
	bag:SetPushedTexture(pushedTexture)

	local highlightTexture = bag:CreateTexture()
	highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	highlightTexture:SetAllPoints(bag)
	bag:SetHighlightTexture(highlightTexture)

	bag:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	bag:RegisterForDrag("LeftButton")

	bag:SetScript('OnShow', OnShow)
	bag:SetScript('OnEnter', OnEnter)
	bag:SetScript('OnLeave', OnLeave)
	bag:SetScript('OnClick', OnClick)
	bag:SetScript('OnDragStart', OnDrag)
	bag:SetScript('OnReceiveDrag', OnClick)

	return bag
end

--[[ Methods ]]--

function BagnonBag.Get()
	return TPool.Get('BagnonBag', Bag_Create)
end

function BagnonBag:Set(parent, bagID)
	Bagnon_AttachToFrame(self, parent)
	self:SetID(bagID)
	
	if bagID <= 0 then
		if bagID == 0 or bagID == -1 then
			getglobal(self:GetName() .. 'IconTexture'):SetTexture('Interface\\Buttons\\Button-Backpack-Up')
		elseif bagID == -2 then
			getglobal(self:GetName() .. 'IconTexture'):SetTexture('Interface\\Buttons\\UI-Button-KeyRing')
			getglobal(self:GetName() .. 'IconTexture'):SetTexCoord(0, 0.5625, 0, 0.609375)
			self:GetNormalTexture():SetWidth(KEY_WIDTH)
			self:SetWidth(KEY_WIDTH)
		end
		self:SetCount(0)
	end
	
	if bagID ~= -2 then
		getglobal(self:GetName() .. 'IconTexture'):SetTexCoord(0, 1, 0, 1)
		self:GetNormalTexture():SetWidth(NORMAL_TEXTURE_SIZE)
		self:SetWidth(SIZE)
	end
	self:Update()
end

function BagnonBag:Release()
	TPool.Release(self, 'BagnonBag')
end

--[[ Update Functions ]]--

function BagnonBag:Update()
	self:UpdateTexture()
	self:UpdateLock()

	--update tooltip
	if GameTooltip:IsOwned(self) then
		if self.hasItem then
			self:OnEnter()
		else
			GameTooltip:Hide()
			ResetCursor()
		end
	end

	-- Update repair all button status
	if MerchantRepairAllIcon then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair then
			SetDesaturation(MerchantRepairAllIcon, nil)
			MerchantRepairAllButton:Enable()
		else
			SetDesaturation(MerchantRepairAllIcon, 1)
			MerchantRepairAllButton:Disable()
		end
	end
end

function BagnonBag:UpdateLock()
	local locked = IsInventoryItemLocked( Bagnon_GetInvSlot(self:GetID()) )
	SetItemButtonDesaturated(self, locked)
end

function BagnonBag:UpdateCursor()
	local invID = Bagnon_GetInvSlot(self:GetID())
	if CursorCanGoInSlot(invID) then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

--actually, update texture and count
function BagnonBag:UpdateTexture()
	local parent = self:GetParent():GetParent()
	local bagID = self:GetID()

	if bagID <= 0 or not parent then return end
	
	local player = parent:GetPlayer()

	if Bagnon_IsCachedBag(player, bagID) then

		local link, count = select(2, BagnonDB.GetBagData(player, self:GetID()))
		if link then
			local texture = select(10, GetItemInfo(link))
			SetItemButtonTexture(self, texture)

			if texture then
				self.hasItem = true
			end
		else
			SetItemButtonTexture(self, nil)
			self.hasItem = nil
		end

		if count then
			self:SetCount(count)
		end
	else
		local texture = GetInventoryItemTexture("player", Bagnon_GetInvSlot(self:GetID()))
		if texture then
			SetItemButtonTexture(self, texture)
			self.hasItem = true
		else
			SetItemButtonTexture(self, nil)
			self.hasItem = nil
		end
		self:SetCount(GetInventoryItemCount("player", Bagnon_GetInvSlot(self:GetID())))
	end
end

function BagnonBag:SetCount(count)
	local countText = getglobal(self:GetName() .. "Count")
	
	if self:GetID() <= 0 then
		countText:Hide()
	else
		if not count then count = 0 end

		if count > 1 then
			if count > 9999 then
				countText:SetFont(NumberFontNormal:GetFont(), 10, "OUTLINE")
			elseif count > 999 then
				countText:SetFont(NumberFontNormal:GetFont(), 11, "OUTLINE")
			else
				countText:SetFont(NumberFontNormal:GetFont(), 12, "OUTLINE")
			end
			countText:SetText(count)
			countText:Show()
		else
			countText:Hide()
		end
	end
end

--[[ OnX Functions ]]--

function BagnonBag:OnClick()
	local parent = self:GetParent():GetParent()
	local player = parent:GetPlayer()
	local bagID = self:GetID()

	local bagID = self:GetID()
	if not(Bagnon_IsCachedBag(player, bagID)) and CursorHasItem() then
		if bagID == KEYRING_CONTAINER then
			PutKeyInKeyRing()
		elseif bagID == 0 then
			PutItemInBackpack()
		else
			PutItemInBag(ContainerIDToInventoryID(bagID))
		end
	else
		parent:ToggleBag(bagID)
	end
end

function BagnonBag:OnDrag()
	local parent = self:GetParent():GetParent()
	local player = parent:GetPlayer()
	local bagID = self:GetID()
	
	if not(Bagnon_IsCachedBag(player, bagID) or bagID <= 0) then
		PlaySound("BAGMENUBUTTONPRESS")
		PickupBagFromSlot(Bagnon_GetInvSlot(bagID))
	end
end

function BagnonBag:OnShow()
	if self:GetID() > 0 and self:GetParent() then
		self:UpdateTexture()
	end
end

--tooltip functions
function BagnonBag:OnEnter()
	local frame = self:GetParent():GetParent()
	local player = frame:GetPlayer()
	local bagID = self:GetID()

	frame:HighlightBag(bagID, true)

	Bagnon_AnchorTooltip(self)

	--mainmenubag specific code
	local cached = Bagnon_IsCachedBag(player, bagID)
	if bagID == 0 then
		GameTooltip:SetText(TEXT(BACKPACK_TOOLTIP), 1, 1, 1)
	elseif bagID == -1 then
		GameTooltip:SetText('Bank', 1, 1, 1)
	--keyring specific code...again
	elseif bagID == KEYRING_CONTAINER then
		GameTooltip:SetText(KEYRING, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	--cached bags
	elseif cached then
		local link = select(2, BagnonDB.GetBagData(frame:GetPlayer(), bagID))
		if link then
			GameTooltip:SetHyperlink(link)
		else
			GameTooltip:SetText(TEXT(EQUIP_CONTAINER), 1, 1, 1)
		end
	elseif not GameTooltip:SetInventoryItem('player', Bagnon_GetInvSlot(bagID)) then
		GameTooltip:SetText(TEXT(EQUIP_CONTAINER), 1, 1, 1)
	end

	local sets = Bagnon_GetPlayerSets()
	if sets.showTooltips then
		if frame:HasBag(bagID) then
			GameTooltip:AddLine(BAGNON_BAGS_HIDE)
		else
			GameTooltip:AddLine(BAGNON_BAGS_SHOW)
		end
	end
	GameTooltip:Show()
end

function BagnonBag:OnLeave()
	local frame = self:GetParent():GetParent()
	frame:HighlightBag(self:GetID(), nil)

	GameTooltip:Hide()
end