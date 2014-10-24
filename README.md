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

Benefits
--------
   * More flexible. Supports a range of SSL passwords
   * Close match of native vim encryption user interface
   * Works with neovim (which does not support encryption)

Usage
------------

Open or create a file with an extension that maps to encryption format
supported by openssl. You will be prompted for a password, and the file will be
decrypted while working on it, and be re-encrypted on write.

Differences
-----------

openssl.vim script above relies completely on the openssl utility for password
management. This can make the script awkward to use, with multiple password prompts.

Issues
------

Password is stored as a buffer local variable. This may be a security concern
for some. I believe the significant ease of use of one password entry per
session justifies the risk.

Password is fed to openssl via bash process substition, which adds a little
security at the cost of a dependency.

Installation
------------

Vundle

Plugin 'fourjay/cryptonomicon-vim'
