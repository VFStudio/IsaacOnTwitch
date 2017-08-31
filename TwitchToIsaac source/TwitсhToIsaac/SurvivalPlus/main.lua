local SPlus = RegisterMod("SurvivalPlus", 1);
local require = require;
require('mobdebug').start();

--Multiroom/Time-based events

local World = {
  Time = {
      mins = 0,
      hours = 6,
      string = function ()
        local s = ""
        
        if self.hours < 10 then s = "0" + self.hours + ":" else s = self.hours + ":" end
        if self.mins < 10 then s = s + "0" + self.mins else s = s + self.mins end
        
        return s
      end,
      
      update = function ()
        if (self.mins < 60) then
          self.mins = self.mins + 1
        else
          self.mins = 0
          self.hours = self.hours + 1
          
        end
        
        if (self.hours == 24) then
          self.hours = 0
        end
      end
  }
}

--Items
local AI_Pistol = Isaac.GetItemIdByName("Pistol")
local AI_Rifle = Isaac.GetItemIdByName("Rifle")
local AI_DEBUG = Isaac.GetItemIdByName("DEBUG ITEM")

local switchWeaponMode = false

local Player = {
    armor = 0,
    armorTime = 30,
    activeWeapon = nil,
    activeWeaponPos = 1,
    name = "Isaac",
    weaponStorage = {
        {
          name = "Pistol",
          available = true,
          ammo = -1,
          fireDelay = 0,
          maxFireDelay = 0,
          shotSpeed = 0,
          damage = 0,
          tearHeight = 0,
          tearFallingSpeed = 0,
          tearFlags = 0,
          accuracy = 2,
          item = AI_Pistol
        },
        
        {
          name = "Rifle",
          available = true,
          ammo = 15,
          fireDelay = 25,
          maxFireDelay = 15,
          shotSpeed = 1.7,
          damage = 8,
          tearHeight = 1,
          tearFallingSpeed = 50,
          tearFlags = 0,
          accuracy = 0.5,
          item = AI_Rifle
        },
        
        {
          name = "Uzi",
          available = false,
          ammo = 45,
          fireDelay = 3,
          maxFireDelay = 1,
          shotSpeed = 1.5,
          damage = 3,
          tearHeight = 1,
          tearFallingSpeed = 50,
          tearFlags = 0,
          accuracy = 4
        },
        {
          name = "LaserGun",
          available = false,
          ammo = 20,
          fireDelay = 15,
          maxFireDelay = 5,
          shotSpeed = 1.5,
          damage = 9,
          tearHeight = 1,
          tearFallingSpeed = 50,
          tearFlags = 1<<22,
          accuracy = 0
        },
    }
}

World.__index = World
Player.__index = Player
Player.activeWeapon = Player.weaponStorage[1]

--Familars storage
local fams = {}

SPlus.funcs = {}

function SPlus.funcs:giveItem (name)
  local p = Isaac.GetPlayer(0);
  local item = Isaac.GetItemIdByName(name)
  p:AddCollectible(item, 0, true);
end

function SPlus.funcs:giveTrinket (name)
  local p = Isaac.GetPlayer(0);
  local item = Isaac.GetTrinketIdByName(name)
  p:AddTrinket(item);
end

----------------------------Cache Update (works through ass)------------------------------

function SPlus:cacheUpdate(player, cacheFlag)
  
  if (cacheFlag == CacheFlag.CACHE_DAMAGE) then
    Player.activeWeapon.damage = player.Damage
  
  elseif (cacheFlag == CacheFlag.CACHE_FIREDELAY) then
    Player.activeWeapon.fireDelay = player.FireDelay
    Player.activeWeapon.maxFireDelay = player.MaxFireDelay
      
  elseif (cacheFlag == CacheFlag.CACHE_SHOTSPEED) then
    Player.activeWeapon.shotSpeed = player.ShotSpeed
      
  elseif (cacheFlag == CacheFlag.CACHE_ALL) then
    if (switchWeaponMode) then
      player.Damage = Player.activeWeapon.damage
      player.FireDelay = Player.activeWeapon.fireDelay
      player.MaxFireDelay = Player.activeWeapon.maxFireDelay
      player.ShotSpeed = Player.activeWeapon.shotSpeed
      p:AddCollectible(Player.activeWeapon.item, 0, true);
      switchWeaponMode = false
    else
      Player.activeWeapon.damage = player.Damage
      Player.activeWeapon.fireDelay = player.FireDelay
      Player.activeWeapon.maxFireDelay = player.MaxFireDelay
      Player.activeWeapon.shotSpeed = player.ShotSpeed
    end

  end
  
