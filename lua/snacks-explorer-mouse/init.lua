---@mod snacks-explorer-mouse Snacks Explorer Mouse Support
---@brief [[
--- A Neovim plugin that adds mouse context menu support to snacks.nvim explorer.
---
--- This plugin provides right-click context menus for file operations in the
--- snacks.nvim file explorer/picker, bringing familiar GUI-style interactions
--- to your terminal workflow.
---
--- Features:
--- - Right-click context menu with file operations
--- - Copy, paste, rename, delete files and directories
--- - Create new files and directories
--- - Copy file paths to clipboard
--- - Keyboard shortcut fallback
--- - Automatic explorer refresh after operations
---
--- Requires:
--- - Neovim >= 0.9.0
--- - snacks.nvim (https://github.com/folke/snacks.nvim)
---
--- For terminal right-click to work, you may need to configure your terminal.
--- See |snacks-explorer-mouse-terminal-setup|.
---@brief ]]

local M = {}

---@class SnacksExplorerMouseConfig
---@field refresh_after_action boolean Refresh explorer after file operations (default: true)
---@field notify_operations boolean Show notifications for operations (default: true)
---@field copy_register string Register to use for copy/paste (default: "e")

---@type SnacksExplorerMouseConfig
local default_config = {
  refresh_after_action = true,
  notify_operations = true,
  copy_register = "e",
}

---@type SnacksExplorerMouseConfig
M.config = vim.deepcopy(default_config)

---@type boolean
M._initialized = false

-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------

---Configure the plugin. This only sets configuration and does not initialize.
---The plugin auto-initializes when needed.
---@param opts SnacksExplorerMouseConfig|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
  M._ensure_initialized()
end

-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

---Notify the user if notifications are enabled
---@param msg string
---@param level integer
local function notify(msg, level)
  if M.config.notify_operations then
    vim.notify(msg, level)
  end
end

---Check if running on Windows
---@return boolean
local function is_windows()
  return vim.fn.has("win32") == 1
end

---Get the absolute path, handling both relative and absolute inputs
---@param path string
---@param cwd string|nil
---@return string
local function resolve_path(path, cwd)
  -- Already absolute
  if vim.fn.fnamemodify(path, ":p") == path then
    return path
  end
  -- Resolve relative to cwd
  cwd = cwd or vim.fn.getcwd()
  return vim.fn.fnamemodify(cwd .. "/" .. path, ":p")
end

-------------------------------------------------------------------------------
-- Picker Integration
-------------------------------------------------------------------------------

---Get the active snacks picker instance
---@return snacks.Picker|nil picker
---@return string|nil error
function M.get_picker()
  if not package.loaded["snacks"] then
    return nil, "snacks not loaded"
  end

  local snacks = require("snacks")

  -- Snacks.picker.get() returns an array of active pickers
  if snacks.picker and snacks.picker.get then
    local pickers = snacks.picker.get()
    if pickers and #pickers > 0 then
      return pickers[1], nil
    end
  end

  return nil, "no active picker"
end

---Get the current item under cursor
---@return table|nil item
---@return string|nil error
function M.get_current_item()
  local picker, err = M.get_picker()
  if not picker then
    return nil, err or "picker not found"
  end

  -- Try picker:current()
  local ok, item = pcall(function()
    return picker:current()
  end)
  if ok and item then
    return item, nil
  end

  -- Fallback: picker:selected with fallback
  local ok2, selected = pcall(function()
    return picker:selected({ fallback = true })
  end)
  if ok2 and selected and #selected > 0 then
    return selected[1], nil
  end

  -- Fallback: picker.list:current()
  if picker.list then
    local ok3, list_item = pcall(function()
      return picker.list:current()
    end)
    if ok3 and list_item then
      return list_item, nil
    end
  end

  return nil, "no current item"
end

---Get the full file path from a picker item
---@param item table
---@return string|nil
function M.get_file_path(item)
  if not item or not item.file then
    return nil
  end

  local file = item.file

  -- If already absolute and exists, return it
  local abs_path = vim.fn.fnamemodify(file, ":p")
  if abs_path == file then
    if vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1 then
      return file
    end
  end

  -- Get picker's cwd for relative paths
  local picker = M.get_picker()
  local cwd
  if picker then
    local ok, picker_cwd = pcall(function()
      return picker:cwd()
    end)
    if ok and picker_cwd then
      cwd = picker_cwd
    end
  end
  cwd = cwd or vim.fn.getcwd()

  -- Construct full path
  local full_path = resolve_path(file, cwd)
  if vim.fn.filereadable(full_path) == 1 or vim.fn.isdirectory(full_path) == 1 then
    return full_path
  end

  -- Last resort: try file as-is
  if vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1 then
    return vim.fn.fnamemodify(file, ":p")
  end

  return nil
end

---Refresh the explorer after an operation
function M.refresh_explorer()
  if not M.config.refresh_after_action then
    return
  end

  local picker = M.get_picker()
  if picker then
    vim.defer_fn(function()
      local ok = pcall(function()
        picker:find()
      end)
      if not ok then
        -- Fallback: try to trigger update
        pcall(function()
          if picker.list and picker.list.update then
            picker.list:update()
          end
        end)
      end
    end, 100)
  end
end

-------------------------------------------------------------------------------
-- File Operations
-------------------------------------------------------------------------------

---Copy a file path to the internal register for paste operation
---@param path string
function M.copy_file(path)
  if not path then
    return
  end
  vim.fn.setreg(M.config.copy_register, path)
  local name = vim.fn.fnamemodify(path, ":t")
  notify("Copied: " .. name, vim.log.levels.INFO)
end

---Paste a file from the internal register
---@param target_path string
function M.paste_file(target_path)
  if not target_path then
    return
  end

  local source = vim.fn.getreg(M.config.copy_register)
  if not source or source == "" then
    notify("Nothing copied (use Copy first)", vim.log.levels.WARN)
    return
  end

  -- Determine target directory
  local target_dir = target_path
  if vim.fn.isdirectory(target_path) == 0 then
    target_dir = vim.fn.fnamemodify(target_path, ":h")
  end

  local source_name = vim.fn.fnamemodify(source, ":t")
  local target = target_dir .. "/" .. source_name

  -- Check if target exists
  if vim.fn.filereadable(target) == 1 or vim.fn.isdirectory(target) == 1 then
    notify("Target exists: " .. source_name, vim.log.levels.WARN)
    return
  end

  -- Check if source exists
  if vim.fn.filereadable(source) == 0 and vim.fn.isdirectory(source) == 0 then
    notify("Source not found: " .. source, vim.log.levels.ERROR)
    return
  end

  -- Execute copy command
  local cmd
  if is_windows() then
    cmd = string.format('copy "%s" "%s"', source, target)
  else
    cmd = string.format('cp -r "%s" "%s"', source, target)
  end

  vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    notify("Pasted: " .. source_name, vim.log.levels.INFO)
    M.refresh_explorer()
  else
    notify("Paste failed", vim.log.levels.ERROR)
  end
end

---Rename a file using snacks.input
---@param path string
function M.rename_file(path)
  if not path then
    return
  end
  if not package.loaded["snacks"] then
    notify("snacks.nvim not loaded", vim.log.levels.WARN)
    return
  end

  local old_name = vim.fn.fnamemodify(path, ":t")
  local dir = vim.fn.fnamemodify(path, ":h")

  require("snacks").input({
    prompt = "Rename to: ",
    default = old_name,
  }, function(new_name)
    if not new_name or new_name == "" or new_name == old_name then
      return
    end

    local new_path = dir .. "/" .. new_name
    if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
      notify("Target exists: " .. new_name, vim.log.levels.WARN)
      return
    end

    local ok = os.rename(path, new_path)
    if ok then
      notify("Renamed: " .. old_name .. " -> " .. new_name, vim.log.levels.INFO)
      M.refresh_explorer()
    else
      notify("Rename failed", vim.log.levels.ERROR)
    end
  end)
end

---Delete a file with confirmation
---@param path string
function M.delete_file(path)
  if not path then
    return
  end

  local name = vim.fn.fnamemodify(path, ":t")
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Delete '" .. name .. "'?",
  }, function(choice)
    if choice ~= "Yes" then
      return
    end

    local is_dir = vim.fn.isdirectory(path) == 1
    local cmd
    if is_dir then
      cmd = is_windows() and string.format('rmdir /s /q "%s"', path)
        or string.format('rm -rf "%s"', path)
    else
      cmd = is_windows() and string.format('del "%s"', path)
        or string.format('rm "%s"', path)
    end

    vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      notify("Deleted: " .. name, vim.log.levels.INFO)
      M.refresh_explorer()
    else
      notify("Delete failed", vim.log.levels.ERROR)
    end
  end)
