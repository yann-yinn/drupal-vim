#!/bin/bash
# generate a function dictionary for Drupal 6
grep "^function" modules/ includes/ -hR | gawk '{ sub(/\(.+/, "(", $2); print $2 }' | sort -u > ~/.vim/dictionaries/drupal6.dict
