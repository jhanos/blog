#!/bin/bash

cd $HOME/blog/
git pull
for i in $(ls $HOME/blog/scripts/*.sh);do bash -x $i;done;
