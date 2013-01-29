#! /bin/sh

source_dir=$1
target_dir=$2

if [ -z "$source_dir" -o -z "$target_dir" ]; then
  echo "Usage: $0 <source_dir> <target_dir>"
  exit 1
fi

echo "Updating $target_dir from $source_dir.."
rm -rf $target_dir/*

for file in README.md moon moonscript moonscript/compile moonscript/transform; do
  target=$target_dir/$file
  source=$source_dir/$file
  echo "* $file"
  if [ -d $source ]; then
    mkdir $target
    cp $source/*.lua $target/
  else
    cp $source $target
  fi
done
