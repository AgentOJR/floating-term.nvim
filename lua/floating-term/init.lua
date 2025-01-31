-- floating-term.nvim/lua/floating-term/init.lua

local M = {}
local terminal_window = nil
local terminal_buffer = nil
-- Store the job ID (used for chansend)
local terminal_job_id = nil

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Create Terminal + Window
-------------------------------------------------------------------------------
local function create_terminal()
	-- If we already have a valid buffer, use it
	if terminal_buffer and vim.api.nvim_buf_is_valid(terminal_buffer) then
		return terminal_buffer
	end

	-- Create a new buffer for the terminal
	terminal_buffer = vim.api.nvim_create_buf(false, true)
	if not terminal_buffer then
		return nil
	end

	-- Set buffer options
	vim.api.nvim_buf_set_option(terminal_buffer, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(terminal_buffer, "buftype", "terminal")
	vim.api.nvim_buf_set_option(terminal_buffer, "buflisted", false)

	-- Run the user’s default shell in the terminal
	local job_id = vim.fn.termopen(vim.o.shell, {
		on_exit = function()
			-- When the shell truly exits, clean everything up
			if terminal_buffer and vim.api.nvim_buf_is_valid(terminal_buffer) then
				vim.api.nvim_buf_delete(terminal_buffer, { force = true })
			end
			terminal_buffer = nil
			terminal_window = nil
			terminal_job_id = nil
		end,
	})

	-- Store the job ID for `chansend`
	terminal_job_id = job_id

	return terminal_buffer
end

local function create_window()
	-- If we have a valid window, just use it
	if terminal_window and vim.api.nvim_win_is_valid(terminal_window) then
		return terminal_window
	end

	local width, height = get_window_size()
	local row, col = get_window_position(width, height)

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

	terminal_window = vim.api.nvim_open_win(terminal_buffer, true, opts)
	vim.wo[terminal_window].winhl = "Normal:Normal,FloatBorder:FloatBorder"
	vim.wo[terminal_window].winblend = 0

	-- Automatically hide the window if user leaves it
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

-------------------------------------------------------------------------------
-- Core Public Functions
-------------------------------------------------------------------------------
--- Toggle the floating terminal.
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

		-- Enter insert mode so you can type in the terminal
		vim.cmd("startinsert")
	else
		-- If it's open, hide it
		vim.api.nvim_win_hide(terminal_window)
		terminal_window = nil
	end
end

--- Run a command in the floating terminal, then close it, leaving the process running.
---@param cmd string The command to run in the terminal
function M.run_command(cmd)
	if not cmd or cmd == "" then
		vim.notify("No command provided", vim.log.levels.WARN)
		return
	end

	-- Create the terminal if needed
	local buf = create_terminal()
	if not buf then
		vim.notify("Failed to create terminal buffer", vim.log.levels.ERROR)
		return
	end

	-- Create/Show the floating window
	local win = create_window()
	if not win then
		vim.notify("Failed to create terminal window", vim.log.levels.ERROR)
		return
	end

	-- Go to insert mode so that nvim is accepting terminal input
	vim.cmd("startinsert")

	-- If we have a valid job, send the command
	if terminal_job_id and terminal_job_id > 0 then
		-- Send the command plus a newline
		vim.fn.chansend(terminal_job_id, cmd .. "\r")
	else
		vim.notify("Invalid terminal job ID", vim.log.levels.ERROR)
	end

	-- OPTIONAL: Close (hide) the floating terminal window right away,
	-- leaving the command running in the background.
	vim.schedule(function()
		if terminal_window and vim.api.nvim_win_is_valid(terminal_window) then
			vim.api.nvim_win_hide(terminal_window)
			terminal_window = nil
		end
	end)
end

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------
function M.setup(opts)
	opts = opts or {}

	vim.api.nvim_create_user_command("ToggleTerminal", M.toggle, {})

	-- Command to run a single shell command in the floating terminal and close
	vim.api.nvim_create_user_command("RunFloatingCommand", function(info)
		M.run_command(info.args)
	end, { nargs = 1, desc = "Run command in floating terminal and hide" })

	if not opts.disable_default_keymap then
		-- Normal-mode toggle keymap
		vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle floating terminal" })

		-- Terminal-mode escape key
		vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
	end
end

return M