end

---Create a new file
---@param dir_path string
function M.create_file(dir_path)
  if not dir_path then
    return
  end
  if not package.loaded["snacks"] then
    notify("snacks.nvim not loaded", vim.log.levels.WARN)
    return
  end

  -- Determine target directory
  local target_dir = dir_path
  if vim.fn.isdirectory(dir_path) == 0 then
    target_dir = vim.fn.fnamemodify(dir_path, ":h")
  end

  require("snacks").input({
    prompt = "File name: ",
  }, function(filename)
    if not filename or filename == "" then
      return
    end

    local filepath = target_dir .. "/" .. filename
    if vim.fn.filereadable(filepath) == 1 then
      notify("File exists: " .. filename, vim.log.levels.WARN)
      return
    end

    local file = io.open(filepath, "w")
    if file then
      file:close()
      notify("Created: " .. filename, vim.log.levels.INFO)
      M.refresh_explorer()
    else
      notify("Failed to create file", vim.log.levels.ERROR)
    end
  end)
end

---Create a new directory
---@param dir_path string
function M.create_directory(dir_path)
  if not dir_path then
    return
  end
  if not package.loaded["snacks"] then
    notify("snacks.nvim not loaded", vim.log.levels.WARN)
    return
  end

  -- Determine parent directory
  local parent_dir = dir_path
  if vim.fn.isdirectory(dir_path) == 0 then
    parent_dir = vim.fn.fnamemodify(dir_path, ":h")
  end

  require("snacks").input({
    prompt = "Directory name: ",
  }, function(dirname)
    if not dirname or dirname == "" then
      return
    end

    local newdir = parent_dir .. "/" .. dirname
    if vim.fn.isdirectory(newdir) == 1 then
      notify("Directory exists: " .. dirname, vim.log.levels.WARN)
      return
    end

    local cmd = is_windows() and string.format('mkdir "%s"', newdir)
      or string.format('mkdir -p "%s"', newdir)

    vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      notify("Created: " .. dirname, vim.log.levels.INFO)
      M.refresh_explorer()
    else
      notify("Failed to create directory", vim.log.levels.ERROR)
    end
  end)
