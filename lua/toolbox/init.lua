local M = {}
local H = {}

H.filter_commands = function(filter)
	if filter == nil then
		return H.opts.commands
	end

	local filtered = {}
	for _, command in ipairs(H.opts.commands) do
		if filter(command) then
			table.insert(filtered, command)
		end
	end
	return filtered
end

H.find_command = function(name)
	for _, command in ipairs(H.opts.commands) do
		if command.name == name then
			return command
		end
	end
	return nil
end

function M.setup(opts)
	opts = vim.tbl_extend("force", {
		commands = {},
	}, opts or {})

	table.sort(opts.commands, function(a, b)
		if a.weight ~= nil or b.weight ~= nil then
			-- Higher weight should be shown first
			-- hence descending sort
			return (a.weight or 0) > (b.weight or 0)
		end
		return string.upper(a.name) < string.upper(b.name)
	end)

	H.opts = opts
end

function M.run(name)
	local command = H.find_command(name)
	if command == nil then
		error("Command " .. name .. " is not found", 0)
	end

	local execute = command.execute
	if execute == nil or type(execute) ~= "function" then
		error("Command has unsupported function type", 0)
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

function M.show_picker(filter, select_opts)
	local mode = vim.api.nvim_get_mode()["mode"]
	local isVisual = mode == "v" or mode == "V" or mode == "\22"
	local startpos = vim.fn.getpos("v")
	local endpos = vim.fn.getpos(".")
	vim.api.nvim_buf_set_mark(startpos[1], "<", startpos[2], startpos[3], {})
	vim.api.nvim_buf_set_mark(endpos[1], ">", endpos[2], endpos[3], {})

	select_opts = vim.tbl_extend("force", {
		prompt = "Toolbox",
		format_item = function(command)
			return command.name
		end,
	}, select_opts or {})

	vim.ui.select(H.filter_commands(filter), select_opts, function(command)
		if command == nil then
			return
		elseif command.execute == nil then
			error("Command " .. command.name .. " has no function to execute", 0)
		end

		local execute = command.execute
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
						.. command.name
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
		elseif type(execute) == "string" then
			local cmdPrefix = ":"
			if isVisual then
				cmdPrefix = cmdPrefix .. "'<,'>"
			end

			if command.require_input then
				vim.api.nvim_feedkeys(cmdPrefix .. execute, "m", false)
				return
			end
			local ok, res = pcall(vim.cmd, cmdPrefix .. execute)
			if not ok then
				error(res, 0)
			end
		else
			error("Command has unsupported function type", 0)
		end
	end)
end

return M
