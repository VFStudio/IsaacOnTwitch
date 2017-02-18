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

-- Event timer
local nowEvent = {
  active = false,
  ontime = false,
  duration = 0,
  rooms = 0,
  onover = nil,
  ontrigger = nil,
  trc = false
}

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
            }
        }
    }
}

--Items
local PI_kappa = Isaac.GetItemIdByName("Kappa")
local PI_goldenKappa = Isaac.GetItemIdByName("Golden Kappa")
local PI_notLikeThis = Isaac.GetItemIdByName("Not Like This")
local PI_kappaPride = Isaac.GetItemIdByName("Kappa Pride")
local PI_futureMan = Isaac.GetItemIdByName("Future Man")
local PI_kreygasm = Isaac.GetItemIdByName("Kreygasm")
local PI_curseLit = Isaac.GetItemIdByName("Curse Lit")
local PI_tropPunch = Isaac.GetItemIdByName("AMP Trop Punch")
local AI_twitchRaid = Isaac.GetItemIdByName("Twitch Raid")
local AI_TTours = Isaac.GetItemIdByName("TTours")
local AI_voteYea = Isaac.GetItemIdByName("Vote Yea")
local AI_voteNay = Isaac.GetItemIdByName("Vote Nay")
local AI_DEBUG = Isaac.GetItemIdByName("DEBUG ITEM")
local FI_subscriber = Isaac.GetItemIdByName("Subscriber")
local FI_nightbot = Isaac.GetItemIdByName("Nightbot")
local FI_stinkyCheese = Isaac.GetItemIdByName("Stinky Cheese")

local PI_kappa_num = 0
local PI_goldenKappa_num = 0
local PI_tropPunch_num = 0
local FI_subscriber_num = 0
local FI_stinky_have = false
local FI_nightbot_have = false

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
  obj.time = 10*60*30
  obj.color = nil
  
  setmetatable(obj, self)
  self.__index = self; return obj
end

local subs = {}

--Familars storage
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
  elseif name == "Charge" then p:FullCharge()
  elseif name == "Discharge" then p:DischargeActiveItem() end
end

