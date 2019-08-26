" ========================================================================///
" Description: command-line based package manager for vim
" Maintainer:  Gianmaria Bajo <mg1979.git@gmail.com>
" File:        vpacks.vim
" Url:         https://github.com/mg979/vim-packs
" License:     MIT License
" Modified:    lun 26 agosto 2019 09:00:45
" ========================================================================///
let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_vpacks')
  finish
endif
let g:loaded_vpacks = 0.1
let g:vpacks = { 'packages': {}, 'errors': [] }

"------------------------------------------------------------------------------

command! -bang -nargs=+ Pack call s:add_package(<bang>0, <args>)

command! PacksCheck   call vpacks#check_packages()
command! PacksInstall call vpacks#install_packages()

"------------------------------------------------------------------------------

fun! s:add_package(bang, ...)
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]
  try
    let url  = split(a:000[0], '/')
    let pack = len(url) == 1 ? url[0] : url[-1]
    let packs[pack] = {
          \'status':  0,
          \'url':     len(url) == 1 ? '' : a:000[0],
          \'options': len(a:000) > 1 && type(a:2) == v:t_dict ? a:2 : {}}
  catch
    call add(errors, 'Invalid package: '. string(a:000[0]))
  endtry
  try
    exe 'packadd!' pack
    let packs[pack].status = 1
  catch
    call add(errors, 'Could not add package: '. a:000[0])
  endtry
endfun

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
