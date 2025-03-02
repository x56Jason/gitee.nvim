local curl = require('plenary.curl')
local gitee_log_view = require("gitee.log_view")
local gitee_prlist_view = require("gitee.prlist_view")

local M = {
	config = {
		token_file = nil,
		token = nil,
		repo = nil,
		prlist_state = "open",
		prlist_sort = "updated",
	},
}

local function do_gitee_log(pr)
	local logview = gitee_log_view.new(pr)
	if logview == nil then
		return
	end
	logview:open()
end

function M.set_config(config)
	if config.token_file then
		M.config.token_file = config.token_file
		local token = vim.fn.systemlist("cat " .. config.token_file)
		if vim.v.shell_error == 0 then
			M.config.token = token[1]
		end
	end
	if config.repo then
		M.config.repo = config.repo
	end
	if config.prlist_state then
		local state = config.prlist_state
		if state ~= "open" and state ~= "merged" and state ~= "closed" and state ~= "all" then
			vim.notify("incorrect config.prlist_state: " .. state, vim.log.levels.ERROR, {})
			return
		end
		M.config.prlist_state = config.prlist_state
	end
	if config.prlist_sort then
		local sort = config.prlist_sort
		if sort ~= "created" and sort ~= "updated" and sort ~= "popularity" and sort ~= "long-running" then
			vim.notify("incorrect config.prlist_sort: " .. sort, vim.log.levels.ERROR, {})
			return
		end
		M.config.prlist_sort = config.prlist_sort
	end
end

function M.do_gitee_pr(cmdline)
	local pr_number = cmdline
	local base_url = "https://gitee.com/api/v5/repos/" .. M.config.repo .. "/pulls/"
	local token = M.config.token
	local opts = {
		method = "get",
		headers = {
			["Accept"] = "application/json",
			["Connection"] = "keep-alive",
			["Content-Type"] = "\'application/json; charset=utf-8\'",
			["User-Agent"] = "Gitee.nvim",
		},
		body = {},
	}
	opts.url = base_url .. pr_number .."?access_token=" .. token .. "&number=" .. pr_number
	-- vim.notify("url: " .. opts.url, vim.log.levels.INFO, {})
	local response = curl["get"](opts)
	local json = vim.fn.json_decode(response.body)
	local desc_body = vim.fn.split(json.body, "\n")
	local pr = {
		number = pr_number,
		labels = json.labels,
		desc_head = {
			url = json.html_url,
			creator = json.head.user.name,
			head = json.head.repo.full_name .. " : " .. json.head.ref,
			base = json.base.repo.full_name .. " : " .. json.base.ref,
			state = json.state,
			created_at = json.created_at,
			updated_at = json.updated_at,
			mergeable = json.mergeable,
			title = json.title,
		},
		desc_body = desc_body,
		user = json.head.user.login,
		url = json.head.repo.html_url,
		branch = json.head.ref,
		sha = json.head.sha,
		base_user = json.base.user.login,
		base_url = json.base.repo.html_url,
		base_branch = json.base.ref,
		base_sha = json.base.sha,
	}
	local source_remote_name = json.head.user.login .. "-" .. json.head.repo.full_name:gsub('/', '-')
	local dest_remote_name = json.base.user.login .. "-" .. json.base.repo.full_name:gsub('/', '-')
	vim.cmd(string.format("!git remote remove %s", source_remote_name))
	vim.cmd(string.format("!git remote add %s %s", source_remote_name, json.head.repo.html_url))
	vim.cmd(string.format("!git remote remove %s", dest_remote_name))
	vim.cmd(string.format("!git remote add %s %s", dest_remote_name, json.base.repo.html_url))
	vim.cmd(string.format("!git fetch %s %s", source_remote_name, json.head.ref))
	vim.cmd(string.format("!git fetch %s %s", dest_remote_name, json.base.ref))

	local commit_from = vim.fn.systemlist(string.format("git merge-base %s %s", json.head.sha, json.base.sha))[1]
	pr.merge_base = commit_from

	do_gitee_log(pr)
end

