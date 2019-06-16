#!/bin/bash
set -e

if [ ! -f Makefile ]
then
  perl Makefile.PL
  make
  make test
fi

exec "$@"
