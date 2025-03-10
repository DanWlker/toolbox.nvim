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
      -- Note variadic arguments need require_input
      {
        name = 'Print Variadic arguments',
        execute = function(...)
          local args = {...}
          print(vim.inspect(args))
        end,
        require_input = true,
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
        tags = { 'first' },
      },
      {
        name = 'Reload plugin',
        execute = function(name)
          package.loaded[name] = nil
          require(name).setup()
        end,
        tags = { 'first', 'second' },
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
    --if function requires no params, it will be immediately invoked
    --if function requires params, it will be shown in the command line
    --if function uses variadic arguments, you need to set `require_input` to true
    --if it is a string, it will be invoked via vim.cmd, similar to `:`
    --@type string|function
    execute = "" | function() end
    --Will populate command line if set to true
    --Functions that use variadic arguments need this to work
    --@type bool
    require_input = false,
    --When calling require('toolbox').show_picker(), you can pass it a tag
    --Ex. require('toolbox').show_picker('first')
    --Commands with the tag will be shown, if no tags are given when calling
    --the function, it will show all commands available
    --@type list
    tags = {},
    -- Higher weights will be placed higher in the list
    -- Lower weights will be placed lower, you can use negative
    -- numbers as well to put it at the end of the list
    --@type number
    weight = 0,
  }
}
```

## Usage

Call `require('toolbox').show_picker()`, it accepts two optional arguments:

- tag

  - Toolbox will filter your commands by specified tags in each command

- select_opts

  - This will be passed to vim.ui.select as the `opts` argument, see `:help vim.ui.select`
  - If you are using a custom `vim.ui.select` implementation, you can add arguments here to achieve additional functionality, toolbox passes select_opts directly to `vim.ui.select`, so any `vim.ui.select` overrides that use additional arguments will receive them as well

## Advanced

1. For advanced users, toolbox contains a lower level function call `show_picker_custom`,
   that provides more control towards filtering and sorting.
   `show_picker_custom` does not require you to use tags for filtering, you can filter by
   anything you want.

<details><summary>Filter commands by current filetype</summary>

#### Configuration

```lua
opts = {
  commands = {
    { name = "Copy full path", execute = ":let @+ = expand('%:p')" },
    { name = "Format JSON with jq", execute = ":%!jq", filetype = "json" }
    { name = "Format QML file", execute = ":qmlformat %", filetype = "qml" }
  },
}
```

#### Usage

```lua
require("toolbox").show_picker_custom({
  filter = function(command)
    return command.filetype == vim.bo.filetype
  end
}, { prompt = "Select " .. vim.bo.filetype .. " command" })
```

</details>

2. `select_opts` is passed to vim.ui.select directly, so, if your custom override expects different values, you can pass them here as well

<details><summary>Change command representation in the list</summary>

#### Usage

```lua
require("toolbox").show_picker(nil, {
  format_item = function(command)
    -- Display => and execute string after the name
    return command.name .. " => " .. (type(command.execute) == "function" and "<function>" or command.execute)
  end
})
```

</details>

3. You can now extend toolbox's existing commands after setup

<details><summary>Add a custom command from somewhere else (ex. after loading a plugin)</summary>

#### Usage

```lua
vim.list_extend(require('toolbox').opts.commands, {
  {
    name = 'This is an extra command to be added in the future',
    execute = function(item, item2, item3)
      print('hello toolbox')
    end,
  },
})
```

</details>
