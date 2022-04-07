function GetTimestampMs()
    return common.GetMsFromDateTime( common.GetLocalDateTime() )
end

function GetTimestampS()
    return GetTimestampMs() / 1000
end

function GetRootCategoryItemIdByName(name)
    local cat = itemLib.GetRootCategories()
    for i = 0, GetTableSize( cat ) do
        local categoryInfo = itemLib.GetCategoryInfo( cat[i] )
        if common.CompareWString(categoryInfo.name, name) == 0 then
            return cat[i]
        end
    end
    return nil
end

function GetChildCategoryItemIdByName(rootName, name)
    local cat = itemLib.GetChildCategories( GetRootCategoryItemIdByName(rootName) )
    for i = 0, GetTableSize( cat ) do
        local categoryInfo = itemLib.GetCategoryInfo( cat[i] )
        if common.CompareWString(categoryInfo.name, name) == 0 then
            return cat[i]
        end
    end
    return nil
end

function GetQualityByName(name)
    if common.CompareWString(userMods.ToWString("Хлам"), name) == 0 then
        return 'ITEM_QUALITY_JUNK'
    elseif common.CompareWString(userMods.ToWString("Обычные"), name) == 0 then
        return 'ITEM_QUALITY_GOODS'
    elseif common.CompareWString(userMods.ToWString("Добротные"), name) == 0 then
        return 'ITEM_QUALITY_COMMON'
    elseif common.CompareWString(userMods.ToWString("Замечательные"), name) == 0 then
        return 'ITEM_QUALITY_UNCOMMON'
    elseif common.CompareWString(userMods.ToWString("Редкие"), name) == 0 then
        return 'ITEM_QUALITY_RARE'
    elseif common.CompareWString(userMods.ToWString("Легендарные"), name) == 0 then
        return 'ITEM_QUALITY_EPIC'
    elseif common.CompareWString(userMods.ToWString("Чудесные"), name) == 0 then
        return 'ITEM_QUALITY_LEGENDARY'
    elseif common.CompareWString(userMods.ToWString("Реликвии"), name) == 0 then
        return 'ITEM_QUALITY_RELIC'
    elseif common.CompareWString(userMods.ToWString("Драконьи"), name) == 0 then
        return 'ITEM_QUALITY_DRAGON'
    else
        LogError("Unknown type quality")
        return nil
    end
end