# snacks-explorer-mouse

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-blueviolet.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Mouse context menu support for
[snacks.nvim](https://github.com/folke/snacks.nvim) file explorer.

> Bring familiar GUI-style right-click menus to your terminal Neovim workflow.

## Features

- **Right-click context menu** with common file operations
- **Copy, paste, rename, delete** files and directories
- **Create new files and directories** from the menu
- **Copy file paths** to system clipboard
- **Keyboard shortcut fallback** via `<Plug>` mappings
- **Automatic explorer refresh** after operations
- **Works with LazyVim** and custom Neovim configurations

## Requirements

- Neovim >= 0.9.0
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- Terminal with mouse support (see [Terminal Setup](#terminal-setup))

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/nvim-snacks-file-picker-mouse-support",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/nvim-snacks-file-picker-mouse-support",
  requires = { "folke/snacks.nvim" },
  config = function()
    require("snacks-explorer-mouse").setup()
  end
}
```

### Local Development

```lua
{
  dir = "~/path/to/nvim-snacks-file-picker-mouse-support",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  opts = {},
}
```

## Configuration

The plugin works out of the box with sensible defaults. Configuration is
optional.

```lua
require("snacks-explorer-mouse").setup({
  -- Refresh explorer after file operations (default: true)
  refresh_after_action = true,

  -- Show notifications for operations (default: true)
  notify_operations = true,

  -- Register to use for copy/paste operations (default: "e")
  copy_register = "e",
})
```

## Usage

1. Open the snacks explorer (`<leader>e` in LazyVim)
2. Navigate to a file or directory
3. **Right-click** to open the context menu
4. Select an action

### Context Menu Options

| Action        | File | Directory | Description                        |
| ------------- | ---- | --------- | ---------------------------------- |
| Copy          | ✓    | ✓         | Copy to internal clipboard         |
| Paste         | ✓    | ✓         | Paste previously copied item       |
| Rename        | ✓    | ✓         | Rename with prompt                 |
| Delete        | ✓    | ✓         | Delete with confirmation           |
| New File      |      | ✓         | Create new file in directory       |
| New Directory |      | ✓         | Create new subdirectory            |
| Copy Path     | ✓    | ✓         | Copy full path to system clipboard |

### Keyboard Access

Use the `<Plug>` mapping for keyboard access:

```lua
vim.keymap.set("n", "<leader>m", "<Plug>(SnacksExplorerMenu)")
```

Or use the command:

```vim
:SnacksExplorerMenu
```

## Terminal Setup

For right-click to work, your terminal must pass mouse events to Neovim.

### Kitty

Add to `~/.config/kitty/kitty.conf`:

```conf
mouse_map right press ungrabbed no-op
```

### Alacritty / WezTerm / Windows Terminal

Mouse events are passed through by default. No configuration needed.

### iTerm2

Go to **Preferences → Profiles → Terminal** and check **"Report mouse clicks"**.

## Commands

| Command                | Description                             |
| ---------------------- | --------------------------------------- |
| `:SnacksExplorerMenu`  | Open context menu for item under cursor |
| `:SnacksExplorerDebug` | Print debug information                 |

## API

```lua
local sem = require("snacks-explorer-mouse")

-- Show context menu
sem.show_context_menu()

-- File operations
sem.copy_file(path)
sem.paste_file(target_path)
sem.rename_file(path)
sem.delete_file(path)
sem.create_file(dir_path)
sem.create_directory(dir_path)
sem.copy_path(path)

-- Picker utilities
local picker, err = sem.get_picker()
local item, err = sem.get_current_item()
local path = sem.get_file_path(item)

-- Debug
sem.debug()
```

## Troubleshooting

### Menu doesn't appear on right-click

1. Check your [terminal setup](#terminal-setup)
2. Ensure you're in the explorer window (filetype should be
   `snacks_picker_list`)
3. Run `:SnacksExplorerDebug` for diagnostic information

### "No item under cursor" error

1. Make sure cursor is on a file/directory line
2. Run `:SnacksExplorerDebug` to check picker state

### Debug

```vim
:SnacksExplorerDebug
" or
:lua require("snacks-explorer-mouse").debug()
```

## Related

- [snacks.nvim](https://github.com/folke/snacks.nvim) - The picker this plugin
  extends
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [LazyVim](https://github.com/LazyVim/LazyVim) - Neovim distribution

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