end

----------------------------Post Update------------------------------
function SPlus:setTriggers()
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
    --Set triggers
  
  if lastRoom ~= l:GetCurrentRoomIndex() then
    lastRoom = l:GetCurrentRoomIndex()
    SPlus:T_RoomChanged(r)
  end
  
  if g:GetFrameCount() == 1 then
    SPlus:relaunchGame(p)
  end
  
  if lastStage ~= l:GetStage() then
    SPlus:T_StageChanged(l:GetStage())
    lastStage = l:GetStage()
  end
end


function SPlus:postUpdate()
  local g = Game()
  local r = g:GetRoom()
  local p = Isaac.GetPlayer(0)
  local l = g:GetLevel()
  local s = SFXManager()
  

  
  --Set subscribers and familiars pos
  local lastFamPos = p.Position
  
  for k, v in pairs(fams) do
    fams[k]:FollowPosition(lastFamPos)
    lastFamPos = fams[k].Position
  end
  
  --Check special pickups
  local entities = Isaac.GetRoomEntities()
  for k, v in pairs(entities) do
    local e = entities[k]
    if (entities[k].Type == EntityType.ENTITY_PICKUP) then
      
      --Armor
      if (e.Variant == 1000 and p:GetPlayerType() and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        
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
      if (e.Variant == 1001 and not e:IsDead() and p.Position:Distance(e.Position) <= 26) then
        s:Play (SoundEffect.SOUND_NICKELPICKUP, 1, 0, false, 1.1)
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
        s:Play (SoundEffect.SOUND_NICKELPICKUP, 1, 0, false, 1.3)
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
        s:Play (SoundEffect.SOUND_NICKELPICKUP, 1, 0, false, 1.45)
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
        s:Play (SoundEffect.SOUND_NICKELPICKUP, 1, 0, false, 1.55)
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
        s:Play (SoundEffect.SOUND_NICKELPICKUP, 1, 0, false, 1.65)
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
 
end

----------------------------Player get damage------------------------------
function SPlus:PlayerTakeDamage(p, damageAmnt, damageFlag, damageSource, damageCountdown)
  
  if (Player.armorTime > 0) then
    return false
  end
  
  if (damageFlag == DamageFlag.DAMAGE_FAKE) then
    return true
  end
  
	if(Player.armor > 0) then
		p:TakeDamage(0.0, DamageFlag.DAMAGE_FAKE, EntityRef(p), damageCountdown)
    Player.armorTime = 45
		local room = Game():GetRoom()
    local beforeDmg = Player.armor
    Player.armor = math.floor(Player.armor - (damageAmnt))
    
		if(Player.armor < 0) then
			Player.armor = 0
    end
    
    return false
  else
		return true
	end
end

----------------------------Post Perfect Update------------------------------
function SPlus:postPerfectUpdate()
  
  local g = Game();
  local r = g:GetRoom();
  local p = Isaac.GetPlayer(0);
  local l = g:GetLevel()
end

----------------------------Render------------------------------
 
function SPlus:Render()
  local p = Isaac.GetPlayer(0)
end

----------------------------Triggers------------------------------
function SPlus:T_gamePaused(g)
end

function SPlus:T_RoomChanged(room)
  local p = Isaac.GetPlayer(0)
  local g = Game()
  local ppos = EntityRef(p).Position
  
end

----------------------------Subscriber------------------------------
function SPlus:UpdateFamiliarSubscriber (familiar)
  if familiar.Variant == 1000 then
    local	player = Isaac.GetPlayer(0)
    sprite = familiar:GetSprite()
    
    if (player:GetFireDirection() ~= Direction.NO_DIRECTION) and (Game():GetFrameCount() % 35 == 0 or Game():GetFrameCount() % 35 < 12) then
      if player:GetHeadDirection() == Direction.LEFT then
        currentAnim = "ShootLeft"
        if (Game():GetFrameCount() % 35 == 0) then SPlus:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      elseif player:GetHeadDirection() == Direction.RIGHT then
        currentAnim = "ShootRight"
        if (Game():GetFrameCount() % 35 == 0) then SPlus:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      elseif player:GetHeadDirection() == Direction.UP then
        currentAnim = "ShootUp"
        if (Game():GetFrameCount() % 35 == 0) then SPlus:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
      elseif player:GetHeadDirection() == Direction.DOWN then
        currentAnim = "ShootDown"
        if (Game():GetFrameCount() % 35 == 0) then SPlus:ShootFamiliarSubscriber(familiar, player:GetHeadDirection()) end
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

function SPlus:ShootFamiliarSubscriber(f, dt)
  direct = Vector(0,0)
  
  if (dt == Direction.LEFT) then direct = Vector(-10, 0)
  elseif (dt == Direction.RIGHT) then direct = Vector(10, 0)
  elseif (dt == Direction.UP) then direct = Vector(0, -10)
  else direct = Vector(0, 10) end

  local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, f.Position, direct, f)
  tear:SetColor(f:GetColor(), 0, 0, false, false)
  
