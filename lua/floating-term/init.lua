-- floating-term.nvim/lua/floating-term/init.lua

local M = {}
local terminal_window = nil
local terminal_instance = nil

-- Initialize required modules
local Terminal, event
local function init_modules()
	if Terminal and event then
		return true
	end

	local has_nui, nui_terminal = pcall(require, "nui.terminal")
	if not has_nui then
		vim.notify("nui.terminal not found. Please ensure nui.nvim is installed", vim.log.levels.ERROR)
		return false
	end

	local has_event, nui_event = pcall(require, "nui.utils.autocmd")
	if not has_event then
		vim.notify("nui.utils.autocmd not found", vim.log.levels.ERROR)
		return false
	end

	Terminal = nui_terminal
	event = nui_event.event
	return true
end

local function create_terminal()
	if terminal_instance then
		return terminal_instance
	end

	if not init_modules() then
		return nil
	end

	local ok, term = pcall(function()
		return Terminal:new({
			position = {
				row = "10%",
				col = "10%",
			},
			size = {
				width = "80%",
				height = "80%",
			},
			border = {
				style = "rounded",
				text = {
					top = "[Terminal]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
		})
	end)

	if not ok then
		vim.notify("Failed to create terminal: " .. tostring(term), vim.log.levels.ERROR)
		return nil
	end

	terminal_instance = term

	local setup_ok, err = pcall(function()
		terminal_instance:on(event.BufWinLeave, function()
			terminal_window = nil
		end)
	end)

	if not setup_ok then
		vim.notify("Failed to setup terminal events: " .. tostring(err), vim.log.levels.ERROR)
	end

	return terminal_instance
end

function M.toggle()
	if not terminal_window then
		local term = create_terminal()
		if not term then
			return
		end

		local ok, err = pcall(function()
			term:mount()
			terminal_window = term.winid
			vim.cmd("startinsert")
		end)

		if not ok then
			vim.notify("Failed to mount terminal: " .. tostring(err), vim.log.levels.ERROR)
		end
	else
		if vim.api.nvim_win_is_valid(terminal_window) then
			vim.api.nvim_win_hide(terminal_window)
			terminal_window = nil
		else
			local term = create_terminal()
			if not term then
				return
			end

			local ok, err = pcall(function()
				term:mount()
				terminal_window = term.winid
				vim.cmd("startinsert")
			end)

			if not ok then
				vim.notify("Failed to mount terminal: " .. tostring(err), vim.log.levels.ERROR)
			end
		end
	end
end

function M.setup(opts)
	opts = opts or {}

	if not init_modules() then
		vim.notify("Failed to initialize floating-term. Required dependencies not found.", vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_create_user_command("ToggleTerminal", M.toggle, {})

	if not opts.disable_default_keymap then
		vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle floating terminal" })
	end
end

return M
