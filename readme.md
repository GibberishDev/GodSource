<p align="center">
  <img src="godsource_logo.png" alt="GodSource" width=70% height=70%>
</p>

## IMPORTANT!!!!!!! and ! Doesnt propperly work with the Rapier or Jolt Physics engine out of the box! Requires a lot of additional tweaking and in most cases its no longer worth it to use em


## As of this current commit this template has following features:
* Ground movement
* Null-movement ( or pesky modern name of SnapTap ) input interpretation
* Air strafing and source like gravity
* Velocity clip
* Explosion template which has TF2 values baked into it for as close as possible Soldier rocket jumping
* Source engine crouch and jump system ( Including toggleable bugged behaviour 😉 )
* Player water movement and jumping out on a ledge

## Planned features that are not in code rn or being worked on:
* object water physics similar to source engine
* Physics props and source engine like prop grabbing
* Inventory system ( or equipable items and weapons )
* Code clean-up and exported variables for ease of use in-engine
* In-engine documentation and readable code comments >.>
* Basic health system
* Source engine bind and alias system(aka all inputs and commands can be bound to keys. Including binding alias binds) 

## Unplanned features but developer has wet dreams about em ( aka I would prob need to be full time dev, way about my paygrade(5 cookies and one mug of MUG) and knowledge ([me:](https://giphy.com/gifs/talk-warming-rpt-Q1aRmd8e90WIw)) to implement them. ) :
* Netcode for Server <-> Client structure 💀
* Example model of character with inverse kinematics for 3rd person view or said multiplayer representation
* (Optional module) Map creating tool with custom "brushes" for non-developers being able to contribute. Might be a plugin for Blender and Godot.
* Custom classes for Player to declutter Player set-up

