if exists('g:autoloaded_titlecase')
    finish
endif
let g:autoloaded_titlecase = 1

" Init {{{1

" Goal:
" build the pattern `s:pat` matching all the words we want to capitalize.

" The following dictionary stores the articles/conjunctions/prepositions
" which should not be capitalized. It misses some of them.
" For more info, see:
"
" https://en.wikipedia.org/wiki/List_of_English_prepositions#Single_words
" https://en.wikipedia.org/wiki/Conjunction_(grammar)#Correlative_conjunctions
" https://en.wikipedia.org/wiki/Conjunction_(grammar)#Subordinating_conjunctions
"
" Correlative and subordinating conjunctions can be in several parts.
" Eg:
"     no sooner than
"     as far as
"
" If one  day, we want  to exclude them,  we would have to  add an entry  in the
" dictionary. They can't be mixed with single-word conjunctions.
" Indeed, each conjunction will be used to produce a concat inside the
" regex used to match the words to capitalize.
" But the syntax for a concat which excludes a multi-part conjunction,
" won't be the same as the concat which excludes a single-word conjunction.

const s:TO_IGNORE = {'articles': ['a', 'an', 'the'],
    \ 'conjunctions': [
    \     'after',
    \     'although',
    \     'and',
    \     'as',
    \     'because',
    \     'before',
    \     'but',
    \     'either',
    \     'for',
    \     'if',
    \     'nor',
    \     'once',
    \     'or',
    \     'since',
    \     'so',
    \     'than',
    \     'that',
    \     'though',
    \     'till',
    \     'until',
    \     'when',
    \     'where',
    \     'whether',
    \     'while',
    \     'yet'
    \ ],
    \
    \ 'prepositions': [
    \     'about',
    \     'above',
    \     'across',
    \     'against',
    \     'along',
    \     'among',
    \     'around',
    \     'at',
    \     'before',
    \     'behind',
    \     'below',
    \     'beneath',
    \     'beside',
    \     'between',
    \     'beyond',
    \     'by',
    \     'down',
    \     'during',
    \     'except',
    \     'for',
    \     'from',
    \     'in',
    \     'inside',
    \     'into',
    \     'like',
    \     'near',
    \     'of',
    \     'off',
    \     'on',
    \     'over',
    \     'since',
    \     'through',
    \     'to',
    \     'toward',
    \     'under',
    \     'until',
    \     'up',
    \     'upon',
    \     'with',
    \     'within',
    \ ]}

" don't capitalize a word which contains an uppercase character
let s:pat = '\%(\k*\u\k*\)\@!\&'

" don't capitalize a word just after an apostrophe
let s:pat ..= '''\@1<!\&'

" don't capitalize roman numerals
let s:pat ..= '\%([ivxlcdm]\+\>\)\@!\&'

" don't capitalize articles, conjunctions, and prepositions
" http://www.grammar-monster.com/lessons/capital_letters_title_case.htm
for s:exception in s:TO_IGNORE.articles
               \ + s:TO_IGNORE.conjunctions
               \ + s:TO_IGNORE.prepositions

    " We don't want `s:exception` to match at the same position than our word.{{{
    "
    " For example, if `s:exception` = `over`, then we need this concat:
    "
    "     \%(over\)\@!\&
    "
    " But, there's an exception. We *do* want to capitalize *any* word when it's
    " at the beginning of the line.
    " So, in fact, we need:
    "
    "     \%(\%(\n\s*\)\@<=.\|\%(over\)\@!\)\&
    "
    " But, there's still another exception.
    " We  *do* want  to capitalize  *any* word  when it's  the first  word on  a
    " commented  line. So,  in fact,  assuming  the  comment character  for  the
    " current buffer is `"`, we need:
    "
    "     \%(\%(\n\s*"\=\s*\)\@<=.\|\%(over\)\@!\)\&
    "                ^----^
    "
    " The commentstring is given by:
    "
    "     matchstr(&commentstring, '^\S\+\ze\s*%s')
    "
    " But we don't use it now, because we're outside the function.
    " We must get `&commentstring` inside the function.
    " So, for the moment, we use `C-a` as a place holder.
    "}}}
    let s:cml = "\x01"
    let s:concat_pat = '\\%(\\%(\\n\\s*'..s:cml..'\\s*\\)\\@<=.\\|\\%(\0\\>\\)\\@!\\)\\\&'
    let s:pat ..= substitute(s:exception, '.*', s:concat_pat, '')
endfor

unlet! s:TO_IGNORE s:exception s:cml s:concat_pat

" don't capitalize a word followed or preceded by a dot
let s:pat ..= '\.\@1<!\k\+\>\.\@!\&'

" *final* concat of  our regex, a word  longer than 3 characters,  without a dot
" before or after; capture first letter, and the rest (separately).
let s:pat ..= '\<\(\k\)\(\k\{3,}\)\>'

lockvar! s:pat

" Garbage sentences to test the pattern:
"
"     hello world foo baZbaz xvi function.calls 'norf either
"     over the quick brown fox jumps over the lazy dog

" functions {{{1
fu titlecase#op(...) abort "{{{2
    if !a:0
        let &opfunc = 'titlecase#op'
        return 'g@'
    endif
    let type = a:1
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = getreginfo('"')

    try
        set cb= sel=inclusive

        " Replace the placeholder (C-a) with the current commentstring.
        let pat = substitute(s:pat, "\x01",
            \ matchstr(&cms, '^\S\+\ze\s*%s')..(empty(&cms) ? '' : '='), 'g')

        "             ┌ first letter of a word
        "             │   ┌ rest of a word
        "             │   │
        let rep = '\u\1\L\2'

        if type is# 'line'
            sil exe 'keepj keepp ''[,'']s/'..pat..'/'..rep..'/ge'
        else
            if type is# 'char'
                sil norm! `[v`]ygv
            elseif type is# 'block'
                sil exe "norm! `[\<c-v>`]ygv"
            endif
            let reginfo = getreginfo('"')
            let contents = get(reginfo, 'regcontents', [])
            call map(contents, {_,v -> substitute(v, pat, rep, 'g')})
            call extend(reginfo, {'regcontents': contents, 'regtype': type[0]})
            call setreg('"', reginfo)
            norm! p
        endif

    catch
        return lg#catch()
    finally
        let [&cb, &sel] = [cb_save, sel_save]
        call setreg('"', reg_save)
    endtry
endfu

