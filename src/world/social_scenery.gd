class_name SocialScenery
extends RefCounted


static func key() -> int:
	var data: Array = [SimLoop.field.settlements.awake_day]
	for record: Dictionary in SimLoop.field.settlements.records.values():
		var standing := false
		for site in record[&"sites"]:
			var index := SimLoop.builds.index_of(site)
			if index >= 0 and SimLoop.builds.slots[index].standing():
				standing = true
		data.append(standing)
	return hash(data)
