for f in "$@"
do
    ffmpeg -i "$f" -vf reverse "${f%.*}_reversed.mp4"
done
