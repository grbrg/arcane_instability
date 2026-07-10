class_name ModifierValidator
extends RefCounted

# Returns {modifier_type: [disallowed_values]} for the current selection given the rules array.
# Each rule has the form: {when: {type: value, ...}, disallow: {type: [values], ...}}
# Use the result to grey out options in the UI that would create invalid combinations.
static func get_disallowed(selection: Dictionary, rules: Array) -> Dictionary:
	var result: Dictionary = {}
	for rule in rules:
		if not (rule.has("when") and rule.has("disallow")):
			continue
		var matches := true
		for k in rule["when"]:
			if selection.get(k, "") != rule["when"][k]:
				matches = false
				break
		if not matches:
			continue
		for k in rule["disallow"]:
			if not result.has(k):
				result[k] = []
			for v in rule["disallow"][k]:
				if v not in result[k]:
					result[k].append(v)
	return result


# Returns false if the selection violates any rule.
static func is_valid(selection: Dictionary, rules: Array) -> bool:
	for rule in rules:
		if not (rule.has("when") and rule.has("disallow")):
			continue
		var matches := true
		for k in rule["when"]:
			if selection.get(k, "") != rule["when"][k]:
				matches = false
				break
		if not matches:
			continue
		for k in rule["disallow"]:
			if selection.get(k, "") in rule["disallow"][k]:
				return false
	return true
