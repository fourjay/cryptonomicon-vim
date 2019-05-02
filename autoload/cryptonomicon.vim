
function! cryptonomicon#openssl_cmd( cipher, pass, direction ) abort
    " try current message digest default
    call cryptonomicon#_openssl_cmd( a:cipher, 'sha256', a:pass, a:direction )
    if v:shell_error
        " redo and try older version
        silent! 0,$y
        silent! undo
        call cryptonomicon#_openssl_cmd( a:cipher, 'md5', a:pass, a:direction )
        if v:shell_error
            echohl WarningMsg | echo  'Could not decrypt ' . v:shell_error | echohl None
            silent! 0,$y
            silent! undo
        endif
    endif
endfunction

function! cryptonomicon#_openssl_cmd( cipher, digest, pass, direction ) abort
    let l:direction_option = ' -e '
    if a:direction ==# 'decrypt'
        let l:direction_option = ' -d '
    endif
    let l:pass = shellescape(a:pass)
    let l:cipher= shellescape(a:cipher)
    silent execute 
                \ '0,$ ! openssl ' 
                \ . l:cipher
                \ . ' -md ' . a:digest
                \ . l:direction_option 
                \ . " -salt -pass file:<( echo '" . l:pass . "')"
endfunction

function! cryptonomicon#decrypt(cipher, pass) abort
    call cryptonomicon#openssl_cmd(a:cipher, a:pass, 'decrypt')
endfunction

function! cryptonomicon#encrypt(cipher, pass) abort
    " echom 'got pass in encrypt of ' . a:pass
    call cryptonomicon#openssl_cmd(a:cipher, a:pass, 'encrypt')
endfunction

function! cryptonomicon#confirmed_prompt_pass() abort
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

function! cryptonomicon#rekey_password() abort
    let l:saved_cmdheight = &cmdheight
    let l:oldpass  = inputsecret('openSSL| enter old password: ')
    let l:newpass  = cryptonomicon#confirmed_prompt_pass()
    if len( l:newpass ) == 0
        echohl WarningMsg | echo  'cannot have blank password' . v:shell_error | echohl None
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

function! cryptonomicon#singlepass_prompt() abort
    let l:saved_cmdheight = &cmdheight
    let l:pass = inputsecret('openSSL| enter password: ')
    let &cmdheight = l:saved_cmdheight
    return l:pass
endfunction

function! cryptonomicon#is_new_file() abort
    return filereadable(expand('%'))
endfunction

function! cryptonomicon#get_cipher() abort
    let l:cipher = expand('%:e')
    if l:cipher ==? 'aes'
        let l:cipher = 'aes-256-cbc'
    endif
    return l:cipher
endfunction

function! cryptonomicon#readpre() abort
    setlocal binary
    setlocal viminfo=
    setlocal noswapfile
    if cryptonomicon#is_new_file()
        let b:openssl_pass = cryptonomicon#singlepass_prompt()
    endif
endfunction

function! cryptonomicon#readpost() abort
    let l:encoding = cryptonomicon#get_cipher()
    call cryptonomicon#decrypt(l:encoding, b:openssl_pass )
endfunction

function! cryptonomicon#write_pre() abort
    setlocal binary
    setlocal noendofline
    if ! exists( 'b:openssl_pass' )
        let b:openssl_pass = cryptonomicon#confirmed_prompt_pass()
    endif
    let l:encoding = cryptonomicon#get_cipher()
    call cryptonomicon#encrypt( l:encoding, b:openssl_pass )
endfunction

function! cryptonomicon#write_post() abort
    call cryptonomicon#readpost()
endfunction

