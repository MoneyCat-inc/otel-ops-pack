#!/bin/bash
# ECRR Key Generator - Bash
# Generates unique ECRR keys in the format ECRR-YYYYMMDD-HHMMSS

SLUG=""
SHOW_USAGE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--slug)
            SLUG="$2"
            shift 2
            ;;
        -h|--help|--usage)
            SHOW_USAGE=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

if [ "$SHOW_USAGE" = true ]; then
    echo "ECRR Key Generator"
    echo "Usage: ./generate-ecrr-key.sh [-s|--slug 'SLUG-NAME'] [-h|--help]"
    echo ""
    echo "Examples:"
    echo "  ./generate-ecrr-key.sh                                    # Basic key"
    echo "  ./generate-ecrr-key.sh -s 'FEATURE-IMPLEMENTATION'       # With slug"
    echo "  ./generate-ecrr-key.sh -h                                 # Show this help"
    exit 0
fi

# Generate timestamp in UTC
ts=$(date -u +%Y%m%d-%H%M%S)
key="ECRR-$ts"

if [ -n "$SLUG" ]; then
    # Clean slug (remove spaces, special chars, uppercase)
    clean_slug=$(echo "$SLUG" | sed 's/[^A-Z0-9-]//g' | sed 's/^-\+\|-\+$//g' | sed 's/-\+/-/g')
    if [ -n "$clean_slug" ]; then
        key="ECRR-$ts-$clean_slug"
    fi
fi

echo "$key"

# Also output for copy-paste
echo ""
echo "Copy-paste commands:"
echo "  Filename: $key.md"
echo "  Front-matter: ecrr_key: $key"
echo "  Commit message: docs(ecrr): $key — [your description]"
