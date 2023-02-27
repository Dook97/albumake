#!/usr/bin/bash

# stdin: list of audio files OF THE SAME FORMAT and preferably mp3 (eg: ls *mp3 | albumake ...)
# arg 1: path to cover image
# arg 2: output file name

set -ueo pipefail

# check number of arguments
[ "$#" -eq 2 ] || (echo "Incorrect number of arguments. Exiting..." >&2 && false)

cover="$1"
output="$2"
extension=""

# fail if output file already exists
[ -e "${output}" ] && (echo "File '${output}' already exists. Exiting..." >&2 && false)

# a cleanup function called on script error
cleanup() {
	rm -rf "${temp_dir}" "${output}"
}

# convert number of seconds into a timestamp
seconds_to_timestamp() {
	local seconds minutes hours
	seconds="$(echo "$1 % 60" | bc)"
	minutes="$(echo "($1 % 3600) / 60" | bc)"
	hours="$(echo "$1 / 3600" | bc)"
	printf '%02d:%02d:%02d' "${hours}" "${minutes}" "${seconds}"
}

# call cleanup function on error
trap 'cleanup' ERR

# create temporary dir where we'll store files needed for the operation
temp_dir=$(mktemp -d)

# create a list of audio files for ffmpeg to concat
# as well as timestamps
time=0
while IFS=$'\n' read -r line; do
	abspath="$(readlink -f "${line}")"
	echo "file '${abspath}'" >> "${temp_dir}/audio_list"

	filename=$(basename "${line}")

	# check that the file formats are the same for all audio files and that they aren't empty strings
	if [ -n "${extension}" ]; then
		[ "${extension}" = "${filename##*.}" ] || (echo "Multiple audio formats not allowed. Exiting..." >&2 && false)
	else
		extension="${filename##*.}"
		[ -n "${extension}" ] || (echo "Empty file extension not allowed. Exiting..." >&2 && false)
	fi

	echo "$(seconds_to_timestamp "${time%.*}")" "${filename%.*}" >> "${temp_dir}/timestamps"

	time=$(ffprobe "${abspath}" 2>&1 | grep 'Duration' | \
		sed -E "s/.*([0-9]+):0?([0-9]{1,2}):0?([0-9]{1,2})\\.0?([0-9]+).*/scale=2;${time}+\\1*3600+\\2*60+\\3+0.\\4/" | bc)
done

# create cover image
convert "${cover}" -resize 1920x1080 -background black -gravity center -extent 1920x1080 "${temp_dir}/cover"

# create the concatenated audio file
ffmpeg -f concat -safe 0 -i "${temp_dir}/audio_list" -c copy "${temp_dir}/audio.${extension}"

# create the video file
ffmpeg -loop 1 -framerate 2 -i "${temp_dir}/cover" \
	-i "${temp_dir}/audio.${extension}" -c:v libx264 \
	-tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p -shortest "${output}"

# print out timestamps
cat "${temp_dir}/timestamps"

rm -rf "${temp_dir}"
