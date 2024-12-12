---@class Toolbox.Config
---@field commands Toolbox.Command[]

---@class Toolbox.Command
---@field name string
---@field execute string|function
---@field require_input boolean
---@field tags string[]?
---@field weight number?

---@class Toolbox.ShowPickerCustomOpts
---@field filter fun(command: Toolbox.Command): boolean