end

---Copy the file path to system clipboard
---@param path string
function M.copy_path(path)
  if not path then
    return
  end
  vim.fn.setreg("+", path)
  notify("Path copied to clipboard", vim.log.levels.INFO)
end

-------------------------------------------------------------------------------
-- Context Menu
-------------------------------------------------------------------------------

---@class SnacksExplorerMenuItem
---@field text string
---@field action string

---Show the context menu for the current item
function M.show_context_menu()
  -- Verify we're in a snacks picker buffer
  local ft = vim.bo.filetype
  if ft ~= "snacks_picker_list" and ft ~= "snacks_picker_input" then
    notify("Not in snacks explorer (filetype: " .. ft .. ")", vim.log.levels.WARN)
    return
  end

  -- Get the current item
  local item, item_err = M.get_current_item()
  if not item then
    notify("No item: " .. (item_err or "unknown error"), vim.log.levels.WARN)
    return
  end

  -- Get the full file path
  local file_path = M.get_file_path(item)
  if not file_path then
    local item_str = vim.inspect(item):sub(1, 100)
    notify("Could not resolve path. Item: " .. item_str, vim.log.levels.WARN)
    return
  end

  local is_dir = vim.fn.isdirectory(file_path) == 1
  local file_name = vim.fn.fnamemodify(file_path, ":t")

  -- Build menu items
  ---@type SnacksExplorerMenuItem[]
  local menu_items = {
    { text = "Copy", action = "copy_file" },
    { text = "Paste", action = "paste_file" },
    { text = "Rename", action = "rename_file" },
    { text = "Delete", action = "delete_file" },
  }

  if is_dir then
    table.insert(menu_items, { text = "New File", action = "create_file" })
    table.insert(menu_items, { text = "New Directory", action = "create_directory" })
  end

  table.insert(menu_items, { text = "Copy Path", action = "copy_path" })

  -- Create choices
  local choices = {}
  for _, menu_item in ipairs(menu_items) do
    table.insert(choices, menu_item.text)
  end

  vim.ui.select(choices, {
    prompt = (is_dir and "[Dir] " or "[File] ") .. file_name,
  }, function(_, idx)
    if idx then
      M.execute_action(menu_items[idx].action, file_path)
    end
  end)
