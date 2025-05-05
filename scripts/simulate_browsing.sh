#!/bin/bash
# DeepPacket-Style Browsing Simulation Script

DURATION=360  # 6 minutes
END=$((SECONDS + DURATION))

echo "[INFO] Starting deep browsing simulation for $DURATION seconds..."

# Diverse URL list
declare -a URLS=(
    "https://www.wikipedia.org"
    "https://en.wikipedia.org/wiki/Deep_learning"
    "https://en.wikipedia.org/wiki/Network_traffic"
    "https://www.bbc.com"
    "https://www.bbc.com/news/technology"
    "https://edition.cnn.com/technology"
    "https://www.nytimes.com/section/science"
    "https://www.reddit.com/r/linux/"
    "https://news.ycombinator.com"
    "https://github.com/explore"
    "https://stackoverflow.com/questions"
    "https://www.theguardian.com/world"
    "https://www.nasa.gov/missions"
    "https://arxiv.org/list/cs.AI/recent"
)

simulate_visit() {
    local URL="$1"
    local TOOL=$((RANDOM % 2))
    
    if [[ $TOOL -eq 0 ]]; then
        curl -s "$URL" > /dev/null
    else
        wget -q "$URL" -O /dev/null
    fi

    echo "[INFO] Visited: $URL"
}

while [[ $SECONDS -lt $END ]]; do
    for i in {1..6}; do
        RANDOM_SITE="${URLS[$RANDOM % ${#URLS[@]}]}"
        simulate_visit "$RANDOM_SITE"
        sleep $((RANDOM % 3 + 1))
    done
    echo "[INFO] --- Looping again ---"
    sleep 2
done

echo "[INFO] Browsing simulation complete. Total run: $DURATION seconds"
