func to_hammer(meters: float) -> float:
	return (meters / 1.905 * 100.0)

func to_meters(hammer_units: float) -> float:
	return (hammer_units * 1.905 / 100.0)
