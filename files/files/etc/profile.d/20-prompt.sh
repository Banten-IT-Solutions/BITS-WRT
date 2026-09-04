#!/bin/sh
# BITS-WRT branded shell prompt (terminal concept)
_cyn="$(printf '\033[1;36m')"
_yll="$(printf '\033[1;33m')"
_rst="$(printf '\033[0m')"
export PS1="${_cyn}\u@\h${_rst}:${_yll}\w${_rst}\$ "
# \u=user  \h=hostname  \w=cwd  \$ -> # if root