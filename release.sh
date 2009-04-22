#!/bin/bash

NAME="MKV-to-M2TS"
VER=1.0

rm ${NAME}-v${VER}.tar* 2>/dev/null
bzr export ${NAME}-v${VER}.tar
tar --delete -f ${NAME}-v${VER}.tar ${NAME}-v${VER}/release.sh
gzip ${NAME}-v${VER}.tar
