vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

nno <expr><unique> +<c-t>      titlecase#op()
nno <expr><unique> +<c-t><c-t> titlecase#op() .. '_'
xno <expr><unique> +<c-t>      titlecase#op()
