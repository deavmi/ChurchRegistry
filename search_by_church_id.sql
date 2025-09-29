SELECT * FROM baptisms

LEFT JOIN church c
WHERE church_id = c.id

-- Parameterize this to the church id
-- you'd like to search for
AND church_id = 1 