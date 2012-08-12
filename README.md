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

    gmailの設定でimapを有効にしてください。やり方はウェブで。

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
xxx

