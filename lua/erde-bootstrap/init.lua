local M = {
	erde = nil,

	--- Only used for auto-setup from `plugin/erde-bootstrap.vim`.
	_default_plugin_config = {
		strict = false,
		auto = true,
	},
}

--- @param rhs table?
---@param lhs table?
---@return table
local function merge_override(lhs, rhs)
	return vim.tbl_deep_extend("force", lhs or {}, rhs or {})
end

--- Returns a loader.
function M.searcher(module_name)
	vim.validate {
		module_name = { module_name, "string" },
	}
	local modname = module_name:gsub("/", ".")

	local fname
	local as_file = vim.fn.globpath(vim.o.runtimepath, string.format("lua/%s.erde", modname))
	if as_file then
		fname = as_file
	else
		local as_dir = vim.fn.globpath(vim.o.runtimepath, string.format("lua/%s/init.erde", modname))
		fname = as_dir
	end

	if not fname or fname == "" then
		return string.format("'%s' not found in &runtimepath", fname)
	end

	local loader = function()
		local file = io.open(fname, "r")
		assert(file)
		if not file then
			return nil
		end
		local text = file:read("*a")
		assert(text)
		if not M.erde then
			M.setup()
		end
		local results = M.erde.run(text, {
			lua_target = "5.1+",
			alias = module_name,
		})
		assert(results)
		return results
	end

	return loader
end

function M.setup(opts)
	opts = opts or {}
	if opts.auto and M.erde ~= nil then
		-- Don't override existing setup() from plugin/erde-bootstrap.vim.
		return M
	end

	local erde_path = vim.fn.globpath(vim.o.runtimepath, "erde/init.lua")
	local erde_root = vim.fs.dirname(vim.fs.dirname(erde_path))

	if not erde_path then
		vim.notify("erde-bootstrap: could not find erde in vim runtimepath", vim.log.levels.ERROR)
		return false
	end

	local path_list = vim.split(package.path, ";")
	table.insert(path_list, string.format("%s/?/init.lua", erde_root))
	table.insert(path_list, string.format("%s/?.lua", erde_root))
	local package_path = vim.iter(path_list):join(";")
	assert(package_path ~= nil)
	package.path = package_path

	--local erde = dofile(erde_path)
	local erde = require("erde")
	assert(erde ~= nil)
	M.erde = erde

	table.insert(package.loaders, M.searcher)

	return M
end

function M._plugin_setup()
	local opts = merge_override(vim.g.erde_config, M._default_plugin_config)
	return M.setup(opts)
end

return M