local function table_concat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function prlist_verify_param(param_table, key, value)
	local gitee_params = {
		["state"] = { "open", "closed", "merged", "all" },
		["sort"]  = { "created", "updated", "popularity", "long-running" },
	}

	local key_found = nil
	for k, p in pairs(gitee_params) do
		if key == k then
			key_found = true
			for _, v in ipairs(p) do
				if value == v then
					param_table[key] = value
				end
			end
		end
	end
	if not key_found then
		param_table[key] = value
	end
end

function M.do_gitee_prlist(cmdline)
	local howmany = "100"
	local param_table = {}
	if cmdline:match('%S+') then
		for param in vim.gsplit(cmdline, " ", {plain=true}) do
			if param:match('%S+') then
				local key, value = unpack(vim.split(param, "=", {plain=true}))
				if key:match('%S+') then
					if not value or value:match('^%s*$') then
						if tonumber(key) then
							howmany = key
						end
					else
						prlist_verify_param(param_table, key, value)
					end
				end
			end
		end
	end

	local query_state = M.config.prlist_state
	local query_sort = M.config.prlist_sort
	if param_table["state"] then
		query_state = param_table["state"]
	end
	if param_table["sort"] then
		query_sort = param_table["sort"]
	end

	local http_param_str = "&state=" .. query_state .. "&sort=" .. query_sort

	if param_table["base"] then
		http_param_str = http_param_str .. "&base=" .. param_table["base"]
	end
	if param_table["milestone_number"] then
		http_param_str = http_param_str .. "&milestone_number=" .. param_table["milestone_number"]
	end
	if param_table["labels"] then
		http_param_str = http_param_str .. "&labels=" .. param_table["labels"]
	end
	if param_table["author"] then
		http_param_str = http_param_str .. "&author=" .. param_table["author"]
	end
	if param_table["assignee"] then
		http_param_str = http_param_str .. "&assignee=" .. param_table["assignee"]
	end

	local base_url = "https://gitee.com/api/v5/repos/" .. M.config.repo .. "/pulls"
	local token = M.config.token
	local opts = {
		method = "get",
		headers = {
			["Accept"] = "application/json",
			["Connection"] = "keep-alive",
			["Content-Type"] = "\'application/json; charset=utf-8\'",
			["User-Agent"] = "Glance",
		},
		body = {},
	}
	local json = {}
	local count = 0
	while count*100 < tonumber(howmany) do
		count = count + 1
		opts.url = base_url .. "?access_token=" .. token .. http_param_str .. "&direction=desc&page="..count.."&per_page=100"
		-- vim.notify("url: " .. opts.url, vim.log.levels.INFO, {})
		local response = curl["get"](opts)
		local tmp = vim.fn.json_decode(response.body)
		if #tmp == 0 then
			break
		end
		table_concat(json, tmp)
	end

	local prlist_view = gitee_prlist_view.new(json, cmdline, true)
	prlist_view:open()
end

local function do_gitee_command(cmdline)
	local gitee_cmd = vim.split(cmdline, " ")
	local config = {
		gitee = {},
	}
	if gitee_cmd[1] == "repo" then
		config.repo = gitee_cmd[2]
	elseif gitee_cmd[1] == "token_file" then
		config.token_file = gitee_cmd[2]
	elseif gitee_cmd[1] == "prlist_state" then
		config.prlist_state = gitee_cmd[2]
	elseif gitee_cmd[1] == "prlist_sort" then
		config.prlist_sort = gitee_cmd[2]
	end
	M.set_config(config)
end

local function do_gitee_commands(user_opts)
	local sub_cmd_str = user_opts.fargs[1]
	local sub_cmd = nil
	local cmdline = ""
	local start_index = 2

	if sub_cmd_str == "prlist" then
		sub_cmd = M.do_gitee_prlist
	elseif sub_cmd_str == "pr" then
		sub_cmd = M.do_gitee_pr
	else
		sub_cmd = do_gitee_command
		start_index = 1
	end

	for i, arg in ipairs(user_opts.fargs) do
		if i == start_index then
			cmdline = arg
		elseif i > start_index then
			cmdline = cmdline .. " " .. arg
		end
	end

	sub_cmd(cmdline)
end

function M.setup(opts)
	local config = opts or {}

	M.set_config(config)

	vim.api.nvim_create_user_command( "Gitee", do_gitee_commands, { desc = "Gitee Commands", nargs = '+' })
end

return M
