if exists('g:loaded_titlecase')
    finish
endif
let g:loaded_titlecase = 1

nno <silent><unique> +<c-t>      :<c-u>set opfunc=titlecase#op<cr>g@
nno <silent><unique> +<c-t><c-t> :<c-u>set opfunc=titlecase#op<bar>exe 'norm! '.v:count1.'g@_'<cr>
xno <silent><unique> +<c-t>      :<c-u>call titlecase#op('vis')<cr>
