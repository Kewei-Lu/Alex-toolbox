#!/bin/bash
echo "download omzsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
export ZPLUG_HOME=/usr/local/
git clone https://github.com/zplug/zplug $ZPLUG_HOME
source $ZPLUG_HOME/.zplug/init.zsh

cp ./.zshrc ~/.zshrc && source ~/.zshrc