end

---Execute a file action by name
---@param action string
---@param path string
function M.execute_action(action, path)
  local actions = {
    copy_file = M.copy_file,
    paste_file = M.paste_file,
    rename_file = M.rename_file,
    delete_file = M.delete_file,
    create_file = M.create_file,
    create_directory = M.create_directory,
    copy_path = M.copy_path,
  }

  local fn = actions[action]
  if fn then
    fn(path)
  end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

---Set up buffer-local keymaps for snacks picker buffers
---@param bufnr integer
local function setup_buffer_keymaps(bufnr)
  -- Right-click context menu
  vim.keymap.set("n", "<RightMouse>", function()
    -- Move cursor to mouse position
    local mouse_pos = vim.fn.getmousepos()
    if mouse_pos and mouse_pos.line > 0 then
      vim.api.nvim_win_set_cursor(0, { mouse_pos.line, 0 })
    end
    -- Small delay for snacks to update state
    vim.defer_fn(function()
      M.show_context_menu()
    end, 10)
  end, {
    buffer = bufnr,
    silent = true,
    noremap = true,
    desc = "Snacks explorer context menu",
  })

  -- Keyboard shortcut
  vim.keymap.set("n", "<Plug>(SnacksExplorerMenu)", function()
    M.show_context_menu()
  end, {
    buffer = bufnr,
    silent = true,
    noremap = true,
    desc = "Snacks explorer context menu",
  })
end

---Ensure the plugin is initialized (called automatically)
function M._ensure_initialized()
  if M._initialized then
    return
  end
  M._initialized = true

  local augroup = vim.api.nvim_create_augroup("SnacksExplorerMouse", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "snacks_picker_list" },
    callback = function(ev)
      setup_buffer_keymaps(ev.buf)
    end,
  })
end

-------------------------------------------------------------------------------
-- Debug
-------------------------------------------------------------------------------

---Debug function to inspect picker state
function M.debug()
  print("=== Snacks Explorer Mouse Debug ===")
  print("Version: 1.0.0")
  print("Filetype: " .. vim.bo.filetype)
  print("Initialized: " .. tostring(M._initialized))

  local snacks_loaded = package.loaded["snacks"] ~= nil
  print("Snacks loaded: " .. tostring(snacks_loaded))

  if snacks_loaded then
    local snacks = require("snacks")
    if snacks.picker and snacks.picker.get then
      local pickers = snacks.picker.get()
      print("Active pickers: " .. #pickers)

      if #pickers > 0 then
        local picker = pickers[1]
        print("Picker source: " .. tostring(picker.opts and picker.opts.source))

        local ok, result = pcall(function()
          return picker:current()
        end)
        print("picker:current(): " .. (ok and "success" or "failed"))
        if ok and result then
          print("  file: " .. tostring(result.file))
        end

        local ok2, cwd = pcall(function()
          return picker:cwd()
        end)
        print("picker:cwd(): " .. (ok2 and tostring(cwd) or "failed"))
      end
    end
  end

  local item, err = M.get_current_item()
  print("get_current_item(): " .. (item and "found" or ("nil - " .. (err or ""))))

  if item then
    local path = M.get_file_path(item)
    print("get_file_path(): " .. tostring(path))
  end

  print("=== End Debug ===")
end

-- Auto-initialize when first loaded
M._ensure_initialized()

return M
