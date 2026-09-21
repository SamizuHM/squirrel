-- Native Rime filtering keeps key selection, mouse selection and learning aligned.
local M = {}
local function hex(s)
  return (s:gsub('.', function(c) return string.format('%02x', string.byte(c)) end))
end

M.filter = function(input, env)
  local context = env.engine.context
  local pool, tail = {}, nil
  local first
  for candidate in input:iter() do
    if not first then first = candidate end
    if #pool >= 24 or candidate.start ~= first.start or candidate._end ~= first._end then
      tail = candidate
      break
    end
    pool[#pool + 1] = candidate
  end
  if #pool == 0 then return end
  local request = context.input .. ':' .. tostring(first.start) .. ':' .. tostring(first._end)
  for _, candidate in ipairs(pool) do request = request .. '\n' .. hex(candidate.text) end
  context:set_property('jev_request', request)
  local ranked = {}
  if context:get_option('jev_enabled') and
      context:get_property('jev_order_key') == request then
    for index, probability in context:get_property('jev_order'):gmatch('(%d+):([%d%.]+)') do
      index = tonumber(index) + 1
      if pool[index] and not ranked[index] then
        ranked[index] = true
        local c = pool[index]
        yield(ShadowCandidate(c, c.type, c.text,
          (c.comment or '') .. ' Jev ' .. string.format('%.0f%%', tonumber(probability) * 100)))
      end
    end
  end
  for index, candidate in ipairs(pool) do
    if not ranked[index] then yield(candidate) end
  end
  if tail then yield(tail) end
  for candidate in input:iter() do yield(candidate) end
end

M.processor = function(key, env)
  local context = env.engine.context
  -- This key is injected ONLY by the polling IPC after a matching response.
  if key.keycode == 0xffd5 and context:get_property('jev_refresh') == '1' then
    context:set_property('jev_refresh', '')
    context:refresh_non_confirmed_composition()
    return 1
  end
  return 2
end
return M
