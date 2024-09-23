local M = {}

local log = require("ijhttp-nvim.log")

function M.exec(opts)
  local command_params = {}
  table.insert(command_params, "--log-level=VERBOSE" )
  table.insert(command_params, "--socket-timeout=300000" )
  if opts.env_file and opts.env then
    table.insert(command_params, "--env-file=" .. opts.env_file)
    table.insert(command_params, "--env=" .. opts.env)
  end
  local params = table.concat(command_params, " ")
  local command = opts.ijhttp_path .. " " .. params .. " " .. opts.request_file
  log.info(command)
  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(job_id, data, event)
      if data and opts.on_success then
        --local result = table.concat(data, "\n")
        --if result ~= "" then
        --  opts.on_success(result)
        --end
        opts.on_success(data)
      end
    end,
    on_stderr = function(job_id, data, event)
      if data and opts.on_error then
        --local error = table.concat(data, "\n")
        --if error ~= "" then
        --  opts.on_error(error)
        --end
        opts.on_error(data)
      end
    end,
  })
end

return M
