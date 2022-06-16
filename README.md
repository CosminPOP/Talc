# Talc - Thunder Ale Loot Companion
v3.0.0.2 - _WoW 3.3.5 enGB/enUS_

![image](https://user-images.githubusercontent.com/7255825/171659476-4d1d8e4c-3a3c-42df-a7f5-3b3374620df9.png)

## Features

### Up to 10 Voting Officers 
Officers will be able to vote on loot.

### Raid Leader's extra frame

![image](https://user-images.githubusercontent.com/7255825/171796513-689fe1bd-8ffb-4776-87e8-746e4c4a0d0a.png)
Contains utility buttons to broadcast boss loot, reset voting after loot is distributed, query the raid to see people with the addon, test addon to show the raid how the loot will pop up, ability to drag loot from inventory to be rolled and button to open Raid Leader's Options.

### Raid Leader Options

![image](https://user-images.githubusercontent.com/7255825/171796760-241f6287-d501-4b23-873b-66ab4c28b93f.png)

![image](https://user-images.githubusercontent.com/7255825/171796787-2bc2d94b-f068-482b-8ba3-14f5ded19db4.png)

#### Pick Buttons
Raid leader can set which loot pick options from:
- BIS - Best In Slot
- MS - Main Spec upgrade
- OS - Off-spec
- XMOG - Cosmetic/Transmog
 
#### Screenshot Awarded Loot
Addon will take a screenshot every time loot is distributed.

#### Sync Loot History
Manually send all recorded loot history to everybody in the raid.

### Settings

![image](https://user-images.githubusercontent.com/7255825/171659726-cc97630f-6d10-47b9-9900-27d8c2012731.png)

Players can set if sounds play (and at high/low volume for some) on different events, move and enable or disable frames.<br>
In this window players can also Purge local Loot History.

### Win Frame

![image](https://user-images.githubusercontent.com/7255825/171359935-f1255fd2-bf6d-4ee7-991a-5d78322c2088.png)


Shows a toast and plays a sound when you loot an item in the set threshold.<br>
You can move the frame by dragging.<br>

### Roll Frame

![image](https://user-images.githubusercontent.com/7255825/171359995-e7b48348-289a-4d10-8778-70d9d7772d26.png)


Shows a toast and plays a sound when two or more players have the same number of votes allowing players to roll or pass on loot.<Br>

### Need Frame
  
![image](https://user-images.githubusercontent.com/7255825/171360096-5c02e31c-31e2-4754-aa9b-ff8dc2c8e401.png)

Shows a toast with the loot the master looter sends to the raid allowing players to pick from the set options.<Br>
Shift-clicking the pass button will add an item to the Need Blacklist, hiding it next time it drops.

### Boss defeated Frame
  
  ![image](https://user-images.githubusercontent.com/7255825/171360181-eaf96707-54b8-45c8-ba42-87c3e1ef19eb.png)

  
Shows a big toast when a raid or dungeon boss is defeated.

### Boss Loot Toast
  
  ![image](https://user-images.githubusercontent.com/7255825/171360251-22c29ada-fda3-4740-acce-90846aa149bb.png)

  
Shows the loot that dropped before the master looter sends it for picks.

### Welcome Screen
  
![image](https://user-images.githubusercontent.com/7255825/171659527-cc4e4d95-a5af-4f4b-a789-d2d3bfcdeef1.png)

  
Displays latest awarded loot, grouped by date allowing players to see items' history and other players' loot history.

### Wishlist

![image](https://user-images.githubusercontent.com/7255825/171659638-e196d297-4760-417d-abe2-52fb0a8cbb11.png)

  
Raiders can add up to 8 items in their wishlist.<br>
When an item from the list drops the frame will glow letting the player know its a wishlist item and
officers will see that that player had this item in his wishlist.<br>
You can add items by ID or DB website url, or, if you have Atlas Loot addon you can search by name.


## Slash commands
`/talc minimap` - Restores hidden minimap button<BR><Br>

`/talc set enchanter [name]` - Sets raid enchanter for disenchanting items<BR>
`/talc search [player/item]` - Search the loot history for players or items<Br>
`/talc scale [0.5-2]` - Scales the main window<Br>
`/talc alpha [0.2-1]` - Sets main window transparency level<Br>
`/talc need rescale` - Resets NeedFrame position and size<Br><br>

`/talc win blacklist add [item]` - Add an item to the Win Blacklist<Br>
`/talc win blacklist remove [item]` - Remove an item from the Win Blacklist<Br>
`/talc win blacklist list` - Show the Win Blacklist<Br>
`/talc win blacklist clear` - Clear the Win Blacklist<Br><br>

`/talc need blacklist add [item]` - Add an item to the Need Blacklist<Br>
`/talc need blacklist remove [item]` - Remove an item from the Need Blacklist<Br>
`/talc need blacklist list` - Show the Need Blacklist<Br>
`/talc need blacklist clear` - Clear the Need Blacklist<Br><Br>


