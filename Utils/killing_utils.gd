extends Node2D
class_name KillingUtils

# Iterates through player and NPC containers to award points to the identified attacker.
static func give_points_on_death(entity: Node2D, points_value: int) -> void:
	var level_comp: Node = entity.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp) and level_comp.has_method("get_points"):
		level_comp.get_points(points_value)
		return				
	else:
		printerr("Attacker has no valid level component")

# Displays a message to the player that killed
static func give_kill_credit(entity: Node2D, victim_username: String, killer_username: String):
	var ui_comp: Node = entity.get_node_or_null("UIComponent")
	if is_instance_valid(ui_comp) and ui_comp.has_method("display_message"):
		ui_comp.display_message.rpc_id(entity.name.to_int(), killer_username + " Killed " + victim_username)
	else:
		printerr("Attacker has no valid ui component")

# Finds the NPC or Player who killed something by their id
static func find_killer(main: Node, killer_id: String) -> Node2D:
	var killer: Node2D = null

	if killer_id == "" or not is_instance_valid(main):
		printerr("No attacker id (Trying to find killer)")
		return

	var containers: Array[String] = ["SpawnedPlayers", "SpawnedNPCs"]
	for container_name: String in containers:
		var container: Node = main.get_node_or_null(container_name)
		if is_instance_valid(container):
			for entity: Node in container.get_children():
				if entity.name == killer_id:
					killer = entity
		else:
			printerr("Kill - No valid container spawned: " + container_name)

	return killer

# Finds the killer, displays a message for them if they are a player and gives them the points
static func route_kill_credits_and_points(main: Node, killer_id: String, points_value: int, victim_username: String = "", killer_username: String = "") -> void:
	var killer: Node2D = find_killer(main, killer_id)
	

	if killer != null:
		if points_value > 0:
			give_points_on_death(killer, points_value)

		if killer.is_in_group("player") and victim_username != "": # Wont show for food 
			var killer_found_username: String = killer_username
			
			if killer_found_username == "" and killer.get("player_username"): # If a username is not passed in for the killer uses their player username
				killer_found_username = killer.player_username
				print("Killer name: " + killer.player_username)
			give_kill_credit(killer, victim_username, killer_found_username)
