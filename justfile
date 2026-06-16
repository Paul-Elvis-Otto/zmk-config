set shell := ["zsh", "-cu"]

KEYMAP := "./sweep_keymap.yaml"

LIGHT_CONFIG := "./draw/light_config.yaml"
DARK_CONFIG := "./draw/dark_config.yaml"

LIGHT_SVG := "./draw/sweep_keymap_light.svg"
DARK_SVG := "./draw/sweep_keymap_dark.svg"

LIGHT_PNG := "./draw/keymap_light.png"
DARK_PNG := "./draw/keymap_dark.png"

PNG_WIDTH := "5120"

COMMIT_MESSAGE := "Update keymap renders"

FIRMWARE_DIR := "./firmware"
FIRMWARE_ARTIFACT := "firmware"
WORKFLOW_NAME := "Build ZMK firmware"

default:
    @just --list

draw: check
    keymap -c {{ LIGHT_CONFIG }} draw {{ KEYMAP }} > {{ LIGHT_SVG }}
    keymap -c {{ DARK_CONFIG }} draw {{ KEYMAP }} > {{ DARK_SVG }}

    rsvg-convert \
        --background-color '#ffffff' \
        -w {{ PNG_WIDTH }} \
        {{ LIGHT_SVG }} \
        -o {{ LIGHT_PNG }}

    rsvg-convert \
        --background-color '#000000' \
        -w {{ PNG_WIDTH }} \
        {{ DARK_SVG }} \
        -o {{ DARK_PNG }}

    git add \
        {{ LIGHT_SVG }} \
        {{ DARK_SVG }} \
        {{ LIGHT_PNG }} \
        {{ DARK_PNG }}

    if git diff --cached --quiet; then \
        echo "No keymap render changes to commit."; \
    else \
        git commit -m "{{ COMMIT_MESSAGE }}"; \
    fi

    @echo "{{ CYAN }}reloading hammerspoon's init.lua{{ NORMAL }}"
    hs -c "hs.reload()"

clean:
    rm -f {{ LIGHT_SVG }} {{ DARK_SVG }} {{ LIGHT_PNG }} {{ DARK_PNG }}

check:
    @command -v keymap >/dev/null || { echo "ERROR: keymap command not found"; exit 1; }
    @command -v rsvg-convert >/dev/null || { echo "ERROR: rsvg-convert not found. Install with: brew install librsvg"; exit 1; }
    @command -v git >/dev/null || { echo "ERROR: git command not found"; exit 1; }
    @command -v gh >/dev/null || { echo "ERROR: gh not found. Install with: brew install gh"; exit 1; }
    @git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not inside a Git repository"; exit 1; }
    @gh auth status >/dev/null 2>&1 || { echo "ERROR: GitHub CLI is not authenticated. Run: gh auth login"; exit 1; }

firmware:
    mkdir -p {{ FIRMWARE_DIR }}
    rm -rf {{ FIRMWARE_DIR }}/*

    run_id="$( gh run list --workflow "{{ WORKFLOW_NAME }}" --branch "$(git branch --show-current)" --status success --limit 1 --json databaseId --jq '.[0].databaseId')"

    if [[ -z "$run_id" || "$run_id" == "null" ]]; then \
        echo "ERROR: no successful firmware build found for current branch"; \
        exit 1; \
    fi

    gh run download "$run_id" \
        --name {{ FIRMWARE_ARTIFACT }} \
        --dir {{ FIRMWARE_DIR }}

    echo "Downloaded newest firmware into {{ FIRMWARE_DIR }}"
