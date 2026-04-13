-- lua/custom/git_file_history.lua
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local sorters = require 'telescope.sorters'
local previewers = require 'telescope.previewers'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local Job = require 'plenary.job'

local M = {}

local function job_capture(cmd, args, cwd)
  local out = { code = 0, stdout = {}, stderr = {} }
  Job:new({
    command = cmd,
    args = args,
    cwd = cwd,
    on_exit = function(j, return_val)
      out.code = return_val
      out.stdout = j:result() or {}
      out.stderr = j:stderr_result() or {}
    end,
  }):sync()
  return out
end

local function get_git_root(start_dir)
  local r = job_capture('git', { 'rev-parse', '--show-toplevel' }, start_dir)
  if r.code ~= 0 or not r.stdout[1] then
    return nil
  end
  return r.stdout[1]
end

local function relpath_from_root(root, abs_path)
  local p = abs_path:gsub('\\', '/')
  local r = root:gsub('\\', '/')
  if p:sub(1, #r) == r then
    local rel = p:sub(#r + 2) -- skip "/"
    if rel ~= '' then
      return rel
    end
  end
  return nil
end

local function file_commits(root)
  local args = {
    'log',
    '--all',
    '--date=short',
    '--decorate=short',
    '--pretty=format:%H%x09%h%x09%ad%x09%d%x09%s',
  }
  local r = job_capture('git', args, root)
  if r.code ~= 0 then
    return nil, table.concat(r.stderr, '\n')
  end

  local commits = {}
  for _, line in ipairs(r.stdout) do
    local full, short, date, deco, subject = line:match '([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t(.+)'
    if full and short and date and subject then
      table.insert(commits, {
        full = full,
        short = short,
        date = date,
        deco = deco,
        subject = subject,
      })
    end
  end
  return commits
end

local function git_show_file(root, full_hash, relpath)
  local spec = string.format('%s:%s', full_hash, relpath)
  local r = job_capture('git', { 'show', spec }, root)
  if r.code ~= 0 then
    local err = table.concat(r.stderr, '\n')
    if err:match("Path '.*' does not exist") or err:match('exists on disk, but not in') then
      return nil, 'File does not exist in this commit.'
    end
    return nil, err
  end
  return r.stdout
end

local function open_revision_in_window(opts)
  local root = opts.root
  local relpath = opts.relpath
  local entry = opts.entry
  local win_cmd = opts.win_cmd or 'split'
  local filetype = opts.filetype

  local lines, err = git_show_file(root, entry.full, relpath)
  if not lines then
    vim.notify(('git show failed: %s'):format(err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local name = ('%s @ %s'):format(relpath, entry.short)
  vim.api.nvim_buf_set_name(buf, name)

  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })

  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('readonly', true, { buf = buf })

  if filetype and filetype ~= '' then
    vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
  end

  vim.cmd(win_cmd)
  vim.api.nvim_win_set_buf(0, buf)
end

function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  local abs = vim.api.nvim_buf_get_name(bufnr)
  if abs == '' then
    vim.notify('Buffer is not associated with a file.', vim.log.levels.ERROR)
    return
  end

  local start_dir = vim.fn.fnamemodify(abs, ':h')
  local root = get_git_root(start_dir)
  if not root then
    vim.notify('Not inside a git repository.', vim.log.levels.WARN)
    return
  end

  local rel = relpath_from_root(root, abs)
  if not rel then
    vim.notify('File is not under the git root.', vim.log.levels.WARN)
    return
  end

  local commits, err = file_commits(root)
  if not commits then
    vim.notify(('git log failed: %s'):format(err or 'unknown error'), vim.log.levels.ERROR)
    return
  end
  if #commits == 0 then
    vim.notify('No commits found for this file (maybe untracked).', vim.log.levels.WARN)
    return
  end

  local ft = vim.bo[bufnr].filetype

  pickers
    .new({}, {
      prompt_title = ('Git file history: %s'):format(rel),

      finder = finders.new_table {
        results = commits,
        entry_maker = function(c)
          local deco = (c.deco and c.deco ~= '') and c.deco or ''
          return {
            value = c,
            display = ('%s  %s  %s  %s'):format(c.short, c.date, deco, c.subject),
            -- -- makes searching by commit hash work well
            ordinal = table.concat({ c.full, c.short, c.date, deco, c.subject }, ' '),
          }
        end,
      },

      sorter = sorters.get_generic_fuzzy_sorter(),

      previewer = previewers.new_buffer_previewer {
        title = 'File @ commit',
        define_preview = function(self, entry)
          local c = entry.value
          local lines, show_err = git_show_file(root, c.full, rel)
          if not lines then
            lines = { ('git show failed: %s'):format(show_err or 'unknown error') }
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          if ft and ft ~= '' then
            vim.api.nvim_set_option_value('filetype', ft, { buf = self.state.bufnr })
          end
        end,
      },

      attach_mappings = function(prompt_bufnr, map)
        local function open_with(cmd)
          local selection = action_state.get_selected_entry()
          if not selection or not selection.value then
            return
          end
          actions.close(prompt_bufnr)
          open_revision_in_window {
            root = root,
            relpath = rel,
            entry = selection.value,
            win_cmd = cmd,
            filetype = ft,
          }
        end

        -- Default: open in split, leaving current pane unchanged
        actions.select_default:replace(function()
          open_with 'split'
        end)

        -- Optional: vsplit/tab mappings in this picker (works regardless of your global Telescope mappings)
        map('i', '<C-v>', function()
          open_with 'vsplit'
        end)
        map('n', 'v', function()
          open_with 'vsplit'
        end)

        map('i', '<C-t>', function()
          open_with 'tabnew'
        end)
        map('n', 't', function()
          open_with 'tabnew'
        end)

        return true
      end,
    })
    :find()
end

return M