function IOTmod.funcs:giveEvent (name)
  local p = Isaac.GetPlayer(0);
  local g = Game()
  local r = g:GetRoom()
  if name == "Slow" then r:SetBrokenWatchState(1)
  elseif name == "Poop" then SpecialEvents:Poop()
  elseif name == "Richy" then SpecialEvents:Richy()
  elseif name == "Earthquake" then SpecialEvents:Earthquake()
  elseif name == "Charm" then SpecialEvents:Charm()
  elseif name == "Hell" then SpecialEvents:Hell()
  elseif name == "Spiky" then SpecialEvents:Spiky()
  elseif name == "Award" then SpecialEvents:Award()
  elseif name == "AngelRage" then SpecialEvents:AngelRage()
  elseif name == "DevilRage" then SpecialEvents:DevilRage()
  elseif name == "RainbowRain" then SpecialEvents:RainbowRain()
  elseif name == "CallToDark" then SpecialEvents:CallToDark()
  elseif name == "RUN" then SpecialEvents:RUN()
  elseif name == "FlashJump" then SpecialEvents:FlashJump()
  elseif name == "EyesBleed" then SpecialEvents:EyesBleed()
  elseif name == "StanleyParable" then SpecialEvents:StanleyParable()
  elseif name == "Supernova" then SpecialEvents:Supernova()
  elseif name == "GoodMusic" then SpecialEvents:GoodMusic()
  elseif name == "Strabismus" then SpecialEvents:Strabismus()
  elseif name == "Inverse" then SpecialEvents:Inverse()
  elseif name == "Slip" then SpecialEvents:Slip()
  elseif name == "NoDMG" then SpecialEvents:NoDMG()
  elseif name == "Whirlwind" then SpecialEvents:Whirlwind()
  elseif name == "DDoS" then SpecialEvents:DDoS()
  elseif name == "Invisible" then SpecialEvents:Invisible()
  elseif name == "Discharge" then p:DischargeActiveItem() end
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
  
  --Check invincible from Twitch Heart
  if (twitchHeartInv > 0) then
    twitchHeartInv = twitchHeartInv - 1
  end
  
  --Remove old subscribers
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
      p:RemoveCollectible(CollectibleType.COLLECTIBLE_BELT)
    else
      bitsTime.gray.frames = bitsTime.gray.frames - 1
    end
  end
  
  if (bitsTime.purple.enable) then
    if (bitsTime.purple.frames <= 0) then
      bitsTime.purple.enable = false
      p:RemoveCollectible(CollectibleType.COLLECTIBLE_SPOON_BENDER)
    else
      bitsTime.purple.frames = bitsTime.purple.frames - 1
    end
  end
  
  if (bitsTime.green.enable) then
    if (bitsTime.green.frames <= 0) then
      bitsTime.green.enable = false
      p:RemoveCollectible(CollectibleType.COLLECTIBLE_TOXIC_SHOCK)
    else
      bitsTime.green.frames = bitsTime.green.frames - 1
    end
  end
  
  if (bitsTime.blue.enable) then
    if (bitsTime.blue.frames <= 0) then
      bitsTime.blue.enable = false
      p:RemoveCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
    else
      bitsTime.blue.frames = bitsTime.blue.frames - 1
    end
  end
  
  if (bitsTime.red.enable) then
    if (bitsTime.red.frames <= 0) then
      bitsTime.red.enable = false
      p:RemoveCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
      p:RemoveCollectible(CollectibleType.COLLECTIBLE_MAW_OF_VOID)
    else
      bitsTime.red.frames = bitsTime.red.frames - 1
    end
  end
  
  -- Check time event
  if (nowEvent.active == true and nowEvent.ontime == true) then
      
    if (nowEvent.duration > 0) then
      if (nowEvent.trc == false and nowEvent.ontrigger ~= nil) then nowEvent.ontrigger(r, p) end
      nowEvent.duration = nowEvent.duration - 1
    else
      nowEvent.active = false
      if (nowEvent.onover ~= nil) then nowEvent.onover(r, p) end
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
  
  --If player pickup Dyinky Cheese
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
  
  --Check special pickups
  local entities = Isaac.GetRoomEntities()
  for k, v in pairs(entities) do
    local e = entities[k]
    if (entities[k].Type == EntityType.ENTITY_PICKUP) then
      
      --Twitch Heart
      if (e.Variant == 1000 and p:GetPlayerType() ~= PlayerType.PLAYER_THELOST and p:GetPlayerType() ~= PlayerType.PLAYER_KEEPER
        and not ((p:GetMaxHearts() + p:GetSoulHearts() + twitchHearts) /2 >= 12)
        and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        
        IOTmod:_playSound(SoundEffect.SOUND_BOSS2_BUBBLES)
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
      if (e.Variant == 1001 and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        IOTmod:_playSound(SoundEffect.SOUND_KEY_DROP0)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        if (bitsTime.gray.enable) then
          bitsTime.gray.frames = bitsTime.gray.frames + (30 * 45) end
        
        if (not p:HasCollectible(CollectibleType.COLLECTIBLE_BELT)) then
          p:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false)
          bitsTime.gray.frames = bitsTime.gray.frames + (30 * 45)
          bitsTime.gray.enable = true
        end
      end
      
      --Bits B
      if (e.Variant == 1002 and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        IOTmod:_playSound(SoundEffect.SOUND_KEY_DROP0)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        if (bitsTime.purple.enable) then
          bitsTime.purple.frames = bitsTime.purple.frames + (30 * 45) end
        
        if (not p:HasCollectible(CollectibleType.COLLECTIBLE_SPOON_BENDER)) then
          p:AddCollectible(CollectibleType.COLLECTIBLE_SPOON_BENDER, 0, false)
          bitsTime.purple.enable = true
          bitsTime.purple.frames = bitsTime.purple.frames + 30 * 45
        end
      end
      
      --Bits C
      if (e.Variant == 1003 and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        IOTmod:_playSound(SoundEffect.SOUND_KEY_DROP0)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        if (bitsTime.green.enable) then
          bitsTime.green.frames = bitsTime.green.frames + (30 * 60) end
        
        if (not p:HasCollectible(CollectibleType.COLLECTIBLE_TOXIC_SHOCK)) then
          p:AddCollectible(CollectibleType.COLLECTIBLE_TOXIC_SHOCK, 0, false)
          bitsTime.green.enable = true
          bitsTime.green.frames = bitsTime.green.frames + 30 * 60
        end
      end
      
      --Bits D
      if (e.Variant == 1004 and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        IOTmod:_playSound(SoundEffect.SOUND_KEY_DROP0)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        if (bitsTime.blue.enable) then
          bitsTime.blue.frames = bitsTime.blue.frames + (30 * 120) end
        
        if (not p:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) then
          p:AddCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE, 0, false)
          bitsTime.blue.enable = true
          bitsTime.blue.frames = bitsTime.blue.frames + 30 * 120
        end
      end
      
      --Bits E
      if (e.Variant == 1005 and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        IOTmod:_playSound(SoundEffect.SOUND_KEY_DROP0)
        e:GetSprite():Play("Collect", false)
        e:Die()
        
        if (bitsTime.red.enable) then
          bitsTime.red.frames = bitsTime.red.frames + (30 * 240) end
        
        if (not p:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and not p:HasCollectible(CollectibleType.COLLECTIBLE_MAW_OF_VOID)) then
          p:AddCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE, 0, false)
          p:AddCollectible(CollectibleType.COLLECTIBLE_MAW_OF_VOID, 0, false)
          bitsTime.red.enable = true
          bitsTime.red.frames = bitsTime.red.frames + 30 * 240
        end
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
      for i = 0, IOLink.Input.Data.count do
        Isaac.Spawn(EntityType.ENTITY_PICKUP, 1001 + IOLink.Input.Data.type, 0, r:FindFreePickupSpawnPosition(r:GetCenterPos(), 0, true), Vector(0,0), p)
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
  
  if Game():IsPaused() ~= IOLink.Output.Param.pause then
    IOTmod:T_gamePaused(Game())
  end
  local ev = IOLink.Input.Data
  local tp = IOLink.Input.Param.textparam
  local p = Isaac.GetPlayer(0)
  --Isaac.DebugString(json.encode(IOLink.Input.Param))
  
  --Render twitch hearts
  if (twitchHearts > 0 and Game():GetLevel():GetCurses () ~= LevelCurse.CURSE_OF_THE_UNKNOWN) then
    twitchHeartFullSprite:SetOverlayRenderPriority(true)
    twitchHeartFullSprite:RenderLayer(1, Vector(0,0))
    twitchHeartHalfSprite:SetOverlayRenderPriority(true)
    twitchHeartHalfSprite:RenderLayer(1, Vector(0,0))
    
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
        TopVector = Vector((i-1)*12 + 50, 13)
      else
        TopVector = Vector((i-7)*12 + 50, 23)
      end
        
      if (not ishalf or i < hearts+twfull-1) then
        twitchHeartFullSprite:Render(TopVector, zv, zv)
      else
        twitchHeartHalfSprite:Render(TopVector, zv, zv)
      end
    end
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
    Isaac.RenderText(subs[k].name, fpos.X-3 * #subs[k].name, fpos.Y-40, subs[k].color.R, subs[k].color.G, subs[k].color.B, 0.8)
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
  local ppos = EntityRef(p).Position
  
  -- Check room-based event
  if (nowEvent.active == true and nowEvent.ontime == false) then
      
    if (nowEvent.duration > 0) then
      if (nowEvent.trc == true and nowEvent.ontrigger ~= nil) then nowEvent.ontrigger(g:GetRoom(), Isaac.GetPlayer(0)) end
      nowEvent.duration = nowEvent.duration - 1
    else
      nowEvent.active = false
      if (nowEvent.onover ~= nil) then nowEvent.onover(g:GetRoom(), Isaac.GetPlayer(0)) end
    end
    
  end
  
  -- Check time event with room trigger
  if (nowEvent.active == true and nowEvent.ontime == true) then
    if (nowEvent.trc == true and nowEvent.ontrigger ~= nil) then nowEvent.ontrigger(r, p) end
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
      if (entities[k]:IsVulnerableEnemy() and not entities[k]:HasEntityFlags(EntityFlag.FLAG_POISON)) then
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
      
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1004), room:GetGridPosition(32), Vector(0,0), nil, 0, 0)
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1004), room:GetGridPosition(42), Vector(0,0), nil, 0, 0)
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1004), room:GetGridPosition(92), Vector(0,0), nil, 0, 0)
      g:Spawn(EntityType.ENTITY_PICKUP, math.random(1000, 1004), room:GetGridPosition(102), Vector(0,0), nil, 0, 0)
      
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
		if entities[i]:IsVulnerableEnemy() then
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
  if (math.random() < 0.20) then twitchRoomGenOnStage = true end
  
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
  table.insert(twitchRoomItemPool, AI_twitchRaid)
  table.insert(twitchRoomItemPool, AI_TTours)
  table.insert(twitchRoomItemPool, AI_voteYea)
  table.insert(twitchRoomItemPool, AI_voteNay)
  table.insert(twitchRoomItemPool, FI_nightbot)
  table.insert(twitchRoomItemPool, FI_stinkyCheese)
