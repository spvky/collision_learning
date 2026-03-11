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
