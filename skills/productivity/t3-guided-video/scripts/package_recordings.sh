#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s OUTPUT_DIR LABEL=RAW_VIDEO [LABEL=RAW_VIDEO ...]\n' "$0" >&2
  exit 2
}
fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

(( $# >= 2 )) || usage
output_dir=$1
shift
for required_command in ffmpeg ffprobe awk tr; do
  command -v "$required_command" >/dev/null 2>&1 || fail "Missing required command: $required_command"
done

declare -a labels=() safe_labels=() inputs=() packaged_videos=()
for recording in "$@"; do
  [[ $recording == *=* ]] || usage
  label=${recording%%=*}
  input_video=${recording#*=}
  [[ -n $label && -s $input_video ]] || fail "Invalid recording: $recording"
  safe_label=$(printf '%s' "$label" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9._-')
  [[ -n $safe_label && $safe_label != all ]] || fail "Use a nonempty filename-safe label other than all: $label"
  for prior in "${safe_labels[@]}"; do
    [[ $safe_label != "$prior" ]] || fail "Labels normalize to the same filename: $label"
  done
  [[ ! -e "$output_dir/${safe_label}-guided.mp4" && ! -e "$output_dir/${safe_label}-frames" && ! -e "$output_dir/${safe_label}-contact-sheet.png" ]] || fail "Output already exists for label: $label"
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$input_video" >/dev/null
  labels+=("$label")
  safe_labels+=("$safe_label")
  inputs+=("$input_video")
done
[[ ! -e "$output_dir/all-guided.mp4" ]] || fail "Combined output already exists: $output_dir/all-guided.mp4"

width=${GUIDED_VIDEO_WIDTH:-}
height=${GUIDED_VIDEO_HEIGHT:-}
if [[ -z $width && -z $height ]]; then
  dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "${inputs[0]}")
  IFS=x read -r width height <<< "$dimensions"
  [[ $width =~ ^[0-9]+$ && $height =~ ^[0-9]+$ ]] || fail 'Could not read the first recording dimensions'
  width=$(( width / 2 * 2 ))
  height=$(( height / 2 * 2 ))
fi
[[ $width =~ ^[0-9]+$ && $height =~ ^[0-9]+$ ]] || fail 'Set GUIDED_VIDEO_WIDTH and GUIDED_VIDEO_HEIGHT together'
(( width >= 2 && height >= 2 && width % 2 == 0 && height % 2 == 0 )) || fail 'Output width and height must be positive even numbers'
fps=${GUIDED_VIDEO_FPS:-30}
[[ $fps =~ ^[1-9][0-9]*$ ]] || fail 'GUIDED_VIDEO_FPS must be a positive integer'

mkdir -p "$output_dir"
for index in "${!inputs[@]}"; do
  safe_label=${safe_labels[$index]}
  output_video="$output_dir/${safe_label}-guided.mp4"
  ffmpeg -n -hide_banner -loglevel error -i "${inputs[$index]}" -map 0:v:0 -an \
    -vf "scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=${fps},setpts=PTS-STARTPTS" \
    -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -movflags +faststart "$output_video"

  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$output_video")
  awk -v duration="$duration" 'BEGIN { exit !(duration > 0) }' || fail "Packaged video has no duration: $output_video"
  frame_dir="$output_dir/${safe_label}-frames"
  mkdir "$frame_dir"
  for sample in {0..7}; do
    timestamp=$(awk -v duration="$duration" -v fps="$fps" -v sample="$sample" 'BEGIN { last = duration - 2 / fps; if (last < 0) last = 0; printf "%.6f", last * sample / 7 }')
    printf -v frame_path '%s/%02d.png' "$frame_dir" "$(( sample + 1 ))"
    ffmpeg -n -hide_banner -loglevel error -ss "$timestamp" -i "$output_video" \
      -frames:v 1 -vf 'scale=480:300:force_original_aspect_ratio=decrease,pad=480:300:(ow-iw)/2:(oh-ih)/2:black,setsar=1' "$frame_path"
    [[ -s $frame_path ]] || fail "Could not extract sample frame: $frame_path"
  done
  ffmpeg -n -hide_banner -loglevel error -framerate 1 -i "$frame_dir/%02d.png" \
    -vf 'tile=4x2:padding=4:margin=4:color=white' -frames:v 1 "$output_dir/${safe_label}-contact-sheet.png"
  packaged_videos+=("$output_video")
done

combined_video="$output_dir/all-guided.mp4"
if (( ${#packaged_videos[@]} == 1 )); then
  cp "${packaged_videos[0]}" "$combined_video"
else
  declare -a ffmpeg_inputs=()
  concat_inputs=''
  for index in "${!packaged_videos[@]}"; do
    ffmpeg_inputs+=(-i "${packaged_videos[$index]}")
    concat_inputs+="[$index:v:0]"
  done
  ffmpeg -n -hide_banner -loglevel error "${ffmpeg_inputs[@]}" \
    -filter_complex "${concat_inputs}concat=n=${#packaged_videos[@]}:v=1:a=0[outv]" \
    -map '[outv]' -an -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -movflags +faststart "$combined_video"
fi
combined_duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$combined_video")
awk -v duration="$combined_duration" 'BEGIN { exit !(duration > 0) }' || fail 'Combined video has no duration'
for index in "${!packaged_videos[@]}"; do
  printf '%s\n' "${labels[$index]}" "Video: ${packaged_videos[$index]}" "Contact sheet: $output_dir/${safe_labels[$index]}-contact-sheet.png"
  ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -show_entries format=duration,size \
    -of default=noprint_wrappers=1 "${packaged_videos[$index]}"
done
printf 'Combined video: %s\nDuration: %s\n' "$combined_video" "$combined_duration"