end

function IOTmod:T_StageChanged(stage)
  PI_curseLit_activated = false
  
  twitchRoomIndex = -1
  if (math.random() < 0.20) then twitchRoomGenOnStage = true end
end

----------------------------Others---------------------------------
-- WTF?! I need to spawn entity every time I want to play a sound? EDMUUUUUND!!!
function IOTmod:_playSound(sound)
  local sound_entity = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, Vector(320,300), Vector(0,0), nil):ToNPC()
  sound_entity:PlaySound(sound, 1, 0, false, 1)
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
    Color(1,0,0,1,0,0,0),
    Color(1,0.5,0,1,0,0,0),
    Color(1,1,0,1,0,0,0),
    Color(0.5,1,0,1,0,0,0),
    Color(0,1,1,1,0,0,0),
    Color(0,0,1,1,0,0,0),
    Color(0.5,0,1,1,0,0,0)
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
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  room:SetFloorColor(Color(0.424,0.243,0.063,1,-50,-50,-50))
  room:SetWallColor(Color(0.424,0.243,0.063,1,-50,-50,-50))
  
  for i = 0, room:GetGridSize()/7 do
    local max = room:GetBottomRightPos()
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, pos, false)
  end
  IOTmod:_playSound(SoundEffect.SOUND_FART)
