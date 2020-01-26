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

command! -bang -nargs=+ -complete=packadd Pack   call s:add_package(<bang>0, <args>)
command! -bang -nargs=* -complete=packadd Vpacks call vpacks#run(<bang>0, <q-args>)

command! PacksCheck   call vpacks#check_packages()
command! PacksInstall call vpacks#install_packages()

"------------------------------------------------------------------------------

" Pack command calls this function.
" a bang! means that the packadd command must be called *without* bang
" that is, the package will be added immediately to the runtimepath.
fun! s:add_package(bang, ...)
  let [packs, errors, add] = [g:vpacks.packages, g:vpacks.errors, 0]
  try
    let url     = split(a:000[0], '/')
    let name    = len(url) == 1 ? url[0] : url[-1]
    let options = len(a:000) > 1 && type(a:2) == v:t_dict ? a:2 : {}
    if !has_key(packs, name)
      let packs[name] = {
            \'status':  0,
            \'url':     len(url) == 1 ? '' : a:000[0],
            \'options': options,
            \}
    endif
  catch
    call add(errors, 'Invalid package: '. string(a:000[0]))
  endtry

  " package has been already processed, now it's being lazy loaded
  if has_key(options, 'is_lazy')
    return s:add(name, a:000[0], 1, a:bang)
  endif

  " package can't be loaded for failing precondition
  if has_key(options, 'has') && !has(options.has)
    return
  endif

  " special options, lazy loading
  for opt in keys(options)
    if index(['dir', 'on', 'for'], opt) >= 0
      call s:options(name, options)
      return
    endif
  endfor

  call s:add(name, a:000[0], 0, a:bang)
endfun

"------------------------------------------------------------------------------

fun! s:add(name, url, lazy, bang) abort
  let [packs, errors] = [g:vpacks.packages, g:vpacks.errors]
  let cmd = 'packadd' . (a:lazy || a:bang ? '' : '!')
  try
    exe cmd a:name
    let packs[a:name].status = 1
  catch
    let nogit = substitute(a:name, '\.git$', '', '')
    if nogit != a:name
      let packs[nogit] = copy(packs[a:name])
      unlet packs[a:name]
    endif
    try
      exe cmd nogit
      let packs[nogit].status = 1
    catch
      let packs[nogit].status = 0
      call add(errors, 'Could not add package: '. a:url)
    endtry
  endtry
  if a:lazy
    exe 'silent! autocmd!  vpacks-'.a:name
    exe 'silent! augroup!  vpacks-'.a:name
  endif
endfun

"------------------------------------------------------------------------------

fun! s:make_cmd(name, com) abort
  if match(a:com, '\c<plug>') == 0
    let cmd = "noremap <silent> %s :call vpacks#lazy_plug('%s', '%s')\<CR>"
    exe printf(cmd, a:com, a:name, a:com)
  else
    let cmd = "call vpacks#lazy_cmd('%s', '%s', <bang>0, <q-args>)"
    exe 'com! -bang -nargs=?' a:com printf(cmd, a:name, a:com)
  endif
endfun

fun! s:options(name, options) abort
  " 'dir': custom runtime
  " 'for': load for filetype
  " 'on':  load on command/plug

  if index(keys(a:options), 'dir') >= 0
    let dir = fnamemodify(expand(a:options.dir), ':p')
    if isdirectory(dir)
      let g:vpacks.packages[a:name].status = 1
      exe 'set runtimepath^='.escape(a:options.dir, ' ')
    endif
    return
  endif

  if index(keys(a:options), 'for') >= 0
    let g:vpacks.packages[a:name].status = 2
    let a:options.is_lazy = 1
    let au = 'vpacks-'.a:name
    exe 'augroup' au
    exe 'au FileType' a:options.for "Pack '".a:name."'"
    exe 'augroup END'
  endif

  if index(keys(a:options), 'on') >= 0
    let g:vpacks.packages[a:name].status = 2
    let a:options.is_lazy = 1
    if type(a:options.on) == v:t_string
      call s:make_cmd(a:name, a:options.on)
    else
      for com in a:options.on
        call s:make_cmd(a:name, com)
      endfor
    endif
  endif
endfun

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
