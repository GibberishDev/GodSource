extends Node

func to_hammer_units(meters: float) -> float:
	return meters * 100 / 1.905

func to_meters(hammer_units: float) -> float:
	return hammer_units * 1.905 / 100

func string_to_vector(input_string: String) -> Vector2:
	var split_variables: PackedStringArray = input_string.split(" ")

	if !split_variables.size() == 3:
		return Vector2.ZERO

	var vector: String = split_variables[0]
	var x: float = 0.0
	var y: float = 0.0

	if vector != "vector2":
		return Vector2.ZERO

	if !split_variables[1].is_valid_float():
		return Vector2.ZERO

	if !split_variables[2].is_valid_float():
		return Vector2.ZERO

	x = float(split_variables[1])
	y = float(split_variables[2])

	return Vector2(x, y)

func string_to_color(input_string: String) -> Color:
	var split_variables: PackedStringArray = input_string.split(" ")

	if !split_variables.size() == 5:
		return Color()

	var color: String = split_variables[0]

	var rgba: Array = [0.00, 0.00, 0.00, 0.00]

	if color != "color":
		return Color()

	for i: int in split_variables.size():
		if i != 0:
			if !split_variables[i].is_valid_float():
				return Color()
			else:
				if float(split_variables[i]) >= 0.00 and float(split_variables[i]) <= 1.00:
					rgba[i - 1] = float(split_variables[i])

	return Color(rgba[0], rgba[1], rgba[2], rgba[3])

func string_to_variable(input_string: String, input_dictionary: Dictionary) -> Variant:
	var split_variables: PackedStringArray = input_string.split(" ")

	if !split_variables.size() == 2:
		return input_string

	var use: String = split_variables[0]
	var variable_name: String = split_variables[1]

	if use != "use":
		return input_string

	if !input_dictionary.has(variable_name):
		return input_string

	return input_dictionary[variable_name]
