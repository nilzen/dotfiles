return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  init = function()
    -- The snacks explorer is built from floating windows, so `wincmd h` from them
    -- jumps to the editor instead of failing at the edge. It is always leftmost,
    -- so hand <C-h> straight to tmux.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "snacks_picker_list", "snacks_picker_input" },
      callback = function(ev)
        vim.keymap.set({ "n", "i" }, "<C-h>", function()
          vim.system({ "tmux", "select-pane", "-t", vim.env.TMUX_PANE or "", "-L" })
        end, { buffer = ev.buf, desc = "Navigate left (tmux)" })
      end,
    })
  end,
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left (nvim/tmux)" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down (nvim/tmux)" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up (nvim/tmux)" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (nvim/tmux)" },
  },
}
