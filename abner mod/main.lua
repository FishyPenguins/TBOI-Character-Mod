local mod = RegisterMod("abner mod", 1)

-- ITEM IDS
local items = {
    damagePotion = Isaac.GetItemIdByName("Damage Potion"),
    blueLover    = Isaac.GetItemIdByName("Blue Lover"),
    bigRedButton = Isaac.GetItemIdByName("Big Red Button"),
    recruit      = Isaac.GetItemIdByName("Recruit"),
    holyOutburst = Isaac.GetItemIdByName("Holy Outburst"),
    reversal     = Isaac.GetTrinketIdByName("The Reversal"),
    gabriel      = Isaac.GetPlayerTypeByName("Gabriel", false),
    gabrielB     = Isaac.GetPlayerTypeByName("Gabriel", true)
}

-- Vanilla IDs
local SKATOLE = 9
local INFESTATION = 148
local HIVE_MIND = 248
local GUPPY_HEAD = 145
local BEST_FRIEND = 136

local blueFamiliarCount = 0

-- 1. INSTANT STAT UPDATE: Forces damage to change mid-room based on fly/spider count
function mod:OnUpdate()
    if not Game():GetRoom() then return end
    
    local count = 0
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
        local ent = entities[i]
        if ent and ent.Type == EntityType.ENTITY_FAMILIAR and 
           (ent.Variant == FamiliarVariant.BLUE_FLY or ent.Variant == FamiliarVariant.BLUE_SPIDER) then
            count = count + 1
        end
    end

    if count ~= blueFamiliarCount then
        blueFamiliarCount = count
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            if p then 
                p:AddCacheFlags(CacheFlag.CACHE_DAMAGE) 
                p:EvaluateItems() 
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnUpdate)

-- 2. CACHE EVALUATION: Handles Damage and Tears math
function mod:EvaluateCache(player, flag)
    if not player then return end

    if flag == CacheFlag.CACHE_DAMAGE then
        -- Blue Lover multiplier
        if player:HasCollectible(items.blueLover) then
            player.Damage = player.Damage * (1 + (blueFamiliarCount * 0.1))
        end

        -- Skatole bonus
        if player:HasCollectible(SKATOLE) then
            player.Damage = player.Damage + (blueFamiliarCount * 0.2)
        end

        -- Gabriel Base Damage adjustment
        if items.gabriel ~= -1 and player:GetPlayerType() == items.gabriel then
            player.Damage = math.max(0.1, player.Damage - 1.0)
        end
    end

    if flag == CacheFlag.CACHE_FIREDELAY and player:GetPlayerType() == items.gabriel then
        player.MaxFireDelay = player.MaxFireDelay - 3
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

-- 3. CHARACTER INITIALIZATION: Starting items and costumes
function mod:OnInit(player)
    if not player then return end
    local pType = player:GetPlayerType()

    if items.gabriel ~= -1 and pType == items.gabriel then
        if Game():GetFrameCount() == 0 then
            player:AddCollectible(items.recruit)
            player:AddCollectible(items.blueLover)
            if items.reversal ~= -1 then player:AddTrinket(items.reversal) end
        end

        local hair = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
        local stole = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")
        if hair ~= -1 then player:AddNullCostume(hair) end
        if stole ~= -1 then player:AddNullCostume(stole) end
    end

    if items.gabrielB ~= -1 and pType == items.gabrielB then
        if Game():GetFrameCount() == 0 then
            player:SetPocketActiveItem(items.holyOutburst, ActiveSlot.SLOT_POCKET, true)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnInit)

-- 4. VANILLA MODIFICATIONS & CUSTOM ITEMS

-- Best Friend Holy Water Creep FIX (Targeting the correct Familiar Variant)
function mod:OnBestFriendUpdate(familiar)
    if familiar.Variant == FamiliarVariant.ISAACS_HEAD then
        if familiar.FrameCount % 15 == 0 then 
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER, 0, familiar.Position, Vector.Zero, familiar):ToEffect()
            if creep then 
                creep.Scale = 1.5 
                creep:SetTimeout(40)
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.OnBestFriendUpdate, FamiliarVariant.ISAACS_HEAD)

-- Recruit Item Logic
function mod:RecruitUse(_, rng, player)
    local spawnCount = rng:RandomInt(5) + 1
    for i = 1, spawnCount do
        local variant = (rng:RandomInt(2) == 0) and FamiliarVariant.BLUE_FLY or FamiliarVariant.BLUE_SPIDER
        Isaac.Spawn(EntityType.ENTITY_FAMILIAR, variant, 0, player.Position, Vector.Zero, player)
    end
    return { Discharge = true, ShowAnim = true }
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RecruitUse, items.recruit)

-- Guppy's Head Modification (Guaranteed Min 4, Max 7)
function mod:OnGuppyHead(_, rng, player)
    local spawnCount = rng:RandomInt(4) + 4
    player:AddBlueFlies(spawnCount, player.Position, player)
    return { Discharge = true, ShowAnim = true }
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnGuppyHead, GUPPY_HEAD)

-- Hive Mind: 100% Spider Spawn on Room Clear
function mod:OnRoomClear()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(HIVE_MIND) then
            player:AddBlueSpider(player.Position)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.OnRoomClear)