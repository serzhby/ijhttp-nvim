local M = {}

local fs = require("ijhttp-nvim.fs")
local dkjson = require("ijhttp-nvim.deps.dkjson")

local parse_env_file

function M.read(ctx)
  local env_file_vars = parse_env_file(ctx.env_file)
  return env_file_vars
end

parse_env_file = function(file)
  if file ~= nil then
    local lines = fs.read_lines(file)
    return dkjson.decode(lines, 1, nil)
  else
    return {}
  end
end

return M
