-- Setup the floating terminal plugin
local M = {}

-- Define a new window with floating term capabilities
function M.create_window(width, height, opts)
	local win = vim.api.nvim_open_win(opts.bufnr, true, {
		relative = "editor",
		row = opts.row,
		col = opts.col,
		width = width,
		height = height,
		focusable = false,
		style = "minimal",
	})

	-- Set the title of the window to be the same as the buffer name
	vim.api.nvim_win_set_option(win, "title", opts.bufname)

	-- Make the window focusable
	vim.api.nvim_win_set_option(win, "focusable", true)

	return win
end

-- Define a floating terminal with the specified width and height
function M.create_floating_term(width, height)
	-- Create a new buffer for the terminal
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- Open the buffer in a floating window with the specified size
	local win = M.create_window(width, height, {
		bufnr = bufnr,
		row = 0,
		col = 0,
	})

	-- Set the terminal to be focused on creation
	vim.api.nvim_win_set_option(win, "focusable", true)

	return win
end

-- Define a function for opening a floating terminal
function M.open_floating_term()
	-- Create a new buffer for the terminal
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- Open the buffer in a floating window with the specified size
	local win = M.create_window(80, 24, {
		bufnr = bufnr,
		row = 0,
		col = 0,
	})

	-- Set the terminal to be focused on creation
	vim.api.nvim_win_set_option(win, "focusable", true)

	return win
end

-- Define a function for focusing the floating terminal
function M.focus_floating_term()
	local floating_term = require("plugins/floating-term").open_floating_term()

	-- Set the focus on the floating terminal
	vim.api.nvim_win_set_option(floating_term, "focusable", true)
end

-- Define a function for closing the floating terminal
function M.close_floating_term()
	local floating_term = require("plugins/floating-term").open_floating_term()

	-- Close the floating terminal window
	vim.api.nvim_win_close(floating_term, false)
end

return M
