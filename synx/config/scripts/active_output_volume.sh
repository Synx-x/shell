#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s <raise|lower|mute-toggle|(+|-)N>\n' "${0##*/}" >&2
    exit 2
fi

for cmd in pactl swayosd-client pgrep pw-link; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf "Missing dependency: %s\n" "$cmd" >&2
        exit 1
    fi
done

action=$1
device=""

# Prefer the sink carrying an active playback stream over the configured default.
active_sink_id=$(
    pactl list short sink-inputs 2>/dev/null \
    | awk 'NF >= 2 { count[$2]++ } END { best=""; best_count=0; for (id in count) if (count[id] > best_count) { best=id; best_count=count[id] } print best }'
)

if [[ -n "${active_sink_id:-}" ]]; then
    device=$(
        pactl list short sinks 2>/dev/null \
        | awk -v id="$active_sink_id" '$1 == id { print $2; exit }'
    )
fi

# EasyEffects deliberately owns the active application streams through its
# virtual sink. Volume must be applied to the physical sink receiving the
# processed output, otherwise only the pre-effects virtual volume changes.
if [[ "${device:-}" == "easyeffects_sink" ]] && pgrep -x easyeffects >/dev/null 2>&1; then
    physical_device=$(
        pw-link -l 2>/dev/null \
            | awk '/^ee_soe_output_level:output_FL$/{seen=1; next} seen && /\|-> alsa_output\..*:playback_FL/{gsub(/^.*\|-> /, ""); sub(/:playback_FL$/, ""); print; exit}' \
            || true
    )
    [[ -n "${physical_device:-}" ]] && device="$physical_device"
fi

if [[ -n "${device:-}" ]]; then
    exec swayosd-client --max-volume 150 --device "$device" --output-volume "$action"
fi

exec swayosd-client --max-volume 150 --output-volume "$action"
