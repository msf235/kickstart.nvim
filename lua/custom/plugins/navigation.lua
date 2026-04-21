return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = { default_file_explorer = false },
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local actions = require 'telescope.actions'

      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        defaults = {
          -- path_display = filename_left_display,

          mappings = {
            i = {
              ['<CR>'] = actions.select_default,
              ['<C-s>'] = actions.select_horizontal, -- split
              ['<C-v>'] = actions.select_vertical, -- vsplit
              ['<C-t>'] = actions.select_tab,
              ['<Del>'] = actions.delete_buffer,
            },
            n = {
              ['<CR>'] = actions.select_default,
              ['s'] = actions.select_horizontal,
              ['v'] = actions.select_vertical,
              ['t'] = actions.select_tab,
              ['<Del>'] = actions.delete_buffer,
              ['dd'] = actions.delete_buffer,
            },
          },
        },
        -- pickers = {
        --   buffers = {
        --     -- sorter = require("telescope.sorters").fuzzy_with_index_bias(),
        --     ignore_current_buffer = false,
        --     show_all_buffers = true,
        --     default_selection_index = current_index,
        --   },
        -- },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      local function search_majors()
        builtin.lsp_document_symbols { symbols = { 'function', 'class', 'method' } }
      end
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>su', search_majors, { desc = '[S]earch F[u]nctions' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>df', function()
        require('custom.telescope_pickers').git_file_history()
      end, { desc = '[G]it [F]ile history (raw versions in split)' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  {
    'aserowy/tmux.nvim',
    config = function()
      return require('tmux').setup {
        copy_sync = {
          sync_clipboard = false,
        },
      }
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
    },
    config = function()
      require('nvim-treesitter').setup()

      require('nvim-treesitter-textobjects').setup {
        select = {
          lookahead = true,
          selection_modes = {
            ['@parameter.outer'] = 'v',
            ['@function.outer'] = 'V',
            ['@class.outer'] = '<c-v>',
          },
          include_surrounding_whitespace = true,
        },
      }

      local select = require 'nvim-treesitter-textobjects.select'
      vim.keymap.set({ 'x', 'o' }, 'af', function()
        select.select_textobject('@function.outer', 'textobjects')
      end, { desc = 'Select around function' })
      vim.keymap.set({ 'x', 'o' }, 'if', function()
        select.select_textobject('@function.inner', 'textobjects')
      end, { desc = 'Select inside function' })
      vim.keymap.set({ 'x', 'o' }, 'ac', function()
        select.select_textobject('@class.outer', 'textobjects')
      end, { desc = 'Select around class' })
      vim.keymap.set({ 'x', 'o' }, 'ic', function()
        select.select_textobject('@class.inner', 'textobjects')
      end, { desc = 'Select inner part of a class region' })
      vim.keymap.set({ 'x', 'o' }, 'as', function()
        select.select_textobject('@local.scope', 'locals')
      end, { desc = 'Select language scope' })

      local group = vim.api.nvim_create_augroup('custom-treesitter-highlight', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = '*',
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewToggleFiles',
      'DiffviewFocusFiles',
      'DiffviewFileHistory',
      'DiffviewRefresh',
    },
    keys = {
      -- Review current branch vs master (change to main if needed)
      { '<leader>dv', '<cmd>DiffviewOpen master...HEAD<cr>', desc = 'Diffview: master...HEAD' },
      -- Review working tree changes (unstaged/staged)
      { '<leader>dV', '<cmd>DiffviewOpen<cr>', desc = 'Diffview: working tree' },
      -- File history (current file)
      { '<leader>dh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Diffview: file history' },
      -- Repo history
      { '<leader>dH', '<cmd>DiffviewFileHistory<cr>', desc = 'Diffview: repo history' },
      -- Close
      { '<leader>dq', '<cmd>DiffviewClose<cr>', desc = 'Diffview: close' },
    },
    opts = function()
      -- Small helper for better default keymaps inside the Diffview buffers
      local actions = require 'diffview.actions'

      return {
        enhanced_diff_hl = true, -- nicer highlights for diffs
        view = {
          merge_tool = {
            layout = 'diff3_mixed',
            disable_diagnostics = true,
          },
        },
        file_panel = {
          listing_style = 'tree', -- "list" is also fine
          win_config = {
            position = 'left',
            width = 38,
          },
        },
        keymaps = {
          -- These are buffer-local within Diffview views/panels
          view = {
            ['q'] = '<cmd>DiffviewClose<cr>',
            ['<leader>e'] = actions.focus_files, -- jump focus to file panel
            ['<leader>t'] = actions.toggle_files, -- toggle file panel
            ['<leader>r'] = '<cmd>DiffviewRefresh<cr>',
            ['o'] = actions.goto_file_split,
            ['<cr>'] = actions.goto_file_split,
          },
          file_panel = {
            ['q'] = '<cmd>DiffviewClose<cr>',
            ['<cr>'] = actions.select_entry, -- open diff for file
            ['o'] = actions.select_entry,
            ['-'] = actions.toggle_stage_entry, -- stage/unstage file (optional, but handy)
            ['S'] = actions.stage_all, -- stage all (optional)
            ['U'] = actions.unstage_all, -- unstage all (optional)
            ['R'] = '<cmd>DiffviewRefresh<cr>',
          },
          file_history_panel = {
            ['q'] = '<cmd>DiffviewClose<cr>',
            ['<cr>'] = actions.select_entry,
            ['o'] = actions.select_entry,
          },
        },
      }
    end,
  },
}
