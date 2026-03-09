vim.api.nvim_create_autocmd("FileType", {
  pattern = "htmlangular",
  callback = function()
    vim.bo.filetype = "html"
  end,
})
