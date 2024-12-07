local M = {}

function M.setup(opts)
	opts = opts or {}
	local commands = opts.commands or {}
	table.sort(opts.commands, function(a, b)
		if a.weight ~= nil or b.weight ~= nil then
			-- Higher weight should be shown first
			-- hence descending sort
			return (a.weight or 0) > (b.weight or 0)
		end
		return string.upper(a.name) < string.upper(b.name)
	end)

	M.commandMap = {}
	M.tagToCommandList = {}
	M.tagToCommandList[""] = {}
	for _, command in ipairs(commands) do
		M.commandMap[command.name] = {
			execute = command.execute,
			require_input = command.require_input or false,
		}
		table.insert(M.tagToCommandList[""], command.name)
		for _, tag in ipairs(command.tags or {}) do
			if M.tagToCommandList[tag] == nil then
				M.tagToCommandList[tag] = {}
			end
			table.insert(M.tagToCommandList[tag], command.name)
		end
	end
end

function M.run(name)
	local execute = M.commandMap[name].execute
	if execute == nil or type(execute) ~= "function" then
		error("Unknown or unexecutable command", 0)
	end
	return {
		withArgs = function(...)
			local ok, res = pcall(execute, ...)
			if not ok then
				error(res, 0)
			end
		end,
	}
end

function M.show_picker(tag)
	local mode = vim.api.nvim_get_mode()["mode"]
	local isVisual = mode == "v" or mode == "V" or mode == "\22"
	local startpos = vim.fn.getpos("v")
	local endpos = vim.fn.getpos(".")
	vim.api.nvim_buf_set_mark(startpos[1], "<", startpos[2], startpos[3], {})
	vim.api.nvim_buf_set_mark(endpos[1], ">", endpos[2], endpos[3], {})

	if tag == nil then
		tag = ""
	end
	if M.tagToCommandList[tag] == nil then
		error("Commands with the tag '" .. tag .. "' do not exist")
		return
	end

	local promptTitle = "Toolbox"
	if tag ~= "" then
		promptTitle = promptTitle .. " <" .. tag .. ">"
	end

	vim.ui.select(M.tagToCommandList[tag], {
		prompt = promptTitle,
	}, function(choice)
		if choice == nil then
			return
		end

		local execute = M.commandMap[choice].execute
		if execute == nil then
			return
		end

		if type(execute) == "function" then
			local numParams = debug.getinfo(execute).nparams
			if numParams > 0 then
				local hintText = " -- " .. numParams
				if numParams > 1 then
					hintText = hintText .. " args required"
				else
					hintText = hintText .. " arg required"
				end
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes(":lua require('toolbox').run(\"", true, false, true)
						.. choice
						.. vim.api.nvim_replace_termcodes(
							'").withArgs()' .. hintText .. string.rep("<Left>", string.len(hintText) + 1),
							true,
							false,
							true
						),
					"m",
					false
				)
				return
			end
			local ok, res = pcall(execute)
			if not ok then
				error(res, 0)
			end
			return
		end

		if type(execute) == "string" then
			local cmdPrefix = ":"
			if isVisual then
				cmdPrefix = cmdPrefix .. "'<,'>"
			end

			if M.commandMap[choice].require_input then
				vim.api.nvim_feedkeys(cmdPrefix .. execute, "m", false)
				return
			end
			local ok, res = pcall(vim.cmd, cmdPrefix .. execute)
			if not ok then
				error(res, 0)
			end
		end
	end)
end

return M
