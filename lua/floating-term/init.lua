local M = {}
M.terminal_window = nil
M.terminal_job_id = nil

function M.setup()
	-- Set up keybindings
	vim.keymap.set("n", "<leader>tt", M.toggle, {})
end

function M.toggle()
	-- Check if the floating terminal is currently open
	if M.terminal_window ~= nil then
		-- Close the floating terminal window
		vim.cmd(":close")
	else
		-- Open a new floating terminal window with the default shell command
		M.terminal_window = vim.fn.openwin(0, "FloatingTerminal", {})
		M.terminal_job_id = vim.fn.jobstart({ "sh", "-i" }, { on_exit = function() end })
	end
end

-- Run the command in the floating terminal and hide
function M.run_command(args)
	-- Check if the floating terminal is open
	if M.terminal_window ~= nil then
		-- Get the current window ID
		local winid = vim.fn.win_getid()
		-- Move to the floating terminal window
		vim.cmd(":execute 'noautocmd wincmd w' . M.terminal_window")
		-- Run the command in the floating terminal and hide
		vim.cmd(string.format(":%s %s", args[1], table.concat(args, " ")))
		-- Move back to the original window
		vim.cmd(string.format(":noautocmd wincmd w %d", winid))
	else
		-- Open a new floating terminal window with the default shell command
		M.terminal_window = vim.fn.openwin(0, "FloatingTerminal", {})
		M.terminal_job_id = vim.fn.jobstart({ "sh", "-i" }, { on_exit = function() end })
	end
end

-- Close the floating terminal window
function M.close()
	-- Check if the floating terminal is open
	if M.terminal_window ~= nil then
		-- Get the current window ID
		local winid = vim.fn.win_getid()
		-- Move to the floating terminal window
		vim.cmd(":execute 'noautocmd wincmd w' . M.terminal_window")
		-- Close the floating terminal window
		vim.cmd(":close")
		-- Move back to the original window
		vim.cmd(string.format(":noautocmd wincmd w %d", winid))
	end
end

-- Initialize the plugin
M.setup()
