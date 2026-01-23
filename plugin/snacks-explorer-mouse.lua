-- Snacks Explorer Mouse Support
-- Lazy-loading entry point
-- This file is kept minimal to avoid impacting startup time

if vim.g.loaded_snacks_explorer_mouse then
  return
end
vim.g.loaded_snacks_explorer_mouse = true

-- Define <Plug> mappings for user customization
vim.keymap.set("n", "<Plug>(SnacksExplorerMenu)", function()
  require("snacks-explorer-mouse").show_context_menu()
end, { noremap = true, silent = true, desc = "Snacks explorer context menu" })

-- Define user commands
vim.api.nvim_create_user_command("SnacksExplorerMenu", function()
  require("snacks-explorer-mouse").show_context_menu()
end, { desc = "Show snacks explorer context menu" })

vim.api.nvim_create_user_command("SnacksExplorerDebug", function()
  require("snacks-explorer-mouse").debug()
end, { desc = "Debug snacks explorer mouse plugin" })
