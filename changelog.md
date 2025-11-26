Commit from Nov 21st 25:
# Big restructure of the project.
## Renaming of the most global classes to be consistent with each other:
| OLD | NEW |
| --- | --- |
| Console(console.gd) | GSConsole(gs_console.gd) |
| GSUtils(utils.gd) | GSUtils(gs_utils.gd) |
| Register(commands_registerer.gd) | CommandsRegister(commands_registerer.gd)
| NetfoxInternals | *Temporarily disabled* |
| camera_anchor.gd | gs_camera_anchor |

## Windowing system
New **GSUIWindow** container that able to be draged and resiszed contained in the app window. Window can overlap another one and if window below it is clicked method to bring it forward.

## General main game scene restructure
Game is no longer loaded from a scene into world. Now game scene has following structure:<br><br>
root<br>
┣GSConsole<br>
┣GSInput<br>
┣GSUtils<br>
┣GSUi<br>
┃ ┣hud<br>
┃ ┣menus<br>
┃ ┗ui_windows<br>
┣GSConsole<br>
┣Bootstrap registers<br>
┗GameRoot<br><br>
GameRoot will contain Player, 3Dworld scene, paperdolls of other online players and what not with other game scenes. Loading of game content will be dynamic with loading via load() instad of change_scene()

<br>
<br>
<br>
<br>
<br>
<br>
<br>
Im so tired...
