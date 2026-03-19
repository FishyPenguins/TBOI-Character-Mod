----all help from TBOI Repentence Mod Tutorials: 
---https://www.youtube.com/playlist?list=PLkIbky8_pFUpqAF9l7dh_YsEV-zpJ4q50 By 'catinsurance'

local mod = RegisterMod("abner mod", 1)
local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local blueLover    = Isaac.GetItemIdByName("Blue Lover")
local bigRedButton = Isaac.GetItemIdByName("Big Red Button")
local recruit      = Isaac.GetItemIdByName("Recruit")
local damagePotionDamage = 2

function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(damagePotion)
        if itemCount > 0 then
            local damageToAdd = damagePotionDamage * itemCount
            player.Damage = player.Damage + damageToAdd
        end

        local blueLoverCount = player:GetCollectibleNum(blueLover)
        if blueLoverCount > 0 then
            local blueFamiliarCount = 0
            local roomEntities = Isaac.GetRoomEntities()
            for _, entity in ipairs(roomEntities) do
                if entity.Type == EntityType.ENTITY_FAMILIAR and
                   (entity.Variant == FamiliarVariant.BLUE_FLY or entity.Variant == FamiliarVariant.BLUE_SPIDER) then
                    blueFamiliarCount = blueFamiliarCount + 1
                end
            end
            if blueFamiliarCount > 0 then
                local damageMultiplier = 1 + (blueFamiliarCount * 0.1)  -- 10% per blue familiar
                player.Damage = player.Damage * damageMultiplier
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)


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

function mod:RecruitUse(item, rng, player, flags, slot)
    local spawnCount = rng:RandomInt(5) + 1
    for i = 1, spawnCount do
        local offset = Vector(rng:RandomFloat() * 40 - 20, rng:RandomFloat() * 40 - 20)
        local velocity = Vector(rng:RandomFloat() * 4 - 2, rng:RandomFloat() * 4 - 2)

        if rng:RandomInt(2) == 0 then
            Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, 0, player.Position + offset, velocity, player)
        else
            Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_SPIDER, 0, player.Position + offset, velocity, player)
        end
    end

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end


mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, bigRedButton)
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RecruitUse, recruit)