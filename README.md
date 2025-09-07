# Bootstrap a Local Machine

This repo is meant to provide default configs for setting up a local environment on MacOS.

## Steps (needs updating for LazyVim)

1. Clone this repo
1. Navigate to the root of the newly cloned repo
1. Run `./setup`
1. Install neovim plugins by opening any file with `vim <some-file>` and running `:PlugInstall`
1. Provide language server config to neovim by running `:LspInstall pyright`
1. Install `pyright` with `npm i -g pyright`

