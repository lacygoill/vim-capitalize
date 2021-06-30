vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

nnoremap <expr><unique> +<C-T>      titlecase#op()
nnoremap <expr><unique> +<C-T><C-T> titlecase#op() .. '_'
xnoremap <expr><unique> +<C-T>      titlecase#op()
