gmail.vim
=========

Description
-----------
The vim script for viewing gmail on vim.
You need to enable imap settings gmail, because this plugin use imap.


Requirements
------------

* vimproc
Interactive command execution in Vim.

    https://github.com/Shougo/vimproc

* openssl
A toolkit implementing SSL v2/v3 and TLS protocols with full-strength cryptography world-wide.
I have been tested to work with openssl included in msysgit for Windows.

    http://www.openssl.org/
    http://code.google.com/p/msysgit/


Setting
-------

* Enable imap
    Please enable imap settings gmail.
    (Please search on yourself)

* Install vimproc
    If you have installed Vundle, please set as follows in your .vimrc.

        Bundle git://github.com/Shougo/vimproc.git

* Through the path to openssl

    let &path = $path . 'c:\Program files\git\bin'

* vimrc settings such as described in the following. (Not required)

  - Server settings

        let g:gmail_imap = 'imap.gmail.com:993'

        let g:gmail_smtp = 'smtp.gmail.com:465'

  - User name settings

        let g:gmail_user_name = 'xxx@gmail.com'

  - Signature when sending mail

        let g:gmail_signature = '# ' . g:gmail_user_name . '(by gmail.vim)'


Usage
-----

* Start

Use the following commands in Command mode to start Gmail.

    :Gmail

* Operations

The first line of each screen is the menu.
Please move cursor on the menu you want to perform, and press the Enter key.

Two Factor Authentication
-------------------------

* Setup an application specific password for gmail.vim under your google security settings.
* Create the following ~/.gmailvimrc

```vim
let g:gmail_user_name = 'xxx@gmail.com'
let g:gmail_user_pass = 'application_specific_password'
```

```bash
chmod 700 ~/.gmailvimrc
# NOTE THE DOUBLE ARROW - SINGLE WILL OVERWRITE YOUR VIMRC
echo 'source ~/.gmailvimrc' >> ~/.vimrc
```

This will allow you to keep your application specific password private, even if you share your vimrc publically via github or elsewhere.

ScreenShots
-----------

* Screen Image

![sample1](http://yuratomo.up.seesaa.net/image/gmail.vim_20120812.PNG "sample1")

Other
-----------

* The disclaimers and copyright etc.

    The author does not assume any responsibility for damages or any loss of profits 
    resulting directly or indirectly caused by this script.
    We will use the condition that you accept the disclaimer of any damages.


HISTORY
-------
    2012/08/12 (1.0) first release

    2013/01/28 (1.1) append 'archive' feature
                     remove 'delete' feature

    2013/02/05       translate README.md
