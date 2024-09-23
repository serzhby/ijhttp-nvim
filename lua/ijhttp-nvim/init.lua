local M = {}

local context = require("ijhttp-nvim.context")
local renderer = require("ijhttp-nvim.renderer")
local launcher = require("ijhttp-nvim.launcher")
local log = require("ijhttp-nvim.log")

M.opts = {}

log.log_level = LogLevel.WARN

local set_env
local print_context

function M.setup(opts)
  if opts.ijhttp_path == nil then
    error("ijhttp_path is required")
  end

  M.opts = {
    ijhttp_path = opts.ijhttp_path,
    project_config_file_name = opts.project_config_file_name or ".ijhttp.project",
    root_dir_name = opts.root_dir_name or ".ijhttp",
    env_file_name = opts.env_file_name or "http-client.env.json",
    env_warn = opts.env_warn or "prod",
    proxy = opts.proxy,
    socket_timeout = opts.socket_timeout
  }

  vim.api.nvim_create_autocmd({"BufRead","BufNewFile"}, {
    pattern = "*.http",
    callback = function(args)
      local current_file_path = vim.api.nvim_buf_get_name(0)
      context.init_env(M.opts, current_file_path)
    end
  })

  vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile", "BufEnter", "FileReadPost"}, {
    pattern = "*.ijrsp",
    callback = function(args)
      log.debug("[ijrsp] args " .. vim.inspect(args))
      local original_buffer = vim.api.nvim_get_current_buf()
      local content = vim.api.nvim_buf_get_lines(original_buffer, 0, -1, false)
      renderer.render(original_buffer, content)
      vim.keymap.set("n", "<Leader>wn", function()
        renderer.next_pane()
      end)
      vim.keymap.set("n", "<Leader>wp", function()
        renderer.prev_pane()
      end)
    end
  })
end

function M.execute(cmd, ...)
  local args = { ... }
  if cmd == "run" then
    launcher.launch(M.opts)
  elseif cmd == "set_env" then
    set_env(args[1])
  elseif cmd == "print_context" then
    print_context(M.opts, args)
  end
end

set_env = function(env)
  local current_file_path = vim.api.nvim_buf_get_name(0)
  context.set_env(M.opts, current_file_path, env)
end

print_context = function(opts, args)
  local current_file_path = vim.api.nvim_buf_get_name(0)
  local ctx = context.build_context(opts, args, current_file_path)
  print(vim.inspect(ctx))
end

return M
