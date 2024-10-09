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
        --replace the bottom two with your own custom functions
        {
          name = 'Format Json',
          execute = "%!jq '.'",
        },
        {
          name = 'Format Json (Function version)',
          execute = function()
            vim.cmd "%!jq '.'"
          end,
        },
      },
    }

    vim.keymap.set({ 'n', 'v' }, '<leader>ch', require('toolbox').show_picker, { desc = '[C]ode [H]elpers' })
  end,
}

```

## Config

```lua
{
  commands = {
    --@type string
    name = ""
    --if it is a function, it will be immediately invoked
    --if it is a string, it will be invoked via vim.cmd, similar to :
    --@type string|function
    execute = ""
  }
}
```
