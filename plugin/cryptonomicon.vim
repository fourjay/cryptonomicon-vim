" Intergrate openssl with vim
" Copyright (C) 2014 Josef Fortier
" 
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 2 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program; if not, see <http://www.gnu.org/licenses/>.

if exists("g:load_cryptomonicon")
    finish
endif
let g:load_cryptomonicon = 1

function! s:openssl_cmd( cipher, pass, direction )
    let l:direction_option = " -e "
    if a:direction == "decrypt"
        let l:direction_option = " -d "
    endif
    let l:pass = shellescape(a:pass)
    let l:cipher= shellescape(a:cipher)
    silent execute 
                \ "0,$ ! openssl " . l:cipher
                \ . l:direction_option 
                \ . " -salt -pass file:<( echo '" . l:pass . "')"
    if v:shell_error
        echohl WarningMsg | echo  "Could not decrypt " . v:shell_error | echohl None
        silent! 0,$y
        silent! undo
    endif
endfunction

function! s:decrypt(cipher, pass)
    call <SID>openssl_cmd(a:cipher, a:pass, "decrypt")
endfunction

function! s:encrypt(cipher, pass)
    echom "got pass in encrypt of " . a:pass
    call <SID>openssl_cmd(a:cipher, a:pass, "encrypt")
endfunction

command! SSLDecrypt call <SID>decrypt(
            \ <SID>get_cipher(),
            \ b:openssl_pass )

function! s:confirmed_prompt_pass()
    let l:saved_cmdheight = &cmdheight
    let l:pass  = inputsecret("enter password: ")
    let l:pass2  = inputsecret("re-enter password: ")
    let cmdheight = l:saved_cmdheight
    if l:pass == l:pass2
        return l:pass
    else
        return ""
    endif
endfunction

function! s:singlepass_prompt()
    let l:saved_cmdheight = &cmdheight
    let l:pass = inputsecret("enter password: ")
    let cmdheight = l:saved_cmdheight
    return l:pass
endfunction

function! s:is_new_file()
    return filereadable(expand('%'))
endfunction

function! s:get_cipher()
    let l:cipher = expand("%:e")
    return l:cipher
endfunction

function! s:readpre()
    setlocal bin
    setlocal viminfo=
    setlocal noswapfile
    if <SID>is_new_file()
        let b:openssl_pass = <SID>singlepass_prompt()
    endif
endfunction

function! s:readpost()
    let l:encoding = <SID>get_cipher()
    call <SID>decrypt(l:encoding, b:openssl_pass )
endfunction

function! s:write_pre()
    setlocal bin
    setlocal noeol
    if ! exists( 'b:openssl_pass' )
        let b:openssl_pass = <SID>confirmed_prompt_pass()
    endif
    let l:encoding = <SID>get_cipher()
    call <SID>encrypt( l:encoding, b:openssl_pass )
endfunction

function! s:write_post()
    call <SID>readpost()
endfunction

augroup cryptomonicon_ag
    autocmd!
    autocmd BufReadPre   *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>readpre()
    autocmd BufReadPost  *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>readpost()
    autocmd BufWritePre  *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>write_pre()
    autocmd BufWritePost *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>write_post()
augroup end

