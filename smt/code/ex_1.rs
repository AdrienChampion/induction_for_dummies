vars {
	x y : int
}

assert {
	(x > 7) ∧ (
		y = 2*x ∨ x = 11
	)
}

check_sat!()