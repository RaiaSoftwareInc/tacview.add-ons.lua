# Welcome to the Tacview Lua Add-ons Repository!

## Introduction

You will find here numerous samples and tools for Tacview. Feel free to experiment and modify the provided source codes.

## How to install an add-on?

To install an existing add-on, simply download the corresponding folder and save it in either:

```
%ProgramData%\Tacview\AddOns\
```

or in the following folder if you just want to install if for the current user:

```
%APPDATA%\Tacview\AddOns\
```

Tacview 1.8.0 has introduced a new command-line option so you can declare another custom path for the add-ons you are working on. This is handy to load your addons directly from a GitHub folder:

```
Tacview64.exe -AddOnsFolders:"C:/Code/GitHub/tacview.add-ons.lua"
```

## How to develop my own add-on?

This repository is dedicated to [Lua](https://www.lua.org/) add-ons. Anyone can develop and run Lua add-ons with any version of Tacview (Yes, even with Tacview Starter!).

The latest version or the Lua API is described in:

```
%ProgramFiles(x86)%\Tacview\AddOns\Tacview Lua Core Interface.txt
%ProgramFiles(x86)%\Tacview\AddOns\Tacview Lua Main Interface.txt
```

The core API is always available to any add-on. Because of technical issues regarding multithreading, the functions described in Lua Main Interface are NOT available to Lua importers and exporters.

If you want to publish your creation or changes, contact us at support@tacview.net and we will grant you access to this repository so you can share your own creation and improvements.

## Add-ons Catalogue

### Telemetry Export

* [lightwave-exporter](lightwave-exporter) – Exports selected object position and rotation in a straightforward csv file which can be used to animate aircraft in [LightWave](https://www.lightwave3d.com/)
