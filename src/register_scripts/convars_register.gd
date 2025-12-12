extends Node

func _ready() -> void:
	register_convars()
	GSConfig.apply_saved_settings()
	GSConsole.connect("convar_changed", convar_changed_notifier)

func register_convars() -> void:
	GSConsole.add_convar(&"sv_cheats", GSConsole.CONVAR_TYPE.BOOLEAN,[], "0")
	GSConsole.add_convar(&"sv_autojump", GSConsole.CONVAR_TYPE.BOOLEAN,[GSConsole.CONVAR_FLAGS.CHEAT], "0")
	GSConsole.add_convar(&"sv_bhop", GSConsole.CONVAR_TYPE.BOOLEAN,[GSConsole.CONVAR_FLAGS.CHEAT], "1")
	GSConsole.add_convar(&"sv_limitjumpspeed", GSConsole.CONVAR_TYPE.BOOLEAN,[GSConsole.CONVAR_FLAGS.CHEAT], "1")
	GSConsole.add_convar(&"sv_accelerate", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], "10")
	GSConsole.add_convar(&"sv_airaccelerate", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], "10")
	GSConsole.add_convar(&"sv_bounce", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], "1")
	GSConsole.add_convar(&"sv_maxspeed", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], str(300.0*1.905/100.0), "0.0")
	GSConsole.add_convar(&"sv_maxvelocity", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], str(3500.0*1.905/100.0), "0.0")
	GSConsole.add_convar(&"sv_friction", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], "4")
	GSConsole.add_convar(&"sv_stopspeed", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], "1.905")
	GSConsole.add_convar(&"sv_gravity", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], str(800.0*1.905/100.0))
	GSConsole.add_convar(&"sv_maxstepup", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], str(18.0*1.905/100.0))
	GSConsole.add_convar(&"sv_upthreshold", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], str(250.0*1.905/100.0))
	GSConsole.add_convar(&"host_timescale", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.CHEAT], "1", "0")
	
	GSConsole.add_convar(&"cl_nullmovement", GSConsole.CONVAR_TYPE.BOOLEAN,[GSConsole.CONVAR_FLAGS.SETTING], "1")
	GSConsole.add_convar(&"cl_vsync", GSConsole.CONVAR_TYPE.BOOLEAN,[GSConsole.CONVAR_FLAGS.SETTING], "0")
	GSConsole.add_convar(&"cl_mousesensx", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.SETTING], "0.003", "-1.0","1.0", "Horizontal mouse sensitivity")
	GSConsole.add_convar(&"cl_mousesensy", GSConsole.CONVAR_TYPE.FLOAT,[GSConsole.CONVAR_FLAGS.SETTING], "0.0045", "-1.0","1.0", "Vertical mouse sensitivity")
	GSConsole.add_convar(&"cl_windowmode", GSConsole.CONVAR_TYPE.INTEGER,[GSConsole.CONVAR_FLAGS.SETTING], "1","0","2", "Window mode: 0 - exclusive fullscreen, 1 - fullscreen, 2 - windowed.")
	GSConsole.add_convar(&"fov_desired", GSConsole.CONVAR_TYPE.INTEGER,[GSConsole.CONVAR_FLAGS.SETTING], "90", "20", "120")
	GSConsole.add_convar(&"fps_max", GSConsole.CONVAR_TYPE.INTEGER,[GSConsole.CONVAR_FLAGS.SETTING], "144", "0", "900")


func convar_changed_notifier(convar_name: StringName) -> void:
	match convar_name:
		&"host_timescale":
			Engine.time_scale = GSConsole.convar_list[&"host_timescale"]["value"]
		&"fps_max":
			Engine.set_max_fps(GSConsole.convar_list[&"fps_max"]["value"])
		&"cl_vsync":
			DisplayServer.window_set_vsync_mode(GSConsole.convar_list[&"cl_vsync"]["value"])
		&"cl_windowmode":
			match GSConsole.convar_list[&"cl_windowmode"]["value"]:
				0:
					DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
				1:
					DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
				2:
					# DisplayServer.window_set_flag(DisplayServer.WindowFlags.WINDOW_FLAG_BORDERLESS, false) #<- for whatever reason on windows 10 causes frame from winddows 95 to display instead of windows 10 one
					DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
				_:
					DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
