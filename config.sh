#!/bin/bash

# whether compilation or interpretation should be done
EXECUTABLE=true

# compiler or interpreter used for building practices
COMPILER=nodejs

# compiler options (optional)
COMPILER_OPTIONS=

# pkg-config --cflags "<space separated array>"
PKG_CFLAGS=

# pkg-config --libs "<space separated array>"
PKG_LIBS=

# whether above compiler or interpreter generates an executable file (true)
# or outputs the result to stdout stream (false)
EXECUTABLE_MODE=false

# language extension. eg: cxx, c, py, js, jar, go, etc.
PRIMARY_EXTENSION=js

# additional extensions coming beside source codes. eg: md, txt, pdf, etc.
ADDITIONAL_EXTENSIONS="md reference.txt comment.txt input.txt output.txt md5sum.txt title.txt"

# whether comments must have a reference for validity or not
REFERENCE_VALIDITY=false

# maximum directory level, almost always 3 levels are meaningful
MAX_DIR_LEVEL=3

# whether comments be available
COMMENTS=true

# if -v is set, show verbose logs
VERBOSE=false;

# if -vv is set, show very verbose logs
VVERBOSE=false;

# if -f is set, shell script is forced to organize and refresh repository
FORCE=false;
