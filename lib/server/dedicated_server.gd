extends Node

var input_thread : Thread;
var escape_character: String = PackedByteArray([0x1b]).get_string_from_ascii()
var input_thread_semaphore : Semaphore = Semaphore.new()
var mutex : Mutex = Mutex.new()
var exit_thread : bool = false

func _ready() -> void:
	printraw(escape_character + "[2J" + escape_character + "[;H")
	print(ProjectSettings.get_setting("application/config/name") + " - version " + ProjectSettings.get_setting("application/config/version"))
	print_rich("[color=green]Starting CLI thread...[/color]")
	input_thread = Thread.new()
	input_thread.start(_cli_input)
	Console.terminal_input_thread_semaphore = input_thread_semaphore
	input_thread_semaphore.post()


func _cli_input() -> void:
	if OS.is_debug_build() and OS.has_feature("editor"):
		print_rich("[color=red]Godot terminal doesnt support terminal input. Shutting down input thread...[/color]\r\n")
		return
	var input_text : String = ""
	while true:
		input_thread_semaphore.wait()
		mutex.lock()
		var should_exit : bool = exit_thread
		mutex.unlock()

		if should_exit:
			return
		
		printraw.call_deferred("> ")
		input_text = OS.read_string_from_stdin(4096).strip_edges()
		Console.process_input(input_text)

func _exit_tree() -> void:
	mutex.lock()
	exit_thread = true # Protect with Mutex.
	mutex.unlock()
	input_thread_semaphore.post()
	input_thread.wait_to_finish()


	
