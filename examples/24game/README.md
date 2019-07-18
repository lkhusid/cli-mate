# 24

CLI for solving 24 game cards.  This shows an example of using **cli-mate** CLI builder/framework to build a CLI.
CLI definition is in [24.cr](src/24.cr).  
It also illustrates an incredible speed of *crystal* lang. See solver implementation in [game](src/game) folder.  

## Build

```sh
shards build --release
```

## Usage

1. Command line mode:
    - solving one card
    ```sh
    $ bin/24 5 6 7 8                                                                                                           ✔  1350  20:52:07
    5 6 7 8 --> 5 + 7 = 12 | 12 - 8 = 4 | 4 * 6 = 24
    Done in 0.024ms
    ```
    - solving one card with fractions
    ```sh
    $ bin/24 1 4 12 14 -f                                                                                                      ✔  1355  20:56:29
    1 4 12 14 --> 14 / 12 = 7/6 | 7/6 - 1 = 1/6 | 4 / 1/6 = 24
    Done in 2.547ms
    ```

2. REPL (interactive) mode:  
    starts console
    ```sh
    $ bin/24                                                                                                                   ✔  1359  21:00:59
    ==> solve card 9 11 15 18
    9 11 15 18 --> 9 + 11 = 20 | 20 * 18 = 360 | 360 / 15 = 24
    Done in 0.017ms
    ==> 9 11 15 18
    9 11 15 18 --> 9 + 11 = 20 | 20 * 18 = 360 | 360 / 15 = 24
    Done in 0.007ms
    ==> solve batch 4
    
    Total:                    17550
    Solveable:                10491 (59.8%)
    Solveable with fractions:   125 ( 0.7%)
    Not solveable:             6934 (39.5%)
    
    Done in 2.41 sec
    ==> exit
    $ _
    ```

## Help
Use built-in *help* command for full description of options and commands.
```sh
$ bin/24 help
```
In REPL general help:
```
==> help
...
```
or for a specific command:
```
==> help solve card
...
```