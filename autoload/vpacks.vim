" ========================================================================///
" Description: command-line based package manager for vim
" Maintainer:  Gianmaria Bajo <mg1979.git@gmail.com>
" File:        vpacks.vim
" Url:         https://github.com/mg979/vim-packs
" License:     MIT License
" Modified:    Mon 24 August 2020 01:57:58
" ========================================================================///

let s:py = executable('python3') ? 'python3' : 'python'
let s:vpacks = executable('vpacks') ? 'vpacks' : has('win32')
      \      ? s:py . ' "' . tr(fnamemodify(expand('<sfile>'), ':p:h:h'), '\', '/') . '/vpacks"'
      \      : fnamemodify(expand('<sfile>'), ':p:h:h') . '/vpacks'

"------------------------------------------------------------------------------

fun! vpacks#check_packages() abort
  " PacksList command.{{{1
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]

  exe tabpagenr()-1 . 'tabnew'
  setlocal bt=nofile bh=wipe noswf nobl nowrap
  setfiletype vpackslist

  let &l:statusline = "%#PmenuSel# I: %#Pmenu# install   %#PmenuSel# U: %#Pmenu# update   %#PmenuSel# D: %#Pmenu# diff"
  call setline(1, printf("%-30s\tStatus\t\t%-38s\tOptions", 'Packages', 'Repo'))
  put =''
  for pack in sort(keys(packs))
    let status  = ['FAIL', 'OK', 'LAZY'][packs[pack].status]
    let url     = s:pad(packs[pack].url, 40)
    let options = empty(packs[pack].options) ? '-'
          \     : string(filter(packs[pack].options, 'v:key != "is_lazy"'))
    let string  = printf("\t%-30s\t%4s\t%-40s\t%s", pack, status, url, options)
    put =string
  endfor
  call append(line('$'), '')

  nnoremap <buffer> I :.call <sid>install_pack()<cr>
  xnoremap <buffer> I :call <sid>install_pack()<cr>
  nnoremap <buffer> D :exe 'Vpacks lastdiff' split(getline('.'))[0]<cr>
  nnoremap <buffer> U :exe 'Vpacks update' split(getline('.'))[0]<cr>

  if empty(errors)
    call append(line('$'), 'No errors')
    1
    return
  endif
  call append(line('$'), 'Errors:')
  call append(line('$'), '')
  for err in errors
    call append('$', "\t".err)
  endfor
  1
endfun "}}}

"------------------------------------------------------------------------------

fun! vpacks#install_packages(bang, args) abort
  " PacksInstall command.{{{1
  if !executable('sh') && !executable('bash')
    echo '[vpacks] sh/bash executable is needed'
    return
  endif

  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]

  if a:bang
    let to_install = keys(filter(copy(packs),
          \'v:val.status != 1 && v:val.url!="" && !has_key(v:val.options, "dir")'))
  else
    let to_install = split(a:args)
  endif

  if empty(to_install)
    echo '[vpacks] no packages to install'
    return
  endif

  let lines = []
  for p in to_install
    if has_key(packs, p)
      let cmd = s:install_cmd(packs[p]) .s:hook(p)
    else
      let cmd = 'install opt ' . p
    endif
    call add(lines, s:vpacks . ' ' . cmd)
  endfor
  let s:cmd = 'packages installation'
  call s:term_start(join(lines, ';'), s:cmd)
  let &l:statusline = '%#Search# Installing packages, please wait.... %#StatusLine# '
endfun "}}}

"------------------------------------------------------------------------------

fun! vpacks#update_packages(bang, args) abort
  " PacksUpdate command.{{{1
  if has('win32')
    echo 'Windows not supported'
    return
  endif
  let [cmd, post, args] = [s:vpacks . ' update', '', !empty(a:args)]
  if !a:bang && !args
    echo '[vpacks] argument needed'
    return
  endif
  let packs = !a:bang ? split(a:args)
        \   : map(s:find_paths(), { k,v -> substitute(v, '.*/', '', '') })
  for pack in packs
    let hasDirOpt = 0
    if has_key(g:vpacks.packages, pack)
      let post .= s:hook(pack)
      let hasDirOpt = has_key(g:vpacks.packages[pack].options, 'dir')
    endif
    " we don't want to add to the command the packages that have a 'dir' option
    " because it means it's not in /pack, so vpacks would fail and terminate
    if args && !hasDirOpt
      let cmd .= ' ' . pack
    endif
  endfor
  " if no arg has been found in the packpath, we don't run a bare full update
  if !a:bang && cmd == s:vpacks . ' update'
    let [cmd, post] = ['', post[1:]]
  else
    let cmd = s:banner('Updating packages...')[1:] . ';' . cmd
  endif
  let s:cmd = cmd
  call s:term_start(cmd . post)