end

------- Earthquake
function SpecialEvents:Earthquake()
  local g = Game()
  local	entities = Isaac.GetRoomEntities()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  g:ShakeScreen(140)
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = false,
      duration = 3,
      onover = nil,
      ontrigger = SpecialEvents.Earthquake,
      trc = true
    }
    
  end
  
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
function SpecialEvents:Charm()
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = false,
      duration = 3,
      onover = nil,
      ontrigger = SpecialEvents.Charm,
      trc = true
    }
    
  end
  
	for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
			entities[i]:AddCharmed(600)
		end
	end
end

------- Hell
function SpecialEvents:Hell()
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
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
    local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
    pos = room:FindFreeTilePosition(pos, 0.5)
    Isaac.GridSpawn(GridEntityType.GRID_SPIKES_ONOFF, math.random(2), pos, false)
  end
    
    room:SetFloorColor(Color(0.4,0.4,0.4,1,50,50,50))
    room:SetWallColor(Color(0.4,0.4,0.4,1,50,50,50))
    IOTmod:_playSound(SoundEffect.SOUND_METAL_BLOCKBREAK)
end

------- Angel Rage
function SpecialEvents:AngelRage()
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
      local ref = EntityRef(entities[i])
      g:SpawnParticles(ref.Position, EffectVariant.CRACK_THE_SKY, 4, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
      g:SpawnParticles(ref.Position, EffectVariant.BLUE_FLAME, 1, math.random(), Color(1, 1, 1, 1, 50, 50, 50), math.random())
		end
	end
    
    IOTmod:_playSound(SoundEffect.SOUND_HOLY)
    room:SetFloorColor(Color(1,1,1,1,150,150,150))
    room:SetWallColor(Color(1,1,1,1,150,150,150))
    g:Darken(-1, 40);
end

------- Devil Rage (very originally)
function SpecialEvents:DevilRage()
  local g = Game()
  local entities = Isaac.GetRoomEntities()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  for i = 1, #entities do
		if entities[i]:IsVulnerableEnemy() then
      local ref = EntityRef(entities[i])
      g:SpawnParticles(ref.Position, EffectVariant.CRACK_THE_SKY, 6, math.random(), Color(1, 0, 0, 1, 50, 0, 0), math.random())
      g:SpawnParticles(ref.Position, EffectVariant.BLUE_FLAME, 1, math.random(), Color(1, 0, 0, 1, 50, 0, 0), math.random())
		end
	end
    
    IOTmod:_playSound(SoundEffect.SOUND_SATAN_APPEAR)
    room:SetFloorColor(Color(0,0,0,1,-50,-50,-50))
    room:SetWallColor(Color(0,0,0,1,-50,-50,-50))
    g:Darken(1, 60);
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
  local room = Game():GetRoom()
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = false,
      duration = 3,
      onover = nil,
      ontrigger = SpecialEvents.RUN,
      trc = true
    }
    
    IOTmod:_playSound(SoundEffect.SOUND_MOM_VOX_EVILLAUGH)
  end
  
  local max = room:GetBottomRightPos()
  local pos = Vector(math.random(math.floor(max.X)), math.random(math.floor(max.Y)))
  pos = room:FindFreeTilePosition(pos, 0.5)
  g:SpawnParticles(pos, EffectVariant.HUSH_LASER, 1, math.random(), Rainbow[math.random(#Rainbow)], math.random())
  
end

------- Flash Jump
function SpecialEvents:FlashJump()
  local g = Game()
  local l = g:GetLevel()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = false,
      duration = 5,
      onover = nil,
      ontrigger = SpecialEvents.FlashJump,
      trc = true
    }
    
  end
  
  g:MoveToRandomRoom(false)
end

------- Eyes Bleed
function SpecialEvents:EyesBleed()
  local g = Game()
  local l = g:GetLevel()
  g:Darken(1, 400)
  g:ShakeScreen(400)
  g:AddPixelation(400)
end
------- Award
function SpecialEvents:Award()
  
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = false,
      duration = 3,
      onover = nil,
      ontrigger = SpecialEvents.Award,
      trc = true
    }
    
  end
  
  room:SpawnClearAward()
  room:SpawnClearAward()
  room:SpawnClearAward()
  room:SpawnClearAward()
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
  local g = Game()
  local player = Isaac.GetPlayer(0)
  local room = Game():GetRoom()
  local ppos = player.Position
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 15*30,
      onover = nil,
      ontrigger = SpecialEvents.Supernova,
      trc = true
    }
    
    IOTmod:_playSound(SoundEffect.SOUND_SUPERHOLY)
  end
  
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

