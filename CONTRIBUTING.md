# Contributing to snacks-explorer-mouse

Thank you for your interest in contributing! This document provides guidelines
and information for contributors.

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to
make Neovim better.

## How to Contribute

### Reporting Issues

Before opening an issue:

1. Check existing issues to avoid duplicates
2. Use the issue templates when available
3. Include:
   - Neovim version (`:version`)
   - snacks.nvim version
   - Your configuration
   - Steps to reproduce
   - Output of `:SnacksExplorerDebug`

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Run tests and linting (see below)
5. Commit with clear messages
6. Push and open a PR

### Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:

- `feat(menu): add move file operation`
- `fix(picker): handle nil item gracefully`
- `docs(readme): add iTerm2 setup instructions`

## Development Setup

### Local Installation

```lua
-- lazy.nvim
{
  dir = "~/path/to/nvim-snacks-file-picker-mouse-support",
  dependencies = { "folke/snacks.nvim" },
  opts = {},
}
```

### Testing Changes

1. Make your changes
2. Restart Neovim (`:qa!` and reopen)
3. Open the snacks explorer
4. Test the affected functionality
5. Run `:SnacksExplorerDebug` to verify state

### Code Style

- Use LuaCATS type annotations
- Follow existing code patterns
- Keep functions focused and small
- Add comments for non-obvious logic
- Use `vim.notify()` for user-facing messages

### Type Annotations

Use LuaCATS annotations for all public functions:

```lua
---Description of the function
---@param arg1 string Description
---@param arg2 number|nil Optional description
---@return boolean success
---@return string|nil error
function M.example(arg1, arg2)
  -- implementation
end
```

### Documentation

- Update vimdoc (`doc/snacks-explorer-mouse.txt`) for user-facing changes
- Update README.md for significant features
- Update CHANGELOG.md following Keep a Changelog format

## Architecture

### Directory Structure

```
nvim-snacks-file-picker-mouse-support/
├── lua/snacks-explorer-mouse/
│   └── init.lua          # Main plugin module
├── plugin/
│   └── snacks-explorer-mouse.lua  # Lazy-loading entry point
├── doc/
│   └── snacks-explorer-mouse.txt  # Vimdoc
├── .github/workflows/
│   └── ci.yml            # GitHub Actions
├── README.md
├── LICENSE
├── CHANGELOG.md
└── CONTRIBUTING.md
```

### Key Functions

- `M.get_picker()` - Gets active snacks picker instance
- `M.get_current_item()` - Gets item under cursor
- `M.get_file_path(item)` - Resolves full path from item
- `M.show_context_menu()` - Shows the context menu
- `M._ensure_initialized()` - Sets up autocommands

### Snacks.nvim Integration

The plugin uses the official snacks.nvim picker API:

- `Snacks.picker.get()` - Returns array of active pickers
- `picker:current()` - Returns item at cursor
- `picker:selected()` - Returns selected items
- `picker:cwd()` - Returns picker's working directory
- `picker:find()` - Refreshes the picker

## Release Process

1. Update version in code
2. Update CHANGELOG.md
3. Create git tag: `git tag v1.x.x`
4. Push tag: `git push origin v1.x.x`
5. Create GitHub release

## Questions?

Open a discussion or issue if you have questions about contributing.