endfun "}}}

"------------------------------------------------------------------------------

fun! vpacks#run(bang, cmd, ...) abort
  " Vpacks command.{{{1
  echo "\r"
  let s:cmd = a:cmd
  if a:bang || get(g:, 'vpacks_force_true_terminal', has('win32'))
    exe '!' . s:vpacks . ' ' . a:cmd
  elseif has('nvim') || has('terminal')
    call s:term_start(s:vpacks . ' ' . a:cmd, 'vpacks ' . a:cmd)
    let wait = '%#Search# Please wait... %#StatusLine# '
    let &l:statusline = a:0 ? a:1 : (wait . 'vpacks ' . a:cmd)
  else
    exe '!' . s:vpacks . ' ' . a:cmd
  endif
endfun "}}}

"------------------------------------------------------------------------------

fun! vpacks#lazy_cmd(name, cmd, bang, l1, l2, args) abort
  " Load a lazy plugin with its real command.{{{1
  exe "delcommand" a:cmd
  exe "Pack! '".a:name."'"
  if g:vpacks.packages[a:name].status
    let bang = a:bang ? '!' : ''
    let range = a:l1 == a:l2 ? '' : a:l1 . ',' . a:l2
    exe printf(":%s%s%s %s", range, a:cmd, bang, a:args)
  else
    echohl WarningMsg
    echo '[vpacks] could not add package'
    echohl None
  endif
endfun "}}}

"------------------------------------------------------------------------------

fun! vpacks#lazy_plug(name, plug) abort
  " Plug for a plugin that has been lazy loaded.{{{1
  exe "unmap" a:plug
  exe "Pack! '".a:name."'"
  if g:vpacks.packages[a:name].status
    " snippet from vim-plug by Junegunn Choi
    let extra = ''
    while 1
      let c = getchar(0)
      if c == 0
        break
      endif
      let extra .= nr2char(c)
    endwhile
    call feedkeys(substitute(a:plug, '\c<plug>', "\<Plug>", '') . extra)
  else
    echohl WarningMsg
    echo '[vpacks] could not add package'
    echohl None
  endif
endfun "}}}




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pad(t, n) abort
  " Make a string fit. {{{1
  if len(a:t) > a:n
    return a:t[:(a:n-1)]."…"
  else
    let spaces = a:n - len(a:t)
    let spaces = printf("%".spaces."s", "")
    return a:t.spaces
  endif
endfun " }}}

fun! s:banner(string)
  " Banner for hooks.{{{1
  return printf(";echo;echo '%s%s';echo %s%s;echo",
        \       "\33[93m", a:string, repeat('-', len(a:string)), "\033[0m")
endfun "}}}

fun! s:setftype() abort
  " Set filetype for the vpacks buffer.{{{1
    if s:cmd =~ 'lastdiff'
      setfiletype diff
    elseif has('win32') || has('win32unix')
      setfiletype vpacks
    endif
endfun "}}}

fun! s:statusline(...)
  " Statusline for the vpacks buffer.{{{1
  let finish =  '%#IncSearch# FINISHED %#StatusLine# '
  let &l:statusline =  finish . s:cmd
  if &ft == 'vpacks'
    set nowrap
    silent! setlocal modifiable
    silent! %s/^---\+/\=repeat('―', 67)/
    setlocal nomodifiable
    setlocal nomodified
  endif
endfun "}}}

