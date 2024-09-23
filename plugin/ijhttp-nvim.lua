if vim.g.loaded_ijhttpnvim then
  return
end

vim.g.loaded_ijhttpnvim = true

function execute(opts)
  require("ijhttp-nvim").execute(unpack(opts.fargs))
end

vim.api.nvim_create_user_command("Ijhttp", execute, {nargs="*"})


