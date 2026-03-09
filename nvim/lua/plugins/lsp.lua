return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints = {
        enabled = false,
      }
      opts.servers.html = {
        settings = {
          html = {
            format = {
              wrapAttributes = "force-aligned",
            },
          },
        },
      }
    end,
  },
}
