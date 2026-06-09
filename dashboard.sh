#!/bin/bash
set -e
exec 3>&1
exec >/dev/null 2>&1

# ------------------------------------------------------------------------------------------------------------------------------
#                                                           Hyprland Dashboard Script
# ------------------------------------------------------------------------------------------------------------------------------


# --------------------------------------------------- Dependency Check ----------------------------------------------
for cmd in alacritty cava htop fastfetch tty-clock hyprctl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is not installed. Exiting." >&3; exit 1; }
done

# ---------------------------------------- Safety Check: Empty Workspace 1-------------------------------------
if hyprctl clients | grep -E "workspace: 1" >/dev/null; then
    echo "[Dashboard] Workspace 1 is occupied. Aborting launch." >&3
    exit 1
fi

# --------------------------------------------------------- WAIT Helper --------------------------------------------------
wait_for_window() {
    local title="$1"
    local timeout=10
    local elapsed=0
    while ! hyprctl clients | grep -q "$title"; do
        sleep 0.1
        elapsed=$((elapsed + 1))
        if [ "$elapsed" -ge "$((timeout * 10))" ]; then
            echo "Timeout waiting for $title. Exiting." >&3
            exit 1
        fi
    done
}

# ---------------------------------------- 1. Ensure we start on Workspace 1 -----------------------------------
hyprctl dispatch workspace 1
sleep 0.02

# -------------------------------------------- 2. Launch BTOP (Left Panel) -----------------------------------------
alacritty --title htop -e htop &
wait_for_window "htop"
hyprctl dispatch focuswindow title:htop
sleep 0.02

# --------------------------------------- 3. Launch CAVA (Bottom Visualizer) ---------------------------------
hyprctl dispatch layoutmsg preselect d
alacritty --title cava  -e cava &
wait_for_window "cava"
sleep 0.01

# --------------------------------------- 4. Squish CAVA: shrink it to thin bar ---------------------------------
hyprctl dispatch focuswindow title:htop
hyprctl dispatch resizeactive 0 200
sleep 0.02

# ------------------------------------------- 5. Launch FASTFETCH (Top Right) -----------------------------------
alacritty --title fetch \
  -o "enable_audio_bell=no" \
  -e "$SHELL" -c "sleep 0.01 && fastfetch -c ~/.config/fastfetch/fastfetch.jsonc; tail -f /dev/null" &
wait_for_window "fetch"
sleep 0.01
hyprctl dispatch focuswindow title:fetch
hyprctl dispatch layoutmsg preselect d

# ------------------------------------------ 6. Launch CLOCK (Bottom Right) -------------------------------------
alacritty --title clock -e sh -c "sleep 1.0; tty-clock -c -C 6 -s" &
wait_for_window "clock"
sleep 0.01
hyprctl dispatch focuswindow title:clock
hyprctl dispatch resizeactive 0 105
sleep 0.01

# ----------------------------------------------- DASHBOARD SUCCESSFUL ----------------------------------------
hyprctl dispatch focuswindow title:htop
echo "[Dashboard] Launched successfully." >&3
