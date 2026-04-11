class_name NameUtils

static func format_stat_name(stat: String) -> String: # Turns max_charge_time into Reload Speed
	return " ".join(Array(stat.split("_")).map(func(w): return w.capitalize()))