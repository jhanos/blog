mkdir -p assets/data/cdn/
cp theme/loveit/assets/data/cdn/jsdelivr.yml assets/data/cdn/jsdelivr.yml
for file in $(yq '.libFiles[]' assets/data/cdn/jsdelivr.yml ); do mkdir -p static/cdn/$(dirname $file); curl -Lo static/cdn/$file https://cdn.jsdelivr.net/npm/$file;done;
cp -rp themes/loveit/static/lib/webfonts static/cdn/@fortawesome/fontawesome-free@6.1.1/
