if exists('b:current_syntax')
  finish
endif

let b:current_syntax = 'vpacks'

syntax sync minlines=200

syn match VpacksPack '^[a-zA-Z0-9-_.]\+:\s*.*' contains=VpacksOk,VpacksUpdating,VpacksFatal,VpacksOther
syn match VpacksOther '\s*\%>30c\<.*' contained
syn match VpacksOk '\s*\%>30c\<ok\>' contained
syn region VpacksUpdating start='\s*\%>30c\<Updating' end='^$' contains=VpacksSha,VpacksUpdate contained
syn match VpacksFatal '\s*\%>30c\<fatal.*' contained
syn match VpacksUpdate '^\p\+' contained
syn match VpacksSha '\<[a-z0-9]\{7}\>' contained
syn match VpacksSeparator '^\%(---\|―――\).*'
syn match VpacksHeader    '^Packs in directory' nextgroup=VpacksDirectory
syn match VpacksDirectory '\p\+' contained

hi default link VpacksPack      Title
hi default link VpacksOk        diffAdded
hi default link VpacksUpdating  Function
hi default link VpacksUpdate    Comment
hi default link VpacksFatal     WarningMsg
hi default link VpacksOther     Comment
hi default link VpacksSha       Special
hi default link VpacksSeparator Statement
hi default link VpacksHeader    Function
hi default link VpacksDirectory Title
