extends RefCounted
class_name UpgradeRequirementChecker
## Evaluates all upgrade requirements for a BuildingData and returns a
## structured result showing which are met, unmet, or not yet trackable.
##
## "Trackable" means the M1 engine can evaluate the requirement right now.
## Untrackable requirements (resources, population, depth, patrons, reputation)
## are shown in the UI but do NOT block the upgrade in M1.

# ── Result helpers ────────────────────────────────────────────────────────────

static func _req(label: String, type: String, met: bool, trackable: bool) -> Dictionary:
	return {"label": label, "type": type, "met": met, "trackable": trackable}

# ── Public API ────────────────────────────────────────────────────────────────

static func evaluate(data: BuildingData, grid: BuildingGrid) -> Dictionary:
	## Returns {can_upgrade: bool, requirements: Array[Dictionary]}
	## can_upgrade is true only when every *trackable* requirement is met.

	if data.upgrade_to.is_empty():
		return {"can_upgrade": false, "requirements": []}

	var reqs: Array[Dictionary] = []

	# ── Gold ──────────────────────────────────────────────────────────────────
	if data.upgrade_cost > 0:
		var met := EconomyState.can_afford(data.upgrade_cost)
		reqs.append(_req("%d gold" % data.upgrade_cost, "gold", met, true))

	# ── Resources (M2) ────────────────────────────────────────────────────────
	for res_id in data.upgrade_resources.keys():
		var amount: int = data.upgrade_resources[res_id]
		reqs.append(_req(
			"%d %s" % [amount, res_id.capitalize().replace("_", " ")],
			"resource", false, false
		))

	# ── Prerequisite buildings ────────────────────────────────────────────────
	for prereq_id in data.upgrade_prerequisites:
		var found := _has_building(grid, prereq_id)
		var prereq_data := DataRegistry.get_building(prereq_id) as BuildingData
		var prereq_name: String = prereq_data.display_name if prereq_data else prereq_id
		reqs.append(_req("%s present" % prereq_name, "prerequisite", found, true))

	# ── Supply chains (M2) ────────────────────────────────────────────────────
	if data.upgrade_supply_chains > 0:
		reqs.append(_req(
			"%d supply chains" % data.upgrade_supply_chains,
			"supply_chains", false, false
		))

	# ── Dungeon depth (M4) ────────────────────────────────────────────────────
	if data.upgrade_dungeon_depth > 0:
		reqs.append(_req(
			"Dungeon floor %d reached" % data.upgrade_dungeon_depth,
			"dungeon_depth", false, false
		))

	# ── Patron count (M3) ────────────────────────────────────────────────────
	if data.upgrade_patron_count > 0:
		reqs.append(_req(
			"%d lifetime patrons" % data.upgrade_patron_count,
			"patron_count", false, false
		))

	# ── Population (M2) ──────────────────────────────────────────────────────
	if data.upgrade_population > 0:
		reqs.append(_req(
			"Population ≥ %d" % data.upgrade_population,
			"population", false, false
		))

	# ── Reputation (M3) ──────────────────────────────────────────────────────
	if data.upgrade_reputation != "":
		reqs.append(_req(
			"Reputation: %s" % data.upgrade_reputation.capitalize(),
			"reputation", false, false
		))

	# can_upgrade = all trackable requirements are met
	var can_upgrade := true
	for r in reqs:
		if r["trackable"] and not r["met"]:
			can_upgrade = false
			break

	return {"can_upgrade": can_upgrade, "requirements": reqs}

# ── Helpers ───────────────────────────────────────────────────────────────────

static func _has_building(grid: BuildingGrid, data_id: String) -> bool:
	for p in grid.get_placements():
		if p["data_id"] == data_id:
			return true
	return false
