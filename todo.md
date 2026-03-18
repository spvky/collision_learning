- [ ] Picking
- [~] Prefabs
- [ ] Saving Colliders
- [ ] Texturing

Goals:
- Fairly sparse but useful ui to create, edit, and save collision triangles, maybe texture them
- Build editor first and then start adding the game to it 
- Save collision scenes to binary, maybe save revisions and have an ability to snapshot a full state as a new file
- Big undo depth, maybe an undo tree
- Be able to seamlessley edit collision, test it, and overwrite the file
- Put editor behind CLI flag and conditionally compile as much as possible for editor only code

Wed 04 Mar 2026 12:13:37 AM EST
- Added a lot of infra for editor events, better grid and started defining cube prefab


Tue 10 Mar 2026 04:09:29 PM EDT
- Considering uisng a handful of arenas for allocations
- Game Allocator (Maybe omit this one, as it has the same lifetime as the program)
- Level Allocator (Emptied when exiting a level, holds things like events emitted in a level)
- Temp Allocator (Emptied each frame)

Tue 10 Mar 2026 08:13:48 PM EDT
TODO: 
- Picking
- Inspector View


Inspector rendering


Tue 17 Mar 2026 04:23:16 PM EDT

- Basic jumping and gravity
- Slopes


Tue 17 Mar 2026 11:54:54 PM EDT

- MC is a little ghost guy
- Movement abilities in different hats/shoes
- Or maybe just one hat, a janitors hat
- Ghostly janitor working for a mad scientist to get shines, but the shines are some sort of energy source
- Can use different star thresholds to give upgrades
- Skid to a stop when sucking, tracking how much your speed drops
- Suck functions like punch grab in SM64
- Can throw like in SM64, or aim and shoot out what you pick up
- Have the Luigis mansion ghost mechanic where how much damage you deal is based on sucking in the opisite direction

Default Abilities:
- Side hop
- Tripple jump
- Long Jump
- Wall kick
- Suck and Shoot
- Crouch backflip
- Dive
- Slide


Unlockable:
- Ground Pound
- Grapple
- Sucking up fluid
- SMS Dash Nozzle/Super Metroid Speed booster

For vacum effect, scroll the UVS in the wind direction while rotating the cone
