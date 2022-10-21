# CoreScripts
### Modified by Saint Mercury

## Description
These are the scripts used to implement most of the essential server logic in TES3MP, including gameplay adjustments for multiplayer as well as state saving and loading. These also include several custome scripts, and minor edits to the core files for easier modification. Typings used for the lua typings system in vscode (an EmmyLua like interpretation).

* TES3MP version: 0.8.1

## Dependencies

* [Pollnet](https://github.com/probable-basilisk/pollnet/releases)
* [NodeJs](https://nodejs.org/en/)

## Setup

1. Download Pollnet and place the `pollnet.dll` (or whatever your platform uses) into the `lib/` folder.
2. `npm i` in `server/`

## Running the server

1. Start http server using `npm start` in from the `server/` folder. (You can also do `npm i --prefix ./server` from `./`)
2. Start the tes3mp server

