class_name VictorySummary
extends RefCounted

var winner_peer_id: int = 1
var winner_name: String = "Survivor"
var victory_reason: String = "ESCAPE"
var escape_strategy: String = "FOOT_VAULT"
var match_duration_sec: float = 0.0
var honorary_title: String = ""
var certificate_text: String = ""


static func generate_honorary_title(strategy: String, reason: String) -> String:
	if reason == "LAST_ONE_STANDING":
		return "Sole Survivor of the Great Firmament Attrition"
	match strategy:
		"VEHICULAR_LAUNCH":
			return "Grand Aeronaut of the Abyss"
		"ENDURANCE_CLIMB":
			return "Master Surveyor of the Outer Ice Wall"
		"FOOT_VAULT":
			return "Pioneer of the Terrestrial Precipice"
		_:
			return "Proven Free-Fall Cartographer"


static func format_certificate(
	p_winner_name: String, p_title: String, p_strategy: String, duration_sec: float
) -> String:
	var minutes: int = int(duration_sec) / 60
	var seconds: int = int(duration_sec) % 60
	return (
		"OFFICIAL FLAT EARTH SURVEY COMMISSION\n"
		+ "GEODETIC PROOF OF TERRESTRIAL FLATNESS\n\n"
		+ "BE IT KNOWN TO ALL ACROSS THE KNOWN BASIN:\n"
		+ "Candidate %s has successfully validated the non-spherical nature\n" % p_winner_name
		+ "of our world by departing over the southern ice rim boundary via %s.\n\n" % p_strategy
		+ "OFFICIALLY CONFERRED TITLE:\n"
		+ "★ %s ★\n\n" % p_title.to_upper()
		+ "TIME TO PROVE FLATNESS: %02d:%02d\n" % [minutes, seconds]
		+ "THE ONLY WAY TO PROVE THE EARTH IS FLAT WAS TO FALL OFF IT."
	)


static func create_summary(
	peer_id: int, display_name: String, reason: String, strategy: String, duration_sec: float
) -> VictorySummary:
	var summary: VictorySummary = VictorySummary.new()
	summary.winner_peer_id = peer_id
	summary.winner_name = display_name if not display_name.is_empty() else "Player_%d" % peer_id
	summary.victory_reason = reason
	summary.escape_strategy = strategy
	summary.match_duration_sec = duration_sec
	summary.honorary_title = generate_honorary_title(strategy, reason)
	summary.certificate_text = format_certificate(
		summary.winner_name, summary.honorary_title, strategy, duration_sec
	)
	return summary


func to_dictionary() -> Dictionary:
	return {
		"winner_peer_id": winner_peer_id,
		"winner_name": winner_name,
		"victory_reason": victory_reason,
		"escape_strategy": escape_strategy,
		"match_duration_sec": match_duration_sec,
		"honorary_title": honorary_title,
		"certificate_text": certificate_text,
	}


static func from_dictionary(dict: Dictionary) -> VictorySummary:
	var s: VictorySummary = VictorySummary.new()
	if dict.has("winner_peer_id"):
		s.winner_peer_id = int(dict["winner_peer_id"])
	if dict.has("winner_name"):
		s.winner_name = str(dict["winner_name"])
	if dict.has("victory_reason"):
		s.victory_reason = str(dict["victory_reason"])
	if dict.has("escape_strategy"):
		s.escape_strategy = str(dict["escape_strategy"])
	if dict.has("match_duration_sec"):
		s.match_duration_sec = float(dict["match_duration_sec"])
	if dict.has("honorary_title"):
		s.honorary_title = str(dict["honorary_title"])
	if dict.has("certificate_text"):
		s.certificate_text = str(dict["certificate_text"])
	return s
