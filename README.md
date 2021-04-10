# 3rd_training_lua
Training mode for Street Fighter III 3rd Strike (Japan 990512), on Fightcade v2.0.91

The right version of Fightcade can be downloaded [here](https://www.fightcade.com/)

## Main features
- Can set dummy to counter-attack with any move on frame 1 after any hit / block / parry / wake-up
- Can record and replay sequences into 8 different slots
- Can replay sequences randomly and as counter-attack
- Can save/load recorded sequences to/from files
- Can display hit/hurt/throwboxes
- Can display input history for both players
- Special training mode to train parries and red parries

## How to use
* Download emulator from [here](https://www.fightcade.com/) and find the proper roms
* Download the archive from [here](https://github.com/Grouflon/3rd_training_lua/archive/master.zip) or clone repository
* Extract the archive anywhere on your computer
* Start the emulator, load the rom, start a match with P1 and P2 (you will need to map input for both players)
* Go to Game->Lua Scripting->New Lua Script Window and run the script **3rd_training.lua** from here
* Follow instructions from the Output Console

## Bug reporting / Contribute
If you want to be informed when a new version come out and/or discuss the current bugs and features, you can join the [Discord server](https://discord.gg/CDXQyFmcSe) of the project.

This training mode is still in development and you may encounter bugs or missing features while using it. Please report any bug on the **#bugs** channel, and any feature request on the **#features** channel of the discord server.

If you wish to contribute or give any feedback, feel free to get in touch or submit pull requests.

## Troubleshooting
**Q: Missing rom, zip file not found**

A: Make sure you have the proper roms. You must have at least 2 roms: _sfiii3.zip_ and _sfiii3a.zip_. sfiii3 is the japanese version and the zip contains _sfiii3_japan_nocd.29f400.u2_. sfiiia is the american version and contains _sfiii3_usa.29f400.u2_.

You may need to rename zip files so they match exactly what the emulator expect for.

**Q: When I run the script, the characters can no longer move**

A: You are probably using the script on FBA-RR which is not supported anymore, in order to benefit from the last features and improvement you must run the script on Fightcade2's FBNeo emulator. However if you still want to use FBA-RR, you can go back to v0.6 which was the last version supported on FBA-RR.

**Q: Emulator crash when I run lua script**

A: Check video settings, you musn't use "Enhanced" blitter option.

**Q: UI looks weird and hitboxes are misplaced**

A: Check video settings, you must use "Basic" blitter option with no scanlines if you want the UI to work properly.

**Q: Emulator doesn't run at all, there's a missing dll**

A: Install prerequires from [here](https://github.com/TASVideos/BizHawk-Prereqs/releases/latest/)

## Roadmap
[Trello board](https://trello.com/b/UQ8ey2rQ/3rdtraining)

## Changelog
### v0.10 (???)
- [Feature] New 3rd_spectator.lua script for displaying info during replays without messing with input
- [Feature] Number display for all gauges and bonuses
- [Feature] Frame advantage display

### v0.9 (04/04/2021)
- [Feature] Projectiles are now blocked/parried
- [Feature] The dummy will now counter-attack on landing after an air recovery
- [Feature] Yun's Genei Jin is now fully blocked/parried by the dummy
- [Feature] Added 4rd Strike rom support in collaboration with @speedmccool25, but no frame data recorded yet.
- [Improvement] When loading a save state, the recording state is reset to a useful state depending on the state you were before
- [Bugfix/Improvement] All characters can now block/parry meaties and all first frame wake up hits
- [Bugfix/Improvement] Fixed a lot of bugs in the overall blocking/parrying/counter-attack system
- [Bugfix/Improvement] Revamped the wake-up / fast wake-up triggering and counter-attack system to be more reliable and maintainable
- [Bugfix] Fixed recordings not loading correctly on US-regioned machines

### v0.8 (23/12/2020)
- [Feature] Special trainings section + parry special training
- [Feature] Stun delayed reset mode
- [Improvement] Added new menu categories and made a better split of options between them
- [Improvement] Changed counter-attack random deviation cap from 40 to 600
- [Bugfix] Fixed incorrect index causing errors when using random replay and weights
- [Bugfix] [issue#21](https://github.com/Grouflon/3rd_training_lua/issues/21) When the game is paused and hitboxes are enabled, an error occurs when loading a savestate
- [Bugfix] [issue#29](https://github.com/Grouflon/3rd_training_lua/issues/29) If you make a recording and rename it with lower case or space in its name, it won't launch
- [Bugfix] [issue#22](https://github.com/Grouflon/3rd_training_lua/issues/22) Input flipping is now decided upon character position diff instead of sprite flip (should fix wrong manipulations occuring after some moves)
- [Bufix] [Fixed meter gauges not updating after loading a save state](https://trello.com/c/7eMUwOHg/76-meter-refill-does-not-update-max-values-correctly-when-coming-back-to-select-screen-or-using-save-states)
- [FrameData] Added some missing Makoto wake up data
- [FrameData] Added some missing Ken wake up data
- [FrameData] Added some missing Ibuki frame data

### v0.7 (12/11/2020)
- Changed main supported emulator from FBA-rr to Fightcade's FBNeo fork
- [Feature] Main player now acts as the training dummy during recording and pre-recording
- [Feature] Added input history display for both players
- [Feature] Added a weight to each replay slot to control randomness (Contribution of @BoredKittenz)
- Redesigned controller display
- [Bugfix] [issue#8](https://github.com/Grouflon/3rd_training_lua/issues/8) Cannot Link moves into super
- [Bugfix] [issue#15](https://github.com/Grouflon/3rd_training_lua/issues/15) Time based super like geneijin not consistent with their meter usage
- [Bugfix] [issue#19](https://github.com/Grouflon/3rd_training_lua/issues/19) Error: Failed to save training settings to training settings.json
- [Bugfix] [issue#18](https://github.com/Grouflon/3rd_training_lua/issues/18) Another Big Issue: Constant Negative Edge While Recording
- [Bugfix] [issue#17](https://github.com/Grouflon/3rd_training_lua/issues/17) Large issue : P2 cannot do EX moves even if they have meter

### v0.6 (04/04/2020)
- Can save/load recorded sequences to/from files
- Keep recordings between sessions (saved per character inside training_settings.json)
- Added counter-attack delay and maximum random deviation to recording slots
- Random blocking mode won't stop blocking in the middle of a true blockstring
- Added First Hit blocking mode
- Added refill delay for life and meter into training settings
- [Bugfix] Fixed dummy bricking when triggering a recording counter attack with nothing recorded
- [Frame Data] Elena
- [Frame Data] Q
- [Frame Data] Ryu
- [Frame Data] Remy
- [Frame Data] Twelve
- [Frame Data] Chun-Li
- [Frame Data] Sean
- [Frame Data] Necro
- [Frame Data] Dudley
- [Frame Data] Yang
- [Frame Data] Yun

### v0.5 (23/03/2020)
- Auto refill life mode
- Auto refill meter mode + ability to set a precise meter amount from the menu
- Infinite Super Art Timer mode
- input autofire (rapid movement when holding key) in menus
- Frame data prediction can resync itself to the actual animation frame, and thus handle a lot more blocking situations
- All 2 hits blocking / parying Fixed
- Blocking / parying of self cancellable moves supported
- Improved wording of some menu elements
- [Bugfix] Fixed infinite meter not working for player 2
- [Bugfix] Fixed recording counterattack triggering in the middle of a blockstring
- [Bugfix] Fixed recording counterattack restarting on hit
- [Frame Data] Oro
- [Frame Data] Ken

### v0.4 (13/02/2020)
- Urien frame data
- Gouki frame data
- Makoto frame data
- Random fast wake up
- Random blocking
- Throws teching
- Added music volume control
- [Bugfix] Fixed Dudley not crouching correctly
- [Bugfix] Fixed Oro not crouching correctly
- [Bugfix] Do not counter attack on state load anymore

### v0.3 (28/01/2020)
- Can now record sequences within 8 different slots
- Can play recorded sequences repeatedly and on random
- Recorded sequences can by triggered as a counter-attack

### v0.2 (26/01/2020)
- New blocking system: Now works by recording hitboxes characteristics to a file for every move and predict hitbox collisions with actual frame data.
- Can switch main player between P1 and P2
- Removed all old frame data
- Entered frame data for Ibuki, Alex and Hugo

### v0.1 (25/11/2019)
- Basic blocking and training options
- Can set dummy to block, parry and red parry after x hits
- Can set dummy to counter-attack with any move after hit, block parry or wake up
- Entered frame data by hand for Ibuki and Urien

## References & Inspirations
- [Wonderful 3S frame data reference](http://baston.esn3s.com/)
- [Hitbox display script by dammit](https://dammit.typepad.com/blog/2011/10/improved-3rd-strike-hitboxes.html)
- [Trials mode script by c_cube](https://ameblo.jp/3fv/entry-12429961069.html)
- [External C# training mode by furitiem](https://www.youtube.com/watch?v=vE27xe0QM64)
- [3S InGame addresses spreadsheet](https://docs.google.com/spreadsheets/d/1eLi9phXMj18QGLfugrHhEQEjIVvSI2zbbUmDgPuLSf0/edit#gid=706955060)
