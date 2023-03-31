#!/bin/bash

cd $HOME/blog/
git pull http-origin
for i in $(ls $HOME/blog/scripts/*.sh);do bash -x $i;done;
