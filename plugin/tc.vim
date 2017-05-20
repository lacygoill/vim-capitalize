" FIXME:
" Use `crt` instead of `cu` ?

nno <silent> cu     :<C-U>set opfunc=tc#op_titlecase<CR>g@
nno <silent> cuu    :<C-U>set opfunc=tc#op_titlecase<Bar>exe 'norm! ' . v:count1 . 'g@_'<CR>

" Can't use `cu` in visual mode because it would shadow the `c` operator.
" Use `Zu` instead. Mnemonic: viZual?

xno <silent> Zu     :<C-U>call tc#op_titlecase(visualmode(), 1)<CR>
xno <silent> Zu     :<C-U>call tc#op_titlecase(visualmode(), 1)<CR>
