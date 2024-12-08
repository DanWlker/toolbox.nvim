# toolbox.nvim

A toolbox for neovim to put your custom neovim functions, all invokable from vim.ui.select! 

![demo](https://github.com/DanWlker/toolbox.nvim/blob/main/demo.gif)

## Installation

### Lazy.nvim

```lua
return {
  'DanWlker/toolbox.nvim',
  keys = {
    {
      '<leader>st',
      function()
        require('toolbox').show_picker()
      end,
      desc = '[S]earch [T]oolbox',
      mode = { 'n', 'v' },
    },
  },
  -- Remove this if you don't need to always see telescope's ui when triggering toolbox
  -- keys = {} will cause toolbox to lazy load, therefore if it loads before telescope you
  -- will see the default vim.ui.select.
  --
  -- If you want to use your custom vim.ui.select overrides, remember to add it into dependencies
  -- to ensure it loads first
  --
  -- Note: This is safe to remove, it is just to ensure plugins load in the correct order
  dependencies = { 'nvim-telescope/telescope.nvim' },
  opts = {
    commands = {
      {
        name = 'Close current tab',
        execute = 'tabclose',
        weight = 2,
      },
      {
        name = 'Format Json',
        execute = "%!jq '.'",
      },
      {
        name = 'Print Vim table',
        execute = function(v)
          print(vim.inspect(v))
        end,
      },
      {
        name = 'Copy relative path to clipboard',
        execute = function()
          local path = vim.fn.expand '%'
          vim.fn.setreg('+', path)
        end,
      },
      {
        name = 'Copy absolute path to clipboard',
        execute = function()
          local path = vim.fn.expand '%:p'
          vim.fn.setreg('+', path)
        end,
      },
      {
        name = 'Copy Vim table to clipboard',
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
  },
  config = true,
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
    -- Higher weights will be placed higher in the list
    -- Lower weights will be placed lower, you can use negative
    -- numbers as well to put it at the end of the list
    --@type number
    weight = 0,
  }
}
```

## Recipes

<details><summary>Filter commands by tag</summary>

### Configuration

```lua
opts = {
  commands = {
    { name = "Copy full path", execute = ":let @+ = expand('%:p')", tags = { "clipboard" } },
    { name = "Copy filename", execute = ":let @+ = expand('%:t')", tags = { "clipboard" } },
    { name = "Remove empty lines", execute = ":g/^$/d", tags = { "editor", "newline" } },
  },
}
```

### Usage

```lua
-- Show only clipboard commands
local function filter(command)
  return command.tags ~= nil and vim.tbl_contains(command.tags, "clipboard")
end
require("toolbox").show_picker(filter, { prompt = "Select clipboard command" })
```

</details>

<details><summary>Filter commands by current filetype</summary>

### Configuration

```lua
opts = {
  commands = {
    { name = "Copy full path", execute = ":let @+ = expand('%:p')" },
    { name = "Format JSON with jq", execute = ":%!jq", filetype = "json" }
    { name = "Format QML file", execute = ":qmlformat %", filetype = "qml" }
  },
}
```

### Usage

```lua
require("toolbox").show_picker(function(command)
  return command.filetype == vim.bo.filetype
end, { prompt = "Select " .. vim.bo.filetype .. " command" })
```

</details>

<details><summary>Change command representation in the list</summary>

### Usage

```lua
require("toolbox").show_picker(nil, {
  format_item = function(command)
    -- Display => and execute string after the name
    return command.name .. " => " .. (type(command.execute) == "function" and "<function>" or command.execute)
  end
})
```

</details>

## TODOs

1. Make it work in visual mode (Done)
