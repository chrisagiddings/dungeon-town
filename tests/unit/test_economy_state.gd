extends GutTest
## Unit tests for EconomyState autoload.

var _saved_gold:     int
var _saved_income:   int
var _saved_expenses: int
var _saved_log:      Array[Dictionary]

func before_each() -> void:
	_saved_gold     = EconomyState.gold
	_saved_income   = EconomyState.total_income
	_saved_expenses = EconomyState.total_expenses
	_saved_log      = EconomyState.transaction_log.duplicate(true)

func after_each() -> void:
	EconomyState.gold             = _saved_gold
	EconomyState.total_income     = _saved_income
	EconomyState.total_expenses   = _saved_expenses
	EconomyState.transaction_log  = _saved_log

# ── add_gold ──────────────────────────────────────────────────────────────────

func test_add_gold_increases_balance() -> void:
	var before: int = EconomyState.gold
	EconomyState.add_gold(100, "test")
	assert_eq(EconomyState.gold, before + 100)

func test_add_gold_increments_total_income() -> void:
	var before: int = EconomyState.total_income
	EconomyState.add_gold(50, "test")
	assert_eq(EconomyState.total_income, before + 50)

func test_add_gold_emits_gold_changed() -> void:
	watch_signals(EventBus)
	EconomyState.add_gold(10, "test")
	assert_signal_emitted(EventBus, "gold_changed")

func test_add_gold_emits_income_recorded() -> void:
	watch_signals(EventBus)
	EconomyState.add_gold(10, "test")
	assert_signal_emitted(EventBus, "income_recorded")

func test_add_gold_zero_does_nothing() -> void:
	var before: int = EconomyState.gold
	EconomyState.add_gold(0, "test")
	assert_eq(EconomyState.gold, before, "Zero amount should leave balance unchanged")

func test_add_gold_negative_does_nothing() -> void:
	var before: int = EconomyState.gold
	EconomyState.add_gold(-50, "test")
	assert_eq(EconomyState.gold, before, "Negative amount should leave balance unchanged")

# ── spend_gold ────────────────────────────────────────────────────────────────

func test_spend_gold_deducts_balance() -> void:
	EconomyState.gold = 200
	EconomyState.spend_gold(75, "test")
	assert_eq(EconomyState.gold, 125)

func test_spend_gold_returns_true_on_success() -> void:
	EconomyState.gold = 200
	var result: bool = EconomyState.spend_gold(50, "test")
	assert_true(result)

func test_spend_gold_returns_false_when_insufficient() -> void:
	EconomyState.gold = 10
	var result: bool = EconomyState.spend_gold(100, "test")
	assert_false(result)

func test_spend_gold_does_not_deduct_when_insufficient() -> void:
	EconomyState.gold = 10
	EconomyState.spend_gold(100, "test")
	assert_eq(EconomyState.gold, 10, "Balance should be unchanged after failed spend")

func test_spend_gold_increments_total_expenses() -> void:
	EconomyState.gold = 500
	var before: int = EconomyState.total_expenses
	EconomyState.spend_gold(30, "test")
	assert_eq(EconomyState.total_expenses, before + 30)

func test_spend_gold_emits_gold_changed_on_success() -> void:
	EconomyState.gold = 200
	watch_signals(EventBus)
	EconomyState.spend_gold(10, "test")
	assert_signal_emitted(EventBus, "gold_changed")

func test_spend_gold_emits_expense_recorded_on_success() -> void:
	EconomyState.gold = 200
	watch_signals(EventBus)
	EconomyState.spend_gold(10, "test")
	assert_signal_emitted(EventBus, "expense_recorded")

func test_spend_gold_zero_returns_false() -> void:
	var result: bool = EconomyState.spend_gold(0, "test")
	assert_false(result, "Spending zero should return false")

# ── can_afford ────────────────────────────────────────────────────────────────

func test_can_afford_true_when_exact_balance() -> void:
	EconomyState.gold = 100
	assert_true(EconomyState.can_afford(100))

func test_can_afford_true_when_more_than_enough() -> void:
	EconomyState.gold = 200
	assert_true(EconomyState.can_afford(100))

func test_can_afford_false_when_insufficient() -> void:
	EconomyState.gold = 50
	assert_false(EconomyState.can_afford(100))

# ── get_net_income ────────────────────────────────────────────────────────────

func test_get_net_income_is_income_minus_expenses() -> void:
	EconomyState.total_income   = 300
	EconomyState.total_expenses = 100
	assert_eq(EconomyState.get_net_income(), 200)

func test_get_net_income_negative_when_overspent() -> void:
	EconomyState.total_income   = 50
	EconomyState.total_expenses = 150
	assert_eq(EconomyState.get_net_income(), -100)

# ── transaction_log ───────────────────────────────────────────────────────────

func test_transaction_log_records_income_entry() -> void:
	EconomyState.transaction_log.clear()
	EconomyState.add_gold(10, "test_source")
	assert_eq(EconomyState.transaction_log.size(), 1)
	assert_eq(EconomyState.transaction_log[0]["label"], "test_source")
	assert_true(EconomyState.transaction_log[0]["is_income"])

func test_transaction_log_records_expense_entry() -> void:
	EconomyState.gold = 500
	EconomyState.transaction_log.clear()
	EconomyState.spend_gold(20, "test_expense")
	assert_eq(EconomyState.transaction_log.size(), 1)
	assert_false(EconomyState.transaction_log[0]["is_income"])

func test_transaction_log_caps_at_max() -> void:
	EconomyState.transaction_log.clear()
	EconomyState.gold = 0
	# Fill beyond the cap with income entries
	for i in range(EconomyState.MAX_TRANSACTION_LOG + 5):
		EconomyState.add_gold(1, "fill")
	assert_eq(
		EconomyState.transaction_log.size(),
		EconomyState.MAX_TRANSACTION_LOG,
		"Log should never exceed MAX_TRANSACTION_LOG"
	)
