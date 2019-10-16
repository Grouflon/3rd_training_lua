# 3rd_training_lua
Training mode for Street Fighter III 3rd Strike (USA 990512), on FBA-RR emulator

## Planned / missing features
- Tech throws
- Blocking: projectiles
- Blocking: random block
- Blocking: first block
- Parry: air parry
- Record & replay system (random replay, replay as counter-attack)
- Record: crop recording up to first input
- Counter-Attack: Kara cancels
- Counter-Attack: On Landing
- Counter-Attack: On wake up
- Detect self cancelled moves

## Frame data database
For the script to function at its best, we need to enter specific frame data for every character and every move into the script database.
When a character frame data is correctly entered in the database, it allows the script to make any opponent dummy successfully block/parry the corresponding move. Otherwise, the script will fall back to a default frame data, that may not match the actual move properties.
Here is a list of character/moves that has been done so far.
### Done characters
- Ibuki : All normals + targets, All specials except projectiles, No supers yet.

### Remaining characters
- alex
- ryu
- yun
- dudley
- necro
- hugo
- elena
- oro
- yang
- ken
- sean
- urien
- gouki
- chunli
- makoto
- q
- twelve
- remy

## References & Inspirations
- [Wonderful 3S frame data reference](http://ensabahnur.free.fr/BastonNew/index.php)
- [Hitbox display script by dammit](https://dammit.typepad.com/blog/2011/10/improved-3rd-strike-hitboxes.html)
- [Trials mode script by c_cube](https://ameblo.jp/3fv/entry-12429961069.html)
- [External C# training mode by furitiem](https://www.youtube.com/watch?v=vE27xe0QM64)
