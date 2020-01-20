# Alpine Linux v3.9.4をベースのイメージとして指定
FROM alpine:3.9.4

# MAINTAINER nontan <nontan@sfc.wide.ad.jp>
LABEL maintainer="nontan@sfc.wide.ad.jp"

WORKDIR /root/work

# パッケージリストの更新
RUN apk update
# TeXLiveのインストールに必要なパッケージを取得
RUN apk add perl wget fontconfig-dev git
# TeXLiveのインストーラーの解凍に必要なパッケージのインストール
RUN apk add xz tar

# 圧縮されたTeXLiveのインストーラーをダウンロードし，tmpディレクトリに保存
ADD http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz /tmp/install-tl-unx.tar.gz
# インストーラーを解凍した際に配置するディレクトリを作成
RUN mkdir /tmp/install-tl-unx
# ダウンロードしたinstall-tl-unx.tar.gzを解凍
RUN tar -xvf /tmp/install-tl-unx.tar.gz -C /tmp/install-tl-unx --strip-components=1
# TeXLiveのインストール用の設定ファイルを作成
RUN echo "selected_scheme scheme-basic" >> /tmp/install-tl-unx/texlive.profile
# TeXLiveのインストール
RUN /tmp/install-tl-unx/install-tl -profile /tmp/install-tl-unx/texlive.profile
# TeXLiveのバージョンを取得しインストールディレクトリを特定し，latestの名称でシンボリックリンクを作成
RUN TEX_LIVE_VERSION=$(/tmp/install-tl-unx/install-tl --version | tail -n +2 | awk '{print $5}'); \
    ln -s "/usr/local/texlive/${TEX_LIVE_VERSION}" /usr/local/texlive/latest
# インストールしたTeXLiveへパスを通す
ENV PATH="/usr/local/texlive/latest/bin/x86_64-linuxmusl:${PATH}"

# TeXLive Package Managerを使用して必要なパッケージをインストール
# texファイルの自動コンパイルパッケージをインストール
RUN tlmgr install latexmk
# latexmkの設定ファイルをホストからイメージにコピー
COPY ./build_item/app/config/.latexmkrc /root/.latexmkrc
# 2カラムの設定に必要なパッケージのインストール
RUN tlmgr install multirow
# 日本語対応パッケージのインストール
RUN tlmgr install collection-langjapanese
# フォントパッケージのインストール
RUN tlmgr install collection-fontsrecommended
RUN tlmgr install collection-fontutils
RUN tlmgr install fontawesome

# 追加sty
RUN tlmgr install cite fancybox framed comment caption float here listings pict2e
RUN mkdir /usr/local/texlive/2019/texmf-dist/tex/latex/user_style

# nodejsを追加
RUN apk update
RUN apk add --no-cache nodejs nodejs-npm
RUN npm install -g browser-sync
# RUN browser-sync start --server --files "/root/work/*" &

# PDF.jsを追加
# RUN git clone https://github.com/mozilla/pdf.js.git
# RUN cd pdf.js
# RUN 

# cron設定
# COPY ./build_item/npm.sh /bin/browser_sync.sh
# COPY ./build_item/latex.sh /bin/latexmk_sync.sh
# COPY ./build_item/root /var/spool/cron/crontabs/root
# RUN chmod +x /bin/browser_sync.sh
# RUN chmod +x /bin/latexmk_sync.sh
# CMD crond -l 2 -f

# 不要なパッケージなどの削除(イメージの容量削減のため)
RUN apk del xz tar
RUN rm -rf /var/cache/apk/*
RUN rm -rf /tmp/*


# References
# - https://github.com/blang/latex-docker
# - https://github.com/Paperist/docker-alpine-texlive-ja/blob/master/Dockerfile
