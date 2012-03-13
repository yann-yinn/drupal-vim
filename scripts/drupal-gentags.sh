#!/bin/bash
# generate tags for drupal 6 with exubertant-ctags

echo " ==== DRUPAL6-PHP-GENTAGS ==="
echo "Enter project name,  this will generate a tags file with this name :"
read project_name
echo "begin tags generation ..."
ctags --tag-relative -f ~/.vim/tags/$project_name.tags --langmap=php:.engine.inc.module.theme.php.install --php-kinds=cdfi --languages=php --recurse --exclude=.svn --exclude=.git --extra=f
echo "... file $project_name.tags created ! "
