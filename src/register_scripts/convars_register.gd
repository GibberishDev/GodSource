extends Node

func _ready() -> void:
    GSConsole.add_convar("sv_cheats", GSConsole.CONVAR_TYPE.BOOLEAN, "0")
    GSConsole.add_convar("sv_autojump", GSConsole.CONVAR_TYPE.BOOLEAN, "0")
    GSConsole.add_convar("sv_bhop", GSConsole.CONVAR_TYPE.BOOLEAN, "1")
    GSConsole.add_convar("sv_limitjumpspeed", GSConsole.CONVAR_TYPE.BOOLEAN, "1")
    GSConsole.add_convar("cl_nullmovement", GSConsole.CONVAR_TYPE.BOOLEAN, "1")

    GSConsole.add_convar("sv_accelerate", GSConsole.CONVAR_TYPE.FLOAT, "10")
    GSConsole.add_convar("sv_airaccelerate", GSConsole.CONVAR_TYPE.FLOAT, "10")
    GSConsole.add_convar("sv_maxspeed", GSConsole.CONVAR_TYPE.FLOAT, str(300.0*1.905/100.0), "0.0")
    GSConsole.add_convar("sv_maxvelocity", GSConsole.CONVAR_TYPE.FLOAT, str(3500.0*1.905/100.0), "0.0")
    GSConsole.add_convar("sv_friction", GSConsole.CONVAR_TYPE.FLOAT, "4.0")
    GSConsole.add_convar("sv_stopspeed", GSConsole.CONVAR_TYPE.FLOAT, "1.905")
    GSConsole.add_convar("sv_gravity", GSConsole.CONVAR_TYPE.FLOAT, str(800.0*1.905/100.0))
    GSConsole.add_convar("sv_maxstepup", GSConsole.CONVAR_TYPE.FLOAT, str(18.0*1.905/100.0))
    GSConsole.add_convar("sv_upthreshold", GSConsole.CONVAR_TYPE.FLOAT, str(250.0*1.905/100.0))

    GSConsole.add_convar("fov_desired", GSConsole.CONVAR_TYPE.INTEGER, "90", "20", "120")
