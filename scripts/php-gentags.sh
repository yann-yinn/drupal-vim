#!/bin/bash

# This script creates the tag index in the file $HOME/.vim/mytags/framework. It scans for PHP files recursively through the tree, excluding any files found in a .svn directory (I'm using a checkout from the subversion repository). 
echo " ==== PHP-GENTAGS ==="
echo "Enter project name,  this will generate a tags file with this name :"
read project_name
echo "begin tags generation ..."
ctags --tag-relative -f ~/.vim/tags/$project_name.tags --langmap=php:.inc.php --languages=php --recurse --exclude=.svn --exclude=.git --extra=f --php-kinds=cfiv --regex-PHP='/abstract\s+class\s+([^ ]+)/\1/c/' --regex-PHP='/interface\s+([^ ]+)/\1/c/' --regex-PHP='/(public\s+|static\s+|abstract\s+|protected\s+|private\s+)function\s+\&?\s*([^ (]+)/\2/f/'
echo "... file $project_name.tags created ! "
