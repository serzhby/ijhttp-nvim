local M = {}

local fs = require("ijhttp-nvim.fs")
local arguments = require("ijhttp-nvim.arguments")
local read_env

function M.build_context(opts, args, base_path)
  if not opts then error("opts is nil") end
  if not base_path then error("base_path is nil") end

  local parsed_args = arguments.parse_args(args)

  local ctx = {}
  ctx.ijhttp_path = opts.ijhttp_path
  ctx.project_file = fs.find_upward(base_path, opts.project_config_file_name)
  if ctx.project_file then
    -- Root path containing the project file
    ctx.project_root = fs.get_parent_directory(ctx.project_file)
    -- Path where project files are stored
    ctx.project_files_dir = fs.concat(ctx.project_root, opts.root_dir_name)
    -- path to a file containing active env name
    ctx.active_env_file = fs.concat(ctx.project_files_dir, "env")
    ctx.env = read_env(ctx.active_env_file)
    ctx.request_file_path = fs.rebase(base_path, ctx.project_root, ctx.project_files_dir)
    local dir, file = fs.split_path(ctx.request_file_path)
    ctx.response_file_path = fs.concat(dir, file .. ".ijrsp")
  else
    local tmp_name = vim.fn.tempname()
    ctx.request_file_path = tmp_name .. ".http"
    ctx.response_file_path = tmp_name .. ".ijrsp"
  end
  ctx.env_file = fs.find_upward(base_path, opts.env_file_name)
  return ctx
end

function M.set_env(opts, base_path, env)
  _G._ijhttp_nvim = { env = env }
  local ctx = M.build_context(opts, {}, base_path)
  if ctx.active_env_file then
    local dir, file = fs.split_path(ctx.active_env_file)
    fs.mkdirp(dir)
    fs.write(ctx.active_env_file, env)
  end
end

function M.init_env(opts, base_path)
  local ctx = M.build_context(opts, {}, base_path)
  local env = nil
  if ctx.active_env_file then
    env = read_env(ctx.active_env_file)
    _G._ijhttp_nvim = { env = env }
  end
  return env
end

read_env = function(path)
  local lines = fs.read_lines(path)
  if not lines or #lines ~= 1 then
    return nil
  else
    return lines[1]
  end
end

return M
