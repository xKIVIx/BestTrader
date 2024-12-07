Global("gAuctionScanCurrPage", 0)
Global("gAuctionScanStartTimestampS", 0)
Global("gAuctionSearchWts", {})
Global("gAuctionScanSearchRequest", {})
Global("gAuctionScanScannedLots", {})
Global("gAuctionSearchResult", {})
Global("gAuctionBuyingItem", nil)
Global("gAuctionBestPrices", nil)

function OnChangeAuctionWidgetState( params )
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtAuctionAddon = common.GetAddonMainForm( sysName ):GetChildChecked( "Auction", false )
    wtAuctionAddon:Show( params['widget']:IsVisibleEx() )
    LogInfo( "Auction widget state - ", params['widget']:IsVisibleEx() )
    gAuctionScanStartTimestampS = 0
    gAuctionBuyingItem = nil
    gAuctionBestPrices = nil
end

function OnSelectBuyingItem( params )
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtAuctionAddon = common.GetAddonMainForm( sysName ):GetChildChecked( "AuctionBuyPanel", true )
    wtAuctionAddon:Show( params['widget']:IsVisibleEx() )
end

function GetSelectedAuction()
    local wtAuctionList = common.GetAddonMainForm( "ContextAuction" ):GetChildChecked( "Main", false )
    wtAuctionList = wtAuctionList:GetChildChecked( "List", false )

    for i = 1, 8 do
        local wtButtons = wtAuctionList:GetChildChecked( string.format("Button0%i", i), true )
        if wtButtons:GetVariant() == 1 then
            return gAuctionSearchResult[i-1]
        end
    end
    return nil
end

function DumpScanResult()
    local scanResult = {}
    scanResult['request'] = gAuctionScanSearchRequest
    scanResult['date'] = common.GetLocalDateTime()
    scanResult['result'] = gAuctionScanScannedLots
    userMods.SetGlobalConfigSection( "scan_dump", scanResult )
end

function ScanCurrentLots()
    for k, lotId in pairs(gAuctionSearchResult) do
        local lotInfo = auction.GetAuctionInfo(lotId)
        local itemInfo = itemLib.GetItemInfo(lotInfo.itemId)
        local lotScanned = lotInfo
        lotScanned['num'] = itemLib.GetStackInfo(lotInfo.itemId)['count']
        lotScanned['name'] = itemLib.GetName(lotInfo.itemId)
        lotScanned['timeLeft'] = nil
        lotScanned['quality'] = itemLib.GetQuality(lotInfo.itemId)['quality']
        lotScanned['resourceId'] = itemLib.GetResourceId( lotInfo.itemId )
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

function ComparePriceLots(a, b)
    if a['buyoutPrice'] == -1 then
        return false
    end
    if b['buyoutPrice'] == -1 then
        return true
    end
    local lotA = a['buyoutPrice'] / a['num']
    local lotB = b['buyoutPrice'] / b['num']
    return lotA < lotB
end

function FindBestPrices()
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtBuyPanel = common.GetAddonMainForm( sysName ):GetChildChecked( "AuctionBuyPanel", true )
    local wt = wtBuyPanel:GetChildChecked( "AuctionTradePriceOnePanel", true ):GetChildChecked( "Value", true )
    local maxPriceOne = tonumber(wt:GetString())
    if maxPriceOne == nil or maxPriceOne <= 0 then
        LogError("Not set price one")
        return
    end

    wt = wtBuyPanel:GetChildChecked( "AuctionTradeMaxCountPanel", true ):GetChildChecked( "Value", true )
    local maxCount = tonumber(wt:GetString())

    wt = wtBuyPanel:GetChildChecked( "AuctionTradeMaxTotalPricePanel", true ):GetChildChecked( "Value", true )
    local maxSum = tonumber(wt:GetString())

    if maxCount == 0 and maxCount == nil and maxSum == 0 and maxSum == nil then
        LogError("Not set maxCount or maxSum")
        return
    end

    local curCount = 0
    local curSum = 0
    local sortedArray = {}
    for k, lot in pairs(gAuctionScanScannedLots) do
        table.insert(sortedArray, lot)
    end
    table.sort(sortedArray, ComparePriceLots)
    gAuctionBestPrices = {}
    for i = 1, #sortedArray do
        if sortedArray[i]['resourceId']:IsEqual(gAuctionBuyingItem) and
           not( sortedArray[i]['buyoutPrice'] == -1 ) and
           not(sortedArray[i]['participationStatus'] =='ENUM_AuctionDescriptorParticipationStatus_OWNER') then
            local priceOne = sortedArray[i]['buyoutPrice'] / sortedArray[i]['num']
            if priceOne <= maxPriceOne then
                local tCount = curCount + sortedArray[i]['num']
                local tSum = curSum + sortedArray[i]['buyoutPrice']
                if (maxSum == nil or maxSum == 0 or tSum <= maxSum) and (maxCount == nil or maxCount == 0 or tCount <= maxCount) then
                    table.insert(gAuctionBestPrices, sortedArray[i])
                    curCount = tCount
                    curSum = tSum
                else
                    break
                end
            end
        end
    end
    gAuctionBuyingItem = nil
    LogInfo("Sum ", curSum, ", Count ", curCount)
    StartScan()
end

