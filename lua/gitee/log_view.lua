local curl = require('plenary.curl')
local glance_commit_view = require("glance.commit_view")
local glance_log_view = require("glance.log_view")
local glance_utils = require("glance.utils")

local M = {
	index = 1,
}

local function parse_headers(pr)
	local headers = {}
	local label_hl_name = {
		["openeuler-cla/yes"] = "GlanceLogCLAYes",
		["lgtm"] = "GlanceLogLGTM",
		["ci_successful"] = "GlanceLogCISuccess",
		["sig/Kernel"] = "GlanceLogSigKernel",
		["stat/needs-squash"] = "GlanceLogNeedSquash",
		["Acked"] = "GlanceLogAcked",
		["approved"] = "GlanceLogApproved",
		["newcomer"] = "GlanceLogNewComer",
	}
	local line = "Pull-Request !" .. pr.number .. "        "
	local hls = {}
	local from = 0
	local to = #line
	table.insert(hls, {from=from, to=to, name="GlanceLogHeader"})
	for _, label in pairs(pr.labels) do
		local label_str = label.name
		line = line .. " | " .. label_str
		from = to + 3
		to = from + #label_str
		if label_hl_name[label_str] then
			table.insert(hls, {from=from, to=to, name=label_hl_name[label_str]})
		end
	end
	table.insert(headers, {line=line, sign=nil, hls=hls})

	table.insert(headers, {line="---", sign=nil, hls=nil})

	pr.desc_head.created_at = pr.desc_head.created_at:gsub("T", " ")
	pr.desc_head.updated_at = pr.desc_head.updated_at:gsub("T", " ")

	line = "URL:      " .. pr.desc_head.url
	local sign = "GlanceLogHeaderField"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line = "Creator:  " .. pr.desc_head.creator
	sign = "GlanceLogHeaderField"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line = "Head:     " .. pr.desc_head.head
	sign = "GlanceLogHeaderHead"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line ="Base:     " .. pr.desc_head.base
	sign = "GlanceLogHeaderBase"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line ="Created:  " .. pr.desc_head.created_at
	sign = "GlanceLogHeaderField"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line ="Updated:  " .. pr.desc_head.updated_at
	sign = "GlanceLogHeaderField"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	if pr.desc_head.mergeable then
		line ="Mergable: true"
	else
		line ="Mergable: false"
	end
	sign = "GlanceLogHeaderField"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line ="State:    " .. pr.desc_head.state
	sign = "GlanceLogHeaderField"
	table.insert(headers, {line=line, sign=sign, hls=nil})

	line ="Title:    " .. pr.desc_head.title
	table.insert(headers, {line=line, sign=nil, hls=nil})

	return headers
end

local function space_with_level(level)
	local str = ""
	for i = 1, level do
		str = str .. "    "
	end
	return str
end

local function parse_one_comment(comments, comment, level)
	comment.created_at = comment.created_at:gsub("T", " ")
	local comment_head = string.format("%d | %s | %s | %s", comment.id, comment.user.login, comment.user.name, comment.created_at)
	local level_space = space_with_level(level)

	local line = level_space .. "> " .. comment_head
	local sign = "GlanceLogCommentHead"
	table.insert(comments, {line=line, sign=sign, hls=nil})

	table.insert(comments, {line="", sign=nil, hls=nil})

	local comment_body = vim.split(comment.body, "\n")
	for _, l in pairs(comment_body) do
		line = "  " .. level_space .. l
		table.insert(comments, {line=line, sign=nil, hls=nil})
	end

	table.insert(comments, {line="", sign=nil, hls=nil})

	if comment.children then
		local child_level = level + 1
		for _, child in pairs(comment.children) do
			parse_one_comment(comments, child, child_level)
		end
	end
end

local function find_comment_by_id(comments, id)
	for _, comment in ipairs(comments) do
		if comment.id == id then
			return comment
		end
	end
end

local function pr_get_comments(pr)
	local gitee = require("gitee")
	local base_url = "https://gitee.com/api/v5/repos/" .. gitee.config.repo .. "/pulls/"
	local token = gitee.config.token
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
	opts.url = base_url .. pr.number .."/comments?access_token=" .. token .. "&number=" .. pr.number .. "&page=1&per_page=100"
	-- vim.notify("url: " .. opts.url, vim.log.levels.INFO, {})
	local response = curl["get"](opts)
	local json = vim.fn.json_decode(response.body)
	local comments = {}
	for _, comment in ipairs(json) do
		if comment.user.login ~= "openeuler-ci-bot" and comment.user.login ~= "openeuler-sync-bot" and comment.user.login ~= "ci-robot" then
			table.insert(comments, comment)
		end

	end
	for _, comment in ipairs(comments) do
		if comment.in_reply_to_id then
			local parent = find_comment_by_id(comments, comment.in_reply_to_id)
			if parent then
				parent.children = parent.children or {}
				table.insert(parent.children, comment)
			else
				comment.in_reply_to_id = nil
			end
		end
	end
	pr.comments = comments
end

local function parse_comments(pr)
	local comments = {}
	local level = 0
	for _, comment in pairs(pr.comments) do
		if not comment.in_reply_to_id then
			parse_one_comment(comments, comment, level)
		end
	end
	return comments
end

function M:open_alldiff_view()
	if not self.pr then
		vim.notify("Not a pr log", vim.log.levels.WARN, {})
	end
	local view = glance_commit_view.new_alldiff(self.pr.merge_base, self.pr.sha)
	if not view then return end
	view:open()
end

function M.new(pr)
	if pr == nil then return nil end

	local headers = parse_headers(pr)

	local message = pr.desc_body

	local commit_range = pr.merge_base .. ".." .. pr.sha
	local cmd = "git log --oneline --no-abbrev-commit --decorate " .. commit_range
	local commits = glance_utils.parse_git_log(cmd)

	pr_get_comments(pr)
	local comments = parse_comments(pr)

	local log_view = glance_log_view.new(headers, message, commits, comments)

	local instance = {
		pr = pr,
		log_view = log_view,
	}

	setmetatable(instance, { __index = M })

	return instance
end

function M:close()
	self.log_view:close()
	self.pr = nil
	self.log_view = nil
end

function M:open()
	local config = {
		mappings = {
			n = {
				["<c-t>"] = function()
					self:open_alldiff_view()
				end,
				["<F5>"] = function()
					if not self.pr.number then
						vim.notify("not a pr", vim.log.levels.WARN, {})
						return
					end
					local pr_number = self.pr.number
					local answer = vim.fn.confirm(string.format("Refresh pr %d?", pr_number), "&yes\n&no")
					if answer ~= 1 then
						return
					end
					self:close()
					vim.cmd("redraw")
					require("gitee").do_gitee_pr(pr_number)
				end,
			},
		},
	}
	self.log_view:open(config)
end

return M