fun! s:term_start(cmd, ...) abort
  " Open a terminal and run a command.{{{1
  if has('nvim')
    botright new
    setlocal bt=nofile bh=hide noswf nobl
    call termopen(a:cmd, { 'on_exit': { -> timer_start(100, function('s:statusline')) } })
    " exe 'terminal ' . a:cmd
  elseif has('terminal')
    let name = a:0 ? a:1 : a:cmd
    let opts = {'vertical': 0,
          \     'exit_cb': { c,j -> timer_start(100, function('s:statusline')) },
          \     'term_name': name}
    call term_start(a:cmd, opts)
  else
    exe '!' . a:cmd
    return
  endif
  120wincmd |
  call s:setftype()
endfun "}}}

fun! s:install_cmd(pack)
  " Generate the command for installation, based on pack options. {{{1
  let cmd = 'install opt '
  if s:full_clone(a:pack)
    let cmd = '-full ' . cmd
  endif
  if !empty(get(a:pack.options, 'pdir', ''))
    let cmd .= 'dir='.a:pack.options.pdir.' '
  endif
  return cmd . a:pack.url
endfun " }}}

fun! s:start_packs() abort
  " Return a list of all packs in pack/*/start. {{{1
  if !exists('s:packs_in_start')
    let s:packs_in_start = globpath(&packpath, "**/pack/*/start/*", 0, 1)
  endif
  return s:packs_in_start
endfun "}}}

fun! s:opt_packs() abort
  " Return a list of all packs in pack/*/opt. {{{1
  if !exists('s:packs_in_opt')
    let s:packs_in_opt = globpath(&packpath, "**/pack/*/opt/*", 0, 1)
  endif
  return s:packs_in_opt
endfun "}}}

fun! s:hook(pack) abort
  " Return the command for the post-update hook, with banner. {{{1
  let opts = g:vpacks.packages[a:pack].options
  let do = get(opts, 'do', '')
  if !empty(do)
    let path = has_key(opts, 'dir') ? expand(opts.dir) : s:find_paths(a:pack)
    let cmd = s:banner("Running hooks for " . a:pack)
    return cmd . ';cd ' . path . ' && ' . do
  endif
  return ''
endfun "}}}

fun! s:find_paths(...) abort
  " Return a list with all packages paths, or of a specific package. {{{1
  if !a:0
    return s:start_packs() + s:opt_packs()
  endif
  for pack in s:start_packs()
    if pack =~ '\V/' . a:1 . '\$'
      return pack
    endif
  endfor
  for pack in s:opt_packs()
    if pack =~ '\V/' . a:1 . '\$'
      return pack
    endif
  endfor
  return ''
endfun "}}}

fun! s:full_clone(pack) abort
  " Perform a non-shallow clone
  return has_key(a:pack.options, 'shallow') && !a:pack.options.shallow
endfun

fun! s:url(pack) abort
  let url = split(a:pack.url, '/')
  if len(url) == 2 || url[0] == 'gh'
    let site = 'www.github.com/'
  else
    let site = 'www.gitlab.com/'
  endif
  return 'https://' . site . a:pack.url
endfun

fun! s:git_clone(pack) abort
  " Return the command to clone the repo at the desired location.
  let depth = s:full_clone(a:pack) ? '' : '--depth 1'
  let basedir = fnamemodify(a:pack.options.dir, ':p:h')
  return printf("mkdir -p %s && cd %s && git clone --recursive %s %s %s", basedir, basedir, depth, s:url(a:pack), a:pack.options.dir)
endfun

fun! s:install_pack() range
  " Install a package from the overview buffer. {{{1
  let lines = []
  for ln in range(a:firstline, a:lastline)
    let name = split(getline(ln))[0]
    try
      let pack = g:vpacks.packages[name]
      if !empty(pack.url)
        if has_key(pack.options, 'dir')
          let cmd = s:git_clone(pack) . s:hook(name)
          call add(lines, cmd)
        else
          let cmd = s:install_cmd(pack) .s:hook(name)
          call add(lines, s:vpacks . ' ' . cmd)
        endif
      else
        echo '[vpacks] no url defined for' name
      endif
    catch
    endtry
  endfor
  let s:cmd = 'packages installation'
  call s:term_start(join(lines, ';'), s:cmd)
  let &l:statusline = '%#Search# Please wait... %#StatusLine# '
endfun " }}}

" vim: et sw=2 ts=2 sts=2 fdm=marker
