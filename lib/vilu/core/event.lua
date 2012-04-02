local M = {}

function M.emit(event, t)
  _G.print("")
  _G.print("event = " .. _G.tostring(event))
  for k, v in pairs(t or {}) do
    print(k .. ' = ' .. _G.tostring(v))
  end
  return false
end


return M
