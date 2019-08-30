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

  syn keyword VpacksOk OK
  syn keyword VpacksLazy LAZY
  syn keyword VpacksFail FAIL
  syn match   VpacksPack '^\%>1l.\{30}'
  hi default link VpacksOk diffAdded
  hi default link VpacksFail diffRemoved
  hi default link VpacksPack Special
  hi default link VpacksLazy Constant

  call setline(1, printf("%-30s\tStatus\t\t%-38s\tOptions", 'Packages', 'Repo'))
  put =''
  for pack in sort(keys(packs))
    let status  = ['FAIL', 'OK', 'LAZY'][packs[pack].status]
    let url     = packs[pack].url
    let options = empty(packs[pack].options) ? '-' : string(packs[pack].options)
    let string  = printf("\t%-30s\t%4s\t%-40s\t%s", pack, status, url, options)
    put =string
  endfor
  call append(line('$'), '')
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
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]
  let to_install = filter(copy(packs),
        \'!v:val.status && v:val.url!="" && !has_key(v:val.options, "dir")')
  let s:urls = map(keys(to_install), 'to_install[v:val].url')
  if empty(s:urls)
    echo '[vpacks] no packages to install'
    return
  endif
  let sl = '[vpacks] Installing packages, please wait...'
  call vpacks#run(0, 'install opt ' . join(s:urls), sl)
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

