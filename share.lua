local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local controls = import('/lua/ui/game/score.lua').controls
local GameMain = import('/lua/ui/game/gamemain.lua')
local Dragger = import('/lua/maui/dragger.lua').Dragger
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local massButtons = {}
local eneButtons = {}
local names = {}
local armies
local massValue = 0.1
local eneValue = 0.5
local currentArmy
local shareWindow
local massPercent
local enePercent

function init()
	shareWindow = Bitmap(GetFrame(0))
	shareWindow.Height:Set(16)
	shareWindow.Width:Set(100)
	shareWindow.Depth:Set(10000)
	shareWindow:SetSolidColor('0f000000')
	local savedPrefs = Prefs.GetFromCurrentProfile("QuickShare")
	if not savedPrefs then
		savedPrefs = {
			Left = 150,
			Top = 150,
		}
		Prefs.SetToCurrentProfile("QuickShare", savedPrefs)
		Prefs.SavePreferences()
	end
	LayoutHelpers.AtLeftTopIn(shareWindow, GetFrame(0), savedPrefs.Left, savedPrefs.Top)
	
	shareWindow.HandleEvent = function(self, event)
		if ((event.Type == 'ButtonPress') and (event.MouseX > (self.Left() + 41))) then
			local drag = Dragger()
			local offX = event.MouseX - self.Left()
			local offY = event.MouseY - self.Top()
			drag.OnMove = function(dragself, x, y)
				self.Left:Set(x - offX)
				self.Top:Set(y - offY)
				GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
			end
			drag.OnRelease = function(dragself)
				local tempPrefs = Prefs.GetFromCurrentProfile("QuickShare")
				tempPrefs.Left = self.Left()
				tempPrefs.Top = self.Top()
				Prefs.SetToCurrentProfile("QuickShare", tempPrefs)
				Prefs.SavePreferences()
				GetCursor():Reset()
				drag:Destroy()
			end
			PostDragger(self:GetRootFrame(), event.KeyCode, drag)
		end
	end
	
	massPercent = UIUtil.CreateText(shareWindow, "Mass: " .. massValue*100 .. "% ", 12, UIUtil.bodyFont, true)
	massPercent.HandleEvent = function (self, event)
		if event.Type == 'ButtonPress' then
			if massValue == 0.1 then massValue = 0.2 
			elseif massValue == 0.2 then massValue = 0.5 
			elseif massValue == 0.5 then 
									massValue = 1 
									self:SetColor('ffff5050')	
			elseif massValue == 1 then 
									massValue = 0.1 
									self:SetColor('ffbadbdb') end
			self:SetText("Mass: " .. massValue*100 .. "% ")
		end
	end
	
	enePercent = UIUtil.CreateText(shareWindow, "Ene: " .. eneValue*100 .. "%", 12, UIUtil.bodyFont, true)
	enePercent.HandleEvent = function (self, event)
		if event.Type == 'ButtonPress' then
			if eneValue == 0.5 then eneValue = 1 
			elseif eneValue == 1 then eneValue = 0.5 end
			self:SetText("Ene: " .. eneValue*100 .. "%")
		end
	end
	
	LayoutHelpers.AtLeftTopIn(massPercent, shareWindow, 1, -20)
	LayoutHelpers.RightOf(enePercent, massPercent)
	
	currentArmy = GetFocusArmy()
	armies = GetArmiesTable().armiesTable
	for i=1,16 do
		names[i] = UIUtil.CreateText(shareWindow, armies[i].nickname, 14, UIUtil.bodyFont, true)
		table.insert(massButtons, Button(shareWindow, '/mods/QuickShare/textures/mass.dds', '/mods/QuickShare/textures/down.dds', '/mods/QuickShare/textures/massH.dds', '/mods/QuickShare/textures/mass.dds', "UI_Menu_MouseDown_Sml", "UI_Menu_MouseDown_Sml"))
		table.insert(eneButtons, Button(shareWindow, '/mods/QuickShare/textures/ene.dds', '/mods/QuickShare/textures/down.dds', '/mods/QuickShare/textures/eneH.dds', '/mods/QuickShare/textures/ene.dds', "UI_Menu_MouseDown_Sml", "UI_Menu_MouseDown_Sml"))
		massButtons[i]:Hide()
		eneButtons[i]:Hide()
		SetupButtons(i)
	end
	
	GameMain.AddBeatFunction(Update)
end

function Update()
	local offset = 0
	for i=1,16 do
		massButtons[i]:Hide()
		eneButtons[i]:Hide()
		names[i]:Hide()
	end
	for armyIndex, armyData in GetArmiesTable().armiesTable do
		if (IsAlly(GetFocusArmy(), armyIndex) and (GetFocusArmy() ~= armyIndex) and (not armyData.outOfGame) and (not armyData.civilian)) then 
			LayoutHelpers.AtLeftTopIn(names[armyIndex], shareWindow, 40, offset)
			LayoutHelpers.AtLeftTopIn(massButtons[armyIndex], shareWindow, 1, offset+1)
			LayoutHelpers.AtLeftTopIn(eneButtons[armyIndex], shareWindow, 21, offset+1)
			shareWindow.Height:Set(17 + offset)
			massButtons[armyIndex]:Show()
			eneButtons[armyIndex]:Show()
			names[armyIndex]:Show()
			offset = offset + 16
		end
	end
end

function SetupButtons(i)	
	massButtons[i].oldHandleEvent = massButtons[i].HandleEvent
	massButtons[i].HandleEvent = function(self, event)
		if event.Type == 'ButtonPress' then
			local eco = GetEconomyTotals()
			print (math.floor(massValue*eco['stored']['MASS']) .. " mass sent to " .. armies[i].nickname)
			SimCallback({Func="GiveResourcesToPlayer", Args={From = currentArmy, To = i, Mass = massValue, Energy = 0}})
		end
		massButtons[i].oldHandleEvent(self, event)
	end
	
	eneButtons[i].oldHandleEvent = eneButtons[i].HandleEvent
	eneButtons[i].HandleEvent = function(self, event)
		if event.Type == 'ButtonPress' then
			local eco = GetEconomyTotals()
			print (math.floor(eneValue*eco['stored']['ENERGY']) .. " energy sent to " .. armies[i].nickname)
			SimCallback({Func="GiveResourcesToPlayer", Args={From = currentArmy, To = i, Mass = 0, Energy = eneValue}})
		end
		eneButtons[i].oldHandleEvent(self, event)
	end
end