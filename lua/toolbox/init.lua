local M = {}

---@type Toolbox.Config
M.opts = {
	commands = {},
}

---@param filter fun(command:Toolbox.Command)
---@return Toolbox.Command[]
local function filter_commands(filter)
	if filter == nil then
		return M.opts.commands
	end

	---@type Toolbox.Command[]
	local filtered = {}
	for _, command in ipairs(M.opts.commands) do
		if filter(command) then
			table.insert(filtered, command)
		end
	end
	return filtered
end

---@param name string
---@return Toolbox.Command|nil
local function find_command(name)
	for _, command in ipairs(M.opts.commands) do
		if command.name == name then
			return command
		end
	end
	return nil
end

---@param opts Toolbox.Config
function M.setup(opts)
	---@type Toolbox.Config
	M.opts = vim.tbl_extend("force", {
		commands = {},
	}, opts or {})
end

---@param name string
function M.run(name)
	local command = find_command(name)
	if command == nil then
		error("Command " .. name .. " is not found", 0)
	end

	local execute = command.execute
	if execute == nil or type(execute) ~= "function" then
		error("Unknown or unexecutable command", 0)
	end

	return {
		with_args = function(...)
			local ok, res = pcall(execute, ...)
			if not ok then
				error(res, 0)
			end
		end,
	}
end

local default_sorter = function(a, b)
	if a.weight ~= nil or b.weight ~= nil then
		-- Higher weight should be shown first
		-- hence descending sort
		return (a.weight or 0) > (b.weight or 0)
	end
	return string.upper(a.name) < string.upper(b.name)
end

---@param tag string|nil
---@param select_opts table Taken from vim.ui.select
---     - prompt (string|nil)
---               Text of the prompt. Defaults to `Select one of:`
---     - format_item (function item -> text)
---               Function to format an
---               individual item from `items`. Defaults to `tostring`.
---     - kind (string|nil)
---               Arbitrary hint string indicating the item shape.
---               Plugins reimplementing `vim.ui.select` may wish to
---               use this to infer the structure or semantics of
---               `items`, or the context in which select() was called.
function M.show_picker(tag, select_opts)
	---@type Toolbox.ShowPickerCustomOpts?
	local opts = {
		sorter = default_sorter,
	}
	if tag ~= nil and tag ~= "" then
		opts.filter = function(command)
			return command.tags ~= nil and vim.tbl_contains(command.tags, tag)
		end
	end

	M.show_picker_custom(opts, select_opts)
end

---@param command_name string
---@param hint_text string|nil
local function print_to_command_line(command_name, hint_text)
	if hint_text == nil then
		hint_text = ""
	end
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(":lua require('toolbox').run(\"", true, false, true)
			.. command_name
			.. vim.api.nvim_replace_termcodes(
				'").with_args()' .. hint_text .. string.rep("<Left>", string.len(hint_text) + 1),
				true,
				false,
				true
			),
		"m",
		false
	)
end

---@param opts Toolbox.ShowPickerCustomOpts?
---@param select_opts table Taken from vim.ui.select
---     - prompt (string|nil)
---               Text of the prompt. Defaults to `Select one of:`
---     - format_item (function item -> text)
---               Function to format an
---               individual item from `items`. Defaults to `tostring`.
---     - kind (string|nil)
---               Arbitrary hint string indicating the item shape.
---               Plugins reimplementing `vim.ui.select` may wish to
---               use this to infer the structure or semantics of
---               `items`, or the context in which select() was called.
function M.show_picker_custom(opts, select_opts)
	opts = opts or {}

	local mode = vim.api.nvim_get_mode()["mode"]
	local is_visual = mode == "v" or mode == "V" or mode == "\22"
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

	local items = filter_commands(opts.filter)
	if opts.sorter ~= nil then
		table.sort(items, opts.sorter)
	end

	vim.ui.select(
		items,
		select_opts,
		---@param command Toolbox.Command
		function(command)
			if command == nil then
				return
			end

			local execute = command.execute
			if type(execute) == "function" then
				local num_params = debug.getinfo(execute).nparams
				if num_params > 0 then
					local hint_text = " -- " .. num_params
					if num_params > 1 then
						hint_text = hint_text .. " args required"
					else
						hint_text = hint_text .. " arg required"
					end
					print_to_command_line(command.name, hint_text)
					return
				end

				-- debug.getinfo can't detect variadic arguments
				if command.require_input then
					print_to_command_line(command.name, nil)
					return
				end

				local ok, res = pcall(execute)
				if not ok then
					error(res, 0)
				end
			elseif type(execute) == "string" then
				local cmd_prefix = ":"
				if is_visual then
					cmd_prefix = cmd_prefix .. "'<,'>"
				end

				if command.require_input then
					vim.api.nvim_feedkeys(cmd_prefix .. execute, "m", false)
					return
				end
				local ok, res = pcall(vim.cmd, cmd_prefix .. execute)
				if not ok then
					error(res, 0)
				end
			end
		end
	)
end

return M
