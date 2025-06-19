-- Lazy plugin specification
return {
  dir = vim.fn.stdpath 'config' .. '/lua/custom/scope_method_picker',
  config = function()
    -- vim.api.nvim_create_user_command('TSLocalSymbols', scoped_method_and_class_telescope, {})
  end,
  keys = {
    {
      '<leader>sU',
      function()
        require('custom.scope_method_picker').scoped_method_and_class_telescope()
      end,
      desc = '[S]earch scoped F[U]nctions and Classes',
    },
  },
  event = 'VeryLazy',
}
