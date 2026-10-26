#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# GitHub Profile — Neofetch-style Terminal Display
# Dynamic version — fetches pinned repos & profile data from GitHub API
# Designed for asciinema recording (120×24) → agg GIF conversion
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION — Edit these values
# ═══════════════════════════════════════════════════════════════════════════

# GitHub
GITHUB_USER="remrearas"

# ASCII art left-column width (visible chars, padded with spaces)
ART_WIDTH=42

# Animation Timing
LINE_DELAY=0.06
TYPING_SPEED=0.04
TYPING_VARIANCE=0.02
COMMAND_PAUSE=0.3
END_PAUSE=3

# ═══════════════════════════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════════════════════════

R='\033[0m'         # Reset
B='\033[1m'         # Bold
D='\033[2m'         # Dim

# Regular foreground
BLK='\033[30m'; RED='\033[31m'; GRN='\033[32m'; YEL='\033[33m'
BLU='\033[34m'; MAG='\033[35m'; CYN='\033[36m'; WHT='\033[37m'

# Bold foreground
BBLK='\033[1;30m'; BRED='\033[1;31m'; BGRN='\033[1;32m'; BYEL='\033[1;33m'
BBLU='\033[1;34m'; BMAG='\033[1;35m'; BCYN='\033[1;36m'; BWHT='\033[1;37m'

# Background (color palette row 1 — normal)
BG_BLK='\033[40m'; BG_RED='\033[41m'; BG_GRN='\033[42m'; BG_YEL='\033[43m'
BG_BLU='\033[44m'; BG_MAG='\033[45m'; BG_CYN='\033[46m'; BG_WHT='\033[47m'

# Background (color palette row 2 — bright)
BG_BBLK='\033[100m'; BG_BRED='\033[101m'; BG_BGRN='\033[102m'; BG_BYEL='\033[103m'
BG_BBLU='\033[104m'; BG_BMAG='\033[105m'; BG_BCYN='\033[106m'; BG_BWHT='\033[107m'

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

