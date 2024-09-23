local M = {}

local uv = vim.uv or vim.loop

---@type boolean
M.is_windows = uv.os_uname().version:match("Windows")

M.is_mac = uv.os_uname().sysname == "Darwin"

M.is_linux = not M.is_windows and not M.is_mac

---@type string
M.sep = M.is_windows and "\\" or "/"

M.mkdirp = function(dir, mode)
  mode = mode or 493
  local mod = ""
  local path = dir
  while vim.fn.isdirectory(path) == 0 do
    mod = mod .. ":h"
    path = vim.fn.fnamemodify(dir, mod)
  end
  while mod ~= "" do
    mod = mod:sub(3)
    path = vim.fn.fnamemodify(dir, mod)
    uv.fs_mkdir(path, mode)
  end
end

M.is_absolute = function(dir)
  if M.is_windows then
    return dir:match("^%a:\\")
  else
    return vim.startswith(dir, "/")
  end
end

function M.abspath(path)
  if not M.is_absolute(path) then
    path = vim.fn.fnamemodify(path, ":p")
  end
  return path
end

function M.write(path, content)
  local file = io.open(path, "w")
  if file ~= nil then
    local text = content
    if type(content) == "table" then
      text = table.concat(content, "\n")
    end
    file:write(text)
    file:close()
  else
    error("Error writing to file " .. path)
  end
end

function M.split_path(path)
  local index = path:match("^.*()" .. M.sep)
  -- Split the path into directory and filename
  local directory = path:sub(1, index)
  local filename = path:sub(index + 1)
  return directory, filename
end

function M.rebase(path, base, new_base)
  local subpath = M.subpath(path, base)
  return M.concat(new_base, subpath)
end

function M.subpath(path, base)
  if base:sub(-1) ~= M.sep then
      base = base .. M.sep
  end
  local subpath = path:sub(#base + 1)
  return subpath
end

function M.concat(path, subpath)
  if path:sub(-1) ~= M.sep then
    path = path .. M.sep
  end
  if subpath:sub(1, 1) == M.sep then
    subpath = subpath:sub(2)
  end
  return path .. subpath
end

function M._is_file(path)
  local f = io.open(path, "r") -- Attempt to open the file
  return f ~= nil and f.close(f)
end

function M.find_upward(path, file_name)
  if not path then error("path is nil") end
  if not file_name then error("file_name is nil") end
  local base = M.abspath(path)
  local result = vim.fn.findfile(file_name, base .. ";")
  if #result == 0 then
    return nil
  else
    return M.abspath(result)
  end
end

function M.get_parent_directory(file_path)
    -- Split the file path by the directory separator
    local parts = {}
    if not file_path then
      return nil
    end
    for part in string.gmatch(file_path, "[^" .. M.sep .. "]+") do
        table.insert(parts, part)
    end

    if #parts > 0 then
      local parent_directory = table.concat(parts, M.sep, 1, #parts - 1)
      if M.is_windows then
        return parent_directory
      else
        return M.sep .. parent_directory
      end
    else
      return nil
    end
end

function M.read_lines(file)
  if not M._is_file(file) then return nil end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

return M
