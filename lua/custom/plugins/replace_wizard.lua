-- lua/custom/plugins/replace_wizard.lua
return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      ----------------------------------------------------------------
      -- Helpers
      ----------------------------------------------------------------
      local function escape_delim(s, delim)
        s = s or ''
        if vim.pesc then
          return s:gsub(vim.pesc(delim), '\\' .. delim)
        else
          local lua_pat = (delim or '#'):gsub('([^%w])', '%%%1')
          return s:gsub(lua_pat, '\\' .. (delim or '#'))
        end
      end

      -- Build :%s#lhs#rhs#flags (range can be "%", "'<,'>", ".", etc.)
      local function build_substitute(range, pat, repl, flags, delim)
        delim = delim or '#'
        local lhs = '\\V' .. escape_delim(pat, delim) -- treat pattern literally
        local rhs = escape_delim(repl, delim)
        return (':' .. (range or '') .. 's' .. delim .. lhs .. delim .. rhs .. delim .. (flags or ''))
      end

      local function current_word_or_selection()
        if vim.fn.mode():match '[vV\22]' then
          local save_reg = vim.fn.getreg 'z'
          local save_type = vim.fn.getregtype 'z'
          vim.cmd.normal { args = { [["zy]] }, bang = true }
          local text = vim.fn.getreg 'z'
          vim.fn.setreg('z', save_reg, save_type)
          return text
        else
          return vim.fn.expand '<cword>'
        end
      end

      ----------------------------------------------------------------
      -- Synchronous wrappers for vim.ui.input / vim.ui.select
      ----------------------------------------------------------------
      local function ui_input_sync(opts)
        local co = coroutine.running()
        local out, done = nil, false
        vim.ui.input(opts or {}, function(v)
          out, done = v, true
          if co and coroutine.status(co) == 'suspended' then
            coroutine.resume(co)
          end
        end)
        if not done then
          coroutine.yield()
        end
        return out
      end

      -- Add format_item so Telescope ui-select renders table items by their label
      local function ui_select_sync(items, opts)
        opts = opts or {}
        if not opts.format_item then
          opts.format_item = function(item)
            if type(item) == 'table' and item.label then
              return item.label
            end
            return tostring(item)
          end
        end
        local co = coroutine.running()
        local out, done = nil, false
        vim.ui.select(items, opts, function(v)
          out, done = v, true
          if co and coroutine.status(co) == 'suspended' then
            coroutine.resume(co)
          end
        end)
        if not done then
          coroutine.yield()
        end
        return out
      end

      ----------------------------------------------------------------
      -- Wizard
      ----------------------------------------------------------------
      local function interactive_substitute()
        -- 1) Scope
        local scopes = {
          { label = 'Buffer (:%s … g)', range = '%', flags = 'g' },
          { label = "Visual Selection ('<,'>)", range = "'<,'>", flags = 'g' },
          { label = 'Current line (:.s)', range = '.', flags = 'g' },
        }
        local chosen = ui_select_sync(scopes, { prompt = 'Scope?' }) or scopes[1]
        local range = chosen.range
        if chosen.label:find 'Visual' and not vim.fn.mode():match '[vV\22]' then
          vim.notify('No visual selection detected; falling back to Buffer scope.', vim.log.levels.WARN)
          range = '%'
        end

        -- 2) Pattern
        local default_pat = current_word_or_selection() or ''
        local pat = ui_input_sync { prompt = 'Find:', default = default_pat } or ''
        if pat == '' then
          return
        end

        -- 3) Replacement
        local repl = ui_input_sync { prompt = 'Replace with:', default = '' }
        if repl == nil then
          return
        end

        -- 4) Flags
        local flag_options = {
          { label = 'g  (global in line)', val = 'g' },
          { label = 'gc (confirm each)', val = 'gc' },
          { label = 'gi (global + ignorecase)', val = 'gi' },
          { label = 'gI (global + smartcase off)', val = 'gI' },
          { label = 'Custom…', val = '__custom' },
          { label = '(none)', val = '' },
        }
        local choice = ui_select_sync(flag_options, { prompt = 'Flags?' }) or flag_options[1]
        local flags = choice.val
        if flags == '__custom' then
          flags = ui_input_sync { prompt = 'Enter flags (e.g. g, gc, gi, gIc):', default = chosen.flags } or chosen.flags
        end

        -- 5) Execute
        vim.cmd(build_substitute(range, pat, repl, flags, '#'))
      end

      -- Run wizard in a coroutine so ui.* can yield properly
      local function start_wizard()
        coroutine.wrap(interactive_substitute)()
      end

      ----------------------------------------------------------------
      -- Keymaps (which-key v3)
      ----------------------------------------------------------------
      local ok, wk = pcall(require, 'which-key')
      if ok and wk.add then
        wk.add {
          { '<leader>r', group = 'replace' },

          { '<leader>rr', start_wizard, desc = 'Find & Replace (wizard)', mode = 'n' },

          {
            '<leader>rb',
            function()
              local word = current_word_or_selection() or ''
              local repl = ui_input_sync { prompt = ("Replace '%s' with:"):format(word), default = '' }
              if repl == nil then
                return
              end
              vim.cmd(build_substitute('%', word, repl, 'g', '#'))
            end,
            desc = 'Quick: buffer (word → …)',
            mode = 'n',
          },

          {
            '<leader>rc',
            function()
              local word = current_word_or_selection() or ''
              local repl = ui_input_sync { prompt = ("Replace '%s' with: (confirm each)"):format(word), default = '' }
              if repl == nil then
                return
              end
              vim.cmd(build_substitute('%', word, repl, 'gc', '#'))
            end,
            desc = 'Quick: confirm each',
            mode = 'n',
          },

          {
            '<leader>rv',
            function()
              if vim.fn.mode():match '[vV\22]' then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
                vim.cmd 'normal! gv'
              end
              start_wizard()
            end,
            desc = 'Wizard on selection',
            mode = { 'n', 'x' },
          },
        }
      else
        -- Fallback without which-key
        vim.keymap.set('n', '<leader>rr', start_wizard, { desc = 'Find & Replace (wizard)' })
        vim.keymap.set('n', '<leader>rb', function()
          local word = current_word_or_selection() or ''
          local repl = ui_input_sync { prompt = ("Replace '%s' with:"):format(word), default = '' }
          if repl == nil then
            return
          end
          vim.cmd(build_substitute('%', word, repl, 'g', '#'))
        end, { desc = 'Quick: buffer (word → …)' })
        vim.keymap.set('n', '<leader>rc', function()
          local word = current_word_or_selection() or ''
          local repl = ui_input_sync { prompt = ("Replace '%s' with: (confirm each)"):format(word), default = '' }
          if repl == nil then
            return
          end
          vim.cmd(build_substitute('%', word, repl, 'gc', '#'))
        end, { desc = 'Quick: confirm each' })
      end
    end,
  },
}
