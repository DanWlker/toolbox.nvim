# toolbox.nvim

A toolbox for neovim to put your custom neovim functions, all invokable from vim.ui.select! 

![demo](https://github.com/DanWlker/toolbox.nvim/blob/main/demo.gif)

## Installation

### Lazy.nvim

```lua
return {
  'DanWlker/toolbox.nvim',
  config = function()
    require('toolbox').setup {
      commands = {
        --replace the bottom few with your own custom functions
        {
          name = 'Format Json',
          execute = "%!jq '.'",
          require_input = true,
        },
        {
          name = 'Try in visual mode!', --this works in visual mode as well!
          execute = 's/leader/thing',
        },
        {
          name = 'Inspect Vim Table',
          execute = function(v)
            print(vim.inspect(v))
          end,
        },
        {
          name = 'Copy Vim Table To Clipboard',
          execute = function(v)
            vim.fn.setreg('+', vim.inspect(v))
          end,
        },
        {
          name = 'Reload plugin',
          execute = function(name)
            package.loaded[name] = nil
            require(name).setup()
          end,
        },
      },
    }

    vim.keymap.set({ 'n', 'v' }, '<leader>st', require('toolbox').show_picker, { desc = '[S]earch [T]oolbox' })
  end,
}
```

## Config

```lua
{
  commands = {
    --Note this is the identifier for the command as well
    --@type string
    name = ""
    --if it is a function and it requires no params, it will be immediately invoked
    --if it requires params, it will be shown in the command line
    --if it is a string, it will be invoked via vim.cmd, similar to `:`
    --@type string|function
    execute = "" | function() end
    --if set for string commands, it will populate the `:` command
    --@type bool
    require_input = false,
  }
}
```

## TODOs

1. Make it work in visual mode (Done)
