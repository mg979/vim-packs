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
    let name = len(url) == 1 ? url[0] : url[-1]
    let options = len(a:000) > 1 && type(a:2) == v:t_dict ? a:2 : {}
    if !has_key(packs, name)
      let packs[name] = {
            \'status':  0,
            \'url':     len(url) == 1 ? '' : a:000[0],
            \'options': options}
    endif
  catch
    call add(errors, 'Invalid package: '. string(a:000[0]))
  endtry
  if !a:bang && !empty(options)
    let packs[name].status = 2
    call s:options(name, options)
  else
    call s:add(name, a:bang)
  endif
endfun

"------------------------------------------------------------------------------

fun! s:add(name, lazy) abort
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]
  let cmd = 'packadd' . (a:lazy ? '' : '!')
  try
    exe cmd a:name
    let packs[a:name].status = 1
  catch
    let packs[a:name].status = 0
    call add(errors, 'Could not add package: '. a:000[0])
  endtry
  if a:lazy
    exe 'silent! autocmd!  vpacks-'.a:name
    exe 'silent! augroup!  vpacks-'.a:name
  endif
endfun

"------------------------------------------------------------------------------

fun! s:options(name, options) abort
  " 'for': load for filetype
  " 'on':  load on command

  if index(keys(a:options), 'for') >= 0
    let au = 'vpacks-'.a:name
    exe 'augroup' au
    exe 'au FileType' a:options.for "Pack! '".a:name."'"
    exe 'augroup END'

  elseif index(keys(a:options), 'on') >= 0
    let q    = ' " . <q-args> . "'
    let cr   = "\n"
    let cmd  = printf('exe "Pack! %s" | ', "'".a:name."'")
    let cmd .= 'call feedkeys(":' . a:options.on . q . cr .'", "n")' . cr
    if type(a:options.on) == v:t_string
      exe 'com! -nargs=?' a:options.on cmd
    else
      for com in a:options.on
        exe 'com! -nargs=?' a:options.on cmd
      endfor
    endif
  endif
endfun

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
