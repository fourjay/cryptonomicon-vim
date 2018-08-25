" Intergrate openssl with vim
" Author: Josef Fortier

if exists('g:loaded_cryptonomicon')
    finish
endif
let g:loaded_cryptonomicon = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:openssl_cmd( cipher, pass, direction ) abort
    " try current message digest default
    call s:_openssl_cmd( a:cipher, 'sha256', a:pass, a:direction )
    if v:shell_error
        " redo and try older version
        silent! 0,$y
        silent! undo
        call s:_openssl_cmd( a:cipher, 'md5', a:pass, a:direction )
        if v:shell_error
            echohl WarningMsg | echo  'Could not decrypt ' . v:shell_error | echohl None
            silent! 0,$y
            silent! undo
        endif
    endif
endfunction

function! s:_openssl_cmd( cipher, digest, pass, direction ) abort
    let l:direction_option = ' -e '
    if a:direction ==# 'decrypt'
        let l:direction_option = ' -d '
    endif
    let l:pass = shellescape(a:pass)
    let l:cipher= shellescape(a:cipher)
    silent execute 
                \ '0,$ ! openssl ' 
                \ . l:cipher
                \ . " -md " . a:digest
                \ . l:direction_option 
                \ . " -salt -pass file:<( echo '" . l:pass . "')"
endfunction

function! s:decrypt(cipher, pass) abort
    call <SID>openssl_cmd(a:cipher, a:pass, 'decrypt')
endfunction

function! s:encrypt(cipher, pass) abort
    " echom 'got pass in encrypt of ' . a:pass
    call <SID>openssl_cmd(a:cipher, a:pass, 'encrypt')
endfunction

command! SSLDecrypt call <SID>decrypt(
            \ <SID>get_cipher(),
            \ b:openssl_pass )

function! s:confirmed_prompt_pass() abort
    let l:saved_cmdheight = &cmdheight
    let l:pass   = inputsecret('openSSL| enter password: ')
    let l:pass2  = inputsecret('openSSL|re-enter password: ')
    " let cmdheight = l:saved_cmdheight
    if l:pass == l:pass2
        return l:pass
    else
        return ''
    endif
endfunction

function! s:rekey_password() abort
    let l:saved_cmdheight = &cmdheight
    let l:oldpass  = inputsecret('openSSL| enter old password: ')
    let l:newpass  = <SID>confirmed_prompt_pass()
    if len( l:newpass ) == 0
        echo 'cannot have blank password'
        return ''
    endif
    let &cmdheight = l:saved_cmdheight
    if l:oldpass == b:openssl_pass
        let b:openssl_pass = l:newpass
        return 1
    else
        echo 'bad password'
        return 0
    endif
endfunction

function! s:singlepass_prompt() abort
    let l:saved_cmdheight = &cmdheight
    let l:pass = inputsecret('openSSL| enter password: ')
    let &cmdheight = l:saved_cmdheight
    return l:pass
endfunction

function! s:is_new_file() abort
    return filereadable(expand('%'))
endfunction

function! s:get_cipher() abort
    let l:cipher = expand('%:e')
    if l:cipher ==? 'aes'
        let l:cipher = 'aes-256-cbc'
    endif
    return l:cipher
endfunction

function! s:readpre() abort
    setlocal binary
    setlocal viminfo=
    setlocal noswapfile
    if <SID>is_new_file()
        let b:openssl_pass = <SID>singlepass_prompt()
    endif
endfunction

function! s:readpost() abort
    let l:encoding = <SID>get_cipher()
    call <SID>decrypt(l:encoding, b:openssl_pass )
endfunction

function! s:write_pre() abort
    setlocal binary
    setlocal noendofline
    if ! exists( 'b:openssl_pass' )
        let b:openssl_pass = <SID>confirmed_prompt_pass()
    endif
    let l:encoding = <SID>get_cipher()
    call <SID>encrypt( l:encoding, b:openssl_pass )
endfunction

function! s:write_post() abort
    call <SID>readpost()
endfunction

command! SSLRekey :call <SID>rekey_password()
augroup cryptonomicon_ag
    autocmd!
    autocmd BufReadPre   *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>readpre()
    autocmd BufReadPost  *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>readpost()
    autocmd BufWritePre  *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>write_pre()
    autocmd BufWritePost *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call <SID>write_post()
    autocmd BufRead      *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx 
                \ :cnoreabbrev <buffer> <expr> X (getcmdtype() is# ':' && getcmdline() is# 'X') ? 'SSLRekey' : 'X'
augroup end

nnoremap <Plug>SSLRekey :call <SID>rekey_password()<Cr>
" nmap <buffer> X <Plug>Rekey

let &cpoptions = s:save_cpo 
unlet s:save_cpo
