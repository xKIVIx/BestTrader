Global("gAuctionScanCurrPage", 0)
Global("gAuctionScanStartTimestampS", 0)
Global("gAuctionSearchWts", {})
Global("gAuctionScanSearchRequest", {})
Global("gAuctionScanScannedLots", {})

function OnChangeAuctionWidgetState( params )
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtAuctionAddon = common.GetAddonMainForm( sysName ):GetChildChecked( "Auction", false )
    local wtAuction = common.GetAddonMainForm( "ContextAuction" ):GetChildChecked( "Main", false )
    wtAuctionAddon:Show( wtAuction:IsVisibleEx() )
    LogInfo( "Auction widget state - ", wtAuction:IsVisibleEx() )
    gAuctionScanStartTimestampS = 0
end

function DumpScanResult()
    local scanResult = {}
    scanResult['request'] = gAuctionScanSearchRequest
    scanResult['date'] = common.GetLocalDateTime()
    scanResult['result'] = gAuctionScanScannedLots
    userMods.SetGlobalConfigSection( "scan_dump", scanResult )
end

function ScanCurrentLots()
    local auctions = auction.GetAuctions()
    for k, lotId in pairs(auctions) do
        local lotInfo = auction.GetAuctionInfo(lotId)
        local itemInfo = itemLib.GetItemInfo(lotInfo.itemId)
        local lotScanned = lotInfo
        lotScanned['num'] = itemLib.GetStackInfo(lotInfo.itemId)['count']
        lotScanned['name'] = itemLib.GetName(lotInfo.itemId)
        lotScanned['timeLeft'] = nil
        lotScanned['quality'] = itemLib.GetQuality(lotInfo.itemId)['quality']
        lotScanned['lvl'] = itemInfo.level
        local cat = itemLib.GetCategoryInfo( itemLib.GetCategory( lotInfo.itemId ) )
        lotScanned['cat1'] = cat['name']
        if cat['rootId'] == nil then
            lotScanned['cat2'] = ""
        else
            lotScanned['cat2'] = itemLib.GetCategoryInfo(cat['rootId'])['name']
        end
        gAuctionScanScannedLots[tostring(lotInfo.id)] = lotScanned
    end
end

function UpdateScanWidget( totalPages )
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtScanProgress = common.GetAddonMainForm( sysName ):GetChildChecked( "AuctionScanProgress", true )

    wtScanProgress:SetVal('total_page', tostring(totalPages))
    wtScanProgress:SetVal('current_page', tostring(gAuctionScanCurrPage))
    if gAuctionScanStartTimestampS == 0 then
        wtScanProgress:SetVal('actual_time', '0')
    else
        local d = GetTimestampS() - gAuctionScanStartTimestampS
        wtScanProgress:SetVal('actual_time', string.format("%.1f", d))
    end
end

function SearchRequest()
    gAuctionScanCurrPage = gAuctionScanCurrPage + 1
    auction.Search( gAuctionScanSearchRequest, AUCTION_ORDERFIELD_LEFTTIME, true, gAuctionScanCurrPage )
end

function OnAuctionSearchResult( params )

    UpdateScanWidget( params['totalPagesCount'] )

    if not (gAuctionScanStartTimestampS == 0) then
        ScanCurrentLots()

        if gAuctionScanCurrPage <= params['totalPagesCount'] then
            SearchRequest()
        else
            DumpScanResult()
            gAuctionScanStartTimestampS = 0
        end
    end
end

function GetSearchRequest()
    local result = {}

    for k, v in pairs(gAuctionSearchWts) do
        local t = common.GetApiType(v)
        if t == 'TextViewSafe' then
            result[k] = v:GetValuedText()
            result[k] = common.ExtractWStringFromValuedText(result[k])
        elseif t == 'EditLineSafe' then
            result[k] = v:GetText()
        else
            LogError("Unknown type ", t)
            return nil
        end
    end

    result['childCategory'] = GetChildCategoryItemIdByName(result['rootCategory'], result['childCategory'])
    result['rootCategory'] = GetRootCategoryItemIdByName(result['rootCategory'])
    result['levelMax'] = common.GetIntFromWString(result['levelMax'])
    result['levelMin'] = common.GetIntFromWString(result['levelMin'])
    result['rarityMax'] = GetQualityByName(result['rarityMax'])
    result['rarityMin'] = GetQualityByName(result['rarityMin'])
    return result
end

function OnAuctionScanStart( params )
    gAuctionScanStartTimestampS = GetTimestampS()
    gAuctionScanSearchRequest = GetSearchRequest()
    gAuctionScanScannedLots = {}
    gAuctionScanCurrPage = 0
    SearchRequest()
end

function AuctionInit()
    local wtAuction = common.GetAddonMainForm( "ContextAuction" ):GetChildChecked( "Main", false )
    wtAuction:SetOnShowNotification( true )
    common.RegisterEventHandler( OnChangeAuctionWidgetState, "EVENT_WIDGET_SHOW_CHANGED", { widget = wtAuction } )
    common.RegisterEventHandler( OnAuctionSearchResult, "EVENT_AUCTION_SEARCH_RESULT", { sysResult = 'ENUM_AuctionSearchResultMsgResult_SUCCESS' } )
    common.RegisterReactionHandler( OnAuctionScanStart, "StartScanAuction" )

    gAuctionSearchWts['rootCategory'] = wtAuction:GetChildChecked( "searchbar.rootCategory.text", true )
    gAuctionSearchWts['childCategory'] = wtAuction:GetChildChecked( "searchbar.childCategory.text", true )
    gAuctionSearchWts['levelMax'] = wtAuction:GetChildChecked( "searchbar.levelMax.edit", true )
    gAuctionSearchWts['levelMin'] = wtAuction:GetChildChecked( "searchbar.levelMax.edit", true )
    gAuctionSearchWts['name'] = wtAuction:GetChildChecked( "searchbar.name.edit", true )
    gAuctionSearchWts['rarityMax'] = wtAuction:GetChildChecked( "searchbar.rarityMax.text", true )
    gAuctionSearchWts['rarityMin'] = wtAuction:GetChildChecked( "searchbar.rarityMin.text", true )

    LogInfo("Auction inited")
end