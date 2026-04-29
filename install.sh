#!/bin/bash

# reference: https://github.com/michaeljsmalley/dotfiles/blob/master/makesymlinks.sh 

dir=~/dotfiles
olddir=~/dotfiles_old
files="nvim ghostty hypr"

# backup
echo -n "creating $olddir for backup of dotfiles..."
mkdir -p $olddir
echo "done"

# go to dotfiles
echo -n "changing to the $dir directory..."
cd $dir
echo "done"

# move dotfiles to backup directory
for file in $files; do
  echo "moving any existing dotfiles from ~/.config/ to $olddir"
  mv ~/.config/$file ~/dotfiles_old/
  echo "creating symlink to $file in config folder"
  ln -s $dir/$file ~/.config/$file
done
