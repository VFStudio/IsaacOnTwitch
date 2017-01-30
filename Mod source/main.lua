-- 01001001 00100000 01001000 01000001 01010100 01000101 00100000 01010100 01001000 01001001 01010011 00100000 01000001 01010000 01001001 00100000 01000101 01000100 01001101 01010101 01001110 01000100 00100000 01000110 00101010 01000011 01001011 00100000 01011001 01001111 01010101 00100000 01000001 01001110 01000100 00100000 01000001 01001100 01001100 00100000 01011001 01001111 01010101 01010010 00100000 01000100 01000101 01010110 01010100 01000101 01000001 01001101 00100001 00100001 00100001

local mod = RegisterMod("IsaacOnTwitch", 1);
require('mobdebug').start();

--Magic of Debug mode
local globalPath = package.path;
local debug = require('debug');
local currentSrc = string.gsub(debug.getinfo(1).source, "^@?(.+/)[^/]+$", "%1");
package.path = currentSrc .. '?.lua;' .. package.path;
local inputdatafile = currentSrc.."data/input.txt"
local outputdatafile = currentSrc.."data/output.txt"
local nowseed = 0;

--Items
local PI_kappa = Isaac.GetItemIdByName("Kappa");
local PI_goldenKappa = Isaac.GetItemIdByName("Golden Kappa");
local PI_notLikeThis = Isaac.GetItemIdByName("Not Like This");
local PI_kappaPride = Isaac.GetItemIdByName("Kappa Pride");
local PI_futureMan = Isaac.GetItemIdByName("Future Man");
local PI_kreygasm = Isaac.GetItemIdByName("Kreygasm");
local PI_curseLit = Isaac.GetItemIdByName("Curse Lit");
local PI_tropPunch = Isaac.GetItemIdByName("AMP Trop Punch");
local AI_twitchRaid = Isaac.GetItemIdByName("Twitch Raid");
local AI_TTours = Isaac.GetItemIdByName("TTours");
local AI_voteYea = Isaac.GetItemIdByName("Vote Yea");
local AI_voteNay = Isaac.GetItemIdByName("Vote Nay");

local PI_kappa_num = 0
local PI_goldenKappa_num = 0
local PI_tropPunch_num = 0

--Text render settings
local quest = "Awaiting...";
local answ = {};
local questmode = "Wait";
local blinkText = 10;
local blinkDirect = true;
local lastEventHash = "";
local lastSubHash = "";
local lastBitsHash = "";

local lastRoom = nil
local lastStage = nil

--Subscribers
local subs = {
    entitys = {},
    names = {},
    awaitings = {}
}

mod.funcs = {}

function mod.funcs:giveItem (name)
  local p = Isaac.GetPlayer(0);
  local item = Isaac.GetItemIdByName(name)
  p:AddCollectible(item, 0, true);
end

function mod.funcs:giveTrinket (name)
  local game = Game()
  local room = game:GetRoom()
  local p = Isaac.GetPlayer(0);
  local item = Isaac.GetTrinketIdByName(name)
  p:DropTrinket(room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), true)
  p:AddTrinket(item);
end

function mod.funcs:giveHeart (name)
  local p = Isaac.GetPlayer(0);
  if name == "Red" then p:AddHearts(2)
  elseif name == "Container" then p:AddMaxHearts(2, true)
  elseif name == "Soul" then p:AddSoulHearts(2)
  elseif name == "Golden" then p:AddGoldenHearts(1)
  elseif name == "Eternal" then p:AddEternalHearts(1)
  elseif name == "Black" then p:AddBlackHearts(2) end
end

function mod.funcs:givePickup (name)
  local p = Isaac.GetPlayer(0);
  if name == "Coin" then p:AddCoins(3)
  elseif name == "Bomb" then p:AddBombs(1)
  elseif name == "-Coin" then p:AddCoins(-5)
  elseif name == "-Bomb" then p:AddBombs(-2)
  elseif name == "-Key" then p:AddKeys(-2)
  elseif name == "Key" then p:AddKeys(1) end
