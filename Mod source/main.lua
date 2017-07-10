-- Before you start reading the source code, I want to say - i really hate this API. It's absolutely shit. Documentation? No, fuck you! Stability? Fuck out! JUST NORMAL WORK? No, take this over9000 bugs and fuck off! It's most ugly thing, with that I had to work. Good job, Isaac DevTeam. Thank you from community.

local IOTmod = RegisterMod("IsaacOnTwitch", 1);
local require = require;
require('mobdebug').start();
local json = require('json');

--Magic of Debug mode
local globalPath = package.path;
local debug = require('debug');
local currentSrc = string.gsub(debug.getinfo(1).source, "^@?(.+/)[^/]+$", "%1")
package.path = currentSrc .. '?.lua;' .. package.path;
local inputdatafile = currentSrc.."data/input1.txt"
local outputdatafile = currentSrc.."data/output1.txt"
local inputparamfile = currentSrc.."data/input2.txt"
local outputparamfile = currentSrc.."data/output2.txt"
local nowseed = 0;

--Multiroom/Time-based events
local TEventStorage = {}
local TEvent = {}
local TEventActive = false

function TEvent:new (duration, ontime, trc, ontrigger, onover)
  local obj= {}
  obj.duration = duration
  obj.ontime = ontime
  obj.trc = trc
  obj.ontrigger = ontrigger
  obj.onover = onover
  
  
  setmetatable(obj, self)
  self.__index = self; return obj
end

-- Bits temporary effect timers
local bitsTime = {
  gray = {
    enable = false,
    frames = 0
  },
  
  purple = {
    enable = false,
    frames = 0
  },
  
  green = {
    enable = false,
    frames = 0
  },
  
  blue = {
    enable = false,
    frames = 0
  },
  
  red = {
    enable = false,
    frames = 0
  }
}

-- UI Sprites
local allowrender = true

local UISpriteStorage = {}
local SpriteEventActive = Sprite()
local SpriteGrayBitsActive = Sprite()
local SpritePurpleBitsActive = Sprite()
local SpriteGreenBitsActive = Sprite()
local SpriteBlueBitsActive = Sprite()
local SpriteRedBitsActive = Sprite()

SpriteEventActive:Load("gfx/ui/mod.twitch_uieffects.anm2", true)
SpriteGrayBitsActive:Load("gfx/ui/mod.twitch_uieffects.anm2", true)
SpritePurpleBitsActive:Load("gfx/ui/mod.twitch_uieffects.anm2", true)
SpriteGreenBitsActive:Load("gfx/ui/mod.twitch_uieffects.anm2", true)
SpriteBlueBitsActive:Load("gfx/ui/mod.twitch_uieffects.anm2", true)
SpriteRedBitsActive:Load("gfx/ui/mod.twitch_uieffects.anm2", true)

SpriteEventActive:Play("Event", true)
SpriteGrayBitsActive:Play("Gray", true)
SpritePurpleBitsActive:Play("Purple", true)
SpriteGreenBitsActive:Play("Green", true)
SpriteBlueBitsActive:Play("Blue", true)
SpriteRedBitsActive:Play("Red", true)

--Entities
local E_BitsA = Isaac.GetEntityVariantByName ("Bits A")
local E_BitsB = Isaac.GetEntityVariantByName ("Bits B")
local E_BitsC = Isaac.GetEntityVariantByName ("Bits C")
local E_BitsD = Isaac.GetEntityVariantByName ("Bits D")
local E_BitsE = Isaac.GetEntityVariantByName ("Bits E")
local SpriteTwitchBlackHole = Isaac.GetEntityTypeByName ("Twitch Black Hole")

--Data IO
local IOLink = {
  
    -- To program
    Output = {
        Data = {
            interrupt = -1,
            interruptHash = ""
        },
        
        Param = {
            pause = true,
            runcount = 0,
            stats = {
              luck = 0
            }
        }
    },
    
    -- From program
    Input = {
        Data = {
            emode = 2,
            text = "Run TwitchToIsaac for start!",
            secondtext = "",
            etype = nil,
            eobj = nil,
            happy = false,
            hash = ""
        },
        
        Param = {
            viewers = 0,
            textparam = {
                firstline = {
                    x = 16,
                    y = 241
                },
                
                secondline = {
                    x = 16,
                    y = 259
                }
            },
            subdel = 10*60*30,
            gift = nil
        }
    }
}

--Items and trinkets
local PI_kappa = Isaac.GetItemIdByName("Kappa")
local PI_goldenKappa = Isaac.GetItemIdByName("Golden Kappa")
local PI_notLikeThis = Isaac.GetItemIdByName("Not Like This")
local PI_kappaPride = Isaac.GetItemIdByName("Kappa Pride")
local PI_futureMan = Isaac.GetItemIdByName("Future Man")
local PI_kreygasm = Isaac.GetItemIdByName("Kreygasm")
local PI_curseLit = Isaac.GetItemIdByName("Curse Lit")
local PI_tropPunch = Isaac.GetItemIdByName("AMP Trop Punch")
local PI_bcouch = Isaac.GetItemIdByName("BCouch")
local PI_brainSlug = Isaac.GetItemIdByName("Brain Slug")
local AI_twitchRaid = Isaac.GetItemIdByName("Twitch Raid")
local AI_TTours = Isaac.GetItemIdByName("TTours")
local AI_voteYea = Isaac.GetItemIdByName("Vote Yea")
local AI_voteNay = Isaac.GetItemIdByName("Vote Nay")
local AI_gowskull = Isaac.GetItemIdByName("GOW Skull")
local AI_DEBUG = Isaac.GetItemIdByName("DEBUG ITEM")
local FI_subscriber = Isaac.GetItemIdByName("Subscriber")
local FI_nightbot = Isaac.GetItemIdByName("Nightbot")
local FI_stinkyCheese = Isaac.GetItemIdByName("Stinky Cheese")

local TI_neonomi = Isaac.GetTrinketIdByName ("Neonomi glasses")
local TI_smite = Isaac.GetTrinketIdByName ("Smite yoshi")
local TI_hutts = Isaac.GetTrinketIdByName ("Hutts hairstyle")
local TI_tijoe = Isaac.GetTrinketIdByName ("Tijoe head")
local TI_junkey = Isaac.GetTrinketIdByName ("Junkey bunny")
local TI_grizzly = Isaac.GetTrinketIdByName ("Grizzly claw")
local TI_hellyeah = Isaac.GetTrinketIdByName ("HellYeah Rage")
local TI_vitecp = Isaac.GetTrinketIdByName ("VitecP UC")

local PI_kappa_num = 0
local PI_goldenKappa_num = 0
local PI_tropPunch_num = 0
local FI_subscriber_num = 0
local FI_stinky_have = false
local FI_nightbot_have = false

local TI_neonomi_active = false

--Sounds
local SND_bitsAppear = Isaac.GetSoundIdByName ("BitsAppear")
local SND_bitsCollect = Isaac.GetSoundIdByName ("BitsCollect")
local SND_superhotBreak = Isaac.GetSoundIdByName ("SuperhotBreak")
local SND_rewind = Isaac.GetSoundIdByName ("Rewind")
local SND_goodMusic = Isaac.GetSoundIdByName ("GoodMusic")
local SND_ddosDialup = Isaac.GetSoundIdByName ("DdosDialup")
local SND_attackOnTitan = Isaac.GetSoundIdByName ("AttackOnTitan")
local SND_interstellar = Isaac.GetSoundIdByName ("Interstellar")

--Challenges
local CH_twitchPower = Isaac.GetChallengeIdByName("Twitch Power")

local CH_twitchPowerMode = false

local statStorage = {
  speed = 0,
  range = 0,
  tears = 0,
  tearspeed = 0,
  damage = 0,
  luck = 0
}

local twitchHearts = 0
local twitchHeartFullSprite = Sprite()
local twitchHeartHalfSprite = Sprite()
local twitchHeartInv = 0

twitchHeartFullSprite:Load("gfx/ui/ui_hearts.anm2", true)
twitchHeartFullSprite:Play("TwitchHeartFull", false)

twitchHeartHalfSprite:Load("gfx/ui/ui_hearts.anm2", true)
twitchHeartHalfSprite:Play("TwitchHeartHalf", false)

--Text render settings
local blinkText = 10;
local blinkDirect = true

local lastEventHash = ""
local lastSubHash = ""
local lastBitsHash = ""

local lastRoom = nil
local lastStage = nil

local twitchRoomGenOnStage = false
local twitchRoomIndex = -999
local twitchRoomItemPool = {}

--Subscribers
local Subscriber = {}

function Subscriber:new (entity, name)
  local obj= {}
  obj.entity = entity
  obj.name = name
  obj.time = IOLink.Input.Param.subdel
  obj.color = nil
  
  setmetatable(obj, self)
  self.__index = self; return obj
end

local subs = {}

--Familars storage. Beacuse Mod API. Because shit.
local fams = {}



IOTmod.funcs = {}

function IOTmod.funcs:giveItem (name)
  local p = Isaac.GetPlayer(0);
  local item = Isaac.GetItemIdByName(name)
  p:AddCollectible(item, 0, true);
end

function IOTmod.funcs:giveTrinket (name)
  local game = Game()
  local room = game:GetRoom()
  local p = Isaac.GetPlayer(0);
  local item = Isaac.GetTrinketIdByName(name)
  p:DropTrinket(room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), true)
  p:AddTrinket(item);
end

function IOTmod.funcs:giveHeart (name)
  local p = Isaac.GetPlayer(0);
  if name == "Red" then p:AddHearts(2)
  elseif name == "Container" then p:AddMaxHearts(2, true)
  elseif name == "Soul" then p:AddSoulHearts(2)
  elseif name == "Golden" then p:AddGoldenHearts(1)
  elseif name == "Eternal" then p:AddEternalHearts(1)
  elseif name == "Twitch" then
    if ( p:GetSoulHearts() % 2 == 1) then
      p:AddSoulHearts(1)
      twitchHearts = twitchHearts + 1;
    else
      twitchHearts = twitchHearts + 2;
    end
  elseif name == "Black" then p:AddBlackHearts(2) end
end

function IOTmod.funcs:givePickup (name)
  local p = Isaac.GetPlayer(0);
  if name == "Coin" then p:AddCoins(IOLink.Input.Data.count)
  elseif name == "Bomb" then p:AddBombs(IOLink.Input.Data.count)
  elseif name == "Key" then p:AddKeys(IOLink.Input.Data.count) end
end

function IOTmod.funcs:giveCompanion (name)
  local p = Isaac.GetPlayer(0);
  local game = Game()
  local room = game:GetRoom()
  if name == "Spider" then
    for i = 0, 5 do
      p:AddBlueSpider(room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true))
    end
    
  elseif name == "Fly" then
    p:AddBlueFlies(5, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), p)
    
  elseif name == "BadFly" then
    for i = 0, 5 do
      Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0,  0, room:GetCenterPos(), Vector(0, 0), p)
    end
    
  elseif name == "BadSpider" then
    for i = 0, 5 do
      Isaac.Spawn(EntityType.ENTITY_SPIDER, 0,  0, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), Vector(0, 0), p)
    end
    
  elseif name == "PrettyFly" then p:AddPrettyFly() end
end

