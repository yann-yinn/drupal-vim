#!/bin/bash
# generate tags for drupal 6 with exubertant-ctags
echo "Enter project name,  this will generate a tags file with this name :"
read project_name
echo "begin tags generation ..."
ctags --tag-relative -f ~/.vim/tags/$project_name.tags --langmap=php:.engine.inc.module.theme.php --php-kinds=cdfi --languages=php --recurse --exclude=.svn --exclude=.git
echo "... file $project_name.tags created ! "
