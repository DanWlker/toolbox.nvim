local M = {}

function M.setup(opts)
	opts = opts or {}
	local commands = opts.commands or {}

	M.commandMap = {}
	for _, val in ipairs(commands) do
		M.commandMap[val.name] = val.execute
	end

	M.commandKeyList = {}
	for k, _ in pairs(M.commandMap) do
		table.insert(M.commandKeyList, k)
	end
end

function M.show_picker()
	vim.ui.select(M.commandKeyList, {
		prompt = "Toolbox",
	}, function(choice)
		if choice == nil then
			return
		end

		local execute = M.commandMap[choice]
		if execute == nil then
			return
		end
		if type(execute) == "function" then
			execute()
		end
		if type(execute) == "string" then
			vim.cmd(execute)
		end
	end)
end

return M
