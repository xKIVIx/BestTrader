CREATE TABLE items AS
SELECT
	result.name as name,
	result.lvl as lvl,
	result.quality as quality,
	root_categories.ROWID as root_cat,
	child_categories.ROWID as child_cat
FROM result
LEFT JOIN root_categories
ON result.cat2 = root_categories.name
LEFT JOIN child_categories
ON result.cat1 = child_categories.name
GROUP BY
	result.name,
	result.lvl,
	result.quality
