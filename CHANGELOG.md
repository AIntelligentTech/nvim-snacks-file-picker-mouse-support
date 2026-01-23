# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-23

### Added

- Initial release
- Right-click context menu for snacks.nvim file explorer
- File operations: copy, paste, rename, delete
- Directory operations: create file, create directory
- Copy file path to clipboard
- `<Plug>(SnacksExplorerMenu)` mapping for keyboard access
- `:SnacksExplorerMenu` and `:SnacksExplorerDebug` commands
- Configurable options for refresh, notifications, and copy register
- Comprehensive vimdoc documentation
- Support for Neovim >= 0.9.0

### Technical

- Uses official Snacks.picker API (`Snacks.picker.get()`, `picker:current()`)
- Buffer-local keymaps via FileType autocommand
- Automatic explorer refresh after operations
- LuaCATS type annotations for IDE support

[Unreleased]:
  https://github.com/yourusername/nvim-snacks-file-picker-mouse-support/compare/v1.0.0...HEAD
[1.0.0]:
  https://github.com/yourusername/nvim-snacks-file-picker-mouse-support/releases/tag/v1.0.0
