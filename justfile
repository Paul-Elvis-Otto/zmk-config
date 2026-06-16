set shell := ["zsh", "-cu"]

KEYMAP := "./sweep_keymap.yaml"

LIGHT_CONFIG := "./draw/light_config.yaml"
DARK_CONFIG := "./draw/dark_config.yaml"

LIGHT_SVG := "./draw/sweep_keymap_light.svg"
DARK_SVG := "./draw/sweep_keymap_dark.svg"

LIGHT_PNG := "./draw/keymap_light.png"
DARK_PNG := "./draw/keymap_dark.png"

PNG_WIDTH := "3840"

COMMIT_MESSAGE := "Update keymap renders"

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

clean:
    rm -f {{ LIGHT_SVG }} {{ DARK_SVG }} {{ LIGHT_PNG }} {{ DARK_PNG }}

check:
    @command -v keymap >/dev/null || { echo "ERROR: keymap command not found"; exit 1; }
    @command -v rsvg-convert >/dev/null || { echo "ERROR: rsvg-convert not found. Install with: brew install librsvg"; exit 1; }
    @command -v git >/dev/null || { echo "ERROR: git command not found"; exit 1; }
    @git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not inside a Git repository"; exit 1; }
