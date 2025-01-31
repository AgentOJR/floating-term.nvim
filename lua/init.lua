-- lua/floating-term/init.lua
local Terminal = require("nui.terminal")
local event = require("nui.utils.autocmd").event

local M = {}
local terminal_window = nil
local terminal_instance = nil

local function create_terminal()
	-- Create terminal instance if it doesn't exist
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

		-- Preserve terminal buffer when window is closed
		terminal_instance:on(event.BufWinLeave, function()
			terminal_window = nil
		end)
	end

	return terminal_instance
end

function M.toggle()
	if not terminal_window then
		-- If window doesn't exist, create and mount terminal
		local term = create_terminal()
		term:mount()
		terminal_window = term.winid

		-- Enter insert mode automatically
		vim.cmd("startinsert")
	else
		-- If window exists, check if it's valid
		if vim.api.nvim_win_is_valid(terminal_window) then
			-- Hide the window
			vim.api.nvim_win_hide(terminal_window)
			terminal_window = nil
		else
			-- Window reference is invalid, create new window
			local term = create_terminal()
			term:mount()
			terminal_window = term.winid
			vim.cmd("startinsert")
		end
	end
end

-- Setup function
function M.setup(opts)
	opts = opts or {}
	-- Add any configuration options here

	-- Create command
	vim.api.nvim_create_user_command("ToggleTerminal", M.toggle, {})

	-- Optional: Set up keymaps
	if not opts.disable_default_keymap then
		vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle floating terminal" })
	end
end

return M
