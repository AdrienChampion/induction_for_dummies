vars {
	x y : int
}

assert {
	x > 7,
	y = 2*x ∨ x = 11,
	y % 2 = 1,
}

check_sat!()
get_model!()