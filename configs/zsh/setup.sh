#!/bin/bash
echo "download omzsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

mkdir ~/omzsh && cd omzsh
echo "download dracula"
git clone https://github.com/dracula/zsh.git dracula
sed -i 's/PROMPT='\'''\''/PROMPT='\''${ret_status} %{$fg[cyan]%}%d%{$reset_color%}'\''/' ./dracula/dracula.zsh-theme
cp ./dracula/dracula.zsh-theme ~/.oh-my-zsh/themes/dracula.zsh-theme
cp -r ./dracula/lib ~/.oh-my-zsh/themes/lib

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions


cp ./.zshrc ~/.zshrc && source ~/.zshrc
