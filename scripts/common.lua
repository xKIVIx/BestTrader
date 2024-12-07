function GetTimestampMs()
    return common.GetMsFromDateTime( common.GetLocalDateTime() )
end

function GetTimestampS()
    return GetTimestampMs() / 1000
end

function GetRootCategoryItemIdByName(name)
    local cats = itemLib.GetRootCategories()
    if cats == nil then
        LogError("Failed get root categories")
        return nil
    end
    for k, r in pairs(cats) do
        local categoryInfo = itemLib.GetCategoryInfo( r )
        if common.CompareWString(categoryInfo.name, name) == 0 then
            return r
        end
    end
    LogError("Not found root category")
    return nil
end

function GetChildCategoryItemIdByName(rootName, name)
    local cats = itemLib.GetChildCategories( GetRootCategoryItemIdByName(rootName) )
    if cats == nil then
        LogError("Failed get child categories")
        return nil
    end
    for k, v in pairs(cats) do
        local categoryInfo = itemLib.GetCategoryInfo(v)
        if common.CompareWString(categoryInfo.name, name) == 0 then
            return v
        end
    end
    LogError("Not found child category")
    return nil
end

function GetWStringConstant(name)
    local sysName = common.GetAddonInfo()['sysFullName']
    local wtCommon = common.GetAddonMainForm( sysName ):GetChildChecked( "Common", false )
    local wtConst = wtCommon:GetChildChecked( name, true )
    if wtConst == nil then
        LogError("Not found constant ", name)
        return nil
    end

    return wtConst:GetWString()
end

function GetQualityByName(name)
    local qualityEnums = {
        'ITEM_QUALITY_JUNK',
        'ITEM_QUALITY_GOODS',
        'ITEM_QUALITY_COMMON',
        'ITEM_QUALITY_UNCOMMON',
        'ITEM_QUALITY_RARE',
        'ITEM_QUALITY_EPIC',
        'ITEM_QUALITY_LEGENDARY',
        'ITEM_QUALITY_RELIC',
        'ITEM_QUALITY_DRAGON'
    }

    for k, v in pairs(qualityEnums) do
        local resConst = GetWStringConstant(v)
        if resConst == nil then
            LogError("Failed get constant ", v)
            return nil
        end

        if common.CompareWString(resConst, name) == 0 then
            return v
        end
    end

    LogError("Unknown type quality ", name)
    return nil
end