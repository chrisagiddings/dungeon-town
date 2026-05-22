extends Node
## EconomyState — gold ledger and financial flow tracking.

# ── Constants ─────────────────────────────────────────────────────────────────
const STARTING_GOLD: int = 500
const MAX_TRANSACTION_LOG: int = 100

# ── State ─────────────────────────────────────────────────────────────────────
var gold: int = STARTING_GOLD
var total_income: int = 0
var total_expenses: int = 0
var transaction_log: Array[Dictionary] = []

# ── Public API ────────────────────────────────────────────────────────────────

func add_gold(amount: int, source: String = "unknown") -> void:
	## Add gold to the balance (income). Emits gold_changed and income_recorded.
	if amount <= 0:
		push_warning("EconomyState.add_gold: non-positive amount %d" % amount)
		return
	gold += amount
	total_income += amount
	_log_transaction(amount, source, true)
	EventBus.gold_changed.emit(gold, amount)
	EventBus.income_recorded.emit(amount, source)

func spend_gold(amount: int, reason: String = "unknown") -> bool:
	## Deduct gold. Returns false (and does nothing) if insufficient funds.
	if amount <= 0:
		push_warning("EconomyState.spend_gold: non-positive amount %d" % amount)
		return false
	if gold < amount:
		return false
	gold -= amount
	total_expenses += amount
	_log_transaction(-amount, reason, false)
	EventBus.gold_changed.emit(gold, -amount)
	EventBus.expense_recorded.emit(amount, reason)
	return true

func can_afford(amount: int) -> bool:
	return gold >= amount

func get_net_income() -> int:
	return total_income - total_expenses

func get_summary() -> String:
	return "Gold: %d | In: %d | Out: %d | Net: %d" % [
		gold, total_income, total_expenses, get_net_income()
	]

# ── Internal ──────────────────────────────────────────────────────────────────

func _log_transaction(delta: int, label: String, is_income: bool) -> void:
	transaction_log.append({
		"day":       GameState.current_day,
		"hour":      GameState.current_hour,
		"delta":     delta,
		"label":     label,
		"is_income": is_income,
		"balance":   gold,
	})
	if transaction_log.size() > MAX_TRANSACTION_LOG:
		transaction_log.pop_front()