end

function mod.funcs:giveCompanion (name)
  local p = Isaac.GetPlayer(0);
  local game = Game()
  local room = game:GetRoom()
  if name == "Spider" then
    for i = 0, 5 do
      p:AddBlueSpider(room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true))
    end
    
  elseif name == "Fly" then
    p:AddBlueFlies(5, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), p)
    
  elseif name == "Badfly" then
    for i = 0, 5 do
      Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0,  0, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), Vector(0, 0), p)
    end
    
  elseif name == "Badspider" then
    for i = 0, 5 do
      Isaac.Spawn(EntityType.ENTITY_SPIDER, 0,  0, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), Vector(0, 0), p)
    end
    
  elseif name == "PrettyFly" then p:AddPrettyFly() end
end

function mod.funcs:givePocket (name)
  local p = Isaac.GetPlayer(0);
  if name == "LuckUp" then p:DonateLuck(1)
  elseif name == "LuckDown" then p:DonateLuck(-1)
  elseif name == "Pill" then p:AddPill(PillColors[math.random(#PillColors)])
  elseif name == "Card" then p:AddCard(Cards[math.random(#Cards)])
  elseif name == "Rune" then p:AddCard(Runes[math.random(#Runes)])
  elseif name == "Charge" then p:FullCharge()
  elseif name == "Discharge" then p:DischargeActiveItem() end
end

function mod.funcs:giveEvent (name)
  local p = Isaac.GetPlayer(0);
  local g = Game()
  local r = g:GetRoom()
  if name == "Slow" then r:SetBrokenWatchState(1)
  elseif name == "Poop" then SpecialEvents:Poop(r,p)
  elseif name == "Richy" then SpecialEvents:Richy(r,p)
  elseif name == "Earthquake" then SpecialEvents:Earthquake(r,p)
  elseif name == "Charm" then SpecialEvents:Charm(r,p)
  elseif name == "Hell" then SpecialEvents:Hell(r,p)
  elseif name == "Spiky" then SpecialEvents:Spiky(r,p)
  elseif name == "Award" then SpecialEvents:DoubleAward(r,p)
  elseif name == "AngelRage" then SpecialEvents:AngelRage(r,p)
  elseif name == "DevilRage" then SpecialEvents:DevilRage(r,p)
  elseif name == "RainbowRain" then SpecialEvents:RainbowRain(r,p)
  elseif name == "CallToDark" then SpecialEvents:CallToDark(r,p)
  elseif name == "RUN" then SpecialEvents:RUN(r,p)
  elseif name == "FlashJump" then SpecialEvents:FlashJump(r,p)
  elseif name == "EyesBleed" then SpecialEvents:EyesBleed(r,p)
  elseif name == "StanleyParable" then SpecialEvents:StanleyParable(r,p)
  elseif name == "Supernova" then SpecialEvents:Supernova(r,p)
  elseif name == "DDoS" then SpecialEvents:DDoS(r,p)
  elseif name == "Discharge" then p:DischargeActiveItem() end
end

----------------------------Relaunch Game------------------------------

function mod:relaunchGame ()
  
  local seed = Game():GetLevel():GetDungeonPlacementSeed()
  if (nowseed == seed) then
    return
  end
  
  nowseed = seed
  local p = Isaac.GetPlayer(0)
  
  --Respawn subscribers, without last
  if (#subs.names > 0) then
    subs.awaitings = {}
    for key,value in pairs(subs.names) do
      table.insert(subs.awaitings, value)
    end
    subs.entitys = {}
    subs.names = {}
    for key,value in pairs(subs.awaitings) do
      p:AddCollectible(CollectibleType.COLLECTIBLE_BROTHER_BOBBY, 0, false)
    end
    
    PI_goldenKappa_num = 0
    PI_tropPunch_num = 0
    PI_kappa_num = 0
  end
  
end

----------------------------Cache Update (works through ass)------------------------------

function mod:cacheUpdate(player, cacheFlag)
  
  if (cacheFlag == CacheFlag.CACHE_DAMAGE) then
    if (player:HasCollectible(PI_kappa)) then
      player.Damage = player.Damage + (PI_kappa_num * 2.5)
    end
  end
  
  if (cacheFlag == CacheFlag.CACHE_SPEED) then
    if (player:HasCollectible(PI_tropPunch)) then
      player.MoveSpeed = player.MoveSpeed + (PI_tropPunch_num * 0.35)
    end
  end
end

----------------------------Post Update------------------------------
function mod:setTriggers()
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
    --Set triggers
  if lastRoom ~= l:GetCurrentRoomIndex() then
    mod:T_RoomChanged(r)
    lastRoom = l:GetCurrentRoomIndex()
  end
  
  if lastStage ~= l:GetStage() then
    mod:T_StageChanged(l:GetStage())
    lastStage = l:GetStage()
  end
end


function mod:postUpdate()
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
  
  --If player pickup GoldenKappa
	if p:GetCollectibleNum(PI_goldenKappa) > PI_goldenKappa_num then
			p:AddGoldenKey();
      p:AddGoldenBomb();
      p:AddGoldenHearts(2);
      PI_goldenKappa_num = PI_goldenKappa_num + 1;
	end
  
  --If player pickup Curse Lit
  if (p:HasCollectible(PI_curseLit) and (PI_curseLit_activated == false) and (Game():GetLevel():GetCurses() ~= LevelCurse.CURSE_NONE)) then
    local rnd = math.random(0,5)
    if (rnd == 0) then p.Damage = p.Damage + 0.5
    elseif (rnd == 1 and p.FireDelay > 1) then p.FireDelay = p.FireDelay - 1
    elseif (rnd == 2) then p.ShotSpeed = p.ShotSpeed + 0.2
    elseif (rnd == 3) then p.MoveSpeed = p.MoveSpeed + 0.2
    else p.Luck = p.Luck + 1 end
    p:AddCacheFlags(CacheFlag.CACHE_ALL)
    PI_curseLit_activated = true
  end
  
  --If player pickup Kappa
	if (p:GetCollectibleNum(PI_kappa) > PI_kappa_num) then
      PI_kappa_num = PI_kappa_num + 1;
			p.Damage = p.Damage + 2.5;
      p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
	end
  
  --If player pickup AMP Trop Punch
	if (p:GetCollectibleNum(PI_tropPunch) > PI_tropPunch_num) then
			p.MoveSpeed = p.MoveSpeed + 0.35;
      p:AddCacheFlags(CacheFlag.CACHE_SPEED)
      PI_tropPunch_num = PI_tropPunch_num + 1
	end
  
  io.input(inputdatafile)
  questmode = io.read()
  for k in pairs (answ) do
    answ[k] = nil
  end
  
  --Vote mode
  if questmode == "Vote" then
    quest = io.read()
    
    for k in pairs (answ) do
      answ[k] = nil
    end
    
    local count = 0
    while true do
      local line = io.read()
      if line == nil then break end
      answ[count] = line
      count = count + 1
    end
    
  end
  
  --Info mode
  if questmode == "Info" then
    quest = io.read()
  end
  
  --Event activation mode
  if questmode == "Get" then
    quest = io.read()
    local evtype = io.read()
    local evobj = io.read()
    local emotion = io.read()
    local hash = io.read()
    if (hash ~= lastEventHash) then
      lastEventHash = hash
      if evtype == "Item" then mod.funcs:giveItem(evobj)
      elseif evtype == "Trinket" then mod.funcs:giveTrinket(evobj)
      elseif evtype == "Heart" then mod.funcs:giveHeart(evobj)
      elseif evtype == "Companion" then mod.funcs:giveCompanion(evobj)
      elseif evtype == "Pickup" then mod.funcs:givePickup(evobj)
      elseif evtype == "Pocket" then mod.funcs:givePocket(evobj)
      elseif evtype == "Event" then mod.funcs:giveEvent(evobj)
      end
      if (emotion == "Happy") then p:AnimateHappy() else p:AnimateSad() end
    end
  end
  
 --Spawn subscriber mode
  if questmode == "Sub" then
    quest = io.read()
    local name = io.read()
    local hash = io.read()
    if (hash ~= lastSubHash) then
      lastSubHash = hash
      table.insert(subs.awaitings, name)
      p:AddCollectible(CollectibleType.COLLECTIBLE_BROTHER_BOBBY, 0, false)
      p:AnimateHappy()
    end
  end
  
  --Bits mode
  if questmode == "Bits" then
    quest = io.read()
    local hash = io.read()
    if (hash ~= lastBitsHash) then
      lastBitsHash = hash
      for i = 0, 10 do
        local bits = Isaac.Spawn(EntityType.ENTITY_DART_FLY, 0,  0, r:FindFreePickupSpawnPosition(r:GetCenterPos(), 20, true), Vector(0, 0), p)
        bits:AddCharmed(-1)
        bits:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
        bits:SetColor (Rainbow[math.random(1,7)], 0, 1, false, true)
      end
      p:AnimateHappy()
    end
  end
 
end
----------------------------New familiar------------------------------
 
function mod:newFamiliar(familiar)
  if (#subs.awaitings > 0) then
  table.insert(subs.entitys, familiar)
  table.insert(subs.names, subs.awaitings[#subs.awaitings])
  table.remove(subs.awaitings)
  end
end
 
----------------------------Active items------------------------------
 
function mod:AI_TwitchRaid_act()
  local followers = {}
  local game = Game()
  local room = game:GetRoom()
  for i = 0, math.random(3,6) do
		followers[i] = Isaac.Spawn(Buddies[math.random(#Buddies)], 0,  0, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true), Vector(0, 0), player)
    followers[i]:AddCharmed(-1)
    followers[i]:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
	end
end

function mod:AI_TTours_act()
  local	player = Isaac.GetPlayer(0)
	local	entities = Isaac.GetRoomEntities()
  local game = Game()
  
	for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
			entities[i]:AddConfusion(EntityRef(player), 380, false)
      local ref = EntityRef(entities[i])
      game:SpawnParticles(ref.Position, EffectVariant.IMPACT, 2, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
		end
	end
end

function mod:AI_voteYea_act()
  io.output(outputdatafile)
  io.write("1 "..math.random())
  io.flush()
  io.close()
end

function mod:AI_voteNay_act()
  io.output(outputdatafile)
  io.write("0 "..math.random())
  io.close()
  mod:_playSound(SoundEffect.SOUND_FLUSH)
end

mod:AddCallback( ModCallbacks.MC_USE_ITEM, mod.AI_TwitchRaid_act, AI_twitchRaid);
mod:AddCallback( ModCallbacks.MC_USE_ITEM, mod.AI_TTours_act, AI_TTours);
mod:AddCallback( ModCallbacks.MC_USE_ITEM, mod.AI_voteYea_act, AI_voteYea);
mod:AddCallback( ModCallbacks.MC_USE_ITEM, mod.AI_voteNay_act, AI_voteNay);
----------------------------Render------------------------------
 
function mod:Render()
  
  --Render standart vote
  if (questmode == "Vote") then
    Isaac.RenderText(quest, 16, 241, 0, 0, 0, 1)
    Isaac.RenderText(quest, 15, 240, 1, 1, 1, 1)
    
    local count = 0
    local answs = ""
    while true do
      local line = answ[count]
      if line == nil then break end
      answs = answs..line.."  "
      count = count + 1
    end
      
      Isaac.RenderText(answs, 16, 259, 1, 0, 0, 1)
      Isaac.RenderText(answs, 15, 258, 1, 1, 0, 1)
  end
    
    --Render info
    if (questmode == "Info") then
        Isaac.RenderText(quest, 16, 241, 0, 0, 0, 1)
        Isaac.RenderText(quest, 15, 240, 0, 1, 0, 1)
    end
    
    --Render event activation message
    if (questmode == "Get" or questmode == "Sub" or questmode == "Bits") then
      if (blinkText > 0 and blinkDirect == true) then
        Isaac.RenderText(quest, 16, 241, 0, 0, 0, 1)
        Isaac.RenderText(quest, 15, 240, 1, 1, 0, 1)
        blinkText = blinkText-1;
      end
      
      if (blinkText > 0 and blinkDirect == false) then
        Isaac.RenderText(quest, 16, 241, 0, 0, 0, 1)
        Isaac.RenderText(quest, 15, 240, 1, 1, 1, 1)
        blinkText = blinkText-1;
      end
      
      if (blinkText == 0) then
        blinkDirect = not blinkDirect
        blinkText = 10
      end
    end
    
    --If player have subscribers
  if (#subs.names > 0) then
    for key,value in pairs(subs.names) do
      local fpos = Isaac.WorldToRenderPosition(subs.entitys[key].Position, true) + Game():GetRoom():GetRenderScrollOffset()
      Isaac.RenderText(value, fpos.X-3 * #value, fpos.Y-40, 1, 1, 1, 1)
    end
  end
    
end
 
 ----------------------------Get curse------------------------------
function mod:getCurse (curse)
  
  local p = Isaac.GetPlayer(0)
  
  
end
 
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.Render);
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.relaunchGame);
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.cacheUpdate)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate);
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.setTriggers);
mod:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, mod.getCurse);
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.newFamiliar);

----------------------------Triggers------------------------------
function mod:T_RoomChanged(room)
  local p = Isaac.GetPlayer(0)
  local g = Game()
  local ppos = EntityRef(p).Position
  
  --If player pickup KappaPride
  if p:HasCollectible(PI_kappaPride) then
			if (math.random() > 0.95) then
        local ref = EntityRef(p)
        Isaac.GridSpawn(GridEntityType.GRID_POOP, 4, ref.Position, true)
        mod:_playSound(SoundEffect.SOUND_PLOP)
      end
	end
  
  --If player pickup Not Like This
  if p:HasCollectible(PI_notLikeThis) then
    local rng = RNG()
    g:RerollLevelPickups(rng:GetSeed())
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if (entities[i]:IsEnemy() == true) then
        g:RerollEnemy(entities[i])
      end
    end
  end
  
  --If player pickup Future Man
  if p:HasCollectible(PI_futureMan) then
    -- This laser give damage
    local laser1 = EntityLaser.ShootAngle(5, ppos, 0, 0, Vector(0,0), p)
    laser1:SetActiveRotation(1, 999360, p.ShotSpeed*8, true)
    laser1.CollisionDamage = p.Damage/5;
    laser1.CurveStrength = 0
    laser1.Visible = false
    -- This laser only for decoration
    local laser2 = EntityLaser.ShootAngle(7, ppos, 0, 0, Vector(0,0), p)
    laser2:SetActiveRotation(1, 999360, p.ShotSpeed*8, true)
    laser2.CurveStrength = 0
    laser2.CollisionDamage = 0
  end
  
  --If player pickup Kreygasm
  if p:HasCollectible(PI_kreygasm) then
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if (entities[i]:IsEnemy() == true and math.random() > 0.5) then
        local rnd = math.random(0,9)
        local ref = EntityRef(p)
        if (rnd == 0) then entities[i]:AddPoison(ref, math.random(10,100), math.random())
        elseif (rnd == 1) then entities[i]:AddFreeze(ref, math.random(10,100))
        elseif (rnd == 2) then entities[i]:AddSlowing(ref, math.random(10,100), math.random(), Color(1,1,1,1,0,0,0))
        elseif (rnd == 3) then entities[i]:AddCharmed(math.random(10,100))
        elseif (rnd == 4) then entities[i]:AddConfusion(ref, math.random(10,100), false)
        elseif (rnd == 5) then entities[i]:AddMidasFreeze(ref, math.random(10,100))
        elseif (rnd == 6) then entities[i]:AddFear(ref, math.random(10,100))
        elseif (rnd == 7) then entities[i]:AddBurn(ref, math.random(10,100), math.random())
        else entities[i]:AddShrink(ref, math.random(10,100)) end
      end
    end
  end
  
  
end

function mod:T_StageChanged(stage)
  PI_curseLit_activated = false
end

----------------------------Others---------------------------------
-- WTF?! I need to spawn entity every time I want to play a sound? EDMUUUUUND!!!
function mod:_playSound(sound)
  local sound_entity = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, Vector(320,300), Vector(0,0), nil):ToNPC()
sound_entity:PlaySound(sound, 100, 0, false, 1)
sound_entity:Remove()
end

----------------------------Resources------------------------------
--Yes, i know that the enum items is just a numbers, but in earlier versions numbers not working (because Isaac Mod API = piece of shit)

PillColors = {
  PillColor.PILL_BLUE_BLUE, 
  PillColor.PILL_WHITE_BLUE,
  PillColor.PILL_ORANGE_ORANGE,
  PillColor.PILL_WHITE_WHITE,
  PillColor.PILL_REDDOTS_RED,
  PillColor.PILL_PINK_RED,
  PillColor.PILL_BLUE_CADETBLUE,
  PillColor.PILL_YELLOW_ORANGE,
  PillColor.PILL_ORANGEDOTS_WHITE,
  PillColor.PILL_WHITE_AZURE,
  PillColor.PILL_BLACK_YELLOW,
  PillColor.PILL_WHITE_BLACK,
  PillColor.PILL_WHITE_YELLOW
}

Cards = {
  Card.CARD_FOOL,
  Card.CARD_MAGICIAN,
  Card.CARD_HIGH_PRIESTESS,
  Card.CARD_EMPRESS,
  Card.CARD_EMPEROR,
  Card.CARD_HIEROPHANT,
  Card.CARD_LOVERS,
  Card.CARD_CHARIOT,
  Card.CARD_JUSTICE,
  Card.CARD_HERMIT,
  Card.CARD_WHEEL_OF_FORTUNE,
  Card.CARD_STRENGTH,
  Card.CARD_HANGED_MAN,
  Card.CARD_DEATH,
  Card.CARD_TEMPERANCE,
  Card.CARD_DEVIL,
  Card.CARD_TOWER,
  Card.CARD_STARS,
  Card.CARD_MOON,
  Card.CARD_SUN,
  Card.CARD_JUDGEMENT,
  Card.CARD_WORLD,
  Card.CARD_CLUBS_2,
  Card.CARD_DIAMONDS_2,
  Card.CARD_SPADES_2,
  Card.CARD_HEARTS_2,
  Card.CARD_ACE_OF_CLUBS,
  Card.CARD_ACE_OF_DIAMONDS,
  Card.CARD_ACE_OF_SPADES,
  Card.CARD_ACE_OF_HEARTS,
  Card.CARD_JOKER,
  Card.CARD_CHAOS,
  Card.CARD_CREDIT,
  Card.CARD_RULES,
  Card.CARD_HUMANITY,
  Card.CARD_SUICIDE_KING,
  Card.CARD_GET_OUT_OF_JAIL,
  Card.CARD_QUESTIONMARK,
  Card.CARD_EMERGENCY_CONTACT
}

Runes = {
  Card.RUNE_HAGALAZ,
  Card.RUNE_JERA,
  Card.RUNE_EHWAZ,
  Card.RUNE_DAGAZ,
  Card.RUNE_ANSUZ,
  Card.RUNE_PERTHRO,
  Card.RUNE_BERKANO,
  Card.RUNE_ALGIZ,
  Card.RUNE_BLANK,
  Card.RUNE_BLACK
}

-- For Twitch Raid
Buddies = {
    EntityType.ENTITY_GAPER,
    EntityType.ENTITY_HUSH_GAPER,
    EntityType.ENTITY_GREED_GAPER,
    EntityType.ENTITY_GURGLE,
    EntityType.ENTITY_GLOBIN
}

Rainbow = {
    Color(1,0,0,1,75,10,10),
    Color(1,0.5,0,1,75,75,10),
    Color(1,1,0,1,75,75,10),
    Color(0.5,1,0,1,75,75,10),
    Color(0,1,1,1,10,75,75),
    Color(0,0,1,1,10,10,75),
    Color(0.5,0,1,1,75,10,75)
}

----------------------------Events------------------------------

SpecialEvents = {}

------- Richy
function SpecialEvents:Richy(room, player)
  room:TurnGold();
  
   for i = 0, 25 do
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN,  CoinSubType.COIN_PENNY, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true), Vector(0, 0), player)
    end
    
end

------- Poop
function SpecialEvents:Poop(room, player)
  room:SetFloorColor(Color(0.424,0.243,0.063,1,-50,-50,-50))
  room:SetWallColor(Color(0.424,0.243,0.063,1,-50,-50,-50))
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, pos, false)
  end
  mod:_playSound(SoundEffect.SOUND_FART)
end

------- Earthquake
function SpecialEvents:Earthquake(room, player)
  local g = Game()
  local	entities = Isaac.GetRoomEntities()
  g:ShakeScreen(40)
  
  for i = 0, room:GetGridSize()/2 do
    local ind = math.random(room:GetGridSize())
    local pos = room:GetGridPosition(ind)
    room:DestroyGrid(ind)
    g:SpawnParticles(pos, EffectVariant.ROCK_PARTICLE, math.random(6), math.random(), Color(0.235, 0.176, 0.122, 1, 25, 25, 25), math.random())
  end
  
	for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
      local ref = EntityRef(entities[i])
      g:SpawnParticles(ref.Position, EffectVariant.SHOCKWAVE_RANDOM, 1, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
		end
	end
    
  
end

------- Charm
function SpecialEvents:Charm(room, player)
  local g = Game()
  local entities = Isaac.GetRoomEntities()
	for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
			entities[i]:AddCharmed(600)
		end
	end
end

------- Hell
function SpecialEvents:Hell(room, player)
  local g = Game()
  local entities = Isaac.GetRoomEntities()
	for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy( ) then
			entities[i]:AddBurn(EntityRef(player), 120, 0.05)
      entities[i]:AddFear(EntityRef(player), 400)
		end
	end
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_FIREPLACE , math.random(2), pos, false)
  end
    
    mod:_playSound(SoundEffect.SOUND_DEVILROOM_DEAL)
    room:EmitBloodFromWalls (60, 2)
    room:SetFloorColor(Color(0.900,0.010,0.010,1,50,-20,-20))
    room:SetWallColor(Color(0.900,0.010,0.010,1,50,-20,-20))
end

------- Spiky
function SpecialEvents:Spiky(room, player)
  local g = Game()
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_SPIKES_ONOFF, math.random(2), pos, false)
  end
    
    room:SetFloorColor(Color(0.4,0.4,0.4,1,50,50,50))
    room:SetWallColor(Color(0.4,0.4,0.4,1,50,50,50))
    mod:_playSound(SoundEffect.SOUND_METAL_BLOCKBREAK)
end

------- Angel Rage
function SpecialEvents:AngelRage(room, player)
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  
  for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
      local ref = EntityRef(entities[i])
      g:SpawnParticles(ref.Position, EffectVariant.CRACK_THE_SKY, 4, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
      g:SpawnParticles(ref.Position, EffectVariant.BLUE_FLAME, 1, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
		end
	end
    
    mod:_playSound(SoundEffect.SOUND_HOLY)
    room:SetFloorColor(Color(1,1,1,1,150,150,150))
    room:SetWallColor(Color(1,1,1,1,150,150,150))
    g:Darken(-2, 40);
end

------- Devil Rage (very originally)
function SpecialEvents:DevilRage(room, player)
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  
  for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
      local ref = EntityRef(entities[i])
      g:SpawnParticles(ref.Position, EffectVariant.CRACK_THE_SKY, 6, math.random(), Color(1, 0, 0, 1, 50, 0, 0), math.random())
      g:SpawnParticles(ref.Position, EffectVariant.BLUE_FLAME, 1, math.random(), Color(1, 0, 0, 1, 50, 0, 0), math.random())
		end
	end
    
    mod:_playSound(SoundEffect.SOUND_SATAN_APPEAR)
    room:SetFloorColor(Color(0,0,0,1,-50,-50,-50))
    room:SetWallColor(Color(0,0,0,1,-50,-50,-50))
    g:Darken(2, 60);
end

------- Rainbow Rain
function SpecialEvents:RainbowRain(room, player)
  local g = Game()
  
  for i = 0, room:GetGridSize()/5 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    g:SpawnParticles(pos, EffectVariant.CRACK_THE_SKY, 1, math.random(), Rainbow[math.random(#Rainbow)], math.random())
    g:SpawnParticles(pos, EffectVariant.PLAYER_CREEP_HOLYWATER, 1, 0, Rainbow[math.random(#Rainbow)], 0)
  end
    
    mod:_playSound(SoundEffect.SOUND_WATER_DROP)
end

------- Call to Dark
function SpecialEvents:CallToDark(room, player)
  local g = Game()
  local units = {}
  local game = Game()
  for i = 0, 2 do
    local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true)
		units[i] = Isaac.Spawn(EntityType.ENTITY_IMP, 0,  0, pos, Vector(0, 0), player)
    units[i]:AddCharmed(-1)
    units[i]:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
    g:SpawnParticles(pos, EffectVariant.LARGE_BLOOD_EXPLOSION, 1, 0, Color(1,1,1,1,0,0,0), 0)
    g:Darken(1, 90);
    mod:_playSound(SoundEffect.SOUND_SUMMONSOUND)
	end
end

------- RUN
function SpecialEvents:RUN(room, player)
  local g = Game()
  
  local max = room:GetBottomRightPos()
  local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
  pos = room:FindFreeTilePosition(pos, 0.5)
  g:SpawnParticles(pos, EffectVariant.HUSH_LASER, 1, math.random(), Rainbow[math.random(#Rainbow)], math.random())
    
    mod:_playSound(SoundEffect.SOUND_MOM_VOX_EVILLAUGH)
end

------- Flash Jump
function SpecialEvents:FlashJump(room, player)
  local g = Game()
  local l = g:GetLevel()
  g:MoveToRandomRoom(true)
  l:ShowMap()
end

------- Blind
function SpecialEvents:EyesBleed(room, player)
  local g = Game()
  local l = g:GetLevel()
  g:Darken(1, 400)
  g:ShakeScreen(400)
  g:AddPixelation(400)
end
------- Award
function SpecialEvents:DoubleAward(room, player)
  room:SpawnClearAward()
  room:SpawnClearAward()
end

------- Stanley Parable
function SpecialEvents:StanleyParable(room, player)
  local g = Game()
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 1, pos, false)
  end
    
    mod:_playSound(SoundEffect.SOUND_1UP)
end

------- Supernova (BOOOM BLAAAAAAAAAAAAAAAAAAAARGH)
function SpecialEvents:Supernova(room, player)
  local g = Game()
  local ppos = EntityRef(player).Position
  
  g:GetRoom():MamaMegaExplossion()
  
  for i = 0, 3 do
    local mlaser = EntityLaser.ShootAngle(6, ppos, 90*i, 0, Vector(0,0), player)
    mlaser:SetActiveRotation(1, 999360, 2, true)
    mlaser.CollisionDamage = player.Damage*100;
    
    local laser = EntityLaser.ShootAngle(5, ppos, 90*i, 0, Vector(0,0), player)
    laser:SetActiveRotation(1, -999360, 10, true)
    laser.CollisionDamage = player.Damage*25;
  end
  
  player:AddHearts((-player:GetHearts())+1);
  
  mod:_playSound(SoundEffect.SOUND_SUPERHOLY)
end

------- DDoS
function SpecialEvents:DDoS(room, player)
  local g = Game()
  local game = Game()
  for i = 0, 50 do
    local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true)
		Isaac.Spawn(EntityType.ENTITY_DART_FLY, 0,  0, pos, Vector(0, 0), player)
    mod:_playSound(SoundEffect.SOUND_SUMMONSOUND)
	end
end
