local api, lsp = vim.api, vim.lsp
local lspconfig = require("lspconfig")

local M = {}

function M.init(config)
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
			vim.api.nvim_set_current_line("\\end{" .. text .. "}")
		end, buf)
	end

	local cancel_build = function()
		local buf = api.nvim_get_current_buf()

		local params = lsp.util.make_position_params()
		local client = lspconfig.util.get_active_client_by_name(buf, "texlab")

		client.request("workspace/executeCommand", {
			command = "texlab.cancelBuild",
			arguments = { params },
		}, function() end, buf)
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

	vim.keymap.set("n", config.build, vim.cmd.TexlabBuild, { desc = "Build LaTeX" })
	vim.keymap.set("n", config.forward, vim.cmd.TexlabForward, { desc = "Forward Search" })
	vim.keymap.set(
		"n",
		config.cancel_build,
		cancel_build,
		{ buffer = true, desc = "Cancel the currently active build" }
	)
	vim.keymap.set(
		"i",
		config.close_env,
		close_env,
		{ buffer = true, desc = "Close the current environment/delimiter" }
	)
	vim.keymap.set("n", config.toggle_star, toggle_star, { buffer = true, desc = "Toggle starred environment" })
end

return M
