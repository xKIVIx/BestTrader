Global("gAuctionScanCurrPage", 0)
Global("gAuctionScanStartTimestampS", 0)
Global("gAuctionSearchWts", {})
Global("gAuctionScanSearchRequest", {})

function OnChangeAuctionWidgetState( params )
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtAuctionAddon = common.GetAddonMainForm( sysName ):GetChildChecked( "Auction", false )
    local wtAuction = common.GetAddonMainForm( "ContextAuction" ):GetChildChecked( "Main", false )
    wtAuctionAddon:Show( wtAuction:IsVisibleEx() )
    LogInfo( "Auction widget state - ", wtAuction:IsVisibleEx() )
    gAuctionScanStartTimestampS = 0
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
        wtScanProgress:SetVal('actual_time', tostring(d))

        local auctions = auction.GetAuctions()
        for i = 0, GetTableSize( auctions ) - 1 do
            local auction = auction.GetAuctionInfo( auctions[ i ] )
        end
    end
end

function OnAuctionSearchResult( params )

    UpdateScanWidget( params['totalPagesCount'] ) 

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

    --result['childCategory'] = GetChildCategoryItemIdByName(result['rootCategory'], result['childCategory'])
    result['rootCategory'] = GetRootCategoryItemIdByName(result['rootCategory'])
    result['levelMax'] = common.GetIntFromWString(result['levelMax'])
    result['levelMin'] = common.GetIntFromWString(result['levelMin'])
    result['rarityMax'] = GetQualityByName(result['rarityMax'])
    result['rarityMin'] = GetQualityByName(result['rarityMin'])
    LogInfo(result['rarityMax'])
    LogInfo(result['rarityMin'])
    return result
end

function OnAuctionScanStart( params )
    gAuctionScanStartTimestampS = GetTimestampS()
    gAuctionScanSearchRequest = GetSearchRequest()

    auction.Search( gAuctionScanSearchRequest, AUCTION_ORDERFIELD_TYPE, true, 1 )

    LogInfo(gAuctionScanSearchRequest['rarityMax'])
end

function AuctionInit()
    local wtAuction = common.GetAddonMainForm( "ContextAuction" ):GetChildChecked( "Main", false )
    wtAuction:SetOnShowNotification( true )
    common.RegisterEventHandler( OnChangeAuctionWidgetState, "EVENT_WIDGET_SHOW_CHANGED", { widget = wtAuction } )
    common.RegisterEventHandler( OnAuctionSearchResult, "EVENT_AUCTION_SEARCH_RESULT", { sysResult = 'ENUM_AuctionSearchResultMsgResult_SUCCESS' } )
    common.RegisterReactionHandler( OnAuctionScanStart, "StartScanAuction" )

    gAuctionSearchWts['rootCategory'] = wtAuction:GetChildChecked( "searchbar.rootCategory.text", true )
    --gAuctionSearchWts['childCategory'] = wtAuction:GetChildChecked( "searchbar.childCategory.text", true )
    gAuctionSearchWts['levelMax'] = wtAuction:GetChildChecked( "searchbar.levelMax.edit", true )
    gAuctionSearchWts['levelMin'] = wtAuction:GetChildChecked( "searchbar.levelMax.edit", true )
    gAuctionSearchWts['name'] = wtAuction:GetChildChecked( "searchbar.name.edit", true )
    gAuctionSearchWts['rarityMax'] = wtAuction:GetChildChecked( "searchbar.rarityMax.text", true )
    gAuctionSearchWts['rarityMin'] = wtAuction:GetChildChecked( "searchbar.rarityMin.text", true )

    LogInfo("Auction inited")
end