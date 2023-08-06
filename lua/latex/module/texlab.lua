local api, lsp = vim.api, vim.lsp
local lspconfig = require("lspconfig")

local M = {}

local cancel_build = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lspconfig.util.get_active_client_by_name(buf, "texlab")

	client.request("workspace/executeCommand", {
		command = "texlab.cancelBuild",
		arguments = { params },
	}, function() end, buf)
end

local close_env = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lspconfig.util.get_active_client_by_name(buf, "texlab")

	client.request("workspace/executeCommand", {
		command = "texlab.findEnvironments",
		arguments = { params },
	}, function(_, envs, _)
		if #envs == 0 then
			print("No environment found")
			return
		end
		local text = envs[#envs].name.text
		local pos = api.nvim_win_get_cursor(0)[2]
		local line = api.nvim_get_current_line()
		local nline = line:sub(0, pos) .. "\\end{" .. text .. "}" .. line:sub(pos + 1)
		vim.api.nvim_set_current_line(nline)
	end, buf)
end

local toggle_star = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lspconfig.util.get_active_client_by_name(buf, "texlab")

	client.request("workspace/executeCommand", {
		command = "texlab.findEnvironments",
		arguments = { params },
	}, function(_, envs, _)
		if #envs == 0 then
			print("No environment found")
			return
		end
		local text = envs[#envs].name.text
		if text:sub(#text) == "*" then
			text = text:sub(1, #text - 1)
		else
			text = text .. "*"
		end
		params.newName = text
		client.request("workspace/executeCommand", {
			command = "texlab.changeEnvironment",
			arguments = { params },
		}, function() end, buf)
	end, buf)
end

local change_env = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lspconfig.util.get_active_client_by_name(buf, "texlab")

	client.request("workspace/executeCommand", {
		command = "texlab.findEnvironments",
		arguments = { params },
	}, function(_, envs, _)
		if #envs == 0 then
			print("No environment found")
			return
		end
		local text = envs[#envs].name.text
		params.newName = vim.fn.input({ prompt = "New Environment Name:", default = text })
		client.request("workspace/executeCommand", {
			command = "texlab.changeEnvironment",
			arguments = { params },
		}, function() end, buf)
	end, buf)
end

function M.init(config)
	if not config.enabled then
		return
	end

	vim.keymap.set("n", config.build, vim.cmd.TexlabBuild, { buffer = true, desc = "Build LaTeX" })
	vim.keymap.set("n", config.forward, vim.cmd.TexlabForward, { buffer = true, desc = "Forward Search" })
	vim.keymap.set("n", config.cancel_build, cancel_build, { buffer = true, desc = "Cancel the current build" })
	vim.keymap.set("n", config.change_env, change_env, { buffer = true, desc = "Close the current environment" })
	vim.keymap.set("i", config.close_env, close_env, { buffer = true, desc = "Close the current environment" })
	vim.keymap.set("n", config.toggle_star, toggle_star, { buffer = true, desc = "Toggle starred environment" })
end

return M
