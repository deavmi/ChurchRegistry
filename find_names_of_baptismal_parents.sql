SELECT name FROM
	(
		SELECT * FROM baptismal_parents

		LEFT JOIN parental_figures pf
		WHERE parental_id = pf.id
	)

-- Parameterize the baptism_id below
WHERE baptism_id = 1