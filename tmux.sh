#!/bin/bash

OMTMUX_FILE_PATH=/tmp/.tmux

echo "Start configuring tmux settings ..."
if [ -z `which tmux` ]; then
    echo "tmux not found, please install tmux first"
    exit 2
fi

if [ -a $OMTMUX_FILE_PATH ]; then
    rm -rf $OMTMUX_FILE_PATH
fi

git clone https://github.com/gpakosz/.tmux.git /tmp/.tmux
cp /tmp/.tmux/.tmux.conf ~/.tmux.conf
cp /tmp/.tmux/.tmux.conf.local ~/.tmux.conf.local
sed -i 's/C-a/C-w/g' ~/.tmux.conf
tmux source-file ~/.tmux.conf

echo "Tmux config End ..."

