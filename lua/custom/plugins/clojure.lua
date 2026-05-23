return {
  {
    'Olical/conjure',
    ft = { 'clojure' },
    cmd = { 'ConjureConnect', 'ConjureEval', 'ConjureSchool' },
    dependencies = { 'folke/which-key.nvim' },
    init = function()
      -- Keep Conjure focused on Clojure so it does not claim mappings in Lua,
      -- Python, SQL, etc. unless those languages are explicitly added later.
      vim.g['conjure#filetypes'] = { 'clojure' }

      vim.g['conjure#mapping#prefix'] = '<localleader>c'
      vim.g['conjure#mapping#doc_word'] = false

      vim.g['conjure#log#botright'] = true
      vim.g['conjure#log#wrap'] = true
      vim.g['conjure#log#fold#enabled'] = true
      vim.g['conjure#log#hud#border'] = 'rounded'
      vim.g['conjure#log#hud#ignore_low_priority'] = true

      vim.g['conjure#client#clojure#nrepl#connection#default_host'] = 'localhost'
      vim.g['conjure#client#clojure#nrepl#connection#port_files'] = { '.nrepl-port' }
      vim.g['conjure#client#clojure#nrepl#connection#auto_repl#enabled'] = false
      vim.g['conjure#client#clojure#nrepl#eval#auto_require'] = false
      vim.g['conjure#client#clojure#nrepl#eval#print_options#right_margin'] = 80
    end,
    config = function()
      local ok, wk = pcall(require, 'which-key')
      if not ok or not wk.add then
        return
      end

      wk.add {
        { '<localleader>c', group = 'Conjure', mode = { 'n', 'x' } },

        { '<localleader>cc', group = 'Connection', mode = 'n' },
        { '<localleader>ccd', desc = 'Disconnect', mode = 'n' },
        { '<localleader>ccf', desc = 'Connect via .nrepl-port', mode = 'n' },

        { '<localleader>ce', group = 'Eval', mode = { 'n', 'x' } },
        { '<localleader>ce!', desc = 'Eval form and replace', mode = 'n' },
        { '<localleader>cE', desc = 'Eval selection/motion', mode = { 'n', 'x' } },
        { '<localleader>ceb', desc = 'Eval buffer', mode = 'n' },
        { '<localleader>cece', desc = 'Eval form as comment', mode = 'n' },
        { '<localleader>cecr', desc = 'Eval root as comment', mode = 'n' },
        { '<localleader>cecw', desc = 'Eval word as comment', mode = 'n' },
        { '<localleader>cee', desc = 'Eval current form', mode = 'n' },
        { '<localleader>cef', desc = 'Eval file', mode = 'n' },
        { '<localleader>cei', desc = 'Interrupt evaluation', mode = 'n' },
        { '<localleader>cem', desc = 'Eval marked form', mode = 'n' },
        { '<localleader>cep', desc = 'Eval previous', mode = 'n' },
        { '<localleader>cer', desc = 'Eval root form', mode = 'n' },
        { '<localleader>cew', desc = 'Eval word', mode = 'n' },

        { '<localleader>cg', group = 'Goto', mode = 'n' },
        { '<localleader>cgd', desc = 'Go to definition', mode = 'n' },

        { '<localleader>cl', group = 'Log', mode = 'n' },
        { '<localleader>cle', desc = 'Log in current window', mode = 'n' },
        { '<localleader>clg', desc = 'Toggle log', mode = 'n' },
        { '<localleader>cll', desc = 'Jump to latest log entry', mode = 'n' },
        { '<localleader>clq', desc = 'Close visible log windows', mode = 'n' },
        { '<localleader>clr', desc = 'Soft reset log', mode = 'n' },
        { '<localleader>clR', desc = 'Hard reset log', mode = 'n' },
        { '<localleader>cls', desc = 'Log split', mode = 'n' },
        { '<localleader>clt', desc = 'Log tab', mode = 'n' },
        { '<localleader>clv', desc = 'Log vertical split', mode = 'n' },

        { '<localleader>cr', group = 'Refresh', mode = 'n' },
        { '<localleader>cra', desc = 'Refresh all namespaces', mode = 'n' },
        { '<localleader>crc', desc = 'Clear refresh cache', mode = 'n' },
        { '<localleader>crr', desc = 'Refresh changed namespaces', mode = 'n' },

        { '<localleader>cs', group = 'Session', mode = 'n' },
        { '<localleader>csf', desc = 'Fresh session', mode = 'n' },
        { '<localleader>csl', desc = 'List sessions', mode = 'n' },
        { '<localleader>csn', desc = 'Next session', mode = 'n' },
        { '<localleader>csp', desc = 'Previous session', mode = 'n' },
        { '<localleader>csq', desc = 'Close session', mode = 'n' },
        { '<localleader>csQ', desc = 'Close all sessions', mode = 'n' },
        { '<localleader>css', desc = 'Select session', mode = 'n' },

        { '<localleader>ct', group = 'Test', mode = 'n' },
        { '<localleader>cta', desc = 'Run all loaded tests', mode = 'n' },
        { '<localleader>ctc', desc = 'Run test under cursor', mode = 'n' },
        { '<localleader>ctn', desc = 'Run namespace tests', mode = 'n' },
        { '<localleader>ctN', desc = 'Run alternate namespace tests', mode = 'n' },

        { '<localleader>cv', group = 'View', mode = 'n' },
        { '<localleader>cv1', desc = 'View latest result', mode = 'n' },
        { '<localleader>cv2', desc = 'View second latest result', mode = 'n' },
        { '<localleader>cv3', desc = 'View third latest result', mode = 'n' },
        { '<localleader>cve', desc = 'View last exception', mode = 'n' },
        { '<localleader>cvs', desc = 'View source under cursor', mode = 'n' },
        { '<localleader>cvt', desc = 'View tap queue', mode = 'n' },

        { '<localleader>cx', group = 'Macroexpand', mode = 'n' },
        { '<localleader>cx1', desc = 'Macroexpand-1 form', mode = 'n' },
        { '<localleader>cxa', desc = 'Macroexpand-all form', mode = 'n' },
        { '<localleader>cxr', desc = 'Macroexpand form', mode = 'n' },
      }
    end,
  },
}
