local M = {}

local parser = require("ijhttp-nvim.parser")
local utils = require("ijhttp-nvim.utils")
local log = require("ijhttp-nvim.log")

M._panes = {}
local prepare_winbar_content
local filetype

function M.render(buf, content)
  local parsed = parser.parse(content)
  M._panes = {}
  M._panes[1] = parsed.raw
  M._panes[2] = parsed.lastItem and parsed.lastItem.response.body
  M._panes[3] = parsed.lastItem and parsed.lastItem.response.headers_raw
  M._content = parsed

  M._win = vim.api.nvim_get_current_win()
  M._content_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(M._win, M._content_buf)
  if parsed.lastItem and parsed.lastItem.response.body and #parsed.lastItem.response.body > 0 then
    M.show_pane(2)
  else
    M.show_pane(1)
  end
end

function M.show_pane(num)
  vim.api.nvim_buf_set_lines(M._content_buf, 0, -1, false, M._panes[num])
  local content = prepare_winbar_content(num)
  vim.api.nvim_set_hl(0, "IjhttpWinbarSelected", { bold = true })
  vim.api.nvim_set_option_value('winbar', content, { win = M._win })
  vim.api.nvim_buf_set_option(M._content_buf, "filetype", filetype(num))
  M._current_pane = num
end

function M.next_pane()
  local num = M._current_pane + 1
  if num > #M._panes then
    num = 1
  end
  M.show_pane(num)
end

function M.prev_pane()
  local num = M._current_pane - 1
  if num < 1 then
    num = #M._panes
  end
  M.show_pane(num)
end

prepare_winbar_content = function(num)
  local pane_names = { "Raw", "Body", "Headers" }
  local content = ""
  for index, pane in ipairs(pane_names) do
    local value = pane
    if index == num then
      value = "%#IjhttpWinbarSelected#" .. pane .. "%*"
    end
    content = content .. value
    if index < #pane_names then
      content = content .. " | "
    end
  end
  return content
end

filetype = function(num)
  if num == 2 then
    local content_type = M._content.lastItem.response.headers["Content-Type"]
    if content_type and utils.starts_with(content_type, "application/json") then
      return "json"
    end
  end
  return nil
end

return M
