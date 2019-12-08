if exists('b:current_syntax')
  finish
endif

let b:current_syntax = 'vpackslist'

syn keyword VpacksListOk OK
syn keyword VpacksListLazy LAZY
syn keyword VpacksListFail FAIL
exe 'syn match   VpacksListPack /^\%>1l\%<'.line('$').'l.\{30}/'

hi default link VpacksListOk diffAdded
hi default link VpacksListFail diffRemoved
hi default link VpacksListPack Special
hi default link VpacksListLazy Constant
