#!/bin/bash
#
# Description: Short description
# Copyright (C) 2014, B.G.L. Nelissen. All rights reserved.
#
################################################################################
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# 
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
################################################################################
# Respect the Google Shell style guide.
# http://google-styleguide.googlecode.com/svn/trunk/shell.xml

# Variables
SCRIPTNAME=$(basename $0)
DESCRIPTIONSHORT="Short description"
DEPENDENCIES=("convert")

# Errors go to stderr
err() {
  echo "ERROR: $@" >&2
}

# usage message
usage() {
cat <<- EOF
usage:  $SCRIPTNAME [options] [path/]file
        [--help]
EOF
}

# help message
helpMessage() {
cat <<- EOF
${SCRIPTNAME}: ${DESCRIPTIONSHORT}

$(usage)

options:
  -f, --file[=FILE]         virtual slide to create mask from

  --help                    display this help and exit

examples:
  $SCRIPTNAME "file.tif"
  $SCRIPTNAME  --file="file.tif"
  find [path/] -name '*.tif' | parallel [path/]slideMask {} 
  find [path/] -name '*.tif' -exec qsub [path/]slideMask {} \; 

Some information on this script. It might be a bit informal, but keep it
plain and simple

Report bugs to <b.g.l.nelissen@gmail.com>
slideToolkit (C) 2014, B.G.L. Nelissen
EOF
}

# MENU
# Empty variables
FILE=""
# illegal option
illegalOption() {
cat <<- EOF
$SCRIPTNAME: illegal option $1
$(usage)
EOF
exit 1
}
# loop through options
while :
do
  case $1 in
    --help | -\?)
      helpMessage
      exit 0 ;;
    -f | --file)
      FILE=$2
      shift 2 ;;
    --file=*)
      FILE=${1#*=}
      shift ;;
    --) # End of all options
      shift
      break ;;
    -*)
      illegalOption "$1"
      shift ;;
    *)  # no more options. Stop while loop
      break ;;
  esac
done
# DEFAULTS
# set FILE
if [ "$FILE" != "" ]; then
  FILE="$FILE"
else
  FILE="$1"
fi

# requirements
checkRequirements() {
  if ! [[ -f "$FILE" ]] ; then
    err "No such file: $FILE"
    usage
    exit 1
  fi
}

# Dependencies
checkDependencies(){
  DEPENDENCIES="$DEPENDENCIES"
  DEPS=""
  for DEP in $DEPENDENCIES; do
    if [[ 0 != $(command -v "$DEP" >/dev/null ;echo $?) ]]; then
      DEPS=$(echo "$DEPS \"$DEP\"") # create `array` with unknown dependencies
    fi
  done
  if [[ "" != "$DEPS" ]]; then
    for d in "$DEPS"; do
      err "Missing dependency: $d"
    done
    exit 1
  fi
}

# actual program
programOutput(){
  # set variables
  FILE="$FILE"
  # path variables
  FILEFULL="$(echo $(cd $(dirname $FILE); pwd)/$(basename $FILE))" # full path $FULL
  FILEPATH="${FILEFULL%.*}"           # full path, no extension
  FOLDERPATH=$(dirname "$FILEFULL")   # folder path
  BASENAME=$(basename "$FILEFULL")    # basename
  FILENAME="${BASENAME%.*}"           # basename, no extension"
  EXTENSION="${BASENAME##*.}"         # extension
  # create tmp working file
  tempfoo=`basename $0`
  TMPFILE=`mktemp -q /tmp/${tempfoo}.XXXXXX`
  if [ $? -ne 0 ]; then
       err "$0: Can't create temp file, exiting..."
       exit 1
  fi
  # extract thumb layer (filter box does not average pixels)
  echo "$TMPFILE"
  convert -verbose "$FILE[0]" -filter box -resize 512x1024 "$FILE.BAS.png"
}
open -g -a Preview "$FILE.BAS.png"

cleanUp(){
  # remove temp files
  rm -rf "$TMPFILE"
}
# all check?
checkRequirements
checkDependencies 

# lets go!
# actual program
programOutput

# cleanup
# cleanup