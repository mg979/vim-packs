if exists('b:current_syntax')
  finish
endif

let b:current_syntax = 'vpacks'

syn match VpacksOk '\s\+\%>30c\<ok\>'

hi default link VpacksOk diffAdded
