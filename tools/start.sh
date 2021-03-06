#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -l|--lab)
        LAB=YES
        shift # past argument
    ;;
    -n|--notebook)
        LAB=NO
        shift
    ;;
    *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# end command processing

export PATH="$HOME/miniconda3/bin:$PATH"

trap "source activate notebook; jupyter notebook stop 8888" EXIT
trap 'for pid in $BKPIDS; do kill $pid; done; exit' SIGINT

{
    source activate notebook
    if [[ $LAB = NO ]]; then
        jupyter notebook
    else
        jupyter lab
    fi
} &

source activate notebook

function generate_slides {
    fswatch --print0 --event=Updated --extended --exclude=".*" --include="^[^~]*\.ipynb$" "./$1" \
        | xargs -0 -I % jupyter nbconvert % --to=slides --reveal-prefix=../reveal.js \
            --output-dir="./docs/$1" --config=./slides-config/slides_config.py
}

{
    generate_slides "better-code-test"
} &
BKPIDS=($!)
{
    generate_slides "better-code-class"
} &
BKPIDS=($!)
{
    generate_slides "better-code-new"
} &
BKPIDS+=($!)
{
    cd ./docs
    bundle exec jekyll build --baseurl "" --watch --incremental
} &
BKPIDS+=($!)

browser-sync start --config bs-config.js
