-- lua/custom/telescope_pickers/init.lua
local M = {}

function M.scope_method()
  require('custom.telescope_pickers.scope_method').open()
end

function M.git_file_history()
  require('custom.telescope_pickers.git_file_history').open()
end

return M
