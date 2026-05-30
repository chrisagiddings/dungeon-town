extends GutTest
## Smoke test — verifies GUT is installed and the runner works.
## If this passes, the test infrastructure is functional.

func test_gut_is_running() -> void:
	assert_true(true, "GUT is installed and running")

func test_autoloads_are_accessible() -> void:
	assert_not_null(GameState,   "GameState autoload is accessible")
	assert_not_null(EconomyState, "EconomyState autoload is accessible")
	assert_not_null(EventBus,    "EventBus autoload is accessible")
	assert_not_null(DataRegistry, "DataRegistry autoload is accessible")
