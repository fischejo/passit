#!/usr/bin/env bash
# Copyright (C) 2015  Johannes Fischer <johannes-fischer@posteo.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

X_SELECTION="${PASSWORD_STORE_X_SELECTION:-clipboard}"
CLIP_TIME="${PASSWORD_STORE_CLIP_TIME:-45}"

GPG_OPTS=( $PASSWORD_STORE_GPG_OPTS "--quiet" "--yes" "--compress-algo=none" "--no-encrypt-to" )
GPG="gpg"

export GPG_TTY="${GPG_TTY:-$(tty 2>/dev/null)}"
which gpg2 &>/dev/null && GPG="gpg2"
[[ -n $GPG_AGENT_INFO || $GPG == "gpg2" ]] && GPG_OPTS+=( "--batch" "--use-agent" )

PROGRAM="${0##*/}"

die() {
	echo "$@" >&2
	exit 1
}

version() {
	cat <<-_EOF
	passit v1.0
	_EOF
}

usage() {
	cmd_version
	echo
	cat <<-_EOF
	Usage:
	    $PROGRAM [--id, -i, --pss, -p, --url, -u] gpg-file
	        Show existing id, password and/or url.
	    $PROGRAM [-v, --version]
	        Show version information
	    $PROGRAM [-h, --help]
	        Show this text
	    $PROGRAM gpg-file
	        Starts interactive mode, press key
	        p: copy password to clipboard
	        i: copy id to clipboard
	        u: copy url to clipboard
	        o: open url with xdg-open
	        d/q: exit program
	_EOF
}

clip() {
	# This base64 business is because bash cannot store binary data in a shell
	# variable. Specifically, it cannot store nulls nor (non-trivally) store
	# trailing new lines.
	local sleep_argv0="password store sleep on display $DISPLAY"
	pkill -f "^$sleep_argv0" 2>/dev/null && sleep 0.5
	local before="$(xclip -o -selection "$X_SELECTION" 2>/dev/null | base64)"
	echo -n "$1" | xclip -selection "$X_SELECTION" || die "Error: Could not copy data to the clipboard"
	(
		( exec -a "$sleep_argv0" sleep "$CLIP_TIME" )
		local now="$(xclip -o -selection "$X_SELECTION" | base64)"
		[[ $now != $(echo -n "$1" | base64) ]] && before="$now"

		# It might be nice to programatically check to see if klipper exists,
		# as well as checking for other common clipboard managers. But for now,
		# this works fine -- if qdbus isn't there or if klipper isn't running,
		# this essentially becomes a no-op.
		#
		# Clipboard managers frequently write their history out in plaintext,
		# so we axe it here:
		qdbus org.kde.klipper /klipper org.kde.klipper.klipper.clearClipboardHistory &>/dev/null

		echo "$before" | base64 -d | xclip -selection "$X_SELECTION"
	) 2>/dev/null & disown
	echo "Copied $2 to clipboard. Will clear in $CLIP_TIME seconds."
}

# parse args
declare -a indexes=()
eval set -- "$(getopt -o piuhv -l pss,id,url,help,version -n "$PROGRAM" -- "$@")"
while true; do case $1 in
	-v|--version) version; exit ;;
	-h|--help) usage; exit ;;
	-p|--pss) indexes[0]='0'; shift ;;
	-i|--id) indexes[1]='1'; shift ;;
	-u|--url) indexes[2]='2'; shift ;;
	--) shift; break ;;
esac done
[[ $? -ne 0 ]] && die "Usage: $PROGRAM [--pss,-p,--url,-u,--id,-i] gpg-file" >&2
file=$1


# decrypt file
if [[ -f $file ]]; then
	declare -a lines
	readarray -t lines < <($GPG -d "${GPG_OPTS[@]}" "$file" )

	if [[ ${indexes[@]} -ne 0 ]]; then
		for i in "${indexes[@]}"
		do
			echo "${lines[i]}"
		done
	else
		# interactive mode
		while read -s -n 1 in
		do
			case $in in
				p) clip "${lines[0]}" "password" ;;
				i) clip "${lines[1]}" "id" ;;
				u) clip "${lines[2]}" "url" ;;
				o) xdg-open "${lines[2]}" ;;
				d|q) break;;
			esac
		done
	fi
else
	die "Error: $file is not a existing file."
fi
