#!/bin/sh -ex
#
# TODO: custom urls.

outdir='subs'
lang="${SCRIPT_LANG:-es}"
# channel="${SCRIPT_CHANNEL:-https://www.youtube.com/@CirculoVicioso8}" # Includes VIDEOS/SHORTS/LIVE.
channel="${SCRIPT_CHANNEL:-https://www.youtube.com/@CirculoVicioso8/streams}" # LIVE only.
opts='--ignore-config --geo-bypass --no-call-home --no-embed-thumbnail --no-write-thumbnail'

yn() {
	while true; do
		printf %s "${1} [y/n] "
		read -r r
		case "$r" in
			([Nn]) exit 1 ;;
			([Yy]) exit 0 ;;
		esac
	done
}

ids() {
	# Get IDs.
	# yt-dlp $opts --playlist-end 5 --print id --skip-download "${channel}" # Get IDs.
	yt-dlp \
		$opts \
		${SCRIPT_END+--playlist-end ${SCRIPT_END}} \
		--print id \
		--skip-download \
		-- "${channel}"
}

id2url() {
	sed 's ^ https://www.youtube.com/watch?v= '
}

urls() {
	if yn "use custom urls?"; then
		printf %s\\n "paste urls, each in it's own line, press ctrl-D when done" 1>&2
		cat -
	else
		ids | id2url
	fi
}

dl_one() {
	# Download subs for each.
	# echo yt-dlp $opts --skip-download --sub-lang="${lang}" --convert-subs srt --write-auto-sub --output "%(id)s" # Download subs for each.
	yt-dlp \
		$opts \
		--skip-download \
		--sub-lang="${lang}" \
		--write-auto-sub \
		-- "$1"
}
dl_many() {
	cd "${outdir}"
	urls | while read -r id; do
		dl_one "$id"
	done
	cd -
}

convert_one() {
	file="$1"
	bn="$(basename "$file" ."$lang".vtt)"
	webvtt-to-json --dedupe --single "${file}" --output="${bn}.json"
}

convert_many() {
	cd "${outdir}"
	find . -type f | while read -r file; do
		convert_one "$file"
	done
	cd -
}

deps() {
	command -v webvtt-to-json  >/dev/null 2>&1 || return 1
	command -v yt-dlp          >/dev/null 2>&1 || return 1
}

main() {
	if ! deps; then
		exit 1
	fi
	rm "${outdir}" -rf
	mkdir -p "${outdir}"
	dl_many
	convert_many
}

"${1:-main}"
