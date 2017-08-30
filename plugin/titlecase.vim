if exists('g:loaded_titlecase')
    finish
endif
let g:loaded_titlecase = 1

nno <silent> crt     :<C-U>set opfunc=titlecase#op<CR>g@
nno <silent> crtt    :<C-U>set opfunc=titlecase#op<Bar>exe 'norm! '.v:count1.'g@_'<CR>

xno <silent> zrt     :<C-U>call titlecase#op(visualmode())<CR>
xno <silent> zrt     :<C-U>call titlecase#op(visualmode())<CR>
