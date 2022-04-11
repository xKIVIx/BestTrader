INSERT INTO root_categories
SELECT cat2
FROM result
LEFT OUTER JOIN root_categories
ON cat2 = root_categories.name
WHERE root_categories.name is NULL AND NOT result.cat2 is NULL
GROUP BY cat2;

INSERT INTO child_categories
SELECT cat1
FROM result
LEFT OUTER JOIN child_categories
ON cat1 = child_categories.name
WHERE child_categories.name is NULL
GROUP BY cat1;

INSERT INTO items
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
LEFT OUTER JOIN items
ON result.name = items.name AND result.lvl = items.lvl AND result.quality = items.quality
WHERE items.name is NULL
GROUP BY
	result.name,
	result.lvl,
	result.quality;

INSERT INTO dumped_data
SELECT
	result.bidderName as bidderName,
	result.buyoutPrice as buyoutPrice,
	result.currentBid as currentBid,
	result.num as num,
	result.participationStatus as participationStatus,
	result.scanTime as scanTime,
	result.sellerName as sellerName,
	result.startPrice as startPrice,
	result.timeLeftSeconds as timeLeftSeconds,
	items.ROWID as itemId
FROM result
LEFT JOIN items
ON result.name = items.name AND result.quality = items.quality AND result.lvl = items.lvl

