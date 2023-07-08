# mpv-separator
Interactively separate the videos you wanna keep from a given playlist

## Description
This script helps you organize your playlists by giving you the hability to
copy or move the current video being played to a default or user defined folder.

## Usage
There are two shortcut keys to this script, which follow below.

### Ctrl + D (Duplicate file)
In the video screen, press `Ctrl + D` to **duplicate** the video and put it
inside the `separator` folder.

### Ctrl + M (Move file)
In the video screen, press `Ctrl + M` to **move** the video to the `separator`
folder.

## Configuration
By default, when a video is copyied or moved, the script will create a folder
which is located where the `mpv` was ran. The folder will be called `separator`
and will be followed by a period and six random ASCII characters which range
between `[a-zA-Z0-9]`. Therefore, the folder's name will follow the pattern
given by `separator.XXXXXX`.

#### Example
```sh
cd /home/user
mpv ./videos/my_videos/cartoons/funny_cartoon.mp4

<< Ctrl + D >>
```

In the scenario above, the `separator` folder will be created in `/home/user`,
which is the current working directory, and the file `funny_cartoon.mp4` will
be duplicated inside of it.

## Defining a custom location
In order to define a custom location, the ambient variable
`MPV_SEPARATOR_OUTPUT` must be changed to reflect the place you want the
`separator` folder to be created.

#### Example
```sh
export MPV_SEPARATOR_OUTPUT="/home/user/.videos"

cd /home/user
mpv great_video.mp4

<< Ctrl + D >>
```

In this case, the `separator` folder will be created inside the directory
`/home/user/.videos`, as it was defined by the ambient variable.
