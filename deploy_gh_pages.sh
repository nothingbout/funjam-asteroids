REMOTE_NAME=${1}
set -ex

if [ -z "${REMOTE_NAME}" ]; then
    echo "provide a remote name"
    exit 1
fi

REPO_URL=$(git remote get-url ${REMOTE_NAME})
SRC_BRANCH=$(git symbolic-ref --short HEAD)
DST_BRANCH=gh-pages

SRC_DIRECTORY=./Web/dist
DST_DIRECTORY=./docs

if [ -d ${DST_DIRECTORY} ]; then
  echo "./docs already exists"
  exit 1
fi

if ! git checkout -b ${DST_BRANCH} ; then
    exit 1
fi

if ! ./build_web_dist.sh ; then
    echo "Failed to build ${SRC_DIRECTORY}"
    exit 1
fi

read -p "Deploying from '${SRC_BRANCH}' branch to '${DST_BRANCH}' branch on ${REPO_URL}. Continue? (y/n): " CONTINUE
if [ "$CONTINUE" != "y" ]; then
    exit 1
fi

cp -r ${SRC_DIRECTORY} ${DST_DIRECTORY}
git add ${DST_DIRECTORY}
git commit -m "Deploy to Github Pages"
git merge --no-edit gh-pages-static # Optional, comment out this line if you don't have a gh-pages-static branch
git push -f ${REMOTE_NAME} ${DST_BRANCH}

git checkout ${SRC_BRANCH}
git branch -D ${DST_BRANCH}
