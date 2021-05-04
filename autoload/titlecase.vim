vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Init {{{1

import Opfunc from 'lg.vim'
const SID: string = execute('fu Opfunc')->matchstr('\C\<def\s\+\zs<SNR>\d\+_')

# Goal:
# build the pattern `spat` matching all the words we want to capitalize.

# The following  dictionary stores the  articles/conjunctions/prepositions which
# should not be capitalized.  It misses some of them.
# For more info, see:
#
# https://en.wikipedia.org/wiki/List_of_English_prepositions#Single_words
# https://en.wikipedia.org/wiki/Conjunction_(grammar)#Correlative_conjunctions
# https://en.wikipedia.org/wiki/Conjunction_(grammar)#Subordinating_conjunctions
#
# Correlative and subordinating conjunctions can be in several parts.
# Eg:
#     no sooner than
#     as far as
#
# If one  day, we want  to exclude them,  we would have to  add an entry  in the
# dictionary.  They can't be mixed with single-word conjunctions.
# Indeed, each conjunction will be used to produce a concat inside the
# regex used to match the words to capitalize.
# But the syntax for a concat which excludes a multi-part conjunction,
# won't be the same as the concat which excludes a single-word conjunction.

const TO_IGNORE: dict<list<string>> = {articles: ['a', 'an', 'the'],
    'conjunctions': [
        'after',
        'although',
        'and',
        'as',
        'because',
        'before',
        'but',
        'either',
        'for',
        'if',
        'nor',
        'once',
        'or',
        'since',
        'so',
        'than',
        'that',
        'though',
        'till',
        'until',
        'when',
        'where',
        'whether',
        'while',
        'yet'
    ],
    'prepositions': [
        'about',
        'above',
        'across',
        'against',
        'along',
        'among',
        'around',
        'at',
        'before',
        'behind',
        'below',
        'beneath',
        'beside',
        'between',
        'beyond',
        'by',
        'down',
        'during',
        'except',
        'for',
        'from',
        'in',
        'inside',
        'into',
        'like',
        'near',
        'of',
        'off',
        'on',
        'over',
        'since',
        'through',
        'to',
        'toward',
        'under',
        'until',
        'up',
        'upon',
        'with',
        'within',
    ]}

# don't capitalize a word which contains an uppercase character
var spat: string = '\%(\k*\u\k*\)\@!\&'

# don't capitalize a word just after an apostrophe
spat ..= '''\@1<!\&'

# don't capitalize roman numerals
spat ..= '\%([ivxlcdm]\+\>\)\@!\&'

# don't capitalize articles, conjunctions, and prepositions
# http://www.grammar-monster.com/lessons/capital_letters_title_case.htm
# We don't want `exception` to match at the same position than our word.{{{
#
# For example, if `exception` = `over`, then we need this concat:
#
#     \%(over\)\@!\&
#
# But, there's an exception.  We *do* want to capitalize *any* word when it's
# at the beginning of the line.
# So, in fact, we need:
#
#     \%(\%(\n\s*\)\@<=.\|\%(over\)\@!\)\&
#
# But, there's still another exception.
# We  *do* want  to capitalize  *any* word  when it's  the first  word on  a
# commented  line.  So,  in fact,  assuming  the comment  character for  the
# current buffer is `"`, we need:
#
#     \%(\%(\n\s*"\=\s*\)\@<=.\|\%(over\)\@!\)\&
#                ^----^
#
# The commentstring is given by:
#
#     &commentstring->matchstr('^\S\+\ze\s*%s')
#
# But we don't use it now, because we're outside the function.
# We must get `&commentstring` inside the function.
# So, for the moment, we use `C-a` as a place holder.
#}}}
var cml: string = "\x01"
var concat_pat: string = '\\%(\\%(\\n\\s*' .. cml .. '\\s*\\)\\@<=.\\|\\%(\0\\>\\)\\@!\\)\\\&'
for exception in TO_IGNORE.articles
               + TO_IGNORE.conjunctions
               + TO_IGNORE.prepositions

    spat ..= exception->substitute('.*', concat_pat, '')
endfor

# don't capitalize a word followed or preceded by a dot
spat ..= '\.\@1<!\k\+\>\.\@!\&'

# *final* concat of  our regex, a word  longer than 3 characters,  without a dot
# before or after; capture first letter, and the rest (separately).
spat ..= '\<\(\k\)\(\k\{3,}\)\>'

lockvar! spat

# Garbage sentences to test the pattern:
#
#     hello world foo baZbaz xvi function.calls 'norf either
#     over the quick brown fox jumps over the lazy dog

# Interface {{{1
def titlecase#op(): string #{{{2
    &opfunc = SID .. 'Opfunc'
    g:opfunc = {core: Titlecase}
    return 'g@'
enddef
#}}}1
# Core {{{1
def Titlecase(type: string) #{{{2
    # Replace the placeholder (C-a) with the current commentstring.
    var pat: string = spat
        ->substitute(
            '\%x01',
            &cms->matchstr('^\S\+\ze\s*%s') .. (empty(&cms) ? '' : '='),
            'g'
        )

    #                     ┌ first letter of a word
    #                     │   ┌ rest of a word
    #                     │   │
    var rep: string = '\u\1\L\2'

    if type == 'line'
        exe 'sil keepj keepp :''[,'']s/' .. pat .. '/' .. rep .. '/ge'
    else
        var reginfo: dict<any> = getreginfo('"')
        var contents: list<string> = get(reginfo, 'regcontents', [])
            ->map((_, v: string): string => v->substitute(pat, rep, 'g'))
        extend(reginfo, {regcontents: contents, regtype: type[0]})
        setreg('"', reginfo)
        norm! p
    endif
enddef

