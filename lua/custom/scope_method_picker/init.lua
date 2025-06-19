-- Main picker logic
local ts = vim.treesitter
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local sorters = require 'telescope.sorters'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local entry_display = require 'telescope.pickers.entry_display'

local M = {}

local function is_method(node)
  local parent = node:parent()
  while parent do
    if parent:type() == 'class_definition' then
      return true
    end
    parent = parent:parent()
  end
  return false
end

local function classify(node)
  local type = node:type()
  if type == 'class_definition' then
    return 'class'
  elseif type == 'function_definition' then
    if is_method(node) then
      return 'method'
    else
      return 'function'
    end
  else
    return type
  end
end

local function collect_symbols(bufnr, filepath)
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()

  local result = {}
  local function recurse(n)
    local kind = classify(n)
    if kind == 'class' or kind == 'function' or kind == 'method' then
      local name_nodes = n:field 'name'
      if not name_nodes or #name_nodes == 0 then
        return
      end
      local name = ts.get_node_text(name_nodes[1], bufnr)
      local start_row, _ = n:start()
      table.insert(result, {
        name = name,
        kind = kind,
        lnum = start_row + 1,
        filepath = filepath,
      })
    end
    for child, _ in n:iter_children() do
      recurse(child)
    end
  end
  recurse(root)
  return result
end

function M.scoped_method_and_class_telescope()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' then
    vim.notify('Buffer is not associated with a file.', vim.log.levels.ERROR)
    return
  end

  local symbols = collect_symbols(bufnr, filepath)

  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 20 },
      { remaining = true },
    },
  }

  pickers
    .new({}, {
      prompt_title = 'Treesitter Symbols',
      finder = finders.new_table {
        results = symbols,
        entry_maker = function(entry)
          return {
            value = entry,
            ordinal = entry.name,
            display = function(e)
              return displayer {
                e.value.name,
                e.value.kind,
              }
            end,
            filename = entry.filepath,
            lnum = entry.lnum,
          }
        end,
      },
      sorter = sorters.get_generic_fuzzy_sorter(),
      previewer = conf.grep_previewer {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
        end)
        return true
      end,
    })
    :find()
end

return M