------- DDoS
function SpecialEvents:DDoS()
  
  function SE__update ()
    if (Game():GetFrameCount() % 5 == 0) then
      local room = Game():GetRoom()
      local p = Isaac.GetPlayer(0)
      local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 20, true)
      Isaac.Spawn(EntityType.ENTITY_DART_FLY, 0,  0, pos, Vector(0, 0), p)
    end
  end
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 20*30,
      onover = nil,
      ontrigger = SE__update,
      trc = false
    }
  end
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
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 25*30,
      onover = SE__over,
      ontrigger = SE__update,
      trc = false
    }
  end
end

------- Good Music
function SpecialEvents:GoodMusic()
  local g = Game()
  local p = Isaac.GetPlayer(0)
  
  function SE__update ()
    local e = Isaac.GetRoomEntities()
    
    for k, v in pairs(e) do
        e[k]:AddVelocity(Vector(math.random(-2,2), math.random(-2,2)))
    end
  end
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 14*30,
      onover = nil,
      ontrigger = SE__update,
      trc = false
    }
  end
  
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
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 25*30,
      onover = nil,
      ontrigger = SE__update,
      trc = false
    }
  end
  
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
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 20*30,
      onover = nil,
      ontrigger = SE__update,
      trc = false
    }
  end
  
end

------- Slip
function SpecialEvents:Slip()
  local g = Game()
  local p = Isaac.GetPlayer(0)
  
  function SE__update ()
    local p = Isaac.GetPlayer(0)
    local e = Isaac.GetRoomEntities()
    
    p:MultiplyFriction(1.15)
    
    for k, v in pairs(e) do
        if (e[k].Type > 8) then e[k]:MultiplyFriction(1.15) end
    end
  end
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 30*30,
      onover = nil,
      ontrigger = SE__update,
      trc = false
    }
  end
  
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
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 20*30,
      onover = SE__over,
      ontrigger = nil,
      trc = false
    }
  end
  
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
  
  if (nowEvent.duration < 1) then
    nowEvent = {
      active = true,
      ontime = true,
      duration = 30*30,
      onover = nil,
      ontrigger = SE__update,
      trc = false
    }
  end
end
