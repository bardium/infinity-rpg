--[[
CREDITS:
UI Library: Inori & wally
Script: bardium
]]

repeat
	task.wait()
until game:IsLoaded()

local start = tick()
local client = game:GetService('Players').LocalPlayer
local executor = identifyexecutor and identifyexecutor() or 'Unknown'

local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/LinoriaLib/main/Library.lua'))()
local themeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/LinoriaLib/main/addons/ThemeManager.lua'))()

local metadata = loadstring(game:HttpGet('https://raw.githubusercontent.com/bardium/infinity-rpg/main/metadata.lua'))()
local httpService = game:GetService('HttpService')
local repStorage = game:GetService('ReplicatedStorage')

local clientData, mobs, gameAmmunition
local counter = 0

while true do
	if typeof(mobs) ~= 'Instance' then
		for _, obj in next, workspace:GetChildren() do
			if obj.Name == 'Mobs' and obj:IsA('Folder') then 
				mobs = obj
			end
		end
	end

	if typeof(clientData) ~= 'Instance' then
		for _, obj in next, repStorage:GetChildren() do
			if obj.Name == 'PlayerData' and obj:IsA('Configuration') then 
				if obj:FindFirstChild(tostring(client.UserId)) then
					clientData = obj:FindFirstChild(tostring(client.UserId))
				end
			end
		end
	end
	
	if typeof(gameAmmunition) ~= 'Instance' then
		for _, obj in next, repStorage:GetChildren() do
			if obj.Name == 'GameAmmunition' and obj:IsA('Folder') and obj:FindFirstChild('Arrows') and obj:FindFirstChild('Bullets') then 
				gameAmmunition = obj
			end
		end
	end

    if (typeof(clientData) == 'Instance' and typeof(mobs) == 'Instance' and typeof(gameAmmunition) == 'Instance') then
        break
    end

    counter = counter + 1
    if counter > 6 then
        client:Kick(string.format('Failed to load game dependencies. Details: %s, %s, %s', typeof(clientData), typeof(mobs), typeof(gameAmmunition)))
    end
    task.wait(1)
end

local runService = game:GetService('RunService')
local virtualInputManager = game:GetService("VirtualInputManager")

local random = Random.new()

