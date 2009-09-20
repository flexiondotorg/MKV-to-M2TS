#!/bin/bash

function build {
    RELEASE_NAME="MKV-to-M2TS"
    RELEASE_VER="1.1"
    RELEASE_KEYWORDS="MKV, M2TS, conversion, PS3, PlayStation 3, Linux, script"
    RELEASE_DESC="Creates a PlayStation 3 compatible MPEG-2 Transport Stream from a Matroska"

    rm ${RELEASE_NAME}-v${RELEASE_VER}.tar* 2>/dev/null
    bzr export ${RELEASE_NAME}-v${RELEASE_VER}.tar
    tar --delete -f ${RELEASE_NAME}-v${RELEASE_VER}.tar ${RELEASE_NAME}-v${RELEASE_VER}/build.sh
    gzip ${RELEASE_NAME}-v${RELEASE_VER}.tar
}
