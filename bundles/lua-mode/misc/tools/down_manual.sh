#! /bin/sh

URL=http://www.lua.org/manual/5.2/manual.html

curl "$URL"|iconv -f windows-1252 -t utf8|pandoc -t markdown -f html
