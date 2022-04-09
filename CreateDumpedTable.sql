CREATE TABLE dumped_data AS
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