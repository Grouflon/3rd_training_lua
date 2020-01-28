# 3rd_training_lua
Training mode for Street Fighter III 3rd Strike (USA 990512), on FBA-RR v0.7 emulator

The right version of FBA-RR can be downloaded [here](http://tasvideos.org/EmulatorResources/Fbarr.html)

## Main features
- Can set dummy to counter-attack with any move on frame 1 after any hit / block / parry / wake-up
- Can record and replay sequences into 8 different slots
- Can replay sequences randomly and as counter-attack

## Roadmap
[Trello board](https://trello.com/b/UQ8ey2rQ/3rdtraining)

## Missing features
Automatic blocking needs some manual setup to be done by character in order to work correctly, so a lot of characters do not support this feature yet. Every missing character is mentioned on the Roadmap though and will be added at some point.

## Bug reporting / Contribute
This training mode is still in development and you may encounter bugs or missing features while using it. Please report anything weird thing on the [issues page](https://github.com/Grouflon/3rd_training_lua/issues)
If you wish to contribute or give any feedback, feel free to get in touch with me or submit pull requests.

## Changelog

### v0.3 ()
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
- [Wonderful 3S frame data reference](http://ensabahnur.free.fr/BastonNew/index.php)
- [Hitbox display script by dammit](https://dammit.typepad.com/blog/2011/10/improved-3rd-strike-hitboxes.html)
- [Trials mode script by c_cube](https://ameblo.jp/3fv/entry-12429961069.html)
- [External C# training mode by furitiem](https://www.youtube.com/watch?v=vE27xe0QM64)
