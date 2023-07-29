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
local repStorage = game:GetService('ReplicatedStorage')

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
				if client.Character:IsDescendantOf(workspace) and client.Character:FindFirstChild('Humanoid') and client.Character.Humanoid.Health < ((Options.HealPercentage.Value / 100 * client.Character.Humanoid.MaxHealth) - 1) and workspace:FindFirstChild('Map') and workspace.Map:FindFirstChild('HealPart', true) then
					local oldPivot = client.Character:GetPivot()
					shared.healing = true
					repeat
						client.Character:PivotTo(workspace.Map:FindFirstChild('HealPart', true):GetPivot())
						task.wait()
					until not client.Character:IsDescendantOf(workspace) or not client.Character:FindFirstChild('Humanoid') or client.Character.Humanoid.Health >= ((Options.HealPercentage.Value / 100 * client.Character.Humanoid.MaxHealth) - 1) or ((not Toggles.AutoHeal) or (not Toggles.AutoHeal.Value))
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
					if closestMob:IsDescendantOf(workspace) and closestMob:FindFirstChildOfClass('Humanoid') then
						if repStorage.GameRemotes:FindFirstChild('Damage'..tostring(Options.DamageType.Value)) and repStorage.GameRemotes:FindFirstChild('Damage'..tostring(Options.DamageType.Value)):IsA('RemoteFunction') then
							if client.Character:FindFirstChildWhichIsA('Tool') then
								client.Character:FindFirstChildWhichIsA('Tool'):Activate()
							end
							task.spawn(function()
								repStorage.GameRemotes:FindFirstChild('Damage'..tostring(Options.DamageType.Value)):InvokeServer(closestMob)
							end)
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
					local closestMob = workspace.Mobs:FindFirstChildOfClass('Model')
					for _, v in ipairs(workspace.Mobs:GetChildren()) do
						if v:IsA('Folder') then
							for _, mob in ipairs(v:GetChildren()) do
								if mob:FindFirstChild('LevelKillReq') and mob.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and (client.Character:GetPivot().Position - mob:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude and mob:FindFirstChildOfClass('Humanoid') then
									closestMob = mob
								end
							end
						end
						if v:FindFirstChild('LevelKillReq') and v.LevelKillReq.Value <= repStorage.PlayerData[tostring(client.UserId)].Level.Value and v:FindFirstChildOfClass('Humanoid') and v:IsA('Model') and v:FindFirstChildOfClass('Humanoid') then
							if (client.Character:GetPivot().Position - v:GetPivot().Position).Magnitude < (closestMob:GetPivot().Position - client.Character:GetPivot().Position).Magnitude then
								closestMob = v
							end
						end
					end
					if closestMob:IsDescendantOf(workspace) and closestMob:FindFirstChildOfClass('Humanoid') and typeof(closestMob:GetPivot()) == 'CFrame' and typeof(closestMob:GetExtentsSize()) == 'Vector3' then
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
Groups.Main:AddDropdown('DamageType', {
	Text = 'Damage type', 
	Compact = true, 
	Default = 'Melee', 
	Values = { 'Melee', 'Ranged', 'Magic', 'Throwing' }, 
	Tooltip = 'Select the type of weapon you are using.', 
})
Groups.Main:AddToggle('TeleportToMobs', { Text = 'Teleport to mobs' })
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