do
	if shared._unload then
		pcall(shared._unload)
	end

	function shared._unload()
		if shared._id then
			pcall(runService.UnbindFromRenderStep, runService, shared._id)
		end

		UI:Unload()

		for i = 1, #shared.threads do
			coroutine.close(shared.threads[i])
		end

		for i = 1, #shared.callbacks do
			task.spawn(shared.callbacks[i])
		end
	end

	shared.threads = {}
	shared.callbacks = {}

	shared._id = httpService:GenerateGUID(false)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.AutoHeal) and (Toggles.AutoHeal.Value)) then
				if client.Character:IsDescendantOf(workspace) and client.Character:FindFirstChild('Humanoid') and client.Character.Humanoid.Health < ((Options.HealPercentage.Value / 100 * client.Character.Humanoid.MaxHealth) - 1) then
					local oldPivot = client.Character:GetPivot()
					shared.healing = true
					if workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('HealPart', true) then
						repeat
							client.Character:PivotTo(workspace.Map:FindFirstChild('HealPart', true):GetPivot() * CFrame.new(random:NextNumber(-3, 3), random:NextNumber(-1, 1), random:NextNumber(-3, 3)))
							task.wait()
						until not client.Character:IsDescendantOf(workspace) or not client.Character:FindFirstChild('Humanoid') or client.Character.Humanoid.Health >= ((Options.HealPercentage.Value / 100 * client.Character.Humanoid.MaxHealth) - 1) or ((not Toggles.AutoHeal) or (not Toggles.AutoHeal.Value))
					else
						repeat
							client.Character:PivotTo(CFrame.new(941, 1, 1089) * CFrame.new(random:NextNumber(-3, 3), random:NextNumber(-1, 1), random:NextNumber(-3, 3)))
							task.wait()
						until not client.Character:IsDescendantOf(workspace) or not client.Character:FindFirstChild('Humanoid') or client.Character.Humanoid.Health >= ((Options.HealPercentage.Value / 100 * client.Character.Humanoid.MaxHealth) - 1) or ((not Toggles.AutoHeal) or (not Toggles.AutoHeal.Value))
					end
					shared.healing = false
					client.Character:PivotTo(oldPivot)
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.KillAura) and (Toggles.KillAura.Value)) then
				if client.Character:IsDescendantOf(workspace) and workspace:FindFirstChild('Mobs') then
					local closestMob = mobs:FindFirstChildOfClass('Model')
					for _, v in next, mobs:GetChildren() do
						if v:IsA('Folder') then
							for _, mob in next, v:GetChildren() do
								if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= clientData.Level.Value and (client.Character:GetPivot().Position - mob:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude and mob:FindFirstChildOfClass('Humanoid') then
									closestMob = mob
								end
							end
						end
						if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= clientData.Level.Value and v:FindFirstChildOfClass('Humanoid') and v:IsA('Model') then
							if (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
								closestMob = v
							end
						end
					end
					local weaponType = 'Melee'
					if not client.Character:FindFirstChildOfClass('Tool') or not client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig') then
						virtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, nil)
						virtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, nil)
						repeat task.wait() until (client.Character:FindFirstChildOfClass('Tool') and client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig')) or ((not Toggles.KillAura) or (not Toggles.KillAura.Value))
					else
						weaponType = tostring(require(client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig')).Type)
						local args = nil
						if weaponType == 'Ranged' then
							local ammoTypes = require(client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig')).AmmoType
							for _, folder in next, gameAmmunition:GetChildren() do
								for _, possibleAmmo in next, folder:GetChildren() do
									if clientData.Ammunition:FindFirstChild(possibleAmmo.Name) and possibleAmmo:FindFirstChild('AmmoConfig') and table.find(ammoTypes, require(possibleAmmo.AmmoConfig).Type) then
										args = possibleAmmo.Name
									end
								end
							end
							if args == nil then
								UI:Notify('You do not have the right ammo for this weapon. Please buy the correct ammo or use a different weapon.', 30)
								Toggles.KillAura:SetValue(false)
							end
						end
						if closestMob:IsDescendantOf(workspace) and closestMob:FindFirstChildOfClass('Humanoid') then
							if repStorage.GameRemotes:FindFirstChild('Damage'..weaponType) and repStorage.GameRemotes:FindFirstChild('Damage'..weaponType):IsA('RemoteFunction') then
								task.spawn(function()
									repStorage.GameRemotes:FindFirstChild('Damage'..weaponType):InvokeServer(closestMob, args)
								end)
							end
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

do
	local thread = task.spawn(function()
		while true do
			task.wait()
			if ((Toggles.TeleportToMobs) and (Toggles.TeleportToMobs.Value)) then
				if client.Character:IsDescendantOf(workspace) then
					local closestMob = nil
					if (Options.TargetMobs.Value) == 'Closest mob' then -- or not mobs:FindFirstChild(tostring(Options.TargetMob.Value))
						closestMob = mobs:FindFirstChildOfClass('Model')
						for _, v in next, mobs:GetChildren() do
							if v:IsA('Folder') then
								for _, mob in next, v:GetChildren() do
									if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= clientData.Level.Value and (client.Character:GetPivot().Position - mob:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude and mob:FindFirstChildOfClass('Humanoid') then
										closestMob = mob
									end
								end
							end
							if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= clientData.Level.Value and v:FindFirstChildOfClass('Humanoid') and (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
								closestMob = v
							end
						end
					elseif (Options.TargetMobs.Value) == 'Highest level possible mob' then
						local highestLevel = -1
						for _, v in next, mobs:GetChildren() do
							if v:IsA('Folder') then
								for _, mob in next, v:GetChildren() do
									if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= clientData.Level.Value and mob:FindFirstChildOfClass('Humanoid') and mob:FindFirstChildWhichIsA('BasePart') and mob:FindFirstChild('MobConfig') and mob.MobConfig:IsA('ModuleScript') and type(require(mob.MobConfig)) == 'table' and type(require(mob.MobConfig).MobLevel) == 'number' then
										if closestMob == nil then
											closestMob = mob
											highestLevel = require(mob.MobConfig).MobLevel
										else
											if require(mob.MobConfig).MobLevel > highestLevel then
												highestLevel = require(mob.MobConfig).MobLevel
												closestMob = mob
											end
										end
									end
								end
							end
							if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= clientData.Level.Value and v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildWhichIsA('BasePart') and v:FindFirstChild('MobConfig') and v.MobConfig:IsA('ModuleScript') and type(require(v.MobConfig)) == 'table' and type(require(v.MobConfig).MobLevel) == 'number' then
								if closestMob == nil then
									closestMob = v
									highestLevel = require(v.MobConfig).MobLevel
								else
									if require(v.MobConfig).MobLevel > highestLevel then
										highestLevel = require(v.MobConfig).MobLevel
										closestMob = v
									end
								end
							end
						end
					else
						closestMob = mobs:FindFirstChild(tostring(Options.TargetMobs.Value), true)
					end
					if closestMob ~= nil and closestMob:IsDescendantOf(mobs) and closestMob:FindFirstChildOfClass('Humanoid') and typeof(closestMob:GetPivot()) == 'CFrame' and typeof(closestMob:GetExtentsSize()) == 'Vector3' and closestMob:FindFirstChildWhichIsA('BasePart') then
						if not shared.healing then
							--local size = closestMob:GetExtentsSize()
							--local offset = Vector3.new(size.X / 2, size.Y / 2, size.Z / 2)
							local offset = Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
							client.Character:PivotTo(CFrame.new(closestMob:GetPivot().Position + offset))
						end
					end
				end
			end
		end
	end)
	table.insert(shared.callbacks, function()
		pcall(task.cancel, thread)
	end)
end

local function addRichText(label)
	label.TextLabel.RichText = true
end

local Window = UI:CreateWindow({
	Title = string.format('infinity rpg - version %s | updated: %s', metadata.version, metadata.updated),
	AutoShow = true,

	Center = true,
	Size = UDim2.fromOffset(550, 567),
})

local Tabs = {}
local Groups = {}

Tabs.Main = Window:AddTab('Main')
Tabs.UISettings = Window:AddTab('UI Settings')

Groups.Main = Tabs.Main:AddLeftGroupbox('Main')
Groups.Main:AddToggle('AutoHeal', { Text = 'Auto heal', Default = true })
Groups.Main:AddSlider('HealPercentage', { Text = 'Heal percentage', Min = 0, Max = 100, Default = 50, Suffix = '%', Rounding = 0, Compact = true, Tooltip = 'Minimum percentage of hp to start healing at' })
Groups.Main:AddToggle('KillAura', { Text = 'Kill aura' })
Toggles.KillAura:OnChanged(function()
	if Toggles.KillAura.Value == true then
		if client.Character:FindFirstChildOfClass('Tool') and client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig') then
			local weaponType = 'Unknown'
			weaponType = tostring(require(client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig')).Type)

			if weaponType ~= 'Melee' and weaponType ~= 'Ranged' then
				UI:Notify('Kill aura may not work on ' .. tostring(weaponType) .. ' weapons. Kill Aura has only been tested on melee and ranged.', 15)
			end
			if weaponType == 'Ranged' then
				UI:Notify('Make sure you have enough ammunition for the type of ranged weapon you are going to use.', 15)
			end
		end
	end
end)
Groups.Main:AddToggle('TeleportToMobs', { Text = 'Teleport to mob' })
local function GetMobsString()
	local MobList = {}

	for _, v in next, mobs:GetChildren() do
		if v:IsA("Folder") then
			for _, mob in next, v:GetChildren() do
				if
					mob:IsA("Model")
					and v:FindFirstChildOfClass("Humanoid")
					and mob:FindFirstChildWhichIsA("BasePart")
				then
					table.insert(MobList, mob)
				end
			end
		elseif v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v:FindFirstChildWhichIsA("BasePart") then
			table.insert(MobList, v)
		end
	end

	local uniqueMobs = {}
	local finalMobList = {}

	for _, v in next, MobList do
		local mobString = tostring(v)
		if not uniqueMobs[mobString] then
			table.insert(finalMobList, v)
			uniqueMobs[mobString] = true
		end
	end

	MobList = finalMobList

	table.sort(MobList, function(str1, str2)
		if
			typeof(str1) == "Instance"
			and typeof(str2) == "Instance"
			and str1:FindFirstChild("LevelKillReq")
			and str2:FindFirstChild("LevelKillReq")
		then
			return str1:FindFirstChild("LevelKillReq").Value < str2:FindFirstChild("LevelKillReq").Value
		else
			return tostring(str1) > tostring(str2)
		end
	end)

	for i, v in next, MobList do
		MobList[i] = tostring(v)
	end
	local newValues = { "Closest mob", "Highest level possible mob" }

	for i, v in next, MobList do
		newValues[#newValues + 1] = MobList[i]
	end

	MobList = newValues

	return MobList
end

Groups.Main:AddDropdown("TargetMobs", {
	Text = "Target mob",
	AllowNull = true,
	Compact = false,
	Values = GetMobsString(),
	Default = "Closest mob",
	Callback = function(Mob)
		if mobs:FindFirstChild(tostring(Mob), true) and mobs:FindFirstChild(tostring(Mob), true):FindFirstChild("LevelKillReq") and mobs:FindFirstChild(tostring(Mob), true).LevelKillReq.Value > clientData.Level.Value
		then
			UI:Notify(
				string.format(
					"The mob will not take damage as your level is too low to damage it. \n Your level: %s \n Mob level: %s",
					tostring(clientData.Level.Value),
					tostring(mobs:FindFirstChild(tostring(Mob), true).LevelKillReq.Value)
				),
				3
			)
		end
	end,
})
Groups.Main:AddButton("Update target mobs", function()
	local TargetMobs = GetMobsString()

	Options.TargetMobs:SetValues(TargetMobs)
end)

--[[
Auto update target mobs:

local function OnMobsChanged()
	local MobList = GetMobsString();
	Options.TargetMob:SetValues(MobList);
end;

mobs.ChildAdded:Connect(OnMobsChanged);
mobs.ChildRemoved:Connect(OnMobsChanged);
for _, v in next, mobs:GetChildren() do
	v.ChildAdded:Connect(OnMobsChanged);
	v.ChildRemoved:Connect(OnMobsChanged);
end
]]

Groups.Main:AddSlider('YOffset', { Text = 'Height offset', Min = -50, Max = 50, Default = 7, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Height offset when teleporting to mobs' })
Groups.Main:AddSlider('XOffset', { Text = 'X position offset', Min = -50, Max = 50, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'X offset when teleporting to mobs' })
Groups.Main:AddSlider('ZOffset', { Text = 'Z position offset', Min = -50, Max = 50, Default = 0, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Z offset when teleporting to mobs' })

Groups.Credits = Tabs.UISettings:AddRightGroupbox('Credits')

addRichText(Groups.Credits:AddLabel('<font color="#0bff7e">bardium</font> - script'))
addRichText(Groups.Credits:AddLabel('<font color="#3da5ff">wally & Inori</font> - ui library'))

Groups.UISettings = Tabs.UISettings:AddRightGroupbox('UI Settings')
Groups.UISettings:AddLabel('Changelogs:\n' .. metadata.message or 'no message found!', true)
Groups.UISettings:AddDivider()
Groups.UISettings:AddButton('Unload Script', function() pcall(shared._unload) end)
Groups.UISettings:AddButton('Copy Discord', function()
	if pcall(setclipboard, "https://discord.gg/hSm6DyF6X7") then
		UI:Notify('Successfully copied discord link to your clipboard!', 5)
	end
end)

Groups.UISettings:AddLabel('Menu toggle'):AddKeyPicker('MenuToggle', { Default = 'Delete', NoUI = true })

UI.ToggleKeybind = Options.MenuToggle

themeManager:SetLibrary(UI)
themeManager:ApplyToGroupbox(Tabs.UISettings:AddLeftGroupbox('Themes'))

UI:Notify(string.format('Loaded script in %.4f second(s)!', tick() - start), 3)
if executor ~= 'Electron' and executor ~= 'Valyse' then
	UI:Notify(string.format('You may experience problems with the script/UI because you are using %s', executor), 30)
	task.wait()
	UI:Notify(string.format('Exploits this script works well with: Electron and Valyse'), 30)
end