type_text() {
    local text="$1"
    for ((i = 0; i < ${#text}; i++)); do
        printf '%s' "${text:$i:1}"
        local v
        v=$(printf "%.3f" "$(echo "scale=3; ($RANDOM % 100) * $TYPING_VARIANCE / 100" | bc)")
        sleep "$(echo "$TYPING_SPEED + $v" | bc)"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# GITHUB API
# ═══════════════════════════════════════════════════════════════════════════

fetch_github_data() {
    echo "Fetching GitHub profile data..." >&2

    # ── User profile (REST) ──────────────────────────────────────────────
    local user_json
    user_json=$(gh api "users/${GITHUB_USER}" 2>/dev/null \
             || curl -sf "https://api.github.com/users/${GITHUB_USER}" \
             || echo '{}')

    USER_NAME=$(echo  "$user_json" | jq -r '.name          // "N/A"')
    USER_LOGIN=$(echo "$user_json" | jq -r '.login         // "unknown"')
    USER_LOC=$(echo   "$user_json" | jq -r '.location      // "N/A"')
    USER_COMPANY=$(echo "$user_json" | jq -r '.company     // "N/A"')
    USER_BLOG=$(echo  "$user_json" | jq -r '.blog          // "N/A"' | sed 's|https\?://\(www\.\)\?||')
    USER_SINCE=$(echo "$user_json" | jq -r '.created_at    // "unknown"' | cut -c1-10)

    # ── Pinned repos (GraphQL) ───────────────────────────────────────────
    local query
    query=$(printf '{ user(login: "%s") { pinnedItems(first: 6, types: REPOSITORY) { nodes { ... on Repository { name } } } } }' "$GITHUB_USER")

    local pinned_json
    pinned_json=$(gh api graphql -f query="$query" 2>/dev/null \
               || echo '{"data":{"user":{"pinnedItems":{"nodes":[]}}}}')

    PINNED_NAMES=()

    local count
    count=$(echo "$pinned_json" | jq '.data.user.pinnedItems.nodes | length' 2>/dev/null || echo 0)

    for ((i = 0; i < count; i++)); do
        PINNED_NAMES+=("$(echo "$pinned_json" | jq -r ".data.user.pinnedItems.nodes[$i].name")")
    done

    echo "Data fetched. Starting display..." >&2
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    fetch_github_data

    sleep 0.5
    clear
    sleep 0.3

    # ── Build prompt string ──────────────────────────────────────────────
    local prompt
    prompt=$(printf '%b%s%b@%b%s%b %b~%b %b$%b ' \
        "$BCYN" "$GITHUB_USER" "$R" \
        "$BCYN" "ARAS-Workspace" "$R" \
        "$BBLU" "$R" \
        "$B" "$R")

    # Type the "neofetch" command
    printf '%s' "$prompt"
    sleep 0.2
    type_text "neofetch"
    sleep "$COMMAND_PAUSE"
    printf '\n'
    sleep 0.4

    # ── Arch Linux ASCII art (plain text — color applied at print) ───────
    local art=()
    art+=("                   -\`")
    art+=("                  .o+\`")
    art+=("                 \`ooo/")
    art+=("                \`+oooo:")
    art+=("               \`+oooooo:")
    art+=("               -+oooooo+:")
    art+=("             \`/:-:++oooo+:")
    art+=("            \`/++++/+++++++:")
    art+=("           \`/++++++++++++++:")
    art+=("          \`/+++ooooooooooooo/\`")
    art+=("         ./ooosssso++osssssso+\`")
    art+=("        .oossssso-\`\`\`\`/ossssss+\`")
    art+=("       -osssssso.      :ssssssso.")
    art+=("      :osssssss/        osssso+++.")
    art+=("     /ossssssss/        +ssssooo/-")
    art+=("   \`/ossssso+/:-        -:/+osssso+-")
    art+=("  \`+sso+:-\`                 \`.-/+oso:")
    art+=(" \`++:.                           \`-/+/")
    art+=(" .\`                                 \`/")

    # ── Build info lines (right column) ──────────────────────────────────
    local lbl="$BCYN"        # label color  (matches Arch art)
    local sep="${D}──────────────────────────────────────${R}"
    local info=()

    # Header
    info+=("${BCYN}${USER_LOGIN}${R}@${BCYN}ARAS-Workspace${R}")
    info+=("${sep}")

    # Profile
    info+=("${lbl}Name${R}: ${USER_NAME}")
    info+=("${lbl}Location${R}: ${USER_LOC}")
    info+=("${lbl}Company${R}: ${USER_COMPANY}")
    info+=("${lbl}Website${R}: ${USER_BLOG}")
    info+=("${lbl}Member Since${R}: ${USER_SINCE}")

    # Pinned repos
    local pin_count=${#PINNED_NAMES[@]}
    if [[ $pin_count -gt 0 ]]; then
        info+=("")
        info+=("${lbl}Pinned${R}:")

        for ((i = 0; i < pin_count; i++)); do
            local name="${PINNED_NAMES[$i]}"

            local conn="├─"
            [[ $i -eq $((pin_count - 1)) ]] && conn="└─"

            info+=("${D}${conn}${R} ${B}${name}${R}")
        done
    fi

    # Color palette
    info+=("")
    info+=("${BG_BLK}   ${BG_RED}   ${BG_GRN}   ${BG_YEL}   ${BG_BLU}   ${BG_MAG}   ${BG_CYN}   ${BG_WHT}   ${R}")
    info+=("${BG_BBLK}   ${BG_BRED}   ${BG_BGRN}   ${BG_BYEL}   ${BG_BBLU}   ${BG_BMAG}   ${BG_BCYN}   ${BG_BWHT}   ${R}")

    # ── Print side-by-side ───────────────────────────────────────────────
    local art_color="$BCYN"
    local total=${#art[@]}
    [[ ${#info[@]} -gt $total ]] && total=${#info[@]}

    printf '\n'

    for ((i = 0; i < total; i++)); do
        # Left column — ASCII art (plain text, colored uniformly)
        if [[ $i -lt ${#art[@]} ]]; then
            printf '%b%-*s%b' "$art_color" "$ART_WIDTH" "${art[$i]}" "$R"
        else
            printf '%-*s' "$ART_WIDTH" ""
        fi

        # Right column — info (contains ANSI codes)
        if [[ $i -lt ${#info[@]} ]]; then
            printf '  %b' "${info[$i]}"
        fi

        printf '\n'
        sleep "$LINE_DELAY"
    done

    printf '\n'

    # ── Final prompt (cursor blinks for END_PAUSE seconds) ───────────────
    printf '%s' "$prompt"
    sleep "$END_PAUSE"
}

# ═══════════════════════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════════════════════

main "$@"