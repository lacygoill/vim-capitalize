" FIXME:
" Use `crt` (CoeRce to Titlecase) instead of `cu` (Change Uppercase) ?

nno <silent> cu     :<C-U>set opfunc=capitalize#op<CR>g@
nno <silent> cuu    :<C-U>set opfunc=capitalize#op<Bar>exe 'norm! '.v:count1.'g@_'<CR>

" Can't use `cu` in visual mode because it would shadow the `c` operator.
" Use `Zu` instead. Mnemonic: viZual?

xno <silent> Zu     :<C-U>call capitalize#op(visualmode(), 1)<CR>
xno <silent> Zu     :<C-U>call capitalize#op(visualmode(), 1)<CR>
