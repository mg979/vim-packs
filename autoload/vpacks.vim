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
  let to_install = filter(copy(packs), '!v:val.status && v:val.url!=""')
  let s:urls = map(keys(to_install), 'to_install[v:val].url')
  if empty(s:urls)
    echo '[vpacks] no packages to install'
    return
  endif
  new
  setlocal bt=nofile bh=wipe noswf nobl
  call setline(1, "Installing packages...")
  put =''
  call append('$', '')
  let Inst = function('s:install')
  call timer_start(100, Inst)
endfun

fun! s:install(...)
  exe 'r! vpacks -nc install opt' join(s:urls)
endfun

"------------------------------------------------------------------------------

fun! vpacks#lazy(name, cmd, bang, args) abort
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