end

----------------------------NightBot------------------------------
function SPlus:UpdateFamiliarNightbot (familiar)
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
        if (not entities[k]:IsDead() and distBetween <= 16) then SPlus:TriggerFamiliarNightbot() end
      end
    end
  end
  
end


function SPlus:TriggerFamiliarNightbot ()
  local entities = Isaac.GetRoomEntities()
  
    for k, v in pairs(entities) do
      if entities[k].Type == EntityType.ENTITY_PROJECTILE then
        entities[k]:Die()
      end
    end
    Game():Darken(-0.5, 7);
end

----------------------------Twitch room generation------------------------------
function SPlus:TwitchRoomGen (room)
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
        SPlus:ReloadTwitchRoomPool ()
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
 
function SPlus:AI_Weapon_act()
  local	p = Isaac.GetPlayer(0)
  local activeWeapons = {}
  local allWeapon = 1
  local activeWeaponPos = 1
  
  for k, v in pairs(Player.weaponStorage) do
    allWeapon = allWeapon + 1
    if (v.available == true) then table.insert(activeWeapons, allWeapon) end
    if (v == Player.activeWeapon) then activeWeaponPos = #activeWeapons end
  end
  
  if (Player.activeWeaponPos >= activeWeapons[#activeWeapons]) then
    Player.activeWeaponPos = activeWeapons[1]
    Player.activeWeapon = Player.weaponStorage[activeWeapons[1]]
  else
    Player.activeWeaponPos = activeWeapons[activeWeaponPos+1]
    Player.activeWeapon = Player.weaponStorage[activeWeapons[activeWeaponPos+1]]
  end
  
  p:AddCollectible(Player.activeWeapon.item, 0, true);
end

function SPlus:AI_DEBUG_act()
  local	player = Isaac.GetPlayer(0)
	local	e = Isaac.GetRoomEntities()
  local game = Game()
  player.Position = Vector(0,0)
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

SPlus:AddCallback(ModCallbacks.MC_POST_RENDER, SPlus.Render)
SPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SPlus.cacheUpdate)
SPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, SPlus.postUpdate)
SPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, SPlus.setTriggers)
SPlus:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, SPlus.postPerfectUpdate)
SPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SPlus.PlayerTakeDamage, EntityType.ENTITY_PLAYER)

SPlus:AddCallback( ModCallbacks.MC_USE_ITEM, SPlus.AI_Weapon_act, AI_Pistol)
SPlus:AddCallback( ModCallbacks.MC_USE_ITEM, SPlus.AI_Weapon_act, AI_Rifle)
SPlus:AddCallback( ModCallbacks.MC_USE_ITEM, SPlus.AI_DEBUG_act, AI_DEBUG)

--If it new run
function SPlus:relaunchGame (p)

  p:AddCacheFlags(CacheFlag.CACHE_ALL)
  p:EvaluateItems()
  p:AddCollectible(AI_Pistol, 0, true);
  for k, v in pairs(fams) do
      fams[k] = nil
  end
  
end

function SPlus:T_StageChanged(stage)
end

----------------------------Others---------------------------------
function SPlus:_playSound(sound)
  local sound_entity = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, Vector(320,300), Vector(0,0), nil):ToNPC()
  sound_entity:PlaySound(sound, 1, 0, false, 1)
  sound_entity:Remove()
end

----------------------------Resources------------------------------

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

Rainbow = {
    Color(1,0,0,1,0,0,0),
    Color(1,0.5,0,1,0,0,0),
    Color(1,1,0,1,0,0,0),
    Color(0.5,1,0,1,0,0,0),
    Color(0,1,1,1,0,0,0),
    Color(0,0,1,1,0,0,0),
    Color(0.5,0,1,1,0,0,0)
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