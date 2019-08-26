" ========================================================================///
" Description: command-line based package manager for vim
" Maintainer:  Gianmaria Bajo <mg1979.git@gmail.com>
" File:        vpacks.vim
" Url:         https://github.com/mg979/vim-packs
" License:     MIT License
" Modified:    lun 26 agosto 2019 09:00:45
" ========================================================================///

"------------------------------------------------------------------------------

fun! vpacks#check_packages() abort
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]

  new
  setlocal bt=nofile bh=wipe noswf nobl
  call setline(1, 'Packages:')
  put =''
  for pack in keys(packs)
    let s = printf("\t%-20s\t%s", pack, string(packs[pack]))
          " \ (packs[pack].status?'ok':'no'))
    put =s
  endfor
  call append(line('$'), '')
  call append(line('$'), 'Errors:')
  call append(line('$'), '')
  for err in errors
    call append('$', "\t".err)
  endfor
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
