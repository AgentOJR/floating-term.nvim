-- ~/.config/nvim/lua/owenrabe/plugins/floating-term/lua/floating-term/init.lua

local Terminal = require("nui.terminal")
local event = require("nui.utils.autocmd").event

local M = {}
local terminal_window = nil
local terminal_instance = nil

local function create_terminal()
	if not terminal_instance then
		terminal_instance = Terminal:new({
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

		terminal_instance:on(event.BufWinLeave, function()
			terminal_window = nil
		end)
	end

	return terminal_instance
end

function M.toggle()
	if not terminal_window then
		local term = create_terminal()
		term:mount()
		terminal_window = term.winid
		vim.cmd("startinsert")
	else
		if vim.api.nvim_win_is_valid(terminal_window) then
			vim.api.nvim_win_hide(terminal_window)
			terminal_window = nil
		else
			local term = create_terminal()
			term:mount()
			terminal_window = term.winid
			vim.cmd("startinsert")
		end
	end
end

function M.setup(opts)
	opts = opts or {}

	vim.api.nvim_create_user_command("ToggleTerminal", M.toggle, {})

	if not opts.disable_default_keymap then
		vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle floating terminal" })
	end
end

return M
