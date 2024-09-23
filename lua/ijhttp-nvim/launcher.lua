local M = {}

local client = require("ijhttp-nvim.client")
local fs = require("ijhttp-nvim.fs")
local log = require("ijhttp-nvim.log")
local context = require("ijhttp-nvim.context")
local vars = require("ijhttp-nvim.vars")

local is_warn_env
local show_confirmation_dialog
local get_current_buffer_content
local write_request_to_file
local show_fetching_win
local close_fetching_win
local display_result
local close_result_win
local close_win

function M.launch(opts, args)
  local current_file_path = vim.api.nvim_buf_get_name(0)
  local ctx = context.build_context(opts, args, current_file_path)
  log.debug("opts " .. vim.inspect(opts))
  log.debug("context " .. vim.inspect(ctx))
  if not is_warn_env(ctx, opts) or show_confirmation_dialog(ctx) then
    local content = get_current_buffer_content()
    write_request_to_file(ctx, content)
    close_result_win()
    show_fetching_win()

    local on_success = function(data)
      if #data > 0 and #data[1] > 0 then
        fs.write(ctx.response_file_path, data)
        close_fetching_win()
        display_result(ctx)
      end
    end
    local on_error = function(data)
      if #data > 0 and #data[1] > 0 then
        vim.api.nvim_buf_set_lines(M._fetching_buf, 0, -1, false, data)
      end
    end
    --local v = vars.read(ctx)
    --log.error(vim.inspect(v))
    client.exec({
      ijhttp_path = ctx.ijhttp_path,
      request_file = ctx.request_file_path,
      env_file = ctx.env_file,
      env = ctx.env,
      vars = v,
      on_success = on_success,
      on_error = on_error
    })
  else
    log.warn("Operation cancelled")
  end
end

is_warn_env = function(ctx, opts)
  if opts.env_warn == nil or ctx.env == nil then
    return false
  end
  if type(opts.env_warn) == 'string' and opts.env_warn == ctx.env then
    return true
  end
  if type(opts.env_warn) == 'table' then
    for _, v in pairs(opts.env_warn) do
      if v == ctx.env then
        return true
      end
    end
  end
  return false
end

show_confirmation_dialog = function(ctx)
  local prompt = "You are abount to execute the query on " .. ctx.env .. " env. Are you sure you want to proceed?"
  local answer = vim.fn.input(prompt .. " [y/N]: ")
  answer = string.lower(answer)
  return answer == 'y' or answer == 'yes'
end

get_current_buffer_content = function()
  local original_buffer = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(original_buffer, 0, -1, false)
  return table.concat(content, "\n")
end

write_request_to_file = function(ctx, content)
  local dir, _ = fs.split_path(ctx.request_file_path)
  fs.mkdirp(dir)
  fs.write(ctx.request_file_path, content)
end

show_fetching_win = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Fething..."})
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  local win = vim.api.nvim_open_win(buf, false, {split = 'right'})
  M._fetching_win = win
end

close_fetching_win = function()
  close_win(M._fetching_win)
  M._fetching_win = nil
end

display_result = function(ctx)
  local bufnr = vim.fn.bufadd(ctx.response_file_path)
  if vim.fn.bufwinid(bufnr) < 0 then
    M._result_win = vim.api.nvim_open_win(bufnr, false, {split = 'right'})
  end
end

close_result_win = function()
  close_win(M._result_win)
  M._result_win = nil
end

close_win = function(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

return M
