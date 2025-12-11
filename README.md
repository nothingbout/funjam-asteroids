
## Prerequisites

Install the Swift toolchain and the WebAssembly SDK as per https://www.swift.org/documentation/articles/wasm-getting-started.html

## Building and running for development

```sh
./build.sh [debug|release]
npx serve Web
```

## Building for distribution

```sh
./build_web_dist.sh
npx serve Web/dist
```

## Deploying on Github Pages

```
# Check out the branch to deploy. Make sure it is clean.
git checkout main

# Substitute REMOTE_NAME with the actual github remote name.
./deploy_gh_pages.sh REMOTE_NAME
```

The deploy script will do the following:
1) Creates a new local branch `gh-pages` from the currently checked out commit
2) Runs `./build_web_dist.sh` which produces `./Web/dist` as a result
3) Copies `./Web/dist` to `./docs`
4) Adds and commits `./docs` to the `gh-pages` branch
5) [OPTIONAL] Merges any persistent content on the `gh-pages-static` branch onto the `gh-pages` branch.
6) Force pushes the `gh-pages` branch to the given remote
7) Deletes the local `gh-pages` branch

As a result, there will be no version history on GitHub for the `gh-pages` branch for previously deployed page versions.

In the GitHub repository `Settings / Pages` page, select `Deploy from branch` as the source, `gh-pages` as the branch
and `/docs` as the directory.
