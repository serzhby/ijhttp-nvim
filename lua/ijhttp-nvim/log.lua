local M = {}

LogLevel = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4
}

M.log_level = LogLevel.INFO

local log

function M.debug(text)
  if M.log_level <= LogLevel.DEBUG then
    log("[DEBUG]", text)
  end
end

function M.info(text)
  if M.log_level <= LogLevel.INFO then
    log("[INFO]", text)
  end
end

function M.warn(text)
  if M.log_level <= LogLevel.WARN then
    log("[WARN]", text)
  end
end

function M.error(text)
  if M.log_level <= LogLevel.ERROR then
    log("[ERROR]", text)
  end
end

log = function(prefix, text)
  if not text then
    text = "nil"
  end
  if type(text) == "table" then
    text = vim.inspect(text)
  end
  if type(text) ~= "string" then
    text = tostring(text)
  end
  print(prefix .. " " .. text)
end

return M
