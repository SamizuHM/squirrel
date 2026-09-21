-- Native Rime filtering keeps key selection, mouse selection and learning aligned.
local M = {}
local function hex(s)
  return (s:gsub('.', function(c) return string.format('%02x', string.byte(c)) end))
end

local function append_comment(base, suffix)
  if not suffix or suffix == '' then return base or '' end
  if not base or base == '' then return suffix end
  return base .. ' · ' .. suffix
end

local function status_label(context, request)
  if context:get_property('jev_status_visible') == '0' or
      not context:get_option('jev_enabled') then
    return nil
  end
  local status = context:get_property('jev_status') or ''
  if status == 'ranked' and context:get_property('jev_order_key') ~= request then
    status = 'context'
  end
  return ({
    context = 'Jev 上下文',
    pending = 'Jev 请求中',
    ranked = 'Jev 已重排',
    none = 'Jev 未采用',
    error = 'Jev 失败',
    no_context = 'Jev 无上下文',
    frozen = 'Jev 已冻结',
    ['local'] = 'Jev 本地',
    disabled = 'Jev 未启用',
  })[status]
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
  local status = status_label(context, request)
  local status_added = false
  local ranked = {}
  if context:get_option('jev_enabled') and
      context:get_property('jev_order_key') == request then
    for index, probability in context:get_property('jev_order'):gmatch('(%d+):([%d%.]+)') do
      index = tonumber(index) + 1
      if pool[index] and not ranked[index] then
        ranked[index] = true
        local c = pool[index]
        local comment = append_comment(c.comment or '',
          status_added and nil or status)
        status_added = status_added or status ~= nil
        comment = append_comment(comment,
          'Jev ' .. string.format('%.0f%%', tonumber(probability) * 100))
        yield(ShadowCandidate(c, c.type, c.text,
          comment))
      end
    end
  end
  for index, candidate in ipairs(pool) do
    if not ranked[index] then
      if status and not status_added then
        status_added = true
        yield(ShadowCandidate(candidate, candidate.type, candidate.text,
          append_comment(candidate.comment or '', status)))
      else
        yield(candidate)
      end
    end
  end
  if tail then
    if status and not status_added then
      status_added = true
      yield(ShadowCandidate(tail, tail.type, tail.text,
        append_comment(tail.comment or '', status)))
    else
      yield(tail)
    end
  end
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
