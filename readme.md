# albumake

A simple script made for the purpouse of making album compilation videos for Youtube.

It takes a list of audio files of the same format on stdin, path to a cover
image and output name and produces a FHD video. Also it generates timestamps
and writes them to stdout.

It's pretty fast because no audio reencoding is needed and we can get away with
low FPS. That also means the filesize is quite small for a FHD vid.

## example usage

```sh
printf "song1.mp3\nsong2.mp3\n" | albumake cover.jpg favorite_album.mp4
```

## dependencies

The standard stuff you find on UNIX systems + ffmpeg and imagemagick.
