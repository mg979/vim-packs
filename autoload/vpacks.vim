" ========================================================================///
" Description: command-line based package manager for vim
" Maintainer:  Gianmaria Bajo <mg1979.git@gmail.com>
" File:        vpacks.vim
" Url:         https://github.com/mg979/vim-packs
" License:     MIT License
" Modified:    gio 29 agosto 2019 23:22:50
" ========================================================================///

let s:vpacks = executable('vpacks') ? 'vpacks' : has('win32')
      \      ? 'python3 ' . fnamemodify(expand('<sfile>'), ':p:h:h') . '/vpacks'
      \      : fnamemodify(expand('<sfile>'), ':p:h:h') . '/vpacks'

fun! vpacks#check_packages() abort
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

  nnoremap <buffer> I :call <sid>install_pack()<cr>
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
endfun

"------------------------------------------------------------------------------

fun! vpacks#install_packages() abort
  if !executable('sh')
    echo '[vpacks] sh executable is needed'
    return
  endif

  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]
  let to_install = filter(copy(packs),
        \'v:val.status != 1 && v:val.url!="" && !has_key(v:val.options, "dir")')

  if empty(map(keys(to_install), 'to_install[v:val].url'))
    echo '[vpacks] no packages to install'
    return
  endif

  let lines = []
  for p in keys(to_install)
    let cmd = s:install_cmd(packs[p])
    call add(lines, tr(s:vpacks, '\', '/') . ' ' . cmd)
  endfor
  call s:run_install(lines, '[vpacks] Installing packages, please wait...')
endfun

"------------------------------------------------------------------------------

fun! vpacks#run(bang, cmd, ...) abort
  echo "\r"
  let s:cmd = a:cmd
  if a:bang || get(g:, 'vpacks_force_true_terminal', 0)
    exe '!' . s:vpacks . ' ' . a:cmd
  elseif has('nvim')
    vnew
    setlocal bt=nofile bh=hide noswf nobl
    exe 'terminal ' . s:vpacks . ' ' . a:cmd
    let &l:statusline = a:0 ? a:1 : ('vpacks ' . a:cmd)
    call s:setftype()
  elseif has('terminal')
    let opts = {'vertical': 1,
          \     'exit_cb': { c,j -> timer_start(100, 'vpacks#statusline') },
          \     'term_name': 'vpacks ' . a:cmd}
    call term_start(s:vpacks . ' ' . a:cmd, opts)
    let wait = '%#Search# Please wait... %#StatusLine# '
    let &l:statusline = a:0 ? a:1 : (wait . 'vpacks ' . a:cmd)
    call s:setftype()
  else
    exe '!' . s:vpacks . ' ' . a:cmd
  endif
endfun

fun! s:setftype() abort
    120wincmd |
    if s:cmd =~ 'lastdiff'
      setfiletype diff
    else
      setfiletype vpacks
    endif
endfun

fun! vpacks#statusline(...)
  let finish =  '%#IncSearch# FINISHED %#StatusLine# '
  let &l:statusline =  finish . 'vpacks ' . s:cmd
  if &ft == 'vpacks'
    setlocal modifiable
    silent! %s/^---\+/―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――/
    setlocal nomodifiable
    setlocal nomodified
  endif
endfun

"------------------------------------------------------------------------------

fun! vpacks#lazy_cmd(name, cmd, bang, args) abort
  exe "delcommand" a:cmd
  exe "Pack! '".a:name."'"
  if g:vpacks.packages[a:name].status
    let b = a:bang ? '!' : ''
    call feedkeys(printf(":%s%s %s\<CR>", a:cmd, b, a:args), 'n')
  else
    echohl WarningMsg
    echo '[vpacks] could not add package'
    echohl None
  endif
endfun

"------------------------------------------------------------------------------

fun! vpacks#lazy_plug(name, plug) abort
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
    call feedkeys(substitute(a:plug, '\c<Plug>', "\<Plug>", '') . extra)
  else
    echohl WarningMsg
    echo '[vpacks] could not add package'
    echohl None
  endif
endfun

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

fun! s:run_install(lines, sl) abort
  " Run install command in terminal. {{{1
  let tfile = tempname()
  call writefile(a:lines, tfile)
  if get(g:, 'vpacks_force_true_terminal', 0)
    exe '!sh' . tfile
  elseif has('nvim')
    vnew
    setlocal bt=nofile bh=hide noswf nobl
    exe 'terminal sh' tfile
    let &l:statusline = a:sl
  elseif has('terminal')
    exe 'vertical terminal ++noclose ++norestore sh' tfile
    let &l:statusline = a:sl
  else
    exe '!sh' . tfile
  endif
endfun " }}}

fun! s:install_cmd(pack)
  " Generate the command for installation, based on pack options. {{{1
  let cmd = 'install opt '
  if has_key(a:pack.options, 'shallow') && !a:pack.options.shallow
    let cmd = '-full ' . cmd
  endif
  if !empty(get(a:pack.options, 'pdir', ''))
    let cmd .= 'dir='.a:pack.options.pdir.' '
  endif
  return cmd . a:pack.url
endfun " }}}

fun! s:install_pack()
  let pack = g:vpacks.packages[split(getline('.'))[0]]
  if !empty(pack.url)
    call vpacks#run(0, s:install_cmd(pack))
  else
    echo '[vpacks] not possible to install' pack[0]
  endif
endfun " }}}

" vim: et sw=2 ts=2 sts=2 fdm=marker
