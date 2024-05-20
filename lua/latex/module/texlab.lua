local api, lsp = vim.api, vim.lsp

local texlab_build_status = {
	[0] = "Success",
	[1] = "Error",
	[2] = "Failure",
	[3] = "Cancelled",
}

local M = {}

local cancel_build = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lsp.get_clients({ bufnr = buf, name = "texlab" })[1]

	if client then
		client.request("workspace/executeCommand", {
			command = "texlab.cancelBuild",
			arguments = { params },
		}, function(err, result)
			if err then
				error(tostring(err))
			end
			print("Build " .. texlab_build_status[result.status])
		end, buf)
	else
		print("method workspace/executeCommand is not supported by any servers active on the current buffer")
	end
end

local close_env = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lsp.get_clients({ bufnr = buf, name = "texlab" })[1]

	if client then
		client.request("workspace/executeCommand", {
			command = "texlab.findEnvironments",
			arguments = { params },
		}, function(err, result)
			if err then
				error(tostring(err))
			end

			if #result == 0 then
				print("No environment found")
				return
			end
			local text = result[#result].name.text
			api.nvim_put({ "\\end{" .. text .. "}" }, "", false, true)
		end, buf)
	else
		print("method workspace/executeCommand is not supported by any servers active on the current buffer")
	end
end

local toggle_star = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lsp.get_clients({ bufnr = buf, name = "texlab" })[1]

	if client then
		client.request("workspace/executeCommand", {
			command = "texlab.findEnvironments",
			arguments = { params },
		}, function(err, result)
			if err then
				error(tostring(err))
			end

			if #result == 0 then
				print("No environment found")
				return
			end
			local text = result[#result].name.text
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
	else
		print("method workspace/executeCommand is not supported by any servers active on the current buffer")
	end
end

local change_env = function()
	local buf = api.nvim_get_current_buf()

	local params = lsp.util.make_position_params()
	local client = lsp.get_clients({ bufnr = buf, name = "texlab" })[1]

	if client then
		client.request("workspace/executeCommand", {
			command = "texlab.findEnvironments",
			arguments = { params },
		}, function(err, result)
			if err then
				error(tostring(err))
			end

			if #result == 0 then
				print("No environment found")
				return
			end
			local text = result[#result].name.text
			params.newName = vim.fn.input({ prompt = "New Environment Name:", default = text })
			client.request("workspace/executeCommand", {
				command = "texlab.changeEnvironment",
				arguments = { params },
			}, function() end, buf)
		end, buf)
	else
		print("method workspace/executeCommand is not supported by any servers active on the current buffer")
	end
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
