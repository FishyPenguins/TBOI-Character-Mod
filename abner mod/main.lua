----all help from TBOI Repentence Mod Tutorials: 
---https://www.youtube.com/playlist?list=PLkIbky8_pFUpqAF9l7dh_YsEV-zpJ4q50 By 'catinsurance'

local mod = RegisterMod("abner mod", 1)
local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local damagePotionDamage = 2

function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(damagePotion)
        if itemCount > 0 then
            local damageToAdd = damagePotionDamage * itemCount
            player.Damage = player.Damage + damageToAdd
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

local bigRedButton = Isaac.GetItemIdByName("Big Red Button")

function mod:RedButtonUse(item)
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            entity:Kill()
        end
    end

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, bigRedButton)