if exists('g:loaded_titlecase')
    finish
endif
let g:loaded_titlecase = 1

" We use `m-u t`, because in `vim-readline`,  we use `M-u` as a prefix to change
" the case of text.
nno  <silent><unique>  <m-u>t   :<C-U>set opfunc=titlecase#op<CR>g@
nno  <silent><unique>  <m-u>tt  :<C-U>set opfunc=titlecase#op<Bar>exe 'norm! '.v:count1.'g@_'<CR>
xno  <silent><unique>  <m-u>t   :<C-U>call titlecase#op('vis')<CR>
