--[[
CREDITS:
UI Library: Inori & wally
Script: goosebetter
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

local runService = game:GetService('RunService')
local virtualInputManager = game:GetService("VirtualInputManager")
local repStorage = game:GetService('ReplicatedStorage')

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
					local closestMob = workspace.Mobs:FindFirstChildOfClass('Model')
					for _, v in ipairs(workspace.Mobs:GetChildren()) do
						if v:IsA('Folder') then
							for _, mob in ipairs(v:GetChildren()) do
								if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and (client.Character:GetPivot().Position - mob:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude and mob:FindFirstChildOfClass('Humanoid') then
									closestMob = mob
								end
							end
						end
						if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and v:FindFirstChildOfClass('Humanoid') and v:IsA('Model') then
							if (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
								closestMob = v
							end
						end
					end
					local weaponType = 'Melee'
					if not client.Character:FindFirstChildOfClass('Tool') or not client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig') then
						virtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, nil)
						virtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, nil)
					else
						weaponType = tostring(require(client.Character:FindFirstChildOfClass('Tool'):FindFirstChild('ToolConfig')).Type)
						if weaponType == 'Ranged' then
							UI:Notify('Ranged weapons are currently not supported with this script.', 30)
							Toggles.KillAura:SetValue(false)
						end
						if closestMob:IsDescendantOf(workspace) and closestMob:FindFirstChildOfClass('Humanoid') then
							if repStorage.GameRemotes:FindFirstChild('Damage'..weaponType) and repStorage.GameRemotes:FindFirstChild('Damage'..weaponType):IsA('RemoteFunction') then
								task.spawn(function()
									repStorage.GameRemotes:FindFirstChild('Damage'..weaponType):InvokeServer(closestMob)
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
				if client.Character:IsDescendantOf(workspace) and workspace:FindFirstChild('Mobs') then
					local closestMob = nil
					if (Options.TargetMobs.Value) == 'Closest mob' then -- or not workspace.Mobs:FindFirstChild(tostring(Options.TargetMob.Value))
						closestMob = workspace.Mobs:FindFirstChildOfClass('Model')
						for _, v in ipairs(workspace.Mobs:GetChildren()) do
							if v:IsA('Folder') then
								for _, mob in ipairs(v:GetChildren()) do
									if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and (client.Character:GetPivot().Position - mob:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude and mob:FindFirstChildOfClass('Humanoid') then
										closestMob = mob
									end
								end
							end
							if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and v:FindFirstChildOfClass('Humanoid') and (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
								closestMob = v
							end
						end
					elseif (Options.TargetMobs.Value) == 'Highest level possible mob' then
						local highestLevel = -1
						for _, v in ipairs(workspace.Mobs:GetChildren()) do
							if v:IsA('Folder') then
								for _, mob in ipairs(v:GetChildren()) do
									if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and mob:FindFirstChildOfClass('Humanoid') and mob:FindFirstChildWhichIsA('BasePart') then
										if closestMob == nil then
											closestMob = mob
											highestLevel = mob.LevelKillReq.Value
										else
											if mob.LevelKillReq.Value > highestLevel then
												highestLevel = mob.LevelKillReq.Value
												closestMob = mob
											end
										end
									end
								end
							end
							if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and v:FindFirstChildOfClass('Humanoid') and v.LevelKillReq.Value > highestLevel and v:FindFirstChildWhichIsA('BasePart') then
								if closestMob == nil then
									closestMob = v
									highestLevel = v.LevelKillReq.Value
								else
									if v.LevelKillReq.Value > highestLevel then
										highestLevel = v.LevelKillReq.Value
										closestMob = v
									end
								end
							end
						end
					else
						closestMob = workspace.Mobs:FindFirstChild(tostring(Options.TargetMobs.Value), true)
					end
					if closestMob ~= nil and closestMob:IsDescendantOf(workspace.Mobs) and closestMob:FindFirstChildOfClass('Humanoid') and typeof(closestMob:GetPivot()) == 'CFrame' and typeof(closestMob:GetExtentsSize()) == 'Vector3' and closestMob:FindFirstChildWhichIsA('BasePart') then
						if not shared.healing then
							client.Character:PivotTo(closestMob:GetPivot() * CFrame.new(0, closestMob:GetExtentsSize().Y + (Options.YOffset.Value), 0))
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

			if weaponType ~= 'Melee' then
				UI:Notify('Kill aura may not work on ' .. tostring(weaponType) .. ' weapons. Kill Aura has only been tested on melee.', 15)
			end
		end
	end
end)
Groups.Main:AddToggle('TeleportToMobs', { Text = 'Teleport to mob' })
if workspace:FindFirstChild('Mobs') then
	local function GetMobsString()
		local MobList = {}

		for _, v in ipairs(workspace.Mobs:GetChildren()) do
			if v:IsA('Folder') then
				for _, mob in ipairs(v:GetChildren()) do
					if mob:IsA('Model') and v:FindFirstChildOfClass('Humanoid') and mob:FindFirstChildWhichIsA('BasePart') then
						table.insert(MobList, mob)
					end
				end
			elseif v:IsA('Model') and v:FindFirstChildOfClass('Humanoid') and v:FindFirstChildWhichIsA('BasePart') then
				table.insert(MobList, v)
			end
		end

		local uniqueMobs = {}
		local finalMobList = {}
	
		for _, v in pairs(MobList) do
			local mobString = tostring(v)
			if not uniqueMobs[mobString] then
				table.insert(finalMobList, v)
				uniqueMobs[mobString] = true
			end
		end

		MobList = finalMobList

		table.sort(MobList, function(str1, str2)
			if typeof(str1) == 'Instance' and typeof(str2) == 'Instance' and str1:FindFirstChild('LevelKillReq') and str2:FindFirstChild('LevelKillReq') then
				return str1:FindFirstChild('LevelKillReq').Value < str2:FindFirstChild('LevelKillReq').Value
			else
				return tostring(str1) > tostring(str2)
			end
		end)

		for i, v in pairs(MobList) do
			MobList[i] = tostring(v)
		end
		local newValues = {'Closest mob', 'Highest level possible mob'}

		for i, v in pairs(MobList) do
			newValues[#newValues + 1] = MobList[i]
		end

		MobList = newValues

		return MobList
	end
	Groups.Main:AddDropdown('TargetMobs', {
		Text = 'Target mob',
		AllowNull = true,
		Compact = false,
		Values = GetMobsString(),
		Default = 'Closest mob',
		Callback = function(Mob)
			if typeof(Mob) == 'Instance' and workspace.Mobs:FindFirstChild(tostring(Mob)) and workspace.Mobs[tostring(Mob)]:FindFirstChild('LevelKillReq') and workspace.Mobs[tostring(Mob)].LevelKillReq.Value > repStorage.PlayerData[tostring(client.UserId)].Level.Value then
				UI:Notify(string.format('The mob will not take damage as your level is too low to damage it. \n Your level: %s \n Mob level: %s', tostring(repStorage.PlayerData[tostring(client.UserId)].Level.Value), tostring(workspace.Mobs[Mob].LevelKillReq.Value)), 3)
			end
		end
	})
	Groups.Main:AddButton('Update target mobs', function()
		local TargetMobs = GetMobsString();

		Options.TargetMobs:SetValues(TargetMobs);
	end)
	--[[
	Auto update target mobs:

	local function OnMobsChanged()
		local MobList = GetMobsString();

		Options.TargetMob:SetValues(MobList);
	end;

	workspace.Mobs.ChildAdded:Connect(OnMobsChanged);
	workspace.Mobs.ChildRemoved:Connect(OnMobsChanged);
	for _, v in ipairs(workspace.Mobs:GetChildren()) do
		v.ChildAdded:Connect(OnMobsChanged);
		v.ChildRemoved:Connect(OnMobsChanged);
	end
	]]
end
Groups.Main:AddSlider('YOffset', { Text = 'Y Offset', Min = -25, Max = 25, Default = -13, Suffix = ' studs', Rounding = 1, Compact = true, Tooltip = 'Y Offset when teleporting to mobs' })

Groups.Credits = Tabs.UISettings:AddRightGroupbox('Credits')

addRichText(Groups.Credits:AddLabel('<font color="#0bff7e">Goose Better</font> - script'))
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
