if exists('g:loaded_titlecase')
    finish
endif
let g:loaded_titlecase = 1

nno <expr><unique> +<c-t>      titlecase#op()
nno <expr><unique> +<c-t><c-t> titlecase#op() .. '_'
xno <expr><unique> +<c-t>      titlecase#op()
