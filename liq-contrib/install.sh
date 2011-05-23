#!/bin/sh
set -e

INST_DIR="/usr/local/bin"
DIST="*.in liq-contrib.1 CHANGES COPYING install.sh"
VERSION="SVN"

# Dummy install script for liquidsoap utils.
# Usage: install --install [ /path/to/install/directory ]
# Path to install directory is optional and is 
# $INST_DIR by default.

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: install.sh --install [ /path/to/install/dir ]"
  echo "Alternate usages:"
  echo "install.sh --clean [ /path/to/install/dir ]: clean previous install"
  echo "install.sh --tarball: prepare a tarball of the scripts"
  echo "install.sh -h|--help: display this message"
  echo ""
  echo "Environement variables: "
  echo "LIQ_BIN: where to find the liquidsoap binary"
  exit 0
elif [ "$1" = "--clean" ]; then
  echo "Cleaning previous install:"
  echo "Removing scripts..."
  if [ "$2" = "" ]; then
    echo "No installation directory provided, using $INST_DIR"
  else
    echo "Using provided install directory: $2"
    INST_DIR="$2"
  fi
find | grep '.in$' | sed -e 's#\.in$##' | while read i; do
  SCRIPT=`basename $i`
  echo "* $SCRIPT"
  rm -f "$INST_DIR/$SCRIPT"
done;
  exit 0
elif [ "$1" = "--tarball" ]; then
  echo "Preparing a tarball at ../liq-contrib-$VERSION.tar.gz..."
  rm -rf liq-contrib-$VERSION
  mkdir liq-contrib-$VERSION
  cp -rf $DIST liq-contrib-$VERSION
  tar cvzf liq-contrib-$VERSION.tar.gz liq-contrib-$VERSION
  mv liq-contrib-$VERSION.tar.gz ..
  rm -rf liq-contrib-$VERSION
  echo "Done !"
  exit 0
elif [ "$1" = "--install" ]; then
  echo "Liquidsoap contributed scripts install starting..."
  if [ "$2" = "" ]; then
    echo "No install path provided, using $INST_DIR"
  else
    echo "Using provided install script: $2"
    INST_DIR=$2
  fi

  echo ""
  # Check for liquidsoap
  echo -n "Checking for liquidsoap... "
  if [ "$LIQ_BIN" = "" ]; then
   LIQ_BIN=`which liquidsoap`
  fi
  if [ "$?" != "0" ]; then
    echo "not found"
    exit 1
  fi
  echo "$LIQ_BIN"

  echo -n "Version found: "
  VER=`$LIQ_BIN --version | head -n 1 | cut -d' ' -f2`
  echo $VER

  # Generating final scripts
  echo "Generating scripts..."
  rm -rf dist
  mkdir dist
  find | grep '.in$' | while read i; do
    SCRIPT=`basename $i | sed -e 's#.in$##'`
    echo "* $SCRIPT"
    cat $i | sed -e "s#@liquidsoap@#$LIQ_BIN#" | sed -e "s#@VERSION@#$VERSION#" > "dist/$SCRIPT"
    chmod +x "dist/$SCRIPT"
  done;

  echo "Installing to $INST_DIR"
  cp -f dist/* "$INST_DIR"
  rm -rf dist
  echo "Finished !"
else
  echo "Wrong argument, or no argument."
  echo "Try install.sh --help to get more informations"
  echo "on how to use this script."
  exit 1
fi
