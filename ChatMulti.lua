local v = require(script.Parent.CommonVariables)
local f = require(script.Parent.MyFunctions)


-- == Chat ==

-- ChatMulti: For chat commands, supports parameters
-- Defaults to requiring authorization, case insensitive
local function chatMultiTemplate(text: string, func: (...any) -> (), authReq: boolean)
	if authReq == nil then authReq = true end

	local function connectPlayer(player: Player)
		player.Chatted:Connect(function(msg)
			local command = msg:match("^(%S+)") 
			if not command or command:lower() ~= text:lower() then return end

			local args = {}
			local rest = msg:sub(#command + 1)

			while #rest > 0 do
				rest = rest:match("^%s*(.*)$")
				if #rest == 0 then break end

				if rest:sub(1,1) == '"' then
					local endQuote = rest:find('"', 2)
					if endQuote then
						table.insert(args, rest:sub(2, endQuote - 1))
						rest = rest:sub(endQuote + 1)
					else
						table.insert(args, rest:sub(2))
						rest = ""
					end
				else
					local endSpace = rest:find("%s")
					local content = endSpace and rest:sub(1, endSpace - 1) or rest
					local num = tonumber(content)
					table.insert(args, num or content)
					rest = endSpace and rest:sub(endSpace + 1) or ""
				end
			end

			-- Authorization check
			if not authReq or f.playerAuthorized(player) then
				func(unpack(args))
			else 
				warn("Player not authorized to use command: " .. text)
			end
		end)
	end

	-- ENVIRONMENT CHECK
	if v.RunService:IsServer() then
		
		for _, player in ipairs(v.Players:GetPlayers()) do
			task.spawn(connectPlayer, player)
		end
		v.Players.PlayerAdded:Connect(connectPlayer)
	else
		
		local player = v.Players.LocalPlayer
		if not player then
			v.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			player = v.Players.LocalPlayer
		end
		connectPlayer(player)
	end
end
