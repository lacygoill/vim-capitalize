if exists('g:loaded_titlecase')
    finish
endif
let g:loaded_titlecase = 1

" Mnemonics:
" CoeRce Titlecase
"
" `vim-abolish` already uses `crt` to perform a simpler titlecase coercion.
" But it only works on the word under the cursor. So it's not very useful.
" Besides, we already have `m-u c` which does something similar.
nno  <silent><unique>  crt   :<C-U>set opfunc=titlecase#op<CR>g@
nno  <silent><unique>  crtt  :<C-U>set opfunc=titlecase#op<Bar>exe 'norm! '.v:count1.'g@_'<CR>

" We use `m-u t`, because in `vim-readline`,  we use `M-u` as a prefix to change
" the case of text.
xno  <silent><unique>  <m-u>t  :<C-U>call titlecase#op('vis')<CR>
