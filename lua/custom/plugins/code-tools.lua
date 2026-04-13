return {
  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        -- config = function() # TODO: fix, maybe by changing path
        --   require('luasnip.loaders.from_vscode').lazy_load { paths = { '.snippets' } }
        -- end,
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        -- opts = {},
      },
      'folke/lazydev.nvim',
      'giuxtaposition/blink-cmp-copilot',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'default',
        ['<Tab>'] = {
          -- first, try a LuaSnip expand or jump, but schedule it so it
          -- doesn’t violate Blink’s “no buffer edits” rule
          function(cmp)
            local ls = require 'luasnip'
            if ls.expand_or_jumpable() then
              vim.schedule(function()
                ls.expand_or_jump()
              end)
              return true
            end
          end,
          -- next, if we’re already inside a snippet, jump to the next placeholder
          'snippet_forward',
          -- finally, fall back to Blink’s normal <Tab> (completion movement, indent, etc.)
          'fallback',
        },

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
        -- Blink does not expose its default kind icons so you must copy them all (or set your custom ones) and add Copilot
        kind_icons = {
          Copilot = '',
          Text = '󰉿',
          Method = '󰊕',
          Function = '󰊕',
          Constructor = '󰒓',

          Field = '󰜢',
          Variable = '󰆦',
          Property = '󰖷',

          Class = '󱡠',
          Interface = '󱡠',
          Struct = '󱡠',
          Module = '󰅩',

          Unit = '󰪚',
          Value = '󰦨',
          Enum = '󰦨',
          EnumMember = '󰦨',

          Keyword = '󰻾',
          Constant = '󰏿',

          Snippet = '󱄽',
          Color = '󰏘',
          File = '󰈔',
          Reference = '󰬲',
          Folder = '󰉋',
          Event = '󱐋',
          Operator = '󰪚',
          TypeParameter = '󰬛',
        },
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev', 'copilot' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
          copilot = {
            name = 'copilot',
            module = 'blink-cmp-copilot',
            score_offset = 100,
            async = true,
          },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,

      -- Keep your function-based format_on_save, but make TeX NOT fall back to LSP.
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        -- local disable_filetypes = { c = true, cpp = true }
        local disable_filetypes = {}
        if disable_filetypes[ft] then
          return nil
        end
        -- For TeX, we want only the external tool (latexindent), no LSP fallback.
        if ft == 'tex' or ft == 'plaintex' then
          return { timeout_ms = 5000, lsp_format = false }
        end
        -- Everything else can still fall back to LSP if no external formatter exists.
        return { timeout_ms = 5000, lsp_format = 'fallback' }
      end,

      formatters_by_ft = {
        lua = { 'stylua' },
        -- python = { 'isort', 'black' },
        python = { 'isort', 'ruff' },
        tex = { 'latexindent' },
        plaintex = { 'latexindent' },
        text = { 'par_textwrap' },
        markdown = { 'par_textwrap' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        cpp = { 'clang_format' },
        c = { 'clang_format' },
        -- text = { 'par_textwrap' },
        -- markdown = { 'par_textwrap' },
      },

      -- Configure latexindent with flags that enforce hard-wrap
      formatters = {
        latexindent = {
          -- Read TeX from STDIN and write formatted TeX to STDOUT
          -- -m = modify line breaks (hard-wrap)
          -- -l <file> = use project-local yaml
          args = { '-m', '-l', '.latexindent.yaml', '-' },
          stdin = true,
        },
        par_textwrap = {
          command = 'par',
          args = { 'w80' }, -- wrap to 80 cols; change if you prefer
          stdin = true,
        },
        prettier = {
          prepend_args = { '--print-width', '80' },
        },
      },
    },
  },

  -- {
  --   'kkrampis/codex.nvim',
  --   lazy = true,
  --   cmd = { 'Codex', 'CodexToggle' }, -- Optional: Load only on command execution
  --   keys = {
  --     {
  --       '<leader>ac', -- Change this to your preferred keybinding
  --       function()
  --         require('codex').toggle()
  --       end,
  --       desc = 'Toggle Codex popup or side-panel',
  --       mode = { 'n', 't' },
  --     },
  --   },
  --   opts = {
  --     keymaps = {
  --       toggle = nil, -- Keybind to toggle Codex window (Disabled by default, watch out for conflicts)
  --       quit = '<C-q>', -- Keybind to close the Codex window (default: Ctrl + q)
  --     }, -- Disable internal default keymap (<leader>cc -> :CodexToggle)
  --     border = 'rounded', -- Options: 'single', 'double', or 'rounded'
  --     width = 0.8, -- Width of the floating window (0.0 to 1.0)
  --     height = 0.8, -- Height of the floating window (0.0 to 1.0)
  --     model = nil, -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
  --     autoinstall = true, -- Automatically install the Codex CLI if not found
  --     panel = true, -- Open Codex in a side-panel (vertical split) instead of floating window
  --     use_buffer = false, -- Capture Codex stdout into a normal buffer instead of a terminal buffer
  --   },
  -- },

  { -- AI Copilot backend
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    cmd = 'Copilot',
    build = ':Copilot auth',
    opts = {
      suggestion = { enabled = false }, -- disable inline suggestions (use Blink.cmp source)
      panel = { enabled = false },
    },
    config = function(_, opts)
      require('copilot').setup(opts)
    end,
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' },
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken',
    opts = function()
      local user = vim.env.USER or 'User'
      user = user:sub(1, 1):upper() .. user:sub(2)

      -- ADDED: prefer visual selection, fall back to buffer
      local sel = require 'CopilotChat.select'

      return {
        auto_insert_mode = true,
        question_header = '  ' .. user .. ' ',
        answer_header = '  Copilot ',
        window = { width = 0.4 },

        -- ADDED: set a default selection strategy for *everything*
        selection = function(source)
          return sel.visual(source) or sel.buffer(source)
        end,

        -- ADDED (optional): an example custom prompt that *always* uses visual
        prompts = {
          ExplainSelection = {
            prompt = 'Explain the selected code in detail:',
            description = 'Explain what the current visual selection does',
            selection = sel.visual,
          },
        },
        mappings = {
          reset = false,
        },
      }
    end,
    keys = {
      { '<c-s>', '<CR>', ft = 'copilot-chat', desc = 'Submit Prompt', remap = true },
      { '<leader>a', '', desc = '+ai', mode = { 'n', 'v' } },

      {
        '<leader>aa',
        function()
          return require('CopilotChat').toggle()
        end,
        desc = 'Toggle (CopilotChat)',
        mode = { 'n', 'v' },
      },
      {
        '<leader>ax',
        function()
          return require('CopilotChat').reset()
        end,
        desc = 'Clear (CopilotChat)',
        mode = { 'n', 'v' },
      },

      -- UPDATED: Quick Chat — capture visual selection automatically
      {
        '<leader>aq',
        function()
          vim.ui.input({ prompt = 'Quick Chat: ' }, function(input)
            if input and input ~= '' then
              require('CopilotChat').ask(input, {
                -- use visual selection when available; fallback handled by opts.selection
                selection = require('CopilotChat.select').visual,
              })
            end
          end)
        end,
        desc = 'Quick Chat (CopilotChat)',
        mode = { 'n', 'v' },
      },

      -- UPDATED: Prompt picker that evaluates with visual selection
      {
        '<leader>ap',
        function()
          local actions = require 'CopilotChat.actions'
          actions.pick(actions.prompt_actions {
            selection = require('CopilotChat.select').visual,
          })
        end,
        desc = 'Prompt Actions (CopilotChat)',
        mode = { 'n', 'v' },
      },
    },
  },
  {
    'NickvanDyke/opencode.nvim',
    dependencies = {
      -- Recommended for `ask()` and `select()`.
      -- Required for `snacks` provider.
      ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
      { 'folke/snacks.nvim', opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
      }

      -- Required for `opts.events.reload`.
      vim.o.autoread = true

      -- Recommended/example keymaps.
      vim.keymap.set({ 'n', 'x' }, '<leader>aq', function()
        require('opencode').ask('@this: ', { submit = true })
      end, { desc = 'Ask opencode…' })
      vim.keymap.set({ 'n', 'x' }, '<leader>ax', function()
        require('opencode').select()
      end, { desc = 'Execute opencode action…' })
      vim.keymap.set({ 'n', 't' }, '<leader>ao', function()
        require('opencode').toggle()
      end, { desc = 'Toggle opencode' })

      vim.keymap.set({ 'n', 'x' }, 'go', function()
        return require('opencode').operator '@this '
      end, { desc = 'Add range to opencode', expr = true })
      vim.keymap.set('n', 'goo', function()
        return require('opencode').operator '@this ' .. '_'
      end, { desc = 'Add line to opencode', expr = true })

      vim.keymap.set('n', '<S-C-u>', function()
        require('opencode').command 'session.half.page.up'
      end, { desc = 'Scroll opencode up' })
      vim.keymap.set('n', '<S-C-d>', function()
        require('opencode').command 'session.half.page.down'
      end, { desc = 'Scroll opencode down' })

      -- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o…".
      -- vim.keymap.set('n', '+', '<C-a>', { desc = 'Increment under cursor', noremap = true })
      -- vim.keymap.set('n', '-', '<C-x>', { desc = 'Decrement under cursor', noremap = true })
    end,
  },

  {
    'lervag/vimtex',
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_compiler_latexmk = { out_dir = 'build' }
    end,
  },
}
