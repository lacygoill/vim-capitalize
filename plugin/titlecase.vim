if exists('g:loaded_titlecase')
    finish
endif
let g:loaded_titlecase = 1

" Mnemonics:
" CoeRce Titlecase
nno <silent> crt     :<C-U>set opfunc=titlecase#op<CR>g@
nno <silent> crtt    :<C-U>set opfunc=titlecase#op<Bar>exe 'norm! '.v:count1.'g@_'<CR>

xno <silent> mrt     :<C-U>exe titlecase#op('vis')<CR>
xno <silent> mrt     :<C-U>exe titlecase#op('vis')<CR>
