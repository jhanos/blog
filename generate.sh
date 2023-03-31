#!/bin/bash

export PATH=/usr/local/bin:$PATH
cd $HOME/blog/
git pull http-origin main
for i in $(ls $HOME/blog/scripts/*.sh);do bash -x $i;done;
