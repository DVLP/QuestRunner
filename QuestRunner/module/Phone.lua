-- (c)1dentity - part of Quest Runner custom mission framework
	-- multi-accounts
	-- per-contact callbacks for phone calls
	-- support for new contact list type
	-- new hack to get JournalNotificationQueue instance after mod reload

local log, logError, trace = table.unpack(require("module/Log"))
local Cron = require("lib/Cron")

Phone = {
	contactList = {},
	journalQ = nil,
	bar = nil,
	disablePreventionSystem = false,
	noConnectionMessage = ""
}

function Phone.init()
	Observe("JournalNotificationQueue", "OnMenuUpdate", function(this) Phone.journalQ = this end)
	Observe("JournalNotificationQueue", "OnPlayerAttach", function(this) Phone.journalQ = this end)
	Observe("JournalNotificationQueue", "OnInitialize", function(this) Phone.journalQ = this end)
	-- regain ref after mod reload - don't ask
	Observe("ShardCollectedInventoryCallback", "OnItemQuantityChanged", function(this) Phone.journalQ = this.notificationQueue end)
	Cron.After(0.1, function() Game.AddToInventory("Items.money", 0) end)

	Override("PreventionSystem", "OnAttach", function(this, wrapped)
		if Phone.disablePreventionSystem then return end
		wrapped()
	end)

	Override("PhoneDialerLogicController", "PopulateListData", function(this, contactDataArray, selectIndex, itemHash, wrapped)
		local listType = #contactDataArray > 0 and contactDataArray[1].type or MessengerContactType.Contact
		if listType == MessengerContactType.SingleThread or listType == MessengerContactType.MultiThread then listType = MessengerContactType.SingleThread end

		-- when pressing R on contact list a temporary list opens with one entry which automatically clicks
		if #contactDataArray == 0 then listType = MessengerContactType.SingleThread end

		-- dont add to the list with one entry - it's a temporary with a single thread
		if #contactDataArray ~= 1 then
			for _, contact in pairs(Phone.contactList) do

				local alreadyListed = false
				for _, existingContact in pairs(contactDataArray) do
					if existingContact.localizedName == contact.localizedName then alreadyListed = true end
				end

				if not alreadyListed then
					local c = ContactData.new()
					c.id = "trainer_fred"
					c.contactId = c.id
					c.avatarID = TweakDBID.new("PhoneAvatars.Avatar_Unknown") -- no need to set

					c.localizedName = contact.localizedName
					c.localizedPreview = contact.localizedPreview
					c.questRelated = contact.questRelated
					c.hasQuestImportantReply = contact.hasQuestImportantReply
					c.lastMesssagePreview = contact.localizedPreview
					c.hasMessages = #contact.messages ~= 0
					c.unreadMessegeCount = #contact.messages
					c.messagesCount = #contact.messages
					c.repliesCount = 0
					c.unreadMessages = #contact.messages ~= 0 and {1} or nil -- {1,2,3,4} how to link?
					-- c.activeDataSync: wref<MessengerContactSyncData>
					c.threadsCount = 1
					-- c.playerCanReply = true
					c.hash = contact.hash
					c.timeStamp = contact.timeStamp
					c.type = listType
					c.hasValidTitle = true
					c.isCallable = contact.isCallable
					table.insert(contactDataArray, c)
				end
			end
		end
		this.dataView:EnableSorting()
		this.dataSource:Reset(contactDataArray)
		this.dataView:DisableSorting()
		this.firstInit = true

		local indexToSelect = selectIndex
		if itemHash ~= 0 then indexToSelect = ContactDataHelper.IndexOfOrZero(this.dataView, itemHash) end
		this.indexToSelect = indexToSelect
	end)

	-- Replace name from "Coach Fred" to the valid one
	ObserveAfter("HudPhoneAvatarController", "RefreshView", function(this)
		if not Phone.replaceDialedName then return end
		local root = this:GetRootWidget()
		-- For some reason the text ref in the avatar class does not work
		local text = root:GetWidgetByPath(BuildWidgetPath({ "phoneAvatarDisplay", "avatarGroup", "holocall_holder", "vertpan9", "horiconnection2", "NewContactName" })) 
		if not text then text = root:GetWidgetByPath(BuildWidgetPath({ "phoneAvatarDisplay", "avatarGroup", "holocall_holder", "inkVerticalPanelWidget7", "horizontal connection", "contactNameText" })) end
		text:SetText(Phone.replaceDialedName)
	end)

	ObserveAfter("MessengerGameController", "OnUninitialize", function()
		Phone.cleanUp(true)
	end)

	-- Injecting contacts
	Override("MessengerUtils", "GetSimpleContactDataArray;JournalManagerBoolBoolBoolMessengerContactSyncData", function (journal, includeUnknown, skipEmpty, includeWithNoUnread, activeDataSync, wrapped)
		local data = wrapped(journal, includeUnknown, skipEmpty, includeWithNoUnread, activeDataSync)

		if includeWithNoUnread == true then
			for id, contactSrc in pairs(Phone.contactList) do
				if #contactSrc.messages > 0 then
					local contact = ContactData.new()
					contact.hash = math.random(999999999)
					contact.localizedName = contactSrc.localizedName
					contact.id = contactSrc.id
					contact.contactId = contactSrc.id
					contact.isCallable = true
					contact.type = MessengerContactType.SingleThread
					contact.avatarID = TweakDBID.new("PhoneAvatars.Avatar_Unknown")
					contact.localizedPreview = contactSrc.secondLine
					contact.hasValidTitle = true

					local d = Game.GetTimeSystem():GetGameTime():Days()
					local h = Game.GetTimeSystem():GetGameTime():Hours()
					local m = Game.GetTimeSystem():GetGameTime():Minutes()

					contact.timeStamp = GameTime.MakeGameTime(d, h, m, 0)
					table.insert(data, contact)
				end
			end
		end

		return data
	end)

	Override("MessangerItemRenderer", "OnJournalEntryUpdated", function (this, entry, extra, wrapped)
		wrapped(entry, extra)
		for _, contact in pairs(Phone.contactList) do
			for _, val in ipairs(contact.messages) do
				if val.id == entry.id then
					this:SetMessageView(
						val.message,
						MessageViewType.Received,
						contact.localizedName
					)
				end
			end
		end
	end)

	Override("PhoneMessagePopupGameController", "OnInitialize", function (this, wrapped)
		wrapped()
		local contact = Phone.getContactByDisplayName(this.data.contactNameLocKey.value)
		if contact then
			this.data.journalEntry = JournalContact.new()
			this.data.journalEntry.id = contact.id
			this:SetupData()
		end
	end)

	Override("PhoneMessagePopupGameController", "OnRefresh", function (this, event, wrapped)
		local contact = Phone.getContactByDisplayName(event.data.contactNameLocKey.value)
		if contact then
			this.data = event.data
			this.data.journalEntry = JournalContact.new()
			this.data.journalEntry.id = contact.id
			this:SetupData()
		else		
			wrapped(event)
		end
	end)

	-- Insert custom messages / replies
	ObserveAfter("MessengerDialogViewController", "UpdateData;BoolBool", function (this, a, _, _)
		for id, contact in pairs(Phone.contactList) do
			if this.parentEntry and this.parentEntry.id == contact.id then
				local countMessages
				local lastMessageWidget

				local messages = {}
				for _, val in pairs(contact.messages) do
					local entry = JournalPhoneMessage.new()
					entry.id = val.id
					table.insert(messages, entry)
				end

				this.messages = messages

				-- Vanilla stuff
				inkWidgetRef.SetVisible(this.replayFluff, #this.replyOptions > 0)
				this:SetVisited(this.messages)
				this.messagesListController:Clear()
				this.messagesListController:PushEntries(this.messages)

				this.choicesListController:Clear()
				this.choicesListController:PushEntries(this.replyOptions)

				if #(this.replyOptions) > 0 then
					this.choicesListController:SetSelectedIndex(0)
				end

				if IsDefined(this.newMessageAninmProxy) then
					this.newMessageAninmProxy:Stop()
				end

				countMessages = this.messagesListController:Size()

				if a and countMessages > 0 then
					lastMessageWidget = this.messagesListController:GetItemAt(countMessages - 1)
				end

				if IsDefined(lastMessageWidget) then
					this.newMessageAninmProxy = this:PlayLibraryAnimationOnAutoSelectedTargets("new_message", lastMessageWidget)
				end

				this.scrollController:SetScrollPosition(1.00)

				-- revert keeping the contact on top after reading
				contact.hasQuestImportantReply = false
				-- go back to generic second line
				contact.localizedPreview = contact.secondLine
			end
		end
	end)

	Observe("HUDProgressBarController", "OnInitialize", function(this) Phone.bar = this end)
	Observe("HUDProgressBarController", "Intro", function(this) Phone.bar = this end)

	Observe("NewHudPhoneGameController", "CallSelectedContact", function(this, contactData)
		local contact = Phone.getContactByDisplayName(contactData.localizedName)

		if contact then
			if not contact.callback then
				log("Phone: No action for call assigned for", contact.localizedName)
				return
			end
			Phone.replaceDialedName = contactData.localizedName
			if EnumInt(Game.GetScriptableSystemsContainer():Get("PreventionSystem"):GetHeatStage()) == 0 then
				Cron.After(2.5, function()
					local action = contact.callback()
					if not action and Phone.bar then
						-- if callback doesn't return true show "failed" popup
						Phone.bar:OnActivated(true)
						Phone.bar:UpdateTimerHeader(Phone.noConnectionMessage)
						Phone.bar:OnActivated(false)
					end
					Phone.disablePreventionSystem = true
				end)
			end

			Cron.After(5, function()
				Game.GetScriptableSystemsContainer():Get("PhoneSystem"):QueueRequest(PhoneTimeoutRequest.new())
				Phone.replaceDialedName = nil
			end)

			Cron.After(7, function()
				Phone.disablePreventionSystem = false
			end)
		end
	end)

	Cron.Every(1, function()
	end)
end

function Phone.getContactByDisplayName(localizedName)
	for _, contact in pairs(Phone.contactList) do
		if contact.localizedName == localizedName then return contact end
	end
	return nil
end

function Phone.setContactProperty(nameId, property, value)
	local contact = Phone.contactList[nameId]
	if not contact then log("Phone.setContactProperty: no such contact", nameId) end
	contact[property] = value
end

function Phone.RegisterCallCallback(nameId, callback)
	if not Phone.contactList[nameId] then
		log("Phone: use addContact before RegisterCallCallback for", nameId)
		return
	end
	Phone.contactList[nameId].callback = callback
	-- Phone.contactList[nameId].isCallable = callback and true or false
end

function Phone.showNewContactNotification(title, name, duration)
	if not Phone.journalQ then return end
	local notificationData = gameuiGenericNotificationData.new()
	local userData = QuestUpdateNotificationViewData.new()
	userData.title = title
	userData.text = name
	userData.animation = "notification_newContactAdded"
	userData.soundEvent = "QuestUpdatePopup"
	userData.soundAction = "OnOpen"
	notificationData.time = duration
	notificationData.widgetLibraryItemName = "notification_NewContactAdded"
	notificationData.notificationData = userData
	Phone.journalQ:AddNewNotificationData(notificationData)
end

function Phone.addContact(nameId, localizedName, secondLine)
	if Phone.contactList[nameId] then return false end
	CName.add(nameId)
	local isNew = false
	if Game.GetQuestsSystem():GetFactStr(nameId .. "_contact_added") == 0 then
		Game.GetQuestsSystem():SetFactStr(nameId .. "_contact_added", 1)
		Phone.saveLastMessageTime(nameId)
		isNew = true
	end
	local t = Game.GetTimeSystem():GetGameTime()
	Phone.contactList[nameId] = { id = nameId, secondLine = secondLine, localizedName = localizedName, hash = math.random(9999999999999), time = t, messages = {} }	
	return isNew
end

function Phone.saveLastMessageTime(nameId)
	local t = Game.GetTimeSystem():GetGameTime()
	Game.GetQuestsSystem():SetFactStr(nameId .. "_d", t:Days())
	Game.GetQuestsSystem():SetFactStr(nameId .. "_h", t:Hours())
	Game.GetQuestsSystem():SetFactStr(nameId .. "_m", t:Minutes())
end

function Phone.getLastMessageTime(nameId)
	local d = Game.GetQuestsSystem():GetFactStr(nameId .. "_d")
	local h = Game.GetQuestsSystem():GetFactStr(nameId .. "_h")
	local m = Game.GetQuestsSystem():GetFactStr(nameId .. "_m")
	return GameTime.MakeGameTime(d, h, m, 0)
end

function Phone.cleanUp(soft)
	if not soft then
		Phone.journalQ = nil
		Phone.bar = nil
		Phone.contactList = {}
	end
	Phone.replaceDialedName = nil
end

function Phone.sendMessage(nameId, message, suppressNotification)
	local contact = Phone.contactList[nameId]
	if not contact then
		logError("Phone: Contact does not exist", nameId)
		return
	end
	if not suppressNotification then
		local notificationData = gameuiGenericNotificationData.new()
		local openAction = OpenPhoneMessageAction.new()

		openAction.phoneSystem = Game.GetScriptableSystemsContainer():Get("PhoneSystem")

		local contactj = JournalContact.new()

		contactj.id = contact.id
		openAction.journalEntry = contactj

		local userData = PhoneMessageNotificationViewData.new()

		userData.title = contact.localizedName
		userData.SMSText = message
		userData.action = openAction
		userData.animation = CName("notification_phone_MSG")
		userData.soundEvent = CName("PhoneSmsPopup")
		userData.soundAction = CName("OnOpen")
		notificationData.time = 5
		notificationData.widgetLibraryItemName = CName("notification_message")
		notificationData.notificationData = userData
		-- bring to the top of the list
		contact.hasQuestImportantReply = true
		-- change second line to message preview
		contact.localizedPreview = message

		if Phone.journalQ then Phone.journalQ:AddNewNotificationData(notificationData) end
	end

	local str = contact.id .. #contact.messages
	table.insert(contact.messages, {
		id = str,
		message = message,
	})
end

return Phone
