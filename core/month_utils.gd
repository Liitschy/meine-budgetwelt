extends RefCounted

const MONTH_NAMES := [
	"Januar",
	"Februar",
	"März",
	"April",
	"Mai",
	"Juni",
	"Juli",
	"August",
	"September",
	"Oktober",
	"November",
	"Dezember",
]


static func current_month_id() -> String:
	var date := Time.get_date_dict_from_system()
	return make_month_id(int(date.year), int(date.month))


static func make_month_id(year: int, month: int) -> String:
	return "%04d-%02d" % [year, clampi(month, 1, 12)]


static func add_months(month_id: String, offset: int) -> String:
	var parts := month_id.split("-")
	if parts.size() != 2:
		return current_month_id()

	var year := int(parts[0])
	var month_index := year * 12 + int(parts[1]) - 1 + offset
	var target_year := floori(float(month_index) / 12.0)
	var target_month := posmod(month_index, 12) + 1
	return make_month_id(target_year, target_month)


static func display_name(month_id: String) -> String:
	var parts := month_id.split("-")
	if parts.size() != 2:
		return month_id
	var year := int(parts[0])
	var month := clampi(int(parts[1]), 1, 12)
	return "%s %d" % [MONTH_NAMES[month - 1], year]

