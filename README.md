cryptonomicon-vim
=============

A wrapper around openssl to integrate with vim in a relatively transparent
fashion.

It's (currently) written for Unix/Linux, but could be adapted for other
environments.

It's inspired by http://www.vim.org/scripts/script.php?script_id=2012

The approach, add autocmd extension mappings to invoke openssl against a file,
appeals to me. My version caches passwords to make it's behavior much closer to
the vim standard encryption

Usage
------------

Open or create a file with an extension that maps to encryption format
supported by openssl. You will be prompted for a password, and the file will be
decrypted while working on it, and be re-encrypted on write.

Installation
------------

Vundle

Plugin 'fourjay/cryptonomicon-vim'
