" Intergrate openssl with vim
" Author: Josef Fortier

if exists('g:loaded_cryptonomicon')
    finish
endif
let g:loaded_cryptonomicon = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! SSLDecrypt call cryptonomicon#decrypt(
            \ cryptonomicon#get_cipher(),
            \ b:openssl_pass )

command! SSLRekey :call cryptonomicon#rekey_password()

augroup cryptonomicon_ag
    autocmd!
    autocmd BufReadPre   *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call cryptonomicon#readpre()
    autocmd BufReadPost  *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call cryptonomicon#readpost()
    autocmd BufWritePre  *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call cryptonomicon#write_pre()
    autocmd BufWritePost *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call cryptonomicon#write_post()
    autocmd BufRead      *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx 
                \ :cnoreabbrev <buffer> <expr> X (getcmdtype() is# ':' && getcmdline() is# 'X') ? 'SSLRekey' : 'X'
augroup end

nnoremap <Plug>SSLRekey :call cryptonomicon#rekey_password()<Cr>
" nmap <buffer> X <Plug>Rekey

let &cpoptions = s:save_cpo 
unlet s:save_cpo
