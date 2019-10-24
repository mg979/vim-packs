" ========================================================================///
" Description: command-line based package manager for vim
" Maintainer:  Gianmaria Bajo <mg1979.git@gmail.com>
" File:        vpacks.vim
" Url:         https://github.com/mg979/vim-packs
" License:     MIT License
" Modified:    gio 29 agosto 2019 23:22:50
" ========================================================================///

fun! vpacks#check_packages() abort
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]

  exe tabpagenr()-1 . 'tabnew'
  setlocal bt=nofile bh=wipe noswf nobl nowrap

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

  syn keyword VpacksOk OK
  syn keyword VpacksLazy LAZY
  syn keyword VpacksFail FAIL
  exe 'syn match   VpacksPack /^\%>1l\%<'.line('$').'l.\{30}/'
  hi default link VpacksOk diffAdded
  hi default link VpacksFail diffRemoved
  hi default link VpacksPack Special
  hi default link VpacksLazy Constant

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
    let pack = packs[p]
    let cmd = 'install opt '
    if has_key(pack.options, 'shallow') && !pack.options.shallow
      let cmd = '-full ' . cmd
    endif
    if !empty(get(pack.options, 'pdir', ''))
      let cmd .= 'dir='.pack.options.pdir.' '
    endif
    call add(lines, 'vpacks ' . cmd . pack.url)
  endfor
  call s:run(lines, '[vpacks] Installing packages, please wait...')
endfun

"------------------------------------------------------------------------------

fun! s:run(lines, sl) abort
  let tfile = tempname()
  call writefile(a:lines, tfile)
  if get(g:, 'vpacks_force_true_terminal', 0)
    exe '!sh' . tfile
  elseif has('nvim')
    vnew
    setlocal bt=nofile bh=wipe noswf nobl
    exe 'terminal sh' tfile
    let &l:statusline = a:sl
  elseif has('terminal')
    exe 'vertical terminal ++noclose ++norestore sh' tfile
    let &l:statusline = a:sl
  else
    exe '!sh' . tfile
  endif
endfun

"------------------------------------------------------------------------------

fun! vpacks#run(bang, cmd, ...) abort
  echo "\r"
  if a:bang || get(g:, 'vpacks_force_true_terminal', 0)
    exe '!vpacks' a:cmd
  elseif has('nvim')
    vnew
    setlocal bt=nofile bh=wipe noswf nobl
    exe 'terminal vpacks' a:cmd
    let &l:statusline = a:0 ? a:1 : ('vpacks ' . a:cmd)
  elseif has('terminal')
    exe 'vertical terminal ++noclose ++norestore vpacks' a:cmd
    let &l:statusline = a:0 ? a:1 : ('vpacks ' . a:cmd)
  else
    exe '!vpacks' a:cmd
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

"------------------------------------------------------------------------------

fun! s:pad(t, n) abort
  if len(a:t) > a:n
    return a:t[:(a:n-1)]."…"
  else
    let spaces = a:n - len(a:t)
    let spaces = printf("%".spaces."s", "")
    return a:t.spaces
  endif
endfun
