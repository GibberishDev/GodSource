extends Node

func _ready() -> void:
    GSConsole.add_convar("sv_cheats", GSConsole.CONVAR_TYPE.BOOLEAN, "0", "0")
    GSConsole.add_convar("sv_limit_jump_speed", GSConsole.CONVAR_TYPE.BOOLEAN, "1", "1")
    GSConsole.add_convar("sv_maxspeed", GSConsole.CONVAR_TYPE.FLOAT, "6.096", "6.096", "0.0")
    GSConsole.add_convar("sv_maxvelocity", GSConsole.CONVAR_TYPE.FLOAT, "66.675", "66.675", "0.0")
    GSConsole.add_convar("sv_friction", GSConsole.CONVAR_TYPE.FLOAT, "4.0", "4.0")
    GSConsole.add_convar("sv_stopspeed", GSConsole.CONVAR_TYPE.FLOAT, "1.905", "1.905")
    GSConsole.add_convar("sv_accelerate", GSConsole.CONVAR_TYPE.FLOAT, "10", "10")
    GSConsole.add_convar("sv_airaccelerate", GSConsole.CONVAR_TYPE.FLOAT, "10", "10")
    GSConsole.add_convar("sv_gravity", GSConsole.CONVAR_TYPE.FLOAT, "15.24", "15.24")