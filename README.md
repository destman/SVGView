# SVGView
Set of tools to render simple SVG files on iOS using Core Graphics

## Prerequisites

```
brew install protobuf
pod install
```

## Build

`svg2pb` is used in Build Rule of SVGViewTest target to create protobuf version of SVG images and it should be build first.

1. Launch archive action on svg2pb target to build and install `svg2pb` into `/usr/local/bin`.
2. Run SVGViewTest application

