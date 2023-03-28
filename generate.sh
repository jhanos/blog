#!/bin/bash

for i in $(ls $HOME/blog/scripts/*.sh);do bash -x $i;done;
