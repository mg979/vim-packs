# vpacks

![Imgur](https://i.imgur.com/xqk21Rm.gif)

A light command-line package manager for vim 8 (or nvim), written in python.

-------------------------------------------------------------------------------

## Installation
```sh
mkdir ~/.vim/pack/vpacks/opt
cd ~/.vim/pack/vpacks/opt
git clone https://github.com/mg979/vim-packs
```
Then in your vimrc:

    packadd vim-packs

If you want shell completion, also source the optional shell script in your
.bashrc:

    source ~/.vim/pack/vpacks/opt/vim-packs/vpacks.sh

You should then make a link to the executable in a directory in your path, eg:

    ln -s ~/.vim/pack/vpacks/opt/vim-packs/vpacks ~/.local/bin/vpacks

-------------------------------------------------------------------------------

## Options

Commands (`list`, `update`, etc) are performed on *all* packages if given
without arguments.

Options are described in the command line help:

    vpacks              // no arguments -> short help
    vpacks -h           // full help

The `list` command also shows if there are modified/untracked files in the
working tree of the plugin:

![Imgur](https://i.imgur.com/oQn13PY.gif)

-------------------------------------------------------------------------------

## Installing packages

    vpacks install user/repo

The script recognizes the following formats for remote repos:

- *user/plugin*: a GitHub repo
- *gh/user/plugin*: a GitHub repo
- *gl/user/plugin*: a GitLab repo
- *http(s)://...*: any repo

Repositories are cloned with `--depth 1` (shallow clones) to save disk space.

The default directory when installing is `vpacks`, in the `opt` subdirectory
(so for example `~/.vim/pack/vpacks/opt/plugin-name`), you can specify
a different directory with the `dir=` option, or `vpacks install start` to
install in the start subdirectory. Read the help for details.

-------------------------------------------------------------------------------

## Vim support plugin

Some VimL commands are included for convenience, even if they aren't necessary
to use the plugins. See `:help vpacks`

You can run the shell command from vim, in a terminal buffer if supported:

    Vpacks [arguments]

**NOTE**: the following commands aren't necessary for the plugins to work, if
you put them in your `pack/*/start/` directories. They actually **require**
that you keep your plugins in the `pack/*/opt/` directories.
Only use them if:

* you want to lazy load some plugins
* you want greater control on which plugins to load
* you want a way to have from Vim an overview of the installed plugins
* you are making the transition from another plugin manager

The syntax is meant to be very similar to the one used by [vim-plug](https://github.com/junegunn/vim-plug).
Implementation is still partial, only `on` and `for` options are supported.

```vim
" first add vpacks itself, so that commands will run
" don't use bang, and be sure that vpacks is in a /opt directory, not in /start
packadd vim-packs

" packadd! a plugin, complete with repo address
Pack 'tpope/vim-surround'

" packadd a plugin, complete with repo address
" note that the bang will cause the packadd command to be called *without* bang
" that means that the package will be immediately be added to the runtimepath
" and sourced, see ':help initialization'
Pack! 'vim-airline/vim-airline'

" a local plugin can still be updated, if it is a valid repo with remotes
Pack 'vim-fugitive'

" lazy load plugins for specific filetypes
Pack 'davidhalter/jedi-vim', {'for': 'python'}

" lazy load plugins on specific commands
Pack 'Olical/vim-enmasse', { 'on': 'EnMasse' }

" also working with lists, and plugs
Pack 'mhinz/vim-grepper', { 'on': ['Grepper', '<plug>(GrepperOperator)'] }

" not a package, but add to runtimepath anyway, cannot be installed or updated
Pack 'junegunn/fzf', { 'dir': '~/.fzf' }

" installed packages overview, and errors about missing packages
:PacksCheck

" try to install missing packages (it won't work with local plugins)
:PacksInstall
```

TODO: improve bash completion, post-install/update hooks, etc.

