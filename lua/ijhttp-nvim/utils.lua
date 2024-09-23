local M = {}

function M.trim(s)
   return s:match("^%s*(.-)%s*$")
end

function M.split_by_line_break(input)
    local result = {}
    for line in input:gmatch("([^\r\n]+)") do
        table.insert(result, line)
    end
    return result
end

function M.starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

function M.ends_with(text, suffix)
  return text:sub(-#suffix) == suffix
end

return M
