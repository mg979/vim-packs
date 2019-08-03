# vpacks

![Imgur](https://i.imgur.com/xqk21Rm.gif)

A light command-line package manager for vim 8 (or nvim), written in python.

## Installation

Put the python executable somewhere (preferably in your path), then you can run
it from the terminal. Tested in Linux only (should work in mintty too).

If you want tab completion, also source the optional shell script in your
.bashrc.

    source path/to/vpacks.sh

## Options explained

Commands (`list`, `update`, etc) are performed on *all* packages if given
without arguments.

Most options are straightforward and described in the command line help.

- the `-nd` (no decorations) option can be useful in combination with `grep`
- the `-na` (no async) option should be used if you must insert passwords
- the `-ps` (print size) option only works with the `list` command

The `list` command also shows if there are modified/untracked files in the
working tree of the plugin:

![Imgur](https://i.imgur.com/oQn13PY.gif)

## Installing packages

The script recognizes the following formats for remote repos:

- *user/plugin*: a GitHub repo
- *gh/user/plugin*: a GitHub repo
- *gl/user/plugin*: a GitLab repo
- *http(s)://...*: any repo

Repositories are cloned with `--depth 1` (shallow clones) to save disk space.
