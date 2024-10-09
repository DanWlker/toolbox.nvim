local M = {}

function M.setup(opts)
	opts = opts or {}
	local commands = opts.commands or {}

	M.commandMap = {}
	for _, val in ipairs(commands) do
		M.commandMap[val.name] = {
			execute = val.execute,
			require_input = val.require_input or false,
		}
	end

	M.commandKeyList = {}
	for k, _ in pairs(M.commandMap) do
		table.insert(M.commandKeyList, k)
	end
end

function M.run(name, ...)
	local execute = M.commandMap[name].execute
	if execute == nil or type(execute) ~= "function" then
		error("Unknown or unexecutable command", 0)
	end
	local ok, res = pcall(execute, ...)
	if not ok then
		error(res, 0)
	end
end

function M.show_picker()
	vim.ui.select(M.commandKeyList, {
		prompt = "Toolbox",
	}, function(choice)
		if choice == nil then
			return
		end

		local execute = M.commandMap[choice].execute
		if execute == nil then
			return
		end

		if type(execute) == "function" then
			if debug.getinfo(execute).nparams > 0 then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes(
						":lua require('toolbox').run(\"" .. choice .. '", )<Left>',
						true,
						false,
						true
					),
					"m",
					true
				)
				return
			end
			local ok, res = pcall(execute)
			if not ok then
				error(res, 0)
			end
		end

		if type(execute) == "string" then
			if M.commandMap[choice].require_input then
				vim.api.nvim_feedkeys(":" .. execute, "m", true)
				return
			end
			local ok, res = pcall(vim.cmd, execute)
			if not ok then
				error(res, 0)
			end
		end
	end)
end

return M
