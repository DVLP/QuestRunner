local subtitle = {
	hudText = nil
}

function subtitle.init()
	Observe("NameplateVisualsLogicController", "OnInitialize", function(this)
		if subtitle.hudText then
			subtitle.hudText:SetVisible(false)
		end

		local label = inkText.new()
		CName.add("custom_subtitle")
		label:SetName('custom_subtitle')
		label:SetFontFamily('base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily')
		label:SetFontStyle('Medium')
		label:SetFontSize(55)
		label:SetLetterCase(textLetterCase.OriginalCase)
		label:SetAnchor(inkEAnchor.Fill)
		label:SetTintColor(HDRColor.new({ Red = 1.1761, Green = 0.3809, Blue = 0.3476, Alpha = 1.0 }))
		label:SetHorizontalAlignment(textHorizontalAlignment.Center)
		label:SetVerticalAlignment(textVerticalAlignment.Top)
		label:SetMargin(inkMargin.new({ left = 0.0, top = 300.0, right = 0.0, bottom = 0.0 }))
		label:SetText("")
		label:SetVisible(false)
		label:Reparent(this:GetRootCompoundWidget().parentWidget.parentWidget.parentWidget.parentWidget.parentWidget, -1)
		subtitle.hudText = label
	end)
end

function subtitle.show(text, size, autohide)
	subtitle._curentText = text
	subtitle._currentSize = size
	subtitle.hideTime = autohide and os.clock() or 0
end

function subtitle.update()
	if not subtitle.hudText then return end -- subtitle.hudText may be empty after mod reload

	if subtitle._curentText then
		if subtitle.hideTime == 0 or (os.clock() - subtitle.hideTime) <= 3 then
			subtitle.hudText:SetFontSize(subtitle._currentSize)
			subtitle.hudText:SetText(subtitle._curentText)
			subtitle.hudText:SetVisible(true)
		else
			subtitle._curentText = nil
			subtitle._currentSize = 55
			subtitle.hideTime = nil
			subtitle.hudText:SetVisible(false)
		end
	else
		subtitle.hudText:SetVisible(false)
	end
end

return subtitle
