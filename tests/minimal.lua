-- Minimal configuration for testing/reproduction
-- Usage: nvim -u tests/minimal.lua

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy-test/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Get the directory of this minimal.lua file
local minimal_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local plugin_dir = vim.fn.fnamemodify(minimal_dir, ":h")

-- Setup plugins
require("lazy").setup({
  { "folke/snacks.nvim", opts = {} },
  {
    dir = plugin_dir,
    name = "snacks-explorer-mouse",
    opts = {},
  },
}, {
  root = vim.fn.stdpath("data") .. "/lazy-test",
})

-- Basic settings
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.number = true

-- Keymaps for testing
vim.keymap.set("n", "<leader>e", function()
  require("snacks").explorer()
end, { desc = "Open explorer" })

vim.keymap.set("n", "<leader>m", "<Plug>(SnacksExplorerMenu)", { desc = "Explorer menu" })

print("Minimal config loaded!")
print("Open explorer: <leader>e")
print("Context menu: <leader>m or right-click")
print("Debug: :SnacksExplorerDebug")
