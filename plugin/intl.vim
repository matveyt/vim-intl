" Vim plugin to add few missing i18n bits
" Last Change:  2022 Jul 21
" License:      VIM License
" URL:          https://github.com/matveyt/vim-intl

if exists('g:loaded_intl')
    finish
endif
let g:loaded_intl = 1

let s:save_cpo = &cpo
set cpo&vim

" internal function to langmap {str}
" {dir} is TRUE to map from ASCII to lang, FALSE otherwise
function s:lmap(str, dir = &iminsert) abort
    if !strchars(a:str, 1) || empty(&keymap)
        return a:str
    endif

    " Note: only works for one-letter lmaps
    let l:tab = 's:tr_'..substitute(&keymap, '\W', '_', 'g')
    if !exists(l:tab)
        let [l:ascii, l:lang] = [[], []]
        for l:from in range(32, 126)->map({_, v -> nr2char(v)})
            let l:to = l:from->maparg('l')
            if !empty(l:to)
                call add(l:ascii, l:from)
                call add(l:lang, l:to)
            endif
        endfor
        let {l:tab} = [join(l:ascii, ''), join(l:lang, '')]
    endif

    return tr(a:str, {l:tab}[!a:dir], {l:tab}[!!a:dir])
endfunction

" generic <plug> to use
inoremap <silent><plug>lmap; <C-^><C-R>=<SID>lmap(@@)<CR>

" default mappings
if !hasmapto('<plug>lmap;', 'i')
    " <C-B> to toggle lmap for the last WORD typed
    " <C-L> to toggle lmap for the last change typed
    " <C-S> to toggle lmap for the last sentence typed
    inoremap <unique><C-B> <C-\><C-O>dB<plug>lmap;
    inoremap <unique><C-L> <C-\><C-O>d`[<plug>lmap;<C-G>u
    inoremap <unique><C-S> <C-\><C-O>d(<plug>lmap;
endif

" download missing spell files (disables spellfile plugin)
autocmd! SpellFileMissing * execute '!'
    \   executable('curl') ? 'curl -OO --create-dirs --output-dir' :
    \   executable('wget') ? 'wget -NP' :
    \   'echo -e ''\e[31;1mSpellFileMissing <amatch>\e[0m\n'''
    \
    \   shellescape(strpart(&rtp, 0, stridx(&rtp, ','))..'/spell', v:true)
    \   printf('%s/%s.%s.{spl,sug}',
    \       get(g:, 'spellfile_URL', 'https://ftp.nluug.nl/pub/vim/runtime/spell'),
    \       '<amatch>', &encoding)

" dumb compat. function
let Gettext = exists('*gettext') ? function('gettext') : {s -> s}

let &cpo = s:save_cpo
unlet s:save_cpo
