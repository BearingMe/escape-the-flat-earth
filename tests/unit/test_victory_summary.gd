extends GutTest


func test_honorary_titles() -> void:
	assert_eq(
		VictorySummary.generate_honorary_title("VEHICULAR_LAUNCH", "ESCAPE"),
		"Grand Aeronaut of the Abyss"
	)
	assert_eq(
		VictorySummary.generate_honorary_title("ENDURANCE_CLIMB", "ESCAPE"),
		"Master Surveyor of the Outer Ice Wall"
	)
	assert_eq(
		VictorySummary.generate_honorary_title("FOOT_VAULT", "ESCAPE"),
		"Pioneer of the Terrestrial Precipice"
	)
	assert_eq(
		VictorySummary.generate_honorary_title("ANY", "LAST_ONE_STANDING"),
		"Sole Survivor of the Great Firmament Attrition"
	)


func test_create_summary_and_serialization() -> void:
	var summary: VictorySummary = VictorySummary.create_summary(
		1, "AeroAce", "ESCAPE", "VEHICULAR_LAUNCH", 325.0
	)
	assert_eq(summary.winner_peer_id, 1)
	assert_eq(summary.winner_name, "AeroAce")
	assert_true(summary.certificate_text.contains("AeroAce"))
	assert_true(summary.certificate_text.contains("GRAND AERONAUT OF THE ABYSS"))
	assert_true(summary.certificate_text.contains("05:25"))

	var dict: Dictionary = summary.to_dictionary()
	var restored: VictorySummary = VictorySummary.from_dictionary(dict)

	assert_eq(restored.winner_peer_id, 1)
	assert_eq(restored.winner_name, "AeroAce")
	assert_eq(restored.honorary_title, "Grand Aeronaut of the Abyss")
	assert_almost_eq(restored.match_duration_sec, 325.0, 0.01)
