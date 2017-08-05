" word_pattern {{{1

" The goal of this section is to build the pattern `s:word_pattern`
" matching all the words we want to capitalize.

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
let s:word_pattern  = '\v%(\k*\u\k*)@!&'

" don't capitalize a word just after an apostrophe
let s:word_pattern .= '''@<!&'

" don't capitalize roman numerals
let s:word_pattern .= '%([ivxlcdm]+>)@!&'

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

    let s:cms            = "\<C-a>"
    let s:concat_pattern = '%(%(\\n\\s*'.s:cms.'?\\s*)@<=.|%(&>)@!)\&'

    let s:word_pattern  .= substitute(s:exception, '.*', s:concat_pattern, '')
endfor

unlet! s:to_ignore s:exception s:cms s:concat_pattern

" don't capitalize a word followed or preceded by a dot
let s:word_pattern .= '\.@<!\k+>\.@!&'

" FINAL concat of our regex, a word longer than 3 characters, without a dot
" before or after.
" Capture first letter, and the rest (separately).

let s:word_pattern .= '<(\k)(\k{3,})>'

" Garbage sentences to test the pattern:
"
"     hello world foo baZbaz xvi function.calls 'norf either
"     over the quick brown fox jumps over the lazy dog

" functions {{{1

let s:reg_translations = {
                         \ '"': 'unnamed',
                         \ '+': 'plus',
                         \ '-': 'minus',
                         \ '*': 'star',
                         \ '/': 'slash',
                         \ }

fu! s:reg_save(names) abort
    for name in a:names
        let suffix          = get(s:reg_translations, name, name)
        let s:save_{suffix} = [getreg(name), getregtype(name)]
    endfor
endfu

fu! s:reg_restore(names) abort
    for name in a:names
        let suffix   = get(s:reg_translations, name, name)
        let contents = s:save_{suffix}[0]
        let type     = s:save_{suffix}[1]

        " FIXME: how to restore `0` {{{
        "
        " When we restore use `setreg()` or `:let`, we can't make
        " a distinction between the unnamed and copy registers.
        " IOW, whatever we do to one of them, we do it to the other.
        "
        " Why are they synchronized with `setreg()` and `:let`?
        " They aren't in normal mode. If I copy some text, they will be
        " identical. But if I delete some other text just afterwards, they
        " will be different.
        "
        " I could understand the synchronization in one direction:
        "
        "     change @0    →    change @"
        "
        " … because one could argue that the unnamed register points to the
        " last changed register. So, when we change the contents of the copy
        " register, the unnamed points to the latter. OK, why not.
        " But I can't understand in the other direction:
        "
        "     change @"    →    change @0
        "
        " If I execute:
        "
        "     :call setreg('"', 'unnamed')
        "
        " … why does the copy register receives the same contents?
        "
        " This cause a problem for all functions (operators) which need to
        " temporarily copy some text, want to restore the unnamed register
        " as well as the copy register to whatever old values they had, and
        " those 2 registers are different at the time the function was
        " invoked.
        "
        " That's why, at the moment, I don't try to restore the copy register
        " in ANY operator function. I simply CAN'T.
"}}}

        call setreg(name, contents, type)
    endfor
endfu

fu! capitalize#op(type, ...) abort

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

    " \1 matches the first letter of a word.
    " \2 matches the rest of a word.

    let upcase_replacement   = '\u\1\L\2'
    call s:reg_save(['"', '+'])

    " Replace the placeholder (C-A) with the current commentstring.
    let s:word_pattern = substitute(s:word_pattern, "\<C-A>",
                                     \ matchstr(&commentstring, '^\S\+\ze\s*%s'), 'g')

    if a:0
        norm! gvy
        let capitalized = substitute(@", s:word_pattern, upcase_replacement, 'g')
        call setreg('"', capitalized, a:type ==? "\<C-v>" ? 'b' : '')
        norm! gv""p

    elseif a:type == 'line'
        sil keepj keepp exe '''[,'']s/'.s:word_pattern.'/'.upcase_replacement.'/ge'

    else
        norm! `[v`]y
        let capitalized = substitute(@", s:word_pattern, upcase_replacement, 'g')
        norm! gv""p

    endif

    call s:reg_restore(['"', '+'])
endfu
