" guard {{{1

if exists('g:auto_loaded_titlecase')
    finish
endif
let g:auto_loaded_titlecase = 1

" functions {{{1
fu! titlecase#op(type) abort "{{{2
    let cb_save  = &cb
    let sel_save = &selection
    let reg_save = [ getreg('"'), getregtype('"') ]

    try
        set cb-=unnamed cb-=unnamedplus
        set selection=inclusive

        " Replace the placeholder (C-a) with the current commentstring.
        let s:pat = substitute(s:pat, "\<c-a>",
        \                      matchstr(&commentstring, '^\S\+\ze\s*%s'), 'g')

        "             ┌─ first letter of a word
        "             │   ┌─ rest of a word
        "             │   │
        let rep = '\u\1\L\2'

        if a:type == 'line'
            sil keepj keepp exe '''[,'']s/'.s:pat.'/'.rep.'/ge'
        else
            if a:type ==# 'vis'
                sil norm! gvy
                norm! gv
            elseif a:type ==# 'char'
                sil norm! `[v`]y
                norm! `[v`]
            elseif a:type ==# 'line'
                sil norm! '[V']y
                norm! '[V']
            elseif a:type ==# 'block'
                sil exe "norm! `[\<c-v>`]y"
                exe "norm! `[\<c-v>`]"
            endif
            let new_text = substitute(@", s:pat, rep, 'g')
            call setreg('"', new_text, a:type ==# "\<c-v>" || a:type ==# 'block' ? 'b' : '')
            norm! p
        endif

    catch
        return 'echoerr '.string(v:exception)
    finally
        let &cb  = cb_save
        let &sel = sel_save
        call setreg('"', reg_save[0], reg_save[1])
    endtry
    return ''
endfu

" variables {{{1
" pat {{{2

" Goal:
" build the pattern `s:pat` matching all the words we want to capitalize.


" The following dictionary stores the articles/conjunctions/prepositions
" which should not be capitalized. It misses some of them.
" For more info, see:
"
"         https://en.wikipedia.org/wiki/List_of_English_prepositions#Single_words
"         https://en.wikipedia.org/wiki/Conjunction_(grammar)#Correlative_conjunctions
"         https://en.wikipedia.org/wiki/Conjunction_(grammar)#Subordinating_conjunctions
"
"
" Correlative and subordinating conjunctions can be in several parts.
" Eg:
"         no sooner than
"         as far as
"
" If one day, we want to exlude them, we would have to add an entry in the
" dictionary. They can't be mixed with single-word conjunctions.
" Indeed, each conjunction will be used to produce a concat inside the
" regex used to match the words to capitalize.
" But the syntax for a concat which excludes a multi-part conjunction,
" won't be the same as the concat which excludes a single-word conjunction.

let s:to_ignore = {'articles':     ['a', 'an', 'the'],
                    \
                    \ 'conjunctions': [
                                      \ 'after',
                                      \ 'although',
                                      \ 'and',
                                      \ 'as',
                                      \ 'because',
                                      \ 'before',
                                      \ 'but',
                                      \ 'either',
                                      \ 'for',
                                      \ 'if',
                                      \ 'nor',
                                      \ 'once',
                                      \ 'or',
                                      \ 'since',
                                      \ 'so',
                                      \ 'than',
                                      \ 'that',
                                      \ 'though',
                                      \ 'till',
                                      \ 'until',
                                      \ 'when',
                                      \ 'where',
                                      \ 'whether',
                                      \ 'while',
                                      \ 'yet'
                                      \ ],
                    \
                    \ 'prepositions': [
                                      \ 'about',
                                      \ 'above',
                                      \ 'across',
                                      \ 'against',
                                      \ 'along',
                                      \ 'among',
                                      \ 'around',
                                      \ 'at',
                                      \ 'before',
                                      \ 'behind',
                                      \ 'below',
                                      \ 'beneath',
                                      \ 'beside',
                                      \ 'between',
                                      \ 'beyond',
                                      \ 'by',
                                      \ 'down',
                                      \ 'during',
                                      \ 'except',
                                      \ 'for',
                                      \ 'from',
                                      \ 'in',
                                      \ 'inside',
                                      \ 'into',
                                      \ 'like',
                                      \ 'near',
                                      \ 'of',
                                      \ 'off',
                                      \ 'on',
                                      \ 'over',
                                      \ 'since',
                                      \ 'through',
                                      \ 'to',
                                      \ 'toward',
                                      \ 'under',
                                      \ 'until',
                                      \ 'up',
                                      \ 'upon',
                                      \ 'with',
                                      \ 'within'
                                      \ ],
                    \ }

" don't capitalize a word which contains an uppercase character
let s:pat = '\v%(\k*\u\k*)@!&'

" don't capitalize a word just after an apostrophe
let s:pat .= '''@<!&'

" don't capitalize roman numerals
let s:pat .= '%([ivxlcdm]+>)@!&'

" don't capitalize articles, conjunctions, and prepositions
" http://www.grammar-monster.com/lessons/capital_letters_title_case.htm

for s:exception in s:to_ignore.articles +
                    \ s:to_ignore.conjunctions +
                    \ s:to_ignore.prepositions

    " We don't want `s:exception` to match at the same position than our word.
    " For example, if `s:exception` = `over`, then we need this concat:
    "
    "         %(over)@!.&
    "
    " But, there's an exception. We Do want to capitalize ANY word when it's
    " at the beginning of the line.
    " So, in fact, we need:
    "
    "         %(%(\n\s*)@<=.|%(over)@!)&
    "
    " But, there's still another exception.
    " We DO want to capitalize ANY word when it's the first word on
    " a commented line. So, in fact, assuming the comment character for the
    " current buffer is `"`, we need:
    "
    "         %(%(\n\s*"?\s*)@<=.|%(over)@!)&

    " The commentstring is given by:
    "
    "     matchstr(&commentstring, '^\S\+\ze\s*%s')
    "
    " But we don't use it now, because we're outside the function.
    " We must get `&commentstring` inside the function.
    " So, for the moment, we use `C-a` as a place holder.

    let s:cml            = "\<C-a>"
    let s:concat_pattern = '%(%(\\n\\s*'.s:cml.'?\\s*)@<=.|%(&>)@!)\&'

    let s:pat .= substitute(s:exception, '.*', s:concat_pattern, '')
endfor

unlet! s:to_ignore s:exception s:cml s:concat_pattern

" don't capitalize a word followed or preceded by a dot
let s:pat .= '\.@<!\k+>\.@!&'

" FINAL concat of our regex, a word longer than 3 characters, without a dot
" before or after.
" Capture first letter, and the rest (separately).

let s:pat .= '<(\k)(\k{3,})>'

" Garbage sentences to test the pattern:
"
"     hello world foo baZbaz xvi function.calls 'norf either
"     over the quick brown fox jumps over the lazy dog
