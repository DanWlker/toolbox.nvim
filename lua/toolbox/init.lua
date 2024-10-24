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
	table.sort(M.commandKeyList, function(a, b)
		return string.upper(a) < string.upper(b)
	end)
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

function M.show_picker()
	local mode = vim.api.nvim_get_mode()["mode"]
	local isVisual = mode == "v" or mode == "V" or mode == "\22"
	local startline = vim.fn.getpos("v")[2]
	local endline = vim.fn.getpos(".")[2]
	if startline > endline then
		startline, endline = endline, startline
	end

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
				cmdPrefix = cmdPrefix .. startline .. "," .. endline
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
