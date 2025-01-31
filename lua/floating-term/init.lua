-- floating-term.nvim/lua/floating-term/init.lua

local M = {}
local terminal_window = nil
local terminal_buffer = nil

local function get_window_size()
	local width = math.floor(vim.api.nvim_get_option("columns") * 0.8)
	local height = math.floor(vim.api.nvim_get_option("lines") * 0.8)
	return width, height
end

local function get_window_position(width, height)
	local row = math.floor((vim.api.nvim_get_option("lines") - height) * 0.1)
	local col = math.floor((vim.api.nvim_get_option("columns") - width) * 0.1)
	return row, col
end

local function create_terminal()
	if terminal_buffer and vim.api.nvim_buf_is_valid(terminal_buffer) then
		return terminal_buffer
	end

	-- Create a new buffer for the terminal
	terminal_buffer = vim.api.nvim_create_buf(false, true)

	-- Set buffer options
	vim.api.nvim_buf_set_option(terminal_buffer, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(terminal_buffer, "modifiable", true)

	-- Open terminal in the buffer
	vim.fn.termopen(vim.o.shell, {
		on_exit = function()
			if terminal_buffer and vim.api.nvim_buf_is_valid(terminal_buffer) then
				vim.api.nvim_buf_delete(terminal_buffer, { force = true })
				terminal_buffer = nil
			end
			terminal_window = nil
		end,
	})

	return terminal_buffer
end

local function create_window()
	local width, height = get_window_size()
	local row, col = get_window_position(width, height)

	-- Window options
	local opts = {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " Terminal ",
		title_pos = "center",
	}

	-- Create the window
	terminal_window = vim.api.nvim_open_win(terminal_buffer, true, opts)

	-- Set window-local options
	vim.wo[terminal_window].winhl = "Normal:Normal,FloatBorder:FloatBorder"
	vim.wo[terminal_window].winblend = 0

	-- Set up autocommands for cleanup
	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		buffer = terminal_buffer,
		callback = function()
			if terminal_window and vim.api.nvim_win_is_valid(terminal_window) then
				vim.api.nvim_win_hide(terminal_window)
				terminal_window = nil
			end
		end,
	})

	return terminal_window
end

function M.toggle()
	if not terminal_window or not vim.api.nvim_win_is_valid(terminal_window) then
		-- Create or get existing terminal buffer
		local buf = create_terminal()
		if not buf then
			vim.notify("Failed to create terminal buffer", vim.log.levels.ERROR)
			return
		end

		-- Create window
		local win = create_window()
		if not win then
			vim.notify("Failed to create terminal window", vim.log.levels.ERROR)
			return
		end

		vim.cmd("startinsert")
	else
		-- Hide the window if it's visible
		vim.api.nvim_win_hide(terminal_window)
		terminal_window = nil
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
