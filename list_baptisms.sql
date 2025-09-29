SELECT * FROM baptisms

LEFT JOIN church c
WHERE church_id = c.id
AND baptisms.id = 1