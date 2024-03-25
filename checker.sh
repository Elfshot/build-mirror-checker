original=$(pwd)
prerun=1

function cleanup {
  exitcode=$?
  echo "Removing ./mirror-checker"
  rm -rf "$original/mirror-checker"

  if [ $prerun -eq 0 ]; then
    echo "Removing ./last-gid.txt"
    rm -f "$original/last-gid.txt"
  fi

  exit $exitcode
}

trap cleanup EXIT

function get_gid() {
  id=$(curl https://git.csclub.uwaterloo.ca/public/mirror-checker/rss/branch/ng -s | xq -x /rss/channel/item[1]/guid)
  if [ -z "$id" ]; then
    echo "Error: Could not get the latest commit id"
    exit 1
  fi

  echo $id
}

# attempt to read gid from last-gid.txt, if it doesn't exist, get it from the rss feed. if it does, and it is the same as the latest commit, exit
if [ -f last-gid.txt ]; then
  last_gid=$(cat last-gid.txt)
  latest_gid=$(get_gid)
  if [ "$last_gid" == "$latest_gid" ]; then
    echo "No new commits"
    exit 0
  fi
else
  latest_gid=$(get_gid)
fi

prerun=0

git clone https://git.csclub.uwaterloo.ca/public/mirror-checker
cp Dockerfile mirror-checker/Dockerfile
cp one-shot.sh mirror-checker/one-shot.sh

echo $latest_gid > last-gid.txt

# Build the go project, then build the docker image and push it to ghcr registry. Tag the image with the latest commit id
cd mirror-checker

env CGO_ENABLED=0 >/dev/null
env GOOS=linux >/dev/null
env GOARCH=amd64 >/dev/null

go build -tags netgo -a -v . 
docker build . --load -t ghcr.io/elfshot/build-mirror-checker -t ghcr.io/elfshot/build-mirror-checker:$latest_gid

# GHCR_USER must be set in the environment
# docker login ghcr.io -u $GHCR_USER
docker push ghcr.io/elfshot/build-mirror-checker:latest

prerun=1