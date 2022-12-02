---
title: "Create your blog With Hugo"
date: 2022-12-02
draft: false
author: Jhanos
featuredImage: hugo.png
#publishDate: 2022-10-27
categories:
- Writting
tags:
- hugo
summary: How to create your blog with hugo

---

# How to create your blog with Hugo

Leitmotiv: Focus on writing blog articles (Avoid spending too much time for the perfect design or tool for your website)

## Why Static Site Generator (Hugo)

Static Site Generator are tool like: Jekyll, Hugo, Hexo, Zola.

Key points:
- Generate a static website (html/javascript) based on markdown files
- Support templating tool with complex function
- No Maintenance
- Very low attack Risk (instead of wordpress tool for example)
- No complex requirements, only a web server like apache or nginx (i.e.:  no dabatabase, no php) 
- Low resources required
- Easy to switch from one theme to another 

## Hosting

You can host your blog for free on:
- Github Page (with Github action)
- Gitlab Page (with gitlab-ci )

It's also possible to define a custom domain name if you have your own domain.

You can of course choose other paid solution:
- AWS
- GCP
- Self-hosted
- ...

## Install Hugo

{{< admonition note >}}
Hugo recommend `extended version` (with WebP images encoding and Transpile Sass to CSS)
{{< /admonition >}}

[Hugo documentation](https://gohugo.io/documentation/) offers a lots of features, sometimes it's confusing but the quickstart is really good.

Hugo is written in GO so you can use directly [release from github](https://github.com/gohugoio/hugo/releases) or use your package manager 

- [Release for amd64 windows](https://github.com/gohugoio/hugo/releases/download/v0.104.3/hugo_0.104.3_windows-amd64.zip)
- [Release for amd64 Linux](https://github.com/gohugoio/hugo/releases/download/v0.104.3/hugo_extended_0.104.3_linux-amd64.tar.gz)




## Create your blog

To create your blog stucture, you just need:

```bash
hugo new site myblog
cd myblog
ls
```

This command will creates:
- config.toml: the config file for your blog site
- content: the directory which contains your articles in markdown format
- static: the directory which contains static content (favicon, avatar, ...)
- themes: the directory which contains your theme

For further detail, see [Directory Structure](https://gohugo.io/getting-started/directory-structure/)

## Choose your theme

You can find a lots of theme for hugo in the [official site](https://themes.gohugo.io/)

Choose on and put it in the theme directory.

I choose [loveit theme](https://hugoloveit.com/) for its features:
- Multi language 
- responsive
- Customizable
- Very active
- Beautiful ( <- totally subjective)


To use this theme, execute this:
```bash
git init
git submodule add https://github.com/dillonzq/LoveIt themes/loveit
echo theme = \"loveit\" >> config.toml
```

{{< admonition note >}}
Git command are optionnal, but i advice to use it to update your theme 
{{< /admonition >}}


## Write your first article

Create your article's file

```bash
hugo new posts/my-first-post/index.en.md
```

Each post contains :
- metadata in order to define title, author, tags and state (publish or not) in the headers 
- your article content

For example, use your favorite editor and add this content in `index.en.md`:
```md
---
title: "My First Post"
date: 2019-03-26T08:47:11+01:00
draft: true
---
My beautiful article

some content 
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
```

## Start the blog in testing mode

Launch Hugo server to see the result:
```bash
hugo server -D
```

You can reach you blog at: [http://localhost:1313/](http://localhost:1313/).

Each time you modify your article, the website is reload

## Customize your theme



Modify the `config.toml` in order to customize your blog:
- Website url (`baseURL`)
- Website title (`params.title`)
- Website description (`params.description`)

## Tips and Tricks

### Multi Language

### Schedule Article

### Avoid Cross requests (GDPR ...)

