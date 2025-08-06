extends Node

var escape_character: String = PackedByteArray([0x1b]).get_string_from_ascii() #shorthand for ascii character

var input_thread : Thread #Separate thread for terminal input reference
var input_thread_semaphore : Semaphore = Semaphore.new()  #Semaphore to suspend the thread untill all commands complete
var input_thread_mutex : Mutex = Mutex.new() #Mutex for locking input thread flags to ensure correct memory safety when handling cross thread communication
var input_thread_exit_flag : bool = false #Indicates input thread that it should kill itself (Thread, you should kill yourself, NOW)

func _ready() -> void:
	printraw(escape_character + "[2J" + escape_character + "[;H") #clears console window
	print(ProjectSettings.get_setting("application/config/name") + " - version " + ProjectSettings.get_setting("application/config/version"))
	print_rich("[color=green]Starting CLI thread...[/color]")
	input_thread = Thread.new()
	input_thread.start(_cli_input)
	Console.terminal_input_thread_semaphore = input_thread_semaphore
	input_thread_semaphore.post() 	#Unsuspend thread input activity. Needs to be done first cause of issues with how thread interacts with main thread execution of commands.
									# (commands usually finish exewcuting later than thread starts listening for new input leading to ability to execute
									#  one more command input after issuing immediate shutdown of input thread via QUIT command)


func _cli_input() -> void:
	if OS.is_debug_build() and OS.has_feature("editor"): #kill input thread immediatelly if launched in godot editor
		print_rich("[color=red]Godot terminal doesnt support terminal input. Export for dedicated  server with feature \"dedicated\" to use with your OS terminal instead. Shutting down input thread...[/color]\r\n")
		get_tree().quit(0)
		return
	while true: #lol, fuck this but i dont care
		input_thread_semaphore.wait() #suspend the input thread untill command execution finishes
		input_thread_mutex.lock() 
		var should_exit : bool = input_thread_exit_flag #copy the thread killer flag
		input_thread_mutex.unlock()
		if should_exit: return #kill thread if should_exit
		
		printraw.call_deferred("> ") 
		var input_text : String = OS.read_string_from_stdin(4096).strip_edges() #await user input
		Console.process_input(input_text) #send input to console class to process it for command inputs

func _exit_tree() -> void: #Dispose of thread safely to not shit the memory
	input_thread_mutex.lock()
	input_thread_exit_flag = true
	input_thread_mutex.unlock()
	input_thread_semaphore.post()
	input_thread.wait_to_finish()

