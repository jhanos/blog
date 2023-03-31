#!/bin/bash

hugo -D -F  --config config-testing.toml -s $HOME/blog -d $HOME/blog/public
