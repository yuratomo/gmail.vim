gmail.vim
=========

Description
-----------
vim上でgmailを見るためのスクリプトです。
imapを使ってメールを操作するので、gmail側の設定でimapを有効にする必要があります。


Requirements
------------
必要なのものは次のとおり。

* vimproc

    git://github.com/Shougo/vimproc.git

* openssl
Windowsのmsysgitに含まれるopensslで動作確認をしています。

    http://code.google.com/p/msysgit/


Setting
-------

* imapの有効化

    gmailの設定でimapを有効にしてください。やり方はウェブで・・・(^^;

* vimprocのインストール

* opensslにパスを通す

    let &path = $path . 'c:\Program files\git\bin'

* 必要なら次のような設定をvimrcに記載する。（必須ではない)

  - サーバーの設定（デフォルトは以下のとおり)

    let g:gmail_imap = 'imap.gmail.com:993'

    let g:gmail_smtp = 'smtp.gmail.com:465'

  - ユーザー名の指定

    let g:gmail_user_name = 'xxx@gmail.com'

  - メール送信時の署名

    let g:gmail_signature = '# ' . g:gmail_user_name . '(by gmail.vim)'


Usage
-----

* 起動

次のコマンドをたたくだけです。

    :Gmail

* 操作

先頭行に表示されているものがメニューです。行いたい操作上でEnterキーを押してください。


ScreenShots
-----------

* 動作イメージ
![sample1](http://yuratomo.up.seesaa.net/image/gmail.vim_20120812.PNG "sample1")

Other
-----------

* 著作権・免責等
本スクリプトによって発生した直接的、間接的に生じたいかなる利益の損失や
損害に対しても作者は一切の責任を負いません。
あらゆる損害の免責をご承諾いただくことを使用条件とします。


HISTORY
-------
    2012/08/12 (1.0)   first release

    2013/01/28 (1.1)   append 'archive' feature
                       remove 'delete' feature

    2013/02/05         translate README.md
    2013/03/29 (1.3)   support delete feature
    2013/05/01 (1.3.1) support unread feature for message window (#6)
    2013/05/01 (1.3.2) append <Plug> keymaps and default keymap 'dd' , 'r' , 'R' and 'x' (#7)
                       buf fix delete feature
    2013/05/01 (1.3.3) append g:gmail_nomove_after_select (#8)
    2013/05/01 (1.3.4) replace '&mdash;' to '--' for easy_html_view (#9)
    2013/05/01 (1.3.5) append g:gmail_show_log_window for debug
    2013/07/07 (1.3.6) 'c' should not be mapped when composing emails.(#12)
    2014/07/04 (1.3.7) fix E154: Duplicate tag vimproc in file $HOME/.vim/.neobundle/doc/vimproc.txt
