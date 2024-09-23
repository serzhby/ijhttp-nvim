local M = {}

local log = require("ijhttp-nvim.log")
local utils = require("ijhttp-nvim.utils")
local dkjson = require("ijhttp-nvim.deps.dkjson")

local SEPARATOR = "###"
local HEADER = "header"
local REQUEST_NUM_LINE = "request_num_line"
local REQUEST_START_SEPARATOR = "request_start_separator"
local REQUEST_LINE = "request_line"
local REQUEST_HEADER = "request_header"
local REQUEST_BODY = "request_body"
local RESPONSE_START_SEPARATOR = "response_start_separator"
local RESPONSE_LINE = "response_line"
local RESPONSE_HEADER = "response_header"
local RESPONSE_BODY = "response_body"
local RESPONSE_STATS = "response_stats"

function M.parse(response)
  local parsed = M._parse_lines(response)
  local result = M._parse_response(parsed)
  return result
end

function M._parse_lines(response)
  local curmode = nil
  local result = {
    raw = response,
    items = {},
    lastItem = nil
  }

  local lines = response
  for _, line in pairs(lines) do
    local l = utils.trim(line)
    curmode = M._define_mode(l, curmode)
    M._apply_mode(curmode, l, result)
  end
  return result
end

function M._parse_response(response)
  local result = {
    raw = response.raw,
    items = {},
    lastItem = nil
  }
  for _, item in pairs(response.items) do
    table.insert(result.items, {
      request = M._parse_rq_rs(item.request),
      response = M._parse_rq_rs(item.response)
    })
  end
  result.lastItem = result.items[#result.items]
  return result
end

function M._define_mode(line, prevmode)
  if line:match("^[┌│├└]") then
    return HEADER
  elseif line:match("Request \'") then
    return REQUEST_NUM_LINE
  elseif line:match("= request =>") then
    return REQUEST_START_SEPARATOR
  elseif line:match("<= response =") then
    return RESPONSE_START_SEPARATOR
  elseif line == SEPARATOR then
    return "UNKNOWN"
  elseif line:match("Response code") then
    return RESPONSE_STATS
  else
    if prevmode == REQUEST_START_SEPARATOR then
      return REQUEST_LINE
    elseif prevmode == REQUEST_LINE then
      return REQUEST_HEADER
    elseif prevmode == REQUEST_HEADER and #line > 0 then
      return REQUEST_HEADER
    elseif prevmode == REQUEST_HEADER and #line == 0 then
      return REQUEST_BODY
    elseif prevmode == REQUEST_BODY then
      return REQUEST_BODY
    elseif prevmode == RESPONSE_START_SEPARATOR then
      return RESPONSE_LINE
    elseif prevmode == RESPONSE_LINE then
      return RESPONSE_HEADER
    elseif prevmode == RESPONSE_HEADER and #line > 0 then
      return RESPONSE_HEADER
    elseif prevmode == RESPONSE_HEADER and #line == 0 then
      return RESPONSE_BODY
    elseif prevmode == RESPONSE_BODY then
      return RESPONSE_BODY
    else
      return "UNKNOWN"
    end
  end
end

function M._apply_mode(mode, line, result)
  local last = function(table) return table[#table] end
  if mode == HEADER then
    if not result.header then
      result.header = {}
    end
    table.insert(result.header, line)
  elseif mode == REQUEST_NUM_LINE then
    table.insert(result.items, {
      request = {
        line = nil,
        headers = {},
        body = {}
      },
      response = {
        line = nil,
        headers = {},
        body = {}
      }
    })
  elseif mode == REQUEST_LINE then
    last(result.items).request.line = line
  elseif mode == REQUEST_HEADER then
    table.insert(last(result.items).request.headers, line)
  elseif mode == REQUEST_BODY then
    table.insert(last(result.items).request.body, line)
  elseif mode == RESPONSE_LINE then
    last(result.items).response.line = line
  elseif mode == RESPONSE_HEADER then
    table.insert(last(result.items).response.headers, line)
  elseif mode == RESPONSE_BODY then
    table.insert(last(result.items).response.body, line)
  end
end

function M._parse_rq_rs(rq_rs)
  local headers = M._parse_headers(rq_rs.headers)
  local body = M._format_body(headers["Content-Type"], rq_rs.body)
  return {
    headers_raw = rq_rs.headers,
    headers = headers,
    body = body
  }
end

function M._parse_headers(headers)
  local result = {}
  for _, header in pairs(headers) do
    local parts = M._split_header(header)
    if #parts == 2 then
      if parts[1] == 'Set-Cookie' then
        result[parts[1]] = M._parse_set_cookie(parts[2])
      else
        result[parts[1]] = parts[2]
      end
    else
      log.error("Header " .. header .. " is incorrect.")
    end
  end
  return result
end

function M._format_body(content_type, body)
  local b = M._remove_empty_lines(body)
  if content_type and utils.starts_with(content_type, "application/json") then
    local text = table.concat(body, "\n")
    local func = function() return M._try_format_json(text) end
    local status, result = pcall(func)
    if status then
      b = result
    end
  end
  return b
end

function M._try_format_json(text)
  local json = vim.json.decode(text)
  local encoded = dkjson.encode(json, { indent = true })
  return utils.split_by_line_break(encoded)
end

function M._parse_set_cookie(header)
  local result = {}
  for option in header:gmatch("[^;]+") do
    local key, value = option:match("^%s*(.-)%s*=%s*(.-)%s*$")
    if key and value then
      result[key] = value
    else
      -- If there's no '=' in the option, it's a flag (e.g., "Secure" or "HttpOnly")
      key = option:match("^%s*(.-)%s*$")
      result[key] = true
    end
  end
  return result
end

function M._split_header(input)
  local colon_pos = string.find(input, ":", 1, true)
  if not colon_pos then
    return {input}
  end
  return {
    utils.trim(string.sub(input, 1, colon_pos - 1)),
    utils.trim(string.sub(input, colon_pos + 1))
  }
end

function M._remove_empty_lines(t)
  local result = {}
  for _, line in pairs(t) do
    if #line > 0 then
      table.insert(result, line)
    end
  end
  return result
end

return M