function IOTmod.funcs:givePocket (name)
  local p = Isaac.GetPlayer(0);
  if name == "LuckUp" then p:DonateLuck(1)
  elseif name == "LuckDown" then p:DonateLuck(-1)
  elseif name == "Pill" then p:AddPill(PillColors[math.random(#PillColors)])
  elseif name == "Card" then p:AddCard(Cards[math.random(#Cards)])
  elseif name == "Rune" then p:AddCard(Runes[math.random(#Runes)])
  elseif name == "Spacebar" and p:GetActiveItem() ~= CollectibleType.COLLECTIBLE_NULL then p:UseActiveItem (p:GetActiveItem(), true, true, true, true)
  elseif name == "Charge" then p:FullCharge()
  elseif name == "Discharge" then p:DischargeActiveItem() end
end

function IOTmod.funcs:giveEvent (name)
  SpecialEvents[name]()
end

----------------------------Cache Update (works through ass)------------------------------

function IOTmod:cacheUpdate(player, cacheFlag)
  
  if (cacheFlag == CacheFlag.CACHE_DAMAGE) then
      player.Damage = player.Damage + statStorage.damage
  
  elseif (cacheFlag == CacheFlag.CACHE_FIREDELAY) then
      player.FireDelay = player.FireDelay + statStorage.tears
      
  elseif (cacheFlag == CacheFlag.CACHE_SHOTSPEED) then
      player.ShotSpeed = player.ShotSpeed + statStorage.tearspeed
      
  elseif (cacheFlag == CacheFlag.CACHE_SPEED) then
      player.MoveSpeed = player.MoveSpeed + statStorage.speed
  
  elseif (cacheFlag == CacheFlag.CACHE_LUCK) then
      player.Luck = player.Luck + statStorage.luck
      
  elseif (cacheFlag == CacheFlag.CACHE_ALL) then
    player.Damage = player.Damage + statStorage.damage
    player.FireDelay = player.FireDelay + statStorage.tears
    player.ShotSpeed = player.ShotSpeed + statStorage.tearspeed
    player.MoveSpeed = player.MoveSpeed + statStorage.speed
    player.Luck = player.Luck + statStorage.luck
  end
  
end

----------------------------Post Update------------------------------
function IOTmod:setTriggers()
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
    --Set triggers
  
  if lastRoom ~= l:GetCurrentRoomIndex() then
    lastRoom = l:GetCurrentRoomIndex()
    IOTmod:T_RoomChanged(r)
  end
  
  if g:GetFrameCount() == 1 then
    IOTmod:relaunchGame(p)
  end
  
  if lastStage ~= l:GetStage() then
    IOTmod:T_StageChanged(l:GetStage())
    lastStage = l:GetStage()
  end
end


function IOTmod:postUpdate()
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
  local s = SFXManager()
  
  --Check invincible from Twitch Heart
  if (twitchHeartInv > 0) then
    twitchHeartInv = twitchHeartInv - 1
  end
  
  --Remove old subscribers
  if (not CH_twitchPowerMode) then
    for k, v in pairs(subs) do
      if (subs[k].time > 0) then
        subs[k].time = subs[k].time - 1
      else
        local v = math.random(1,4)*10
        Isaac.Spawn(EntityType.ENTITY_PICKUP, v,  0, subs[k].entity.Position, Vector(0, 0), p)
        g:SpawnParticles(subs[k].entity.Position, EffectVariant.GOLD_PARTICLE, 10, 0, subs[k].entity.Color, 0)
        subs[k].entity:Die()
        subs[k] = nil
      end
    end
  end
  
  --Set subscribers and familiars pos
  local lastFamPos = p.Position
  for k, v in pairs(subs) do
    subs[k].entity:FollowPosition(lastFamPos)
    lastFamPos = subs[k].entity.Position
  end
  
  for k, v in pairs(fams) do
    fams[k]:FollowPosition(lastFamPos)
    lastFamPos = fams[k].Position
  end
  
  --Check TwitchHeart overflow
  if ((p:GetMaxHearts() + p:GetSoulHearts() + twitchHearts) /2 > 12) then
    twitchHearts = (12 - (p:GetMaxHearts() + p:GetSoulHearts())/2)*2
  end
  
  --Check bits
  if (bitsTime.gray.enable) then
    if (bitsTime.gray.frames <= 0) then
      bitsTime.gray.enable = false
    else
      bitsTime.gray.frames = bitsTime.gray.frames - 1
      if (math.random(1,35) == 1) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) then
        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*10, p:GetShootingInput().Y*10), p):ToTear()
        t:ChangeVariant(TearVariant.METALLIC)
        t.TearFlags = setbit(t.TearFlags, bit(1))
        t.TearFlags = setbit(t.TearFlags, bit(2))
      end
    end
  end
  
  if (bitsTime.purple.enable) then
    if (bitsTime.purple.frames <= 0) then
      bitsTime.purple.enable = false
    else
      bitsTime.purple.frames = bitsTime.purple.frames - 1
      if (math.random(1,30) == 1) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) then
        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*10, p:GetShootingInput().Y*10), p):ToTear()
        t:ChangeVariant(TearVariant.METALLIC)
        t:SetColor(Color(0.741, 0.388, 1, 1, 37, 19, 50), 0, 0, false, false)
        t.TearFlags = setbit(t.TearFlags, bit(3))
        t.TearFlags = setbit(t.TearFlags, bit(21))
      end
    end
  end
  
  if (bitsTime.green.enable) then
    if (bitsTime.green.frames <= 0) then
      bitsTime.green.enable = false
    else
      bitsTime.green.frames = bitsTime.green.frames - 1
      if (math.random(1,25) == 1) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) then
        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*10, p:GetShootingInput().Y*10), p):ToTear()
        t:ChangeVariant(TearVariant.METALLIC)
        t:SetColor(Color(0.004, 0.898, 0.659, 1, 0, 44, 32), 0, 0, false, false)
        t.TearFlags = setbit(t.TearFlags, bit(5))
        t.TearFlags = setbit(t.TearFlags, bit(40))
        t.TearFlags = setbit(t.TearFlags, bit(44))
        t.TearFlags = setbit(t.TearFlags, bit(20))
      end
    end
  end
  
  if (bitsTime.blue.enable) then
    if (bitsTime.blue.frames <= 0) then
      bitsTime.blue.enable = false
    else
      bitsTime.blue.frames = bitsTime.blue.frames - 1
      if (math.random(1,20) == 1) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) then
        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*10, p:GetShootingInput().Y*10), p):ToTear()
        t:ChangeVariant(TearVariant.METALLIC)
        t:SetColor(Color(0.149, 0.416, 0.804, 1, 7, 20, 40), 0, 0, false, false)
        t.TearFlags = setbit(t.TearFlags, bit(18))
        t.TearFlags = setbit(t.TearFlags, bit(33))
      end
    end
  end
  
  if (bitsTime.red.enable) then
    if (bitsTime.red.frames <= 0) then
      bitsTime.red.enable = false
    else
      bitsTime.red.frames = bitsTime.red.frames - 1
      if (math.random(1,15) == 1) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) then
        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*10, p:GetShootingInput().Y*10), p):ToTear()
        t:ChangeVariant(TearVariant.METALLIC)
        t:SetColor(Color(0.988, 0.345, 0.306, 1, 49, 17, 15), 0, 0, false, false)
        t.TearFlags = setbit(t.TearFlags, bit(10))
        t.TearFlags = setbit(t.TearFlags, bit(19))
        t.TearFlags = setbit(t.TearFlags, bit(23))
        t.TearFlags = setbit(t.TearFlags, bit(55))
        t.TearFlags = setbit(t.TearFlags, bit(50))
        t.TearFlags = setbit(t.TearFlags, bit(8))
      end
    end
  end
  
  -- Check time events
  if (#TEventStorage == 0) then TEventActive = false else TEventActive = true end
  for k, v in pairs(TEventStorage) do
      if (v.ontime == true and v.duration > 0) then
        if (v.trc == false and v.ontrigger ~= nil) then v.ontrigger() end
        v.duration = v.duration - 1
      end
        
      if (v.duration <= 0) then
        if (v.onover ~= nil) then v.onover() end
        TEventStorage[k] = nil
      end
      
  end
  
  --If player pickup Subscriber|TODO: ONLY FOR DEBUG
  if p:GetCollectibleNum(FI_subscriber) > FI_subscriber_num then
    FI_subscriber_num = FI_subscriber_num + 1;
    table.insert(subs, Subscriber:new(Isaac.Spawn(EntityType.ENTITY_FAMILIAR, 1000, 0, p.Position, Vector(0,0), p):ToFamiliar(), "VirtualZer0"))
	end
  
  --If player pickup Nightbot
  if p:HasCollectible(FI_nightbot) and not FI_nightbot_have then
    FI_nightbot_have = true
    table.insert(fams, Isaac.Spawn(EntityType.ENTITY_FAMILIAR, 1001, 0, p.Position, Vector(0,0), p):ToFamiliar())
	end
  
  --If player pickup Stinky Cheese
  if p:HasCollectible(FI_stinkyCheese) and not FI_stinky_have then
    FI_stinky_have = true
    table.insert(fams, Isaac.Spawn(EntityType.ENTITY_FAMILIAR, 1002, 0, p.Position, Vector(0,0), p):ToFamiliar())
	end
  
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
    if (rnd == 0) then statStorage.damage = statStorage.damage + 0.5
    elseif (rnd == 1 and p.FireDelay > p.MaxFireDelay) then statStorage.tears = statStorage.tears - 1
    elseif (rnd == 2) then statStorage.tearspeed = statStorage.tearspeed + 0.2
    elseif (rnd == 3 and p.MoveSpeed < 2) then statStorage.speed = statStorage.speed + 0.2
    else p.Luck = p.Luck + 1; statStorage.luck = statStorage.luck + 1 end
    p:AddCacheFlags(CacheFlag.CACHE_ALL)
    p:EvaluateItems()
    PI_curseLit_activated = true
  end
  
  --If player pickup Kappa
	if (p:GetCollectibleNum(PI_kappa) > PI_kappa_num) then
      PI_kappa_num = PI_kappa_num + 1;
      statStorage.damage = statStorage.damage + 2.5
      p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
      p:EvaluateItems()
	end
  
  --If player pickup AMP Trop Punch
	if (p:GetCollectibleNum(PI_tropPunch) > PI_tropPunch_num and p.MoveSpeed < 2.5) then
    statStorage.speed = statStorage.speed + 0.35
    p:AddCacheFlags(CacheFlag.CACHE_SPEED)
    p:EvaluateItems()
    PI_tropPunch_num = PI_tropPunch_num + 1
	end
  
  --If player hold Junkey Bunny
  if (p:HasTrinket(TI_junkey) and math.random(0, 100) > 98) then
    Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(math.random(-20, 20), math.random(-20, 20)), p)
  end
  
    --If player hold VitecP UC
  if (p:HasTrinket(TI_vitecp) and math.random(0, 100) > 98) then
    Game():SpawnParticles(p.Position, EffectVariant.PLAYER_CREEP_RED, 1, 0, Color(1,1,1,1,0,0,0), 0)
  end
  
  --If player hold Tijoe head
  if (p:HasTrinket(TI_tijoe) and math.random(0, 1000) > 996) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) then
    local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*15, p:GetShootingInput().Y*15), p):ToTear()
    t.CollisionDamage = p.Damage * 30
    t:ChangeVariant(TearVariant.MULTIDIMENSIONAL)
    t.TearFlags = setbit(t.TearFlags, bit(1))
    t.TearFlags = setbit(t.TearFlags, bit(2))
    t.TearFlags = setbit(t.TearFlags, bit(3))
    t:SetColor(Rainbow[1], 0, 0, false, false)
    t.Scale = 5
    if (math.random(1,10) <= 4) then
      p:TakeDamage (0.5, DamageFlag.DAMAGE_FIRE, EntityRef(p), 30)
    end
  end
  
  --If player hold Neonomi Glasses
  if (p:HasTrinket(TI_neonomi) and math.random(0, 1000) > 995) then TI_neonomi_active = true else TI_neonomi_active = false end
  
  --Check special pickups and entities
  local entities = Isaac.GetRoomEntities()
  for k, v in pairs(entities) do
    local e = entities[k]
    
    if (entities[k].Type == EntityType.ENTITY_PROJECTILE) then
      if (TI_neonomi_active) then
        v:AddVelocity(Vector(-v.Velocity.X, -v.Velocity.Y))
      end
    end
    
    --If player pickup Brain Slug
    if (entities[k]:IsActiveEnemy (false)) then
      if p:HasCollectible(PI_brainSlug) and (p:GetFireDirection() ~= Direction.NO_DIRECTION) and not v:IsBoss() then
        v:AddVelocity(Vector(p:GetShootingJoystick().X*0.8, p:GetShootingJoystick().Y*0.8))
      end
    end
    
    if (entities[k].Type == EntityType.ENTITY_PICKUP) then
      
      if (p:HasTrinket(TI_smite) and v.Variant > 1000 and v.Variant <= 1005) then
        if (v.Variant == E_BitsA) then
          for i=0, 2 do Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, LocustSubtypes.LOCUST_OF_DEATH, v.Position, Vector(0,0), p) end
          v:Remove()
        end
        
        if (v.Variant == E_BitsB) then
          for i=0, 3 do Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, LocustSubtypes.LOCUST_OF_FAMINE, v.Position, Vector(0,0), p) end
          v:Remove()
        end
        
        if (v.Variant == E_BitsC) then
          for i=0, 5 do Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, LocustSubtypes.LOCUST_OF_PESTILENCE, v.Position, Vector(0,0), p) end
          v:Remove()
        end
        
        if (v.Variant == E_BitsD) then
          for i=0, 7 do Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, LocustSubtypes.LOCUST_OF_CONQUEST, v.Position, Vector(0,0), p) end
          v:Remove()
        end
        
        if (v.Variant == E_BitsE) then
          for i=0, 10 do Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, LocustSubtypes.LOCUST_OF_WRATH, v.Position, Vector(0,0), p) end
          v:Remove()
        end
      end
      
      --Twitch Heart
      if (e.Variant == 1000 and p:GetPlayerType() ~= PlayerType.PLAYER_THELOST and p:GetPlayerType() ~= PlayerType.PLAYER_KEEPER
        and not ((p:GetMaxHearts() + p:GetSoulHearts() + twitchHearts) /2 >= 12)
        and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        
        s:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1)
        e:GetSprite():Play("Collect", true)
        e:Die()
        if ((p:GetMaxHearts() + p:GetSoulHearts()) /2 ~= 12) then
          if ( p:GetSoulHearts() % 2 == 1) then
            p:AddSoulHearts (1)
            twitchHearts = twitchHearts + 1;
          else
            twitchHearts = twitchHearts + 2;
          end
        end
      end
      
      --Bits A
      if (e.Variant == E_BitsA and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        s:Play (SND_bitsCollect, 2.5, 0, false, 1.1)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        bitsTime.gray.enable = true
        bitsTime.gray.frames = bitsTime.gray.frames + (30 * 45)
      end
      
      --Bits B
      if (e.Variant == E_BitsB and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        s:Play (SND_bitsCollect, 2.5, 0, false, 1.3)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        bitsTime.purple.enable = true
        bitsTime.purple.frames = bitsTime.purple.frames + (30 * 45)
      end
      
      --Bits C
      if (e.Variant == E_BitsC and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        s:Play (SND_bitsCollect, 2.5, 0, false, 1.45)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        bitsTime.green.enable = true
        bitsTime.green.frames = bitsTime.green.frames + (30 * 60)
      end
      
      --Bits D
      if (e.Variant == E_BitsD and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        s:Play (SND_bitsCollect, 2.5, 0, false, 1.55)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        bitsTime.blue.enable = true
        bitsTime.blue.frames = bitsTime.blue.frames + (30 * 75)
      end
      
      --Bits E
      if (e.Variant == E_BitsE and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        s:Play (SND_bitsCollect, 2.5, 0, false, 1.65)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        bitsTime.red.enable = true
        bitsTime.red.frames = bitsTime.red.frames + (30 * 90)
      end
      
    end
  end
  
  --Event activation mode
  if IOLink.Input.Data.emode == 3 then
    
    if (IOLink.Input.Data.hash ~= lastEventHash) then
      lastEventHash = IOLink.Input.Data.hash
      local ev = IOLink.Input.Data
      if ev.etype == 1 then IOTmod.funcs:giveItem(ev.eobj)
      elseif ev.etype == 2 then IOTmod.funcs:giveTrinket(ev.eobj)
      elseif ev.etype == 3 then IOTmod.funcs:giveHeart(ev.eobj)
      elseif ev.etype == 4 then IOTmod.funcs:giveCompanion(ev.eobj)
      elseif ev.etype == 5 then IOTmod.funcs:givePickup(ev.eobj)
      elseif ev.etype == 6 then IOTmod.funcs:givePocket(ev.eobj)
      elseif ev.etype == 7 then IOTmod.funcs:giveEvent(ev.eobj, ev.duration)
      end
      if (ev.happy == true) then p:AnimateHappy() else p:AnimateSad() end
    end
  end
  
 --Spawn subscriber mode
  if IOLink.Input.Data.emode == 4 then
    if (IOLink.Input.Data.hash ~= lastSubHash) then
      lastSubHash = IOLink.Input.Data.hash
      FI_subscriber_num = FI_subscriber_num + 1;
      table.insert(subs, Subscriber:new(Isaac.Spawn(EntityType.ENTITY_FAMILIAR, 1000, 0, p.Position, Vector(0,0), p):ToFamiliar(), IOLink.Input.Data.name))
      p:AnimateHappy()
    end
  end
  
  --Bits mode
  if IOLink.Input.Data.emode == 5 then
    if (IOLink.Input.Data.hash ~= lastBitsHash) then
      lastBitsHash = IOLink.Input.Data.hash
      for i = 1, IOLink.Input.Data.count do
        Isaac.Spawn(EntityType.ENTITY_PICKUP, E_BitsA + IOLink.Input.Data.type, 0, r:FindFreePickupSpawnPosition(r:GetCenterPos(), 0, true), Vector(0,0), p)
      end
      p:AnimateHappy()
    end
  end
 
end

----------------------------Player get damage------------------------------
function IOTmod:PlayerTakeDamage(p, damageAmnt, damageFlag, damageSource, damageCountdown)
  
  if (twitchHeartInv > 0) then
    return false
  end
  
  if p:ToPlayer():HasCollectible(PI_bcouch) then
    local entities = Isaac.GetRoomEntities()
    for k, v in pairs(entities) do
      if (v:IsActiveEnemy(false) and (p.Position:Distance(v.Position) <= 220)) then
        local vec = Vector(v.Position.X - p.Position.X, v.Position.Y - p.Position.Y):Normalized()
        v:AddVelocity(Vector(vec.X * 60, vec.Y * 60))
      end
    end
    p:AddVelocity(Vector(-p.Velocity.X, -p.Velocity.Y))
  end
  
  if (p:ToPlayer():HasTrinket(TI_hellyeah) and math.random(1,4) == 1) then
    Game():SpawnParticles(p.Position, EffectVariant.RED_CANDLE_FLAME, 1, 0, Color(1, 0, 0, 1, 300, 60, 60), 0)
    Game():SpawnParticles(Vector(p.Position.X-50, p.Position.Y), EffectVariant.RED_CANDLE_FLAME, 1, 0, Color(1, 0, 0, 1, 300, 200, 200), 0)
    Game():SpawnParticles(Vector(p.Position.X+50, p.Position.Y), EffectVariant.RED_CANDLE_FLAME, 1, 0, Color(1, 0, 0, 1, 300, 200, 200), 0)
    Game():SpawnParticles(Vector(p.Position.X, p.Position.Y-50), EffectVariant.RED_CANDLE_FLAME, 1, 0, Color(1, 0, 0, 1, 300, 200, 200), 0)
    Game():SpawnParticles(Vector(p.Position.X, p.Position.Y+50), EffectVariant.RED_CANDLE_FLAME, 1, 0, Color(1, 0, 0, 1, 300, 200, 200), 0)
    Game():SpawnParticles(Vector(p.Position.X, p.Position.Y-100), EffectVariant.RED_CANDLE_FLAME, 1, 0, Color(1, 0, 0, 1, 300, 200, 200), 0)
    Game():Darken(0.7, 10)
  end
  
  if (p:ToPlayer():HasTrinket(TI_grizzly) and math.random(1,2) == 1) then
    local entities = Isaac.GetRoomEntities()
    for k, v in pairs(entities) do
      if (v:IsActiveEnemy(false) and (p.Position:Distance(v.Position) <= 200)) then
        v:AddFear (EntityRef(p), 300)
      end
    end
  end
  
  if (damageFlag == DamageFlag.DAMAGE_FAKE) then
    return true
  end
  
	if(twitchHearts > 0) then
		p:TakeDamage(0.0, DamageFlag.DAMAGE_FAKE, EntityRef(p), damageCountdown)
    twitchHeartInv = 45
		local room = Game():GetRoom()
    local beforeDmg = twitchHearts
    twitchHearts = math.floor(twitchHearts - (damageAmnt*0.5))
    
		if(twitchHearts < 0) then
			twitchHearts = 0
		end
    
    if (beforeDmg - twitchHearts >= 2 or (beforeDmg - twitchHearts == 1 and twitchHearts % 2 == 0)) then
      
      local ef = (beforeDmg - twitchHearts)/2
      
      for i=0,4*ef do
        local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER, 0,  0, p.Position, Vector(0, 0), p)
        spider:AddCharmed(-1)
        spider:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
        spider:SetColor(Color(0.392, 0.255, 0.643, 1, 39, 25, 64), 0, 0, false, false)
        
        local fly = Isaac.Spawn(EntityType.ENTITY_DART_FLY, 0,  0, p.Position, Vector(0, 0), p)
        fly:AddCharmed(-1)
        fly:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
        fly:SetColor(Color(0.392, 0.255, 0.643, 1, 39, 25, 64), 0, 0, false, false)
      end
      
      Game():SpawnParticles(p.Position, EffectVariant.PLAYER_CREEP_HOLYWATER, 1, 0, Color(0.392, 0.255, 0.643, 1, 1, 1, 1), 0)
      
      for i = 0, 15 do
        Game():SpawnParticles(p.Position, EffectVariant.WISP, 1, 0, Color(0.392, 0.255, 0.643, 1, 1, 1, 1), 0)
      end
    end
    
    return false
  else
		return true
	end
end

----------------------------Post Perfect Update------------------------------
function IOTmod:postPerfectUpdate()
  
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
  
  --Update data every 8 frames and parameters every 100 frames
  if g:GetFrameCount() % 8 == 0 then
    io.input(inputdatafile)
    IOLink.Input.Data = json.decode(io.read("*all"))
  end
  
  if g:GetFrameCount() % 100 == 0 then
    io.input(inputparamfile)
    IOLink.Input.Param = json.decode(io.read("*all"))
    
    IOLink.Output.Param.stats.luck = p.Luck
    io.output(outputparamfile)
    io.write(json.encode(IOLink.Output.Param))
    io.close()
  end
end

----------------------------Render------------------------------
 
function IOTmod:Render()
  
  --Check boss screen
  if (Game():GetRoom():GetType() == RoomType.ROOM_BOSS and Game():GetRoom():GetFrameCount() == 0) then
    allowrender = false
  else
    allowrender = true
  end
  
  if Game():IsPaused() ~= IOLink.Output.Param.pause then
    IOTmod:T_gamePaused(Game())
  end
  local ev = IOLink.Input.Data
  local tp = IOLink.Input.Param.textparam
  local p = Isaac.GetPlayer(0)
  --Isaac.DebugString(json.encode(IOLink.Input.Param))
  
  --Render twitch hearts
  if (twitchHearts > 0 and Game():GetLevel():GetCurses () ~= LevelCurse.CURSE_OF_THE_UNKNOWN and allowrender) then
    
    local twfull = twitchHearts/2
    local ishalf = (twitchHearts % 2 == 1)
    local isstdhalf = p:GetSoulHearts() % 2
    local hearts = (p:GetMaxHearts() + p:GetSoulHearts()) /2
    local zv = Vector(0,0)
    local TopVector = zv
    
    if (hearts > 6) then line = 1 end
    if (ishalf) then twfull = twfull + 1 end
    if (line == 1) then offset = hearts - 6 else offset = hearts end
    
    for i=hearts+1, (hearts+twfull) do
      if (i < 7) then
        TopVector = Vector((i-1)*12 + 48, 12)
      else
        TopVector = Vector((i-7)*12 + 48, 22)
      end
        
      if (not ishalf or i < hearts+twfull-1) then
        twitchHeartFullSprite:Render(TopVector, zv, zv)
      else
        twitchHeartHalfSprite:Render(TopVector, zv, zv)
      end
    end
  end
  
  -- Render bits and events icons
  local bitsuishift = 0
  
  if (TEventActive and allowrender) then
    SpriteEventActive:Update()
    SpriteEventActive:Render(Vector(136 + 16*bitsuishift, 13), Vector(0,0), Vector(0,0))
    bitsuishift = bitsuishift + 1
  end
  
  if (bitsTime.gray.enable and allowrender) then
    SpriteGrayBitsActive:Update()
    SpriteGrayBitsActive:Render(Vector(136 + 16*bitsuishift, 13), Vector(0,0), Vector(0,0))
    bitsuishift = bitsuishift + 1
  end
  
  if (bitsTime.purple.enable and allowrender) then
    SpritePurpleBitsActive:Update()
    SpritePurpleBitsActive:Render(Vector(136 + 16*bitsuishift, 13), Vector(0,0), Vector(0,0))
    bitsuishift = bitsuishift + 1
  end
  
  if (bitsTime.green.enable and allowrender) then
    SpriteGreenBitsActive:Update()
    SpriteGreenBitsActive:Render(Vector(136 + 16*bitsuishift, 13), Vector(0,0), Vector(0,0))
    bitsuishift = bitsuishift + 1
  end
  
  if (bitsTime.blue.enable and allowrender) then
    SpriteBlueBitsActive:Update()
    SpriteBlueBitsActive:Render(Vector(136 + 16*bitsuishift, 13), Vector(0,0), Vector(0,0))
    bitsuishift = bitsuishift + 1
  end
  
  if (bitsTime.red.enable and allowrender) then
    SpriteRedBitsActive:Update()
    SpriteRedBitsActive:Render(Vector(136 + 16*bitsuishift, 13), Vector(0,0), Vector(0,0))
    bitsuishift = bitsuishift + 1
  end
  
  
  --Render standart vote
  if (ev.emode == 1) then
    Isaac.RenderText(ev.text, tp.firstline.x, tp.firstline.y, 0, 0, 0, 1)
    Isaac.RenderText(ev.text, tp.firstline.x-1, tp.firstline.y-1, 1, 1, 1, 1)
    
    Isaac.RenderText(ev.secondtext, tp.secondline.x, tp.secondline.y, 1, 0, 0, 1)
    Isaac.RenderText(ev.secondtext, tp.secondline.x, tp.secondline.y, 1, 1, 0, 1)
  end
    
  --Render info
  if (ev.emode == 2) then
      Isaac.RenderText(ev.text, tp.firstline.x, tp.firstline.y, 0, 0, 0, 1)
      Isaac.RenderText(ev.text, tp.firstline.x-1, tp.firstline.y-1, 0, 1, 0, 1)
  end
    
  --Render event activation message
  if (ev.emode > 2) then
    if (blinkText > 0 and blinkDirect == true) then
      Isaac.RenderText(ev.text, tp.firstline.x, tp.firstline.y, 0, 0, 0, 1)
      Isaac.RenderText(ev.text, tp.firstline.x-1, tp.firstline.y-1, 1, 1, 0, 1)
      blinkText = blinkText-1;
    end
    
    if (blinkText > 0 and blinkDirect == false) then
      Isaac.RenderText(ev.text, tp.firstline.x, tp.firstline.y, 0, 0, 0, 1)
      Isaac.RenderText(ev.text, tp.firstline.x-1, tp.firstline.y-1, 1, 1, 1, 1)
      blinkText = blinkText-1;
    end
    
    if (blinkText == 0) then
      blinkDirect = not blinkDirect
      blinkText = 10
    end
  end
    
    --If player have subscribers
  for k, v in pairs(subs) do
    local fpos = Isaac.WorldToRenderPosition(subs[k].entity.Position, true) + Game():GetRoom():GetRenderScrollOffset()
    if (subs[k].color == nil) then
      subs[k].color = ChatColors[math.random(0, #ChatColors-1)]
      subs[k].entity:SetColor(subs[k].color, 0, 0, false, false)
    end
    if (allowrender) then
      Isaac.RenderText(subs[k].name, fpos.X-3 * #subs[k].name, fpos.Y-40, subs[k].color.R, subs[k].color.G, subs[k].color.B, 0.8)
    end
  end
    
end

----------------------------Triggers------------------------------
function IOTmod:T_gamePaused(g)
  IOLink.Output.Param.pause = g:IsPaused()
  
  io.output(outputparamfile)
  io.write(json.encode(IOLink.Output.Param))
  io.close()
end

function IOTmod:T_RoomChanged(room)
  local p = Isaac.GetPlayer(0)
  local g = Game()
  local ppos = p.Position
  
  -- Check room-based event
  for k, v in pairs(TEventStorage) do
    if (v.ontime == false) then
      if (v.trc == true and v.ontrigger ~= nil) then v.ontrigger() end
      v.duration = v.duration - 1
    end
    
    if (v.ontime == true and v.trc == true and v.ontrigger ~= nil ) then v.ontrigger() end
  end
  
  
  --If player pickup KappaPride
  if p:HasCollectible(PI_kappaPride) then
			if (math.random() > 0.93) then
        local ref = EntityRef(p)
        Isaac.GridSpawn(GridEntityType.GRID_POOP, 4, ref.Position, true)
        IOTmod:_playSound(SoundEffect.SOUND_PLOP)
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
        if (rnd == 0) then entities[i]:AddPoison(ref, math.random(30,300), math.random())
        elseif (rnd == 1) then entities[i]:AddFreeze(ref, math.random(30,300))
        elseif (rnd == 2) then entities[i]:AddSlowing(ref, math.random(30,300), math.random(), Color(1,1,1,1,0,0,0))
        elseif (rnd == 3) then entities[i]:AddCharmed(math.random(30,300))
        elseif (rnd == 4) then entities[i]:AddConfusion(ref, math.random(30,300), false)
        elseif (rnd == 5) then entities[i]:AddMidasFreeze(ref, math.random(30,300))
        elseif (rnd == 6) then entities[i]:AddFear(ref, math.random(30,300))
        elseif (rnd == 7) then entities[i]:AddBurn(ref, math.random(30,300), math.random())
        else entities[i]:AddShrink(ref, math.random(30,300)) end
      end
    end
  end
  
  --If player hold Hutts hairstyle
  if (p:ToPlayer():HasTrinket(TI_hutts)) then
    local entities = Isaac.GetRoomEntities()
    for k, v in pairs(entities) do
      if (v:IsActiveEnemy(false) and math.random(1,4) == 1) then
        v:AddCharmed(300)
      end
    end
  end
  
  IOTmod:TwitchRoomGen (g:GetRoom())
  
end

----------------------------Subscriber------------------------------
function IOTmod:UpdateFamiliarSubscriber (familiar)
  if familiar.Variant == 1000 then
    local	player = Isaac.GetPlayer(0)
    sprite = familiar:GetSprite()
    
    if (player:GetFireDirection() ~= Direction.NO_DIRECTION) and (Game():GetFrameCount() % 35 == 0 or Game():GetFrameCount() % 35 < 12) then
      if player:GetHeadDirection() == Direction.LEFT then
        currentAnim = "ShootLeft"
        if (Game():GetFrameCount() % 35 == 0) then IOTmod:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      elseif player:GetHeadDirection() == Direction.RIGHT then
        currentAnim = "ShootRight"
        if (Game():GetFrameCount() % 35 == 0) then IOTmod:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      elseif player:GetHeadDirection() == Direction.UP then
        currentAnim = "ShootUp"
        if (Game():GetFrameCount() % 35 == 0) then IOTmod:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      elseif player:GetHeadDirection() == Direction.DOWN then
        currentAnim = "ShootDown"
        if (Game():GetFrameCount() % 35 == 0) then IOTmod:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      end
    else
      if player:GetHeadDirection() == Direction.LEFT then
        currentAnim = "FloatLeft"
      elseif player:GetHeadDirection() == Direction.RIGHT then
        currentAnim = "FloatRight"
      elseif player:GetHeadDirection() == Direction.UP then
        currentAnim = "FloatUp"
      elseif player:GetHeadDirection() == Direction.DOWN then
        currentAnim = "FloatDown"
      end
    end
    sprite:Play(currentAnim,true)
  end
end

function IOTmod:ShootFamiliarSubscriber(f, dt)
  direct = Vector(0,0)
  
  if (dt == Direction.LEFT) then direct = Vector(-10, 0)
  elseif (dt == Direction.RIGHT) then direct = Vector(10, 0)
  elseif (dt == Direction.UP) then direct = Vector(0, -10)
  else direct = Vector(0, 10) end

  local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, f.Position, direct, f)
  tear:SetColor(f:GetColor(), 0, 0, false, false)
  
end

----------------------------NightBot------------------------------
function IOTmod:UpdateFamiliarNightbot (familiar)
  if familiar.Variant == 1001 then
    local	player = Isaac.GetPlayer(0)
    sprite = familiar:GetSprite()
    
      if player:GetHeadDirection() == Direction.LEFT then
        currentAnim = "FloatLeft"
      elseif player:GetHeadDirection() == Direction.RIGHT then
        currentAnim = "FloatRight"
      elseif player:GetHeadDirection() == Direction.UP then
        currentAnim = "FloatUp"
      elseif player:GetHeadDirection() == Direction.DOWN then
        currentAnim = "FloatDown"
      end
    sprite:Play(currentAnim,true)
    
    local entities = Isaac.GetRoomEntities()
  
    for k, v in pairs(entities) do
      if (entities[k].Type == EntityType.ENTITY_PROJECTILE) then
        local distBetween = familiar.Position:Distance(entities[k].Position)
        if (not entities[k]:IsDead() and distBetween <= 16) then IOTmod:TriggerFamiliarNightbot() end
      end
    end
  end
  
end


function IOTmod:TriggerFamiliarNightbot ()
  local entities = Isaac.GetRoomEntities()
  
    for k, v in pairs(entities) do
      if entities[k].Type == EntityType.ENTITY_PROJECTILE then
        entities[k]:Die()
      end
    end
    Game():Darken(-0.5, 7);
end

----------------------------Stinky Cheese------------------------------
function IOTmod:UpdateFamiliarStinkyCheese (familiar)
  if familiar.Variant == 1002 then
    local	player = Isaac.GetPlayer(0)
    sprite = familiar:GetSprite()
    if (sprite:IsFinished("Float")) then sprite:Play("Float", false) end
    
    local entities = Isaac.GetRoomEntities()
  
    for k, v in pairs(entities) do
      if (entities[k]:IsActiveEnemy() and not entities[k]:HasEntityFlags(EntityFlag.FLAG_POISON)) then
        local distBetween = familiar.Position:Distance(entities[k].Position)
        if (not entities[k]:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and not entities[k]:IsDead() and distBetween <= 64) then IOTmod:TriggerFamiliarStinkyCheese(familiar, entities[k]) end
      end
    end
  end
  
end


function IOTmod:TriggerFamiliarStinkyCheese (f, e)
  IOTmod:_playSound(SoundEffect.SOUND_FART)
  e:AddPoison(EntityRef(f), 160, 1)
end

----------------------------Familiar init------------------------------
function IOTmod:InitFamiliar (familiar)
  
end

----------------------------Twitch room generation------------------------------
function IOTmod:TwitchRoomGen (room)
  local g = Game()
  if (twitchRoomGenOnStage == true or twitchRoomIndex ~= -999) 
  and (twitchRoomIndex == -999 or twitchRoomIndex == Game():GetLevel():GetCurrentRoomIndex()) 
  and (room:GetType() == RoomType.ROOM_DEFAULT)
  and (Game():GetLevel():GetStartingRoomIndex () ~= Game():GetLevel():GetCurrentRoomIndex())
  and (room:GetRoomShape() == RoomShape.ROOMSHAPE_1x1) then
    
    twitchRoomGenOnStage = false
    room:SetClear(true)
    twitchRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
    
    for i = 16, 118 do
      local ge = room:GetGridEntity(i)
      if (ge ~= nil) and (i%15 ~= 0 and (i+1)%15 ~= 0) then -- Look on this shit! Edmund, why GridEntityType is not working?
        local grid = room:GetGridEntity(i)
        room:RemoveGridEntity (i, 0, true)
      end
      
      if (ge ~= nil and (i == 74 or i == 60 or i == 7 or i == 127)) then
        
      end
    end
    
    local e = Isaac.GetRoomEntities()
    
    for k, v in pairs(e) do
      if (e[k].Type > 8 and not e[k]:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
        e[k]:Remove()
      end
    end
    
    room:SetFloorColor(Color(0.392, 0.255, 0.643, 1, 9, -5, 34))
    room:SetWallColor(Color(0.392, 0.255, 0.643, 1, -21, -35, 4))
    
    -- Flames
    g:SpawnParticles(room:GetGridPosition(16), EffectVariant.BLUE_FLAME, 1, 0, Color(0.392, 0.255, 0.643, 1, 392, 255, 643), 0)
    g:SpawnParticles(room:GetGridPosition(28), EffectVariant.BLUE_FLAME, 1, 0, Color(0.392, 0.255, 0.643, 1, 392, 255, 643), 0)
    g:SpawnParticles(room:GetGridPosition(106), EffectVariant.BLUE_FLAME, 1, 0, Color(0.392, 0.255, 0.643, 1, 392, 255, 643), 0)
    g:SpawnParticles(room:GetGridPosition(118), EffectVariant.BLUE_FLAME, 1, 0, Color(0.392, 0.255, 0.643, 1, 392, 255, 643), 0)
    
    --Beetles
    for i = 0, 2 do
      g:SpawnParticles(room:GetGridPosition(52), EffectVariant.WISP, 1, 0, Rainbow[math.random(#Rainbow)], 0)
      g:SpawnParticles(room:GetGridPosition(82), EffectVariant.WISP, 1, 0, Rainbow[math.random(#Rainbow)], 0)
      g:SpawnParticles(room:GetGridPosition(68), EffectVariant.WISP, 1, 0, Rainbow[math.random(#Rainbow)], 0)
      g:SpawnParticles(room:GetGridPosition(66), EffectVariant.WISP, 1, 0, Rainbow[math.random(#Rainbow)], 0)
    end
    
    if (room:IsFirstVisit())  then
      g:SpawnParticles(room:GetGridPosition(67), EffectVariant.FIREWORKS, 1, 0, Color(1, 1, 1, 1, 0, 0, 0), 0)
      
      if (#twitchRoomItemPool == 0) then
        IOTmod:ReloadTwitchRoomPool ()
      end
      
      local itemnum = math.random(#twitchRoomItemPool)
      local item = twitchRoomItemPool[itemnum]
      twitchRoomItemPool[itemnum] = nil
      
      Isaac.Spawn(5, 100, item, room:GetGridPosition(67), Vector(0,0), nil, 0)
      
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1005), room:GetGridPosition(32), Vector(0,0), nil, 0, 0)
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1005), room:GetGridPosition(42), Vector(0,0), nil, 0, 0)
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1005), room:GetGridPosition(92), Vector(0,0), nil, 0, 0)
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1005), room:GetGridPosition(102), Vector(0,0), nil, 0, 0)
      
    end
  end
end

----------------------------Active items------------------------------
 
function IOTmod:AI_TwitchRaid_act()
  local followers = {}
  local game = Game()
  local room = game:GetRoom()
  for i = 0, math.random(3,6) do
		followers[i] = Isaac.Spawn(Buddies[math.random(#Buddies)], 0,  0, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true), Vector(0, 0), player)
    followers[i]:AddCharmed(-1)
    followers[i]:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
	end
end

function IOTmod:AI_TTours_act()
  local	player = Isaac.GetPlayer(0)
	local	entities = Isaac.GetRoomEntities()
  local game = Game()
  
	for i = 1, #entities do
		if entities[i]:IsActiveEnemy() then
			entities[i]:AddConfusion(EntityRef(player), 580, false)
      local ref = EntityRef(entities[i])
      game:SpawnParticles(ref.Position, EffectVariant.IMPACT, 2, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
		end
	end
end

function IOTmod:AI_voteYea_act()
  IOLink.Output.Data.interrupt = 1
  IOLink.Output.Data.interruptHash = math.random()
  
  io.output(outputdatafile)
  io.write(json.encode(IOLink.Output.Data))
  io.close()
  IOTmod:_playSound(SoundEffect.SOUND_BEEP)
end

function IOTmod:AI_voteNay_act()
  IOLink.Output.Data.interrupt = 0
  IOLink.Output.Data.interruptHash = math.random()
  
  io.output(outputdatafile)
  io.write(json.encode(IOLink.Output.Data))
  io.close()
  IOTmod:_playSound(SoundEffect.SOUND_FLUSH)
end

function IOTmod:AI_gowskull_act()
  local r = Game():GetRoom()
  local p = Isaac.GetPlayer(0)
  
  for i = r:GetTopLeftPos().Y + 10, r:GetBottomRightPos().Y - 10 do
    if (i % 30 == 0) then
      Game():SpawnParticles(Vector(r:GetTopLeftPos().X, i), EffectVariant.BRIMSTONE_SWIRL, 1, 0, Color(1, 1, 1, 1, 0, 0, 0), 0)
    end
  end
end

function IOTmod:AI_DEBUG_act()
  
  local	player = Isaac.GetPlayer(0)
	local	e = Isaac.GetRoomEntities()
  local game = Game()
  Isaac.DebugString("*********************Room*********************")
  Isaac.DebugString("| Index:" .. Game():GetLevel():GetCurrentRoomIndex())
  
  Isaac.DebugString("*********************Entity*********************")
	for k, v in pairs(e) do
    Isaac.DebugString("|" .. k .. " Entity Type:" .. e[k].Type .. " Variant:" .. e[k].Variant .. " Sub:" .. e[k].SubType)
    Isaac.DebugString("|--- Flags:" .. e[k]:GetEntityFlags())
    Isaac.DebugString("|--- Invincible:" .. tostring(e[k]:IsInvincible()))
    Isaac.DebugString("|--- Grid collision:" .. e[k].GridCollisionClass)
    Isaac.DebugString("|--- EntityCollision:" .. e[k].EntityCollisionClass)
    Isaac.DebugString(".........................")
	end
end

IOTmod:AddCallback(ModCallbacks.MC_POST_RENDER, IOTmod.Render);
IOTmod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, IOTmod.cacheUpdate)
IOTmod:AddCallback(ModCallbacks.MC_POST_UPDATE, IOTmod.postUpdate);
IOTmod:AddCallback(ModCallbacks.MC_POST_UPDATE, IOTmod.setTriggers);
IOTmod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, IOTmod.postPerfectUpdate);
IOTmod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, IOTmod.PlayerTakeDamage, EntityType.ENTITY_PLAYER)

IOTmod:AddCallback( ModCallbacks.MC_USE_ITEM, IOTmod.AI_TwitchRaid_act, AI_twitchRaid);
IOTmod:AddCallback( ModCallbacks.MC_USE_ITEM, IOTmod.AI_TTours_act, AI_TTours);
IOTmod:AddCallback( ModCallbacks.MC_USE_ITEM, IOTmod.AI_voteYea_act, AI_voteYea);
IOTmod:AddCallback( ModCallbacks.MC_USE_ITEM, IOTmod.AI_voteNay_act, AI_voteNay);
IOTmod:AddCallback( ModCallbacks.MC_USE_ITEM, IOTmod.AI_gowskull_act, AI_gowskull);
IOTmod:AddCallback( ModCallbacks.MC_USE_ITEM, IOTmod.AI_DEBUG_act, AI_DEBUG);

IOTmod:AddCallback (ModCallbacks.MC_FAMILIAR_UPDATE, IOTmod.UpdateFamiliarNightbot)
IOTmod:AddCallback (ModCallbacks.MC_FAMILIAR_UPDATE, IOTmod.UpdateFamiliarSubscriber)
IOTmod:AddCallback (ModCallbacks.MC_FAMILIAR_UPDATE, IOTmod.UpdateFamiliarStinkyCheese)
IOTmod:AddCallback (ModCallbacks.MC_FAMILIAR_INIT, IOTmod.InitFamiliar)

--If it new run
function IOTmod:relaunchGame (p)
  
  twitchHearts = 0
  
  statStorage = {
    speed = 0,
    range = 0,
    tears = 0,
    tearspeed = 0,
    damage = 0,
    luck = 0
  }
  
  nowEvent = {
    active = false,
    ontime = false,
    duration = 0,
    rooms = 0,
    onover = nil,
    ontrigger = nil,
    trc = false
  }
  
  bitsTime = {
    gray = {
      enable = false,
      frames = 0
    },
    
    purple = {
      enable = false,
      frames = 0
    },
    
    green = {
      enable = false,
      frames = 0
    },
    
    blue = {
      enable = false,
      frames = 0
    },
    
    red = {
      enable = false,
      frames = 0
    }
  }

  p:AddCacheFlags(CacheFlag.CACHE_ALL)
  p:EvaluateItems()
  
  twitchRoomIndex = -999
  if (math.random() < 0.15) then twitchRoomGenOnStage = true end
  
  for k, v in pairs(fams) do
      fams[k] = nil
  end
  
  for k, v in pairs(subs) do
      subs[k].entity = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, 1000, 0, p.Position, Vector(0,0), p):ToFamiliar()
      subs[k].entity:SetColor(subs[k].color, 0, 1, false, false)
  end
    
  PI_goldenKappa_num = 0
  PI_tropPunch_num = 0
  PI_kappa_num = 0
  FI_nightbot_have = false
  FI_stinky_have = false
  
  IOLink.Output.Param.runcount = IOLink.Output.Param.runcount+1
  
  --Reload TwitchRoom Pool
  IOTmod:ReloadTwitchRoomPool ()
  
  --Check on Challenge
  if (Game().Challenge ~= CH_twitchPower) then
    CH_twitchPowerMode = false
  else
    CH_twitchPowerMode = true
    IOTmod:startChallengeTwitchPower()
  end
  
  --Check special gift
  if (IOLink.Input.Param.gift ~= nil) then
    local room = Game():GetRoom()
    local p = Isaac.GetPlayer(0);
    p:DropTrinket(room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true), true)
    p:AddTrinket(Isaac.GetTrinketIdByName(IOLink.Input.Param.gift))
  end
  
end

function IOTmod:ReloadTwitchRoomPool ()
  table.insert(twitchRoomItemPool, PI_kappa)
  table.insert(twitchRoomItemPool, PI_goldenKappa)
  table.insert(twitchRoomItemPool, PI_notLikeThis)
  table.insert(twitchRoomItemPool, PI_kappaPride)
  table.insert(twitchRoomItemPool, PI_futureMan)
  table.insert(twitchRoomItemPool, PI_kreygasm)
  table.insert(twitchRoomItemPool, PI_curseLit)
  table.insert(twitchRoomItemPool, PI_tropPunch)
  table.insert(twitchRoomItemPool, PI_bcouch)
  table.insert(twitchRoomItemPool, PI_brainSlug)
  table.insert(twitchRoomItemPool, AI_gowskull)
  table.insert(twitchRoomItemPool, AI_twitchRaid)
  table.insert(twitchRoomItemPool, AI_TTours)
  table.insert(twitchRoomItemPool, AI_voteYea)
  table.insert(twitchRoomItemPool, AI_voteNay)
  table.insert(twitchRoomItemPool, FI_nightbot)
  table.insert(twitchRoomItemPool, FI_stinkyCheese)
end

function IOTmod:T_StageChanged(stage)
  PI_curseLit_activated = false
  
  twitchRoomIndex = -999
  if (math.random() < 0.15) then twitchRoomGenOnStage = true end
end

----------------------------Others---------------------------------
function IOTmod:_playSound(sound)
  SFXManager():Play(sound, 1, 0, false, 1)
end

function IOTmod:startChallengeTwitchPower()
  local g = Game()
  local r = g:GetRoom()
  local p = Isaac.GetPlayer(0)
  
  p:RemoveCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
  twitchHearts = 12
  p:AddCollectible(AI_twitchRaid, 6, false)
  p:AddCollectible(FI_stinkyCheese, 0, false)
end

function IOTmod:startChallengeTwitchPower()
  local g = Game()
  local r = g:GetRoom()
  local p = Isaac.GetPlayer(0)
  
  p:RemoveCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
  twitchHearts = 12
  p:AddCollectible(AI_twitchRaid, 6, false)
  p:AddCollectible(FI_stinkyCheese, 0, false)
end

function bit(p)
  return 2 ^ (p - 1)  -- 1-based indexing
end

function hasbit(x, p)
  return x % (p + p) >= p       
end

function setbit(x, p)
  return hasbit(x, p) and x or x + p
end

function clearbit(x, p)
  return hasbit(x, p) and x - p or x
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

TearFlags = {
	FLAG_NO_EFFECT = 0,
	FLAG_SPECTRAL = 1,
	FLAG_PIERCING = 1<<1,
	FLAG_HOMING = 1<<2,
	FLAG_SLOWING = 1<<3,
	FLAG_POISONING = 1<<4,
	FLAG_FREEZING = 1<<5,
	FLAG_COAL = 1<<6,
	FLAG_PARASITE = 1<<7,
	FLAG_MAGIC_MIRROR = 1<<8,
	FLAG_POLYPHEMUS = 1<<9,
	FLAG_WIGGLE_WORM = 1<<10,
	FLAG_UNK1 = 1<<11, --No noticeable effect
	FLAG_IPECAC = 1<<12,
	FLAG_CHARMING = 1<<13,
	FLAG_CONFUSING = 1<<14,
	FLAG_ENEMIES_DROP_HEARTS = 1<<15,
	FLAG_TINY_PLANET = 1<<16,
	FLAG_ANTI_GRAVITY = 1<<17,
	FLAG_CRICKETS_BODY = 1<<18,
	FLAG_RUBBER_CEMENT = 1<<19,
	FLAG_FEAR = 1<<20,
	FLAG_PROPTOSIS = 1<<21,
	FLAG_FIRE = 1<<22,
	FLAG_STRANGE_ATTRACTOR = 1<<23,
	FLAG_UNK2 = 1<<24, --Possible worm?
	FLAG_PULSE_WORM = 1<<25,
	FLAG_RING_WORM = 1<<26,
	FLAG_FLAT_WORM = 1<<27,
	FLAG_UNK3 = 1<<28, --Possible worm?
	FLAG_UNK4 = 1<<29, --Possible worm?
	FLAG_UNK5 = 1<<30, --Possible worm?
	FLAG_HOOK_WORM = 1<<31,
	FLAG_GODHEAD = 1<<32,
	FLAG_UNK6 = 1<<33, --No noticeable effect
	FLAG_UNK7 = 1<<34, --No noticeable effect
	FLAG_EXPLOSIVO = 1<<35,
	FLAG_CONTINUUM = 1<<36,
	FLAG_HOLY_LIGHT = 1<<37,
	FLAG_KEEPER_HEAD = 1<<38,
	FLAG_ENEMIES_DROP_BLACK_HEARTS = 1<<39,
	FLAG_ENEMIES_DROP_BLACK_HEARTS2 = 1<<40,
	FLAG_GODS_FLESH = 1<<41,
	FLAG_UNK8 = 1<<42, --No noticeable effect
	FLAG_TOXIC_LIQUID = 1<<43,
	FLAG_OUROBOROS_WORM = 1<<44,
	FLAG_GLAUCOMA = 1<<45,
	FLAG_BOOGERS = 1<<46,
	FLAG_PARASITOID = 1<<47,
	FLAG_UNK9 = 1<<48, --No noticeable effect
	FLAG_SPLIT = 1<<49,
	FLAG_DEADSHOT = 1<<50,
	FLAG_MIDAS = 1<<51,
	FLAG_EUTHANASIA = 1<<52,
	FLAG_JACOBS_LADDER = 1<<53,
	FLAG_LITTLE_HORN = 1<<54,
	FLAG_GHOST_PEPPER = 1<<55
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
    Color(1,0,0,1,0,0,0),
    Color(1,0.5,0,1,0,0,0),
    Color(1,1,0,1,0,0,0),
    Color(0.5,1,0,1,0,0,0),
    Color(0,1,1,1,0,0,0),
    Color(0,0,1,1,0,0,0),
    Color(0.5,0,1,1,0,0,0)
}

Doors = {
  RoomType.ROOM_DEFAULT,
  RoomType.ROOM_SHOP,
  RoomType.ROOM_TREASURE,
  RoomType.ROOM_BOSS,
  RoomType.ROOM_SECRET,
  RoomType.ROOM_ARCADE,
  RoomType.ROOM_CURSE,
  RoomType.ROOM_SACRIFICE,
  RoomType.ROOM_DEVIL,
  RoomType.ROOM_ANGEL
}

ChatColors = {
  Color(1,0,0,1,0,0,0),
  Color(0,0,1,1,0,0,0),
  Color(0.698, 0.133, 0.133,1,0,0,0),
  Color(1, 0.498, 0.314,1,0,0,0),
  Color(0.604, 0.804, 0.196,1,0,0,0),
  Color(1, 0.271, 0,1,0,0,0),
  Color(0.18, 0.545, 0.341,1,0,0,0),
  Color(0.855, 0.647, 0.125,1,0,0,0),
  Color(0.824, 0.412, 0.118,1,0,0,0),
  Color(0.373, 0.62, 0.627,1,0,0,0),
  Color(0.118, 0.565, 1,1,0,0,0),
  Color(1, 0.412, 0.706,1,0,0,0),
  Color(0.541, 0.169, 0.886,1,0,0,0),
  Color(0,0.502,0,1,0,0,0),
  Color(0, 1, 0.498,1,0,0,0)
}

----------------------------Events------------------------------

EV_shader_ScreenSide_enabled = 0;
EV_shader_ScreenSide_color = {1,1,0};
EV_shader_ScreenSide_intensity = 50;

SpecialEvents = {}

------- Richy
function SpecialEvents:Richy()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  room:TurnGold();
  
   for i = 0, 25 do
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN,  CoinSubType.COIN_PENNY, room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true), Vector(0, 0), player)
    end
    
end

------- Poop
function SpecialEvents:Poop()
  local p = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  room:SetFloorColor(Color(0.424,0.243,0.063,1,-50,-50,-50))
  room:SetWallColor(Color(0.424,0.243,0.063,1,-50,-50,-50))
  
  for i = 0, math.random(3, 5) do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_BUTT,  0, p.Position, Vector(math.random(-30,30), math.random(-30,30)), p)
    Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, pos, false)
  end
  IOTmod:_playSound(SoundEffect.SOUND_FART)
end

------- Earthquake
function SpecialEvents:Earthquake()
  
  function SE__update ()
    local g = Game()
    local	entities = Isaac.GetRoomEntities()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    g:ShakeScreen(100)
    for i = 0, room:GetGridSize()/2 do
      local ind = math.random(room:GetGridSize())
      local pos = room:GetGridPosition(ind)
      room:DestroyGrid(ind)
      g:SpawnParticles(pos, EffectVariant.ROCK_PARTICLE, math.random(6), math.random(), Color(0.235, 0.176, 0.122, 1, 25, 25, 25), math.random())
    end
    
    for i = 1, #entities do
      if entities[i]:IsActiveEnemy() and math.random(1,3) == 2 then
        local ref = EntityRef(entities[i])
        g:SpawnParticles(ref.Position, EffectVariant.SHOCKWAVE_RANDOM, 1, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
      end
    end
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(3, false, true, SE__update, nil))
  
end

------- Charm
function SpecialEvents:Charm()
  local g = Game()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  function SE__update ()
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if entities[i]:IsActiveEnemy() then
        entities[i]:AddCharmed(600)
      end
    end
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(3, false, true, SE__update, nil))

end

------- Hell
function SpecialEvents:Hell()
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
	for i = 1, #entities do
		if entities[i]:IsActiveEnemy( ) then
			entities[i]:AddBurn(EntityRef(player), 120, 0.05)
      entities[i]:AddFear(EntityRef(player), 400)
		end
	end
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local posv = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(posv, 0.5)
    if (player.Position:Distance(posv) >= 65) then
      Isaac.GridSpawn(GridEntityType.GRID_FIREPLACE , math.random(2), pos, false)
    end
  end
    
    IOTmod:_playSound(SoundEffect.SOUND_DEVILROOM_DEAL)
    room:EmitBloodFromWalls (60, 2)
    room:SetFloorColor(Color(0.900,0.010,0.010,1,50,-20,-20))
    room:SetWallColor(Color(0.900,0.010,0.010,1,50,-20,-20))
end

------- Spiky
function SpecialEvents:Spiky()
  local g = Game()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local posv = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(posv, 0.5)
    if (player.Position:Distance(posv) >= 65) then
      Isaac.GridSpawn(GridEntityType.GRID_SPIKES_ONOFF, math.random(2), pos, false)
    end
  end
    
    room:SetFloorColor(Color(0.4,0.4,0.4,1,50,50,50))
    room:SetWallColor(Color(0.4,0.4,0.4,1,50,50,50))
    IOTmod:_playSound(SoundEffect.SOUND_METAL_BLOCKBREAK)
end

------- Angel Rage
function SpecialEvents:AngelRage()
  
  function SE__update()
    local g = Game()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if entities[i]:IsActiveEnemy() and math.random(1,3) == 2 then
        local ref = EntityRef(entities[i])
        g:SpawnParticles(ref.Position, EffectVariant.CRACK_THE_SKY, 3, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
        g:SpawnParticles(ref.Position, EffectVariant.BLUE_FLAME, 1, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
      end
    end
      
      IOTmod:_playSound(SoundEffect.SOUND_HOLY)
      room:SetFloorColor(Color(1,1,1,1,150,150,150))
      room:SetWallColor(Color(1,1,1,1,150,150,150))
      g:Darken(-1, 40);
      
    end
    
    SE__update()
    table.insert(TEventStorage, TEvent:new(5, false, true, SE__update, nil))
end

------- Devil Rage (very originally)
function SpecialEvents:DevilRage()
  
  function SE__update()
    local g = Game()
    local entities = Isaac.GetRoomEntities()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    for i = 1, math.random(3,7) do
        local pos = room:GetRandomPosition(1)
        g:SpawnParticles(pos, EffectVariant.CRACK_THE_SKY, 3, math.random(), Color(1, 0, 0, 1, 50, 0, 0), math.random())
        g:SpawnParticles(pos, EffectVariant.LARGE_BLOOD_EXPLOSION, 1, math.random(), Color(1, 0, 0, 1, 50, 0, 0), math.random())
    end
      
      IOTmod:_playSound(SoundEffect.SOUND_SATAN_APPEAR)
      room:SetFloorColor(Color(0,0,0,1,-50,-50,-50))
      room:SetWallColor(Color(0,0,0,1,-50,-50,-50))
      g:Darken(1, 60);
    end
    
    SE__update();
    table.insert(TEventStorage, TEvent:new(5, false, true, SE__update, nil))
end

------- Rainbow Rain
function SpecialEvents:RainbowRain()
  local g = Game()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  for i = 0, room:GetGridSize()/5 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    g:SpawnParticles(pos, EffectVariant.CRACK_THE_SKY, 1, math.random(), Rainbow[math.random(#Rainbow)], math.random())
    g:SpawnParticles(pos, EffectVariant.PLAYER_CREEP_HOLYWATER, 1, 0, Rainbow[math.random(#Rainbow)], 0)
  end
    
    IOTmod:_playSound(SoundEffect.SOUND_WATER_DROP)
end

------- Call to Dark
function SpecialEvents:CallToDark()
  local g = Game()
  local units = {}
  local game = Game()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  for i = 0, 2 do
    local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true)
		units[i] = Isaac.Spawn(EntityType.ENTITY_IMP, 0,  0, pos, Vector(0, 0), player)
    units[i]:AddCharmed(-1)
    units[i]:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
    g:SpawnParticles(pos, EffectVariant.LARGE_BLOOD_EXPLOSION, 1, 0, Color(1,1,1,1,0,0,0), 0)
    g:Darken(1, 90);
    IOTmod:_playSound(SoundEffect.SOUND_SUMMONSOUND)
	end
end

------- RUN
function SpecialEvents:RUN()
  local g = Game()
  local player = Isaac.GetPlayer(0)
  
  function SE__update ()
    local room = Game():GetRoom()
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    g:SpawnParticles(pos, EffectVariant.HUSH_LASER, 1, math.random(), Rainbow[math.random(#Rainbow)], math.random())
  end
  
  function SE__over ()
    local e = Isaac.GetRoomEntities()
    
    for k, v in pairs(e) do
      if (v.Type == 1000 and v.Variant == 96) then
        v:Die()
      end
    end
  end
  
  SE__update()
  IOTmod:_playSound(SoundEffect.SOUND_MOM_VOX_EVILLAUGH)
  table.insert(TEventStorage, TEvent:new(15*30, true, true, SE__update, SE__over))
end

------- Flash Jump
function SpecialEvents:FlashJump()
  
  function SE__update ()
    local g = Game()
    g:MoveToRandomRoom(false)
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(5, false, true, SE__update, nil))
end

------- Eyes Bleed
function SpecialEvents:EyesBleed()
  local g = Game()
  local l = g:GetLevel()
  g:Darken(1, 400)
  g:ShakeScreen(400)
  g:AddPixelation(400)
end

------- Heal
function SpecialEvents:Heal()
  
  function SE__update ()
    if (Game():GetFrameCount() % 3 == 0) then
      local e = Isaac.GetRoomEntities()
    
      for k, v in pairs(e) do
        if (v:IsActiveEnemy() and v.HitPoints < v.MaxHitPoints) then
          v:AddHealth(0.5)
          Game():SpawnParticles(Vector(v.Position.X + math.random()*20, v.Position.Y + math.random()*20), EffectVariant.ULTRA_GREED_BLING, 1, 0, Color(0.5,1,0,1,0,0,0), 0)
        end
      end
    end
  end
  
  table.insert(TEventStorage, TEvent:new(50*30, true, false, SE__update, nil))
end

------- Flashmob
function SpecialEvents:Flashmob()
  
  function SE__update ()
    local e = Isaac.GetRoomEntities()
    local p = Isaac.GetPlayer(0)
  
    for k, v in pairs(e) do
      if (v.Type ~= EntityType.ENTITY_PLAYER) then
        v:AddVelocity(Vector(-p.Velocity.X, -p.Velocity.Y))
      end
    end
  end
  
  table.insert(TEventStorage, TEvent:new(45*30, true, false, SE__update, nil))
end

------- AttackOnTitan
function SpecialEvents:AttackOnTitan()
  
    local s = SFXManager()
  
  function SE__update ()
    local e = Isaac.GetRoomEntities()
    local p = Isaac.GetPlayer(0)
  
    for k, v in pairs(e) do
      if (v:IsActiveEnemy() and v:ToNPC().Scale ~= 2.5) then
        v:ToNPC().Scale = 2.5
        v:ToNPC().MaxHitPoints = v:ToNPC().MaxHitPoints*3
        v:ToNPC().HitPoints = v:ToNPC().HitPoints*3
      end
    end
  end
  
  function SE__over ()
    local e = Isaac.GetRoomEntities()
  
    for k, v in pairs(e) do
      if (v:IsActiveEnemy() and v:ToNPC().Scale == 2.5) then
        v:ToNPC().Scale = 1
      end
    end
  end
  
  s:Play(SND_attackOnTitan, 1.2, 0, false, 1)
  
  table.insert(TEventStorage, TEvent:new(45*30, true, false, SE__update, SE_over))
end

------- Diarrhea
function SpecialEvents:Diarrhea()
  function SE__update ()
    local e = Isaac.GetRoomEntities()
    local p = Isaac.GetPlayer(0)
  
    if (Game():GetFrameCount() % 20 == 0) then
      local f = Isaac.Spawn(EntityType.ENTITY_DIP, 0,  0, p.Position, Vector(math.random(-20, 20), math.random(-20, 20)), p)
      f:AddCharmed(-1)
      f:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
      IOTmod:_playSound(SoundEffect.SOUND_FART)
    end
  end
  
  table.insert(TEventStorage, TEvent:new(45*30, true, false, SE__update, SE_over))
end

------- Blade storm
function SpecialEvents:BladeStorm()
  function SE__update ()
    
    local p = Isaac.GetPlayer(0)
    local e = Isaac.GetRoomEntities()
    for k, v in pairs(e) do
      if (v.Type == EntityType.ENTITY_EFFECT and v.Variant == EffectVariant.SPEAR_OF_DESTINY and p.Position:Distance(v.Position) < 30) then
        p:TakeDamage(0.5, DamageFlag.DAMAGE_LASER, EntityRef(v), 30)
      end
    end
    
    if (Game():GetFrameCount() % 8 ~= 0) then return end
    
    local r = Game():GetRoom()
    local min = r:GetTopLeftPos().X
    local max = r:GetBottomRightPos().X
    local height = r:GetTopLeftPos().Y - 50
    local ef = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPEAR_OF_DESTINY, 0, Vector(math.random(min, max), height), Vector(0, 12), p)
      
    if (Game():GetFrameCount() % 30 ~= 0) then return end
  
    for k, v in pairs(e) do
      if (v.Type == EntityType.ENTITY_EFFECT and v.Variant == EffectVariant.SPEAR_OF_DESTINY and v.Position.Y > r:GetBottomRightPos().Y + 50) then
        v:Remove()
      end
    end
  end
  
  table.insert(TEventStorage, TEvent:new(45*30, true, false, SE__update, nil))
end

------- Award
function SpecialEvents:Award()
  
  local player = Isaac.GetPlayer(0)
  
  function SE__update ()
    local room = Game():GetRoom()
    if (room:GetType() == RoomType.ROOM_DEFAULT) then
      room:SpawnClearAward()
      room:SpawnClearAward()
    end
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(4, false, true, SE__update, nil))
end

------- Stanley Parable
function SpecialEvents:StanleyParable()
  local g = Game()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 1, pos, false)
  end
    
    IOTmod:_playSound(SoundEffect.SOUND_1UP)
end

------- Supernova (BOOOM BLAAAAAAAAAAAAAAAAAAAARGH)
function SpecialEvents:Supernova()
  
  function SE__update ()
    
    local g = Game()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    local ppos = player.Position
    g:GetRoom():MamaMegaExplossion()
    
    for i = 0, 3 do
      local mlaser = EntityLaser.ShootAngle(6, ppos, 90*i, 0, Vector(0,0), player)
      mlaser:SetActiveRotation(1, 999360, 2, true)
      mlaser.CollisionDamage = player.Damage*100;
      
      local laser = EntityLaser.ShootAngle(5, ppos, 90*i, 0, Vector(0,0), player)
      laser:SetActiveRotation(1, -999360, 10, true)
      laser.CollisionDamage = player.Damage*25;
    end
    
    if (player:GetHearts() >= 1) then
      player:AddHearts((-player:GetHearts())+1)
      player:AddSoulHearts(-player:GetSoulHearts())
    else
      player:AddSoulHearts(-player:GetSoulHearts() + 1)
    end
  end
  
  SE__update()
  IOTmod:_playSound(SoundEffect.SOUND_SUPERHOLY)
  table.insert(TEventStorage, TEvent:new(4, false, true, SE__update, nil))
end

------- DDoS
function SpecialEvents:DDoS()
  
  local s = SFXManager()
  
  function SE__update ()
    if (Game():GetFrameCount() % 8 == 0) then
      local room = Game():GetRoom()
      local p = Isaac.GetPlayer(0)
      local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true)
      Isaac.Spawn(EntityType.ENTITY_DART_FLY, 0,  0, pos, Vector(0, 0), p)
    end
  end
  
  s:Play(SND_ddosDialup, 1, 0, false, 1)
  table.insert(TEventStorage, TEvent:new(30*30, true, false, SE__update, nil))
end

------- Interstellar
function SpecialEvents:Interstellar()
  
  local s = SFXManager()
  
  function SE__update ()
    local room = Game():GetRoom()
    local p = Isaac.GetPlayer(0)
    
    local e = Isaac.GetRoomEntities()
    local sbh = false
    local pv = Vector(math.random(room:GetTopLeftPos().X, room:GetBottomRightPos().X), math.random(room:GetTopLeftPos().Y, room:GetBottomRightPos().Y))
    local sv = Vector(room:GetCenterPos().X - pv.X, room:GetCenterPos().Y - pv.Y):Normalized()
    local bl = Isaac.Spawn(EntityType.ENTITY_EFFECT, 103,  0, pv, Vector(sv.X*6, sv.Y*6), p)
    bl:SetColor(Color(0.149, 0.416, 0.804, 1, 7, 20, 40), 0, 0, false, false)
    for k, v in pairs(e) do
      if (v.Type ~= EntityType.ENTITY_EFFECT and v.Variant ~= 1100) then
        local vec = Vector(v.Position.X - room:GetCenterPos().X, v.Position.Y - room:GetCenterPos().Y):Normalized()
        
        if (v.Type == EntityType.ENTITY_PLAYER) then
          v:AddVelocity(Vector(-vec.X*0.8, -vec.Y*0.8))
        else
          v:AddVelocity(Vector(-vec.X*5, -vec.Y*5))
        end
        
        if (room:GetCenterPos():Distance(v.Position) <= 40) then
          if (v.Type == EntityType.ENTITY_PICKUP or v.Type == EntityType.ENTITY_TEAR or v.Type == EntityType.ENTITY_PROJECTILE or (v.Type == EntityType.ENTITY_EFFECT and v.Variant == 103)) then
            v:Die()
          elseif (v.Type == EntityType.ENTITY_PLAYER) then
            v:TakeDamage(0.5, DamageFlag.DAMAGE_LASER, EntityRef(p), 30)
          else
            v:TakeDamage(2, DamageFlag.DAMAGE_LASER, EntityRef(p), 10)
          end
        end
        
      end
      
      if (v.Type == 1000 and v.Variant == 1100) then
        sbh = true
      end
    end
    
    if (not sbh) then
      local bh = Isaac.Spawn(1000, 1100,  0, room:GetCenterPos(), Vector(0, 0), p)
      bh:GetSprite():Play("Default", true)
      for i = 0, 3 do
        local l = EntityLaser.ShootAngle(7, room:GetCenterPos(), 90*i, 0, Vector(0,0), bh)
        l:SetActiveRotation(1, 999360, 10, true)
      end
    end
  end
  
  function SE__over ()
    local e = Isaac.GetRoomEntities()
    for k, v in pairs(e) do
      if (v.Type == EntityType.ENTITY_EFFECT and v.Variant == 1100) then
        v:GetSprite():Play("Disappear", true)
        v:Die()
      end
    end
  end
  
  s:Play(SND_interstellar, 1, 0, false, 1)
  table.insert(TEventStorage, TEvent:new(30*30, true, false, SE__update, SE__over))
  
  local e = Isaac.GetRoomEntities()
    for k, v in pairs(e) do
      if (v.Type == EntityType.ENTITY_EFFECT and v.Variant == 1100) then
        v:Remove()
      end
    end
  
  SE__update()
  Game():Darken(-1, 30*30)
end

------- Invisible
function SpecialEvents:Invisible()
  
  local p = Isaac.GetPlayer(0)
    p.Visible = false;
  
  function SE__over ()
    local p = Isaac.GetPlayer(0)
    p.Visible = true;
  end
  
  function SE__update ()
    local p = Isaac.GetPlayer(0)
    p.Visible = false;
  end
  
  table.insert(TEventStorage, TEvent:new(40*30, true, false, SE__update, SE__over))
end

------- Good Music
function SpecialEvents:GoodMusic()
  local g = Game()
  local p = Isaac.GetPlayer(0)
  local s = SFXManager()
  
  function SE__update ()
    local e = Isaac.GetRoomEntities()
    
    for k, v in pairs(e) do
        e[k]:AddVelocity(Vector(math.random(-3,3), math.random(-3,3)))
    end
  end
  
  s:Play(SND_goodMusic, 2, 0, false, 1)
  table.insert(TEventStorage, TEvent:new(14*30, true, false, SE__update, nil))
  
end

------- Strabismus
function SpecialEvents:Strabismus()
  local g = Game()
  local p = Isaac.GetPlayer(0)
  
  function SE__update ()
    local e = Isaac.GetRoomEntities()
    
    for k, v in pairs(e) do
        if (e[k].Type == EntityType.ENTITY_TEAR) then e[k]:AddVelocity(Vector(math.random(-10,10), math.random(-10,10))) end
    end
  end
  
  table.insert(TEventStorage, TEvent:new(40*30, true, false, SE__update, nil))
  
end

------- Inverse
function SpecialEvents:Inverse()
  local g = Game()
  local p = Isaac.GetPlayer(0)
  
  function SE__update ()
    local p = Isaac.GetPlayer(0)
    local e = Isaac.GetRoomEntities()
    
    p:AddVelocity(Vector(-p:GetMovementJoystick().X*2, -p:GetMovementJoystick().Y*2))
    
    for k, v in pairs(e) do
        if (e[k].Type == EntityType.ENTITY_TEAR and e[k].FrameCount < 1) then e[k]:AddVelocity(Vector(-e[k].Velocity.X*2, -e[k].Velocity.Y*2)) end
    end
  end
  
  table.insert(TEventStorage, TEvent:new(45*30, true, false, SE__update, nil))
  
end

------- Slip
function SpecialEvents:Slip()
  local g = Game()
  local p = Isaac.GetPlayer(0)
  
  function SE__update ()
    local p = Isaac.GetPlayer(0)
    p:MultiplyFriction(1.15)
  end
  
  table.insert(TEventStorage, TEvent:new(45*30, true, false, SE__update, nil))
end

------- NoDMG
function SpecialEvents:NoDMG()
  local p = Isaac.GetPlayer(0)
  
  statStorage.damage = statStorage.damage - 100
  p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
  p:EvaluateItems()
  
  function SE__over ()
    local p = Isaac.GetPlayer(0)
    statStorage.damage = statStorage.damage + 100
    p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    p:EvaluateItems()
  end
  
  table.insert(TEventStorage, TEvent:new(40*30, true, false, nil, SE__over))
end

------- Whirlwind
function SpecialEvents:Whirlwind()
  local p = Isaac.GetPlayer(0)
  
  function SE__update ()
    local frame = Game():GetFrameCount()
    if (frame % 2 ~= 0) then return end
    local p = Isaac.GetPlayer(0)
    local k = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(math.cos(frame*0.2) * 8, math.sin(frame*0.2) * 8), p)
    
  end
  
  table.insert(TEventStorage, TEvent:new(40*30, true, false, SE__update, nil))
end

------- Russian Hackers
function SpecialEvents:RussianHackers()
  
  function SE__update ()
    local frame = Game():GetFrameCount()
    if (frame % 2 ~= 0) then return end
    local p = Isaac.GetPlayer(0)
    p:AddCoins(math.random(-1,1))
    p:AddKeys(math.random(-1,1))
    p:AddBombs(math.random(-1,1))
  end
  
  table.insert(TEventStorage, TEvent:new(10*30, true, false, SE__update, nil))
end

------- Machine Gun
function SpecialEvents:MachineGun()
  
  function SE__update ()
    local p = Isaac.GetPlayer(0)
    if (p:GetFireDirection() == Direction.NO_DIRECTION) then return end
    
    for i = 0, 3 do
      local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, p.Position, Vector(p:GetShootingInput().X*15+math.random(-3,3), p:GetShootingInput().Y*15+math.random(-3,3)), p):ToTear()
      t.CollisionDamage = 0.07
      t.Scale = 0.2
      t:ChangeVariant(TearVariant.METALLIC)
      t.KnockbackMultiplier = 10
    end
  end
  
  table.insert(TEventStorage, TEvent:new(30*30, true, false, SE__update, nil))
end

------- Toxic
function SpecialEvents:Toxic()
  
  function SE__update ()
    local p = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if (entities[i]:IsActiveEnemy()) then
        local ref = EntityRef(p)
        entities[i]:AddPoison(ref, math.random(100,300), 0.25)
      end
    end
    
    p:SetColor(Rainbow[4], 0, 0, false, false)
    
    for i = 0, math.random(2,4) do
      local pos = room:GetRandomPosition(2)
      if (p.Position:Distance(pos) >= 65) then
        Game():SpawnParticles(pos, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 10, 0, Rainbow[4], 0)
        Game():SpawnParticles(pos, EffectVariant.FART, 1, 0, Rainbow[4], 0)
        Game():Spawn(Buddies[4], 0, pos, Vector(0,0), p, 0, 0)
      end
    end
    
    for i = 0, math.random(5,10) do
      local pos = room:GetRandomPosition(2)
      if (p.Position:Distance(pos) >= 65) then
        Game():SpawnParticles(pos, EffectVariant.CREEP_GREEN, 1, 0, Rainbow[4], 0)
      end
    end
    
    room:SetWallColor(Color(0.5,1,0,1,50,100,-20))
    room:SetFloorColor(Color(0.5,1,0,1,50,100,-20))
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(5, false, true, SE__update, nil))
end

------- Crazy Doors
function SpecialEvents:CrazyDoors()
  
  function SE__update ()
    
    local frame = Game():GetFrameCount()
    if (frame % 15 ~= 0) then return end
    
    local p = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    for i = DoorSlot.LEFT0, DoorSlot.DOWN1 do
      if (room:IsDoorSlotAllowed(i) and room:GetDoor(i) ~= nil) then
        room:GetDoor(i):SetRoomTypes (room:GetType(), Doors[math.random(#Doors)])
      end
    end
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(40*30, true, false, SE__update, nil))
end

------- Rewind

local EV_rewind = {}
local EV_rewind_play = false

function SpecialEvents:Rewind()
  
  function SE__update ()
    
    local p = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    local s = SFXManager()
    
    if (#EV_rewind < 15*30 and not EV_rewind_play) then
      table.insert(EV_rewind, p.Velocity:__mul(-1))
    elseif (not EV_rewind_play) then
      EV_rewind_play = true
      s:Play(SND_rewind, 1, 0, false, 1)
    end
    
    if (#EV_rewind ~= 0 and EV_rewind_play) then
      p.Velocity = table.remove(EV_rewind, #EV_rewind)
    end
  end
  
  function SE__over ()
    EV_rewind = {}
    EV_rewind_play = false
  end
  
  table.insert(TEventStorage, TEvent:new(30*30, true, false, SE__update, SE__over))
  
end

------- SUPERHOT
function SpecialEvents:Superhot()
  
  function SE__update ()
    
    
    local p = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    local entities = Isaac.GetRoomEntities()
    
    room:SetFloorColor(Color(1,1,1,1,150,150,150))
    room:SetWallColor(Color(1,1,1,1,150,150,150))
    
    for i = 1, #entities do
      if (entities[i]:IsActiveEnemy() and entities[i]:IsVulnerableEnemy()) then
        if (math.abs(p.Velocity.X) < 0.2 and math.abs(p.Velocity.Y) < 0.2 and p:GetFireDirection() == Direction.NO_DIRECTION) then
          entities[i]:AddFreeze(EntityRef(p), 1)
          entities[i].Velocity = Vector(0,0)
          if (not entities[i]:IsBoss() and entities[i].HitPoints < entities[i].MaxHitPoints) then
            Game():SpawnParticles(entities[i].Position, EffectVariant.SPIKE, 20, math.random()*2, Rainbow[1], math.random()*5)
            entities[i]:Die()
            IOTmod:_playSound(SND_superhotBreak)
          end
        else
          entities[i]:Update()
        end
        
        entities[i]:SetColor(Rainbow[1], 0, 0, false, false)
      end
    end
    
  end
  
  function SE_over ()
    local room = Game():GetRoom()
    local entities = Isaac.GetRoomEntities()
    
    room:SetFloorColor(Color(1,1,1,1,0,0,0))
    room:SetWallColor(Color(1,1,1,1,0,0,0))
    
    for i = 1, #entities do
      if (entities[i]:IsActiveEnemy() and entities[i]:IsVulnerableEnemy()) then
        entities[i]:SetColor(Color(1,1,1,1,0,0,0), 0, 0, false, false)
      end
    end
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(40*30, true, false, SE__update, SE__over))
end

------- SCP-173

local EV_scp173_btime = 1
local EV_scp173_cd = 75
local EV_scp173_active = false

function SpecialEvents:SCP173()
  
  function SE__update ()
    
    local p = Isaac.GetPlayer(0)
    local entities = Isaac.GetRoomEntities()
    
    if (EV_scp173_cd > 0) then
      EV_scp173_cd = EV_scp173_cd - 1
      for i = 1, #entities do
        if (entities[i]:IsActiveEnemy()) then
          local ref = EntityRef(p)
          entities[i]:AddFreeze(ref, 1)
          entities[i].Velocity = Vector(0,0)
        end
      end
    elseif (EV_scp173_btime > -1) then
      EV_scp173_btime = EV_scp173_btime - 0.03
      
      if (math.abs(EV_scp173_btime) > 0.05) then
        for i = 1, #entities do
          if (entities[i]:IsActiveEnemy()) then
            local ref = EntityRef(p)
            entities[i]:AddFreeze(ref, 1)
            entities[i].Velocity = Vector(0,0)
          end
        end
      else
          for i = 1, #entities do
          if (entities[i]:IsActiveEnemy()) then
            for a = 0, 30 do
              entities[i]:Update()
            end
          end
        end
      end
    else
      for i = 1, #entities do
        if (entities[i]:IsActiveEnemy()) then
          local ref = EntityRef(p)
          entities[i]:AddFreeze(ref, 1)
          entities[i].Velocity = Vector(0,0)
        end
      end
      EV_scp173_cd = 75
      EV_scp173_btime = 1
    end
    
  end
  
  function SE__over ()
    
    EV_scp173_btime = 1
    EV_scp173_cd = 75
    EV_scp173_active = false
    
  end
  
  EV_scp173_active = true
  SE__update()
  table.insert(TEventStorage, TEvent:new(30*30, true, false, SE__update, SE__over))
end

------- Point of view

EV_PointOfView_Pos = 0

function SpecialEvents:PointOfView()
  
  function SE__update ()
    EV_PointOfView_Pos = math.random(1,3)
  end
  
  function SE__over ()
    EV_PointOfView_Pos = 0
  end
  
  SE__update()
  table.insert(TEventStorage, TEvent:new(8, false, true, SE__update, SE__over))
end

------- Radioactive
local EV_radioactive_intensity = 0

function SpecialEvents:Radioactive()
  
  function SE__update ()
    
    local p = Isaac.GetPlayer(0)
    local s = SFXManager()
  end
  
  function SE__over ()
  end
  
  table.insert(TEventStorage, TEvent:new(30*30, true, false, SE__update, SE__over))
  
end

function IOTmod:GetShaderParams(shaderName)
  
  if (shaderName == "Blink") then
    local params
    if (EV_scp173_active) then params = {Time = math.abs(EV_scp173_btime)} else params = {Time = 1} end
    return params;
  end
  
  if (shaderName == "ScreenRotate") then
    local params
    params = {Pos = EV_PointOfView_Pos}
    return params;
  end
  
  if (shaderName == "VHS") then
    local params
    params = {Enabled = 1, VHSPos = (Isaac.GetFrameCount()%150)/150}
    if (EV_rewind_play) then params.Enabled = 1 else params.Enabled = 0 end
    return params;
  end
  
  if (shaderName == "ColorSides") then
    local params
    params = {Enabled = EV_shader_ScreenSide_enabled, Intensity = EV_shader_ScreenSide_intensity, VColor = EV_shader_ScreenSide_color}
    return params;
  end
end

IOTmod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, IOTmod.GetShaderParams)