function BuyBestPrice()
    local isBuy = false
    for k, lotId in pairs(gAuctionSearchResult) do
        local lotInfo = auction.GetAuctionInfo(lotId)
        local itemInfo = itemLib.GetItemInfo(lotInfo.itemId)
        for i = 1, #gAuctionBestPrices do
            if gAuctionBestPrices[i]['resourceId']:IsEqual(itemLib.GetResourceId( lotInfo.itemId )) then
                if gAuctionBestPrices[i]['buyoutPrice'] == lotInfo['buyoutPrice'] and
                gAuctionBestPrices[i]['num'] == itemLib.GetStackInfo(lotInfo.itemId)['count'] then
                    auction.Buyout(lotId)
                    gAuctionBestPrices[i]['num'] = -1
                    break
                end
            end
        end
    end
    if isBuy == true then
        gAuctionScanCurrPage = gAuctionScanCurrPage - 1
    end
end

function UpdateScanWidget( totalPages )
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtScanProgress = common.GetAddonMainForm( sysName ):GetChildChecked( "AuctionScanProgress", true )

    wtScanProgress:SetVal('total_page', tostring(totalPages))
    wtScanProgress:SetVal('current_page', tostring(gAuctionScanCurrPage))
    wtScanProgress:SetVal('procent', string.format("%.1f", gAuctionScanCurrPage/totalPages * 100.0))
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
    gAuctionSearchResult = auction.GetAuctions()

    if not (gAuctionScanStartTimestampS == 0) then
        if gAuctionBestPrices == nil then
            ScanCurrentLots()
        else
            BuyBestPrice()
        end

        if gAuctionScanCurrPage < params['totalPagesCount'] then
            SearchRequest()
        else
            gAuctionScanStartTimestampS = 0
            if gAuctionBuyingItem == nil and gAuctionBestPrices == nil then
                LogInfo("Dump result")
                DumpScanResult()
            elseif gAuctionBestPrices == nil then
                LogInfo("Find best prices")
                FindBestPrices()
            else
                gAuctionBestPrices = nil
            end
        end
    end
end

function GetSearchRequest()
    local result = {}

    for k, v in pairs(gAuctionSearchWts) do
        local t = common.GetApiType(v)
        if t == 'Widget_TextViewSafe' then
            result[k] = v:GetWString()
        elseif t == 'Widget_EditLineSafe' then
            result[k] = v:GetText()
        else
            LogError("Unknown type ", t)
            return nil
        end
    end

    result['childCategory'] = GetChildCategoryItemIdByName(result['rootCategory'], result['childCategory'])
    result['rootCategory'] = GetRootCategoryItemIdByName(result['rootCategory'])
    result['levelMax'] = result['levelMax']:ToInt()
    result['levelMin'] = result['levelMin']:ToInt()
    result['rarityMax'] = GetQualityByName(result['rarityMax'])
    result['rarityMin'] = GetQualityByName(result['rarityMin'])
    return result
end

function StartScan()
    gAuctionScanStartTimestampS = GetTimestampS()
    gAuctionScanSearchRequest = GetSearchRequest()
    gAuctionScanScannedLots = {}
    gAuctionScanCurrPage = 0
    SearchRequest()
end

function OnAuctionScanStart( params )
    StartScan()
end

function OnAuctionBuying( params )
    local selectedAuc = GetSelectedAuction()
    local lotInfo = auction.GetAuctionInfo(selectedAuc)
    gAuctionBuyingItem = itemLib.GetResourceId( lotInfo.itemId )
    StartScan()
end

function AuctionInit()
    local wtAuction = common.GetAddonMainForm( "ContextAuction" ):GetChildChecked( "Main", false )
    local wtBidButton = wtAuction:GetChildChecked( "ButtonBid", true )
    wtAuction:SetOnShowNotification( true )
    wtBidButton:SetOnShowNotification( true )
    common.RegisterEventHandler( OnChangeAuctionWidgetState, "EVENT_WIDGET_SHOW_CHANGED", { widget = wtAuction } )
    common.RegisterEventHandler( OnSelectBuyingItem, "EVENT_WIDGET_SHOW_CHANGED", { widget = wtBidButton } )
    common.RegisterEventHandler( OnAuctionSearchResult, "EVENT_AUCTION_SEARCH_RESULT", { sysResult = 'ENUM_AuctionSearchResultMsgResult_SUCCESS' } )

    common.RegisterReactionHandler( OnAuctionScanStart, "StartScanAuction" )
    common.RegisterReactionHandler( OnAuctionBuying, "AuctionTradeBuy" )

    gAuctionSearchWts['rootCategory'] = wtAuction:GetChildChecked( "searchbar.rootCategory.text", true )
    gAuctionSearchWts['childCategory'] = wtAuction:GetChildChecked( "searchbar.childCategory.text", true )
    gAuctionSearchWts['levelMax'] = wtAuction:GetChildChecked( "searchbar.levelMax.edit", true )
    gAuctionSearchWts['levelMin'] = wtAuction:GetChildChecked( "searchbar.levelMax.edit", true )
    gAuctionSearchWts['name'] = wtAuction:GetChildChecked( "searchbar.name.edit", true )
    gAuctionSearchWts['rarityMax'] = wtAuction:GetChildChecked( "searchbar.rarityMax.text", true )
    gAuctionSearchWts['rarityMin'] = wtAuction:GetChildChecked( "searchbar.rarityMin.text", true )

    LogInfo("Auction inited")
end