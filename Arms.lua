--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Unit       = HL.Unit
local Player     = Unit.Player
local Target     = Unit.Target
local Pet        = Unit.Pet
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
-- HeroRotation
local HR         = HeroRotation

-- Azerite Essence Setup
local AE         = HL.Enum.AzeriteEssences
local AESpellIDs = HL.Enum.AzeriteEssenceSpellIDs

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
if not Spell.Warrior then Spell.Warrior = {} end
Spell.Warrior.Arms = {
  Skullsplitter                         = Spell(260643),
  DeadlyCalm                            = Spell(262228),
  DeadlyCalmBuff                        = Spell(262228),
  Ravager                               = Spell(152277),
  ColossusSmash                         = Spell(167105),
  Warbreaker                            = Spell(262161),
  ColossusSmashDebuff                   = Spell(208086),
  Bladestorm                            = Spell(227847),
  Cleave                                = Spell(845),
  Slam                                  = Spell(1464),
  CrushingAssaultBuff                   = Spell(278826),
  MortalStrike                          = Spell(12294),
  OverpowerBuff                         = Spell(7384),
  Dreadnaught                           = Spell(262150),
  ExecutionersPrecisionBuff             = Spell(242188),
  Execute                               = MultiSpell(163201, 281000),
  Overpower                             = Spell(7384),
  SweepingStrikesBuff                   = Spell(260708),
  TestofMight                           = Spell(275529),
  TestofMightBuff                       = Spell(275540),
  DeepWoundsDebuff                      = Spell(262115),
  SuddenDeathBuff                       = Spell(52437),
  StoneHeartBuff                        = Spell(225947),
  SweepingStrikes                       = Spell(260708),
  Whirlwind                             = Spell(1680),
  FervorofBattle                        = Spell(202316),
  Rend                                  = Spell(772),
  RendDebuff                            = Spell(772),
  AngerManagement                       = Spell(152278),
  SeismicWave                           = Spell(277639),
  Charge                                = Spell(100),
  HeroicLeap                            = Spell(6544),
  BloodFury                             = Spell(20572),
  Berserking                            = Spell(26297),
  ArcaneTorrent                         = Spell(50613),
  LightsJudgment                        = Spell(255647),
  Fireblood                             = Spell(265221),
  AncestralCall                         = Spell(274738),
  BagofTricks                           = Spell(312411),
  Avatar                                = Spell(107574),
  Massacre                              = Spell(281001),
  Pummel                                = Spell(6552),
  IntimidatingShout                     = Spell(5246),
  RazorCoralDebuff                      = Spell(303568),
  ConductiveInkDebuff                   = Spell(302565),
  BloodoftheEnemy                       = Spell(297108),
  MemoryofLucidDreams                   = Spell(298357),
  PurifyingBlast                        = Spell(295337),
  RippleInSpace                         = Spell(302731),
  ConcentratedFlame                     = Spell(295373),
  TheUnboundForce                       = Spell(298452),
  WorldveinResonance                    = Spell(295186),
  FocusedAzeriteBeam                    = Spell(295258),
  GuardianofAzeroth                     = Spell(295840),
  GuardianofAzerothBuff                 = Spell(295855),
  ReapingFlames                         = Spell(310690),
  ConcentratedFlameBurn                 = Spell(295368),
  RecklessForceBuff                     = Spell(302932),
  SeethingRageBuff                      = Spell(297126)
};
local S = Spell.Warrior.Arms;

-- Items
if not Item.Warrior then Item.Warrior = {} end
Item.Warrior.Arms = {
  PotionofFocusedResolve           = Item(168506),
  PotionofUnbridledFury            = Item(169299),
  AshvanesRazorCoral               = Item(169311, {13, 14}),
  AzsharasFontofPower              = Item(169314, {13, 14})
};
local I = Item.Warrior.Arms;

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.AshvanesRazorCoral:ID(),
  I.AzsharasFontofPower:ID()
}

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local InExecuteRange;

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Warrior.Commons,
  Arms = HR.GUISettings.APL.Warrior.Arms
};

-- Stuns
local StunInterrupts = {
  {S.IntimidatingShout, "Cast Intimidating Shout (Interrupt)", function () return true; end},
};

local EnemyRanges = {8}
local function UpdateRanges()
  for _, i in ipairs(EnemyRanges) do
    HL.GetEnemies(i);
  end
end

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function Precombat()
  -- flask
  -- food
  -- augmentation
  -- snapshot_stats
  if Everyone.TargetIsValid() then
    -- use_item,name=azsharas_font_of_power
    if I.AzsharasFontofPower:IsEquipReady() and Settings.Commons.UseTrinkets then
      if HR.Cast(I.AzsharasFontofPower, nil, Settings.Commons.TrinketDisplayStyle) then return "azsharas_font_of_power"; end
    end
    -- worldvein_resonance
    if S.WorldveinResonance:IsCastableP() then
      if HR.Cast(S.WorldveinResonance) then return "worldvein_resonance"; end
    end
    -- memory_of_lucid_dreams,if=talent.fervor_of_battle.enabled|!talent.fervor_of_battle.enabled&target.time_to_die>150
    if S.MemoryofLucidDreams:IsCastableP() and (S.FervorofBattle:IsAvailable() or not S.FervorofBattle:IsAvailable() and Target:TimeToDie() > 150) then
      if HR.Cast(S.MemoryofLucidDreams) then return "memory_of_lucid_dreams"; end
    end
    -- guardian_of_azeroth,if=talent.fervor_of_battle.enabled|talent.massacre.enabled&target.time_to_die>210|talent.rend.enabled&(target.time_to_die>210|target.time_to_die<145)
    if S.GuardianofAzeroth:IsCastableP() and (S.FervorofBattle:IsAvailable() or S.Massacre:IsAvailable() and Target:TimeToDie() > 210 or S.Rend:IsAvailable() and (Target:TimeToDie() > 210 or Target:TimeToDie() < 145)) then
      if HR.Cast(S.GuardianofAzeroth) then return "guardian_of_azeroth"; end
    end
    -- potion,name=potion_of_unbridled_fury,if=essence.condensed_lifeforce.major
    if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions and (Spell:EssenceEnabled(AE.CondensedLifeForce)) then
      if HR.CastSuggested(I.PotionofUnbridledFury) then return "potion 3"; end
    end
    -- potion,name=potion_of_focused_resolve,if=essence.memory_of_lucid_dreams.major
    if I.PotionofFocusedResolve:IsReady() and Settings.Commons.UsePotions and (Spell:EssenceEnabled(AE.MemoryofLucidDreams)) then
      if HR.CastSuggested(I.PotionofFocusedResolve) then return "potion 4"; end
    end
    -- potion
    if I.PotionofFocusedResolve:IsReady() then
      if HR.CastSuggested(I.PotionofFocusedResolve) then return "potion 5"; end
    end
  end
end

local function Movement()
  -- heroic_leap
  if S.HeroicLeap:IsCastableP() then
    if HR.Cast(S.HeroicLeap, Settings.Arms.GCDasOffGCD.HeroicLeap) then return "heroic_leap 16"; end
  end
end

local function Execute()
  -- skullsplitter,if=rage<52&buff.deadly_calm.down&buff.memory_of_lucid_dreams.down
  if S.Skullsplitter:IsCastableP("Melee") and (Player:Rage() < 52 and Player:BuffDownP(S.DeadlyCalmBuff) and Player:BuffDownP(S.MemoryofLucidDreams)) then
    if HR.Cast(S.Skullsplitter) then return "skullsplitter 6"; end
  end
  -- ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if S.Ravager:IsCastableP(40) and HR.CDsON() and (Player:BuffDownP(S.DeadlyCalmBuff) and (S.ColossusSmash:CooldownRemainsP() < 2 or (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 2))) then
    if HR.Cast(S.Ravager, Settings.Arms.GCDasOffGCD.Ravager) then return "ravager 12"; end
  end
  -- colossus_smash,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
  if S.ColossusSmash:IsCastableP("Melee") and HR.CDsON() and (not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) or (Player:BuffP(S.MemoryofLucidDreams) or S.MemoryofLucidDreams:CooldownRemainsP() > 10)) then
    if HR.Cast(S.ColossusSmash, Settings.Arms.GCDasOffGCD.ColossusSmash) then return "colossus_smash 22"; end
  end
  -- warbreaker,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
  if S.Warbreaker:IsCastableP("Melee") and HR.CDsON() and (not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) or (Player:BuffP(S.MemoryofLucidDreams) or S.MemoryofLucidDreams:CooldownRemainsP() > 10)) then
    if HR.Cast(S.Warbreaker, Settings.Arms.GCDasOffGCD.Warbreaker) then return "warbreaker 26"; end
  end
  -- deadly_calm
  if S.DeadlyCalm:IsCastableP() then
    if HR.Cast(S.DeadlyCalm, Settings.Arms.OffGCDasOffGCD.DeadlyCalm) then return "deadly_calm 30"; end
  end
  -- bladestorm,if=!buff.memory_of_lucid_dreams.up&buff.test_of_might.up&rage<30&!buff.deadly_calm.up
  if S.Bladestorm:IsCastableP() and HR.CDsON() and (Player:BuffDownP(S.MemoryofLucidDreams) and Player:BuffP(S.TestofMightBuff) and Player:Rage() < 30 and Player:BuffDownP(S.DeadlyCalmBuff)) then
    if HR.Cast(S.Bladestorm, Settings.Arms.GCDasOffGCD.Bladestorm, nil, 8) then return "bladestorm 32"; end
  end
  -- cleave,if=spell_targets.whirlwind>2
  if S.Cleave:IsReadyP("Melee") and (Cache.EnemiesCount[8] > 2) then
    if HR.Cast(S.Cleave) then return "cleave 36"; end
  end
  -- slam,if=buff.crushing_assault.up&buff.memory_of_lucid_dreams.down
  if S.Slam:IsReadyP("Melee") and (Player:BuffP(S.CrushingAssaultBuff) and Player:BuffDownP(S.MemoryofLucidDreams)) then
    if HR.Cast(S.Slam) then return "slam 38"; end
  end
  -- rend,if=remains<=duration*0.3&target.time_to_die>7
  if S.Rend:IsReadyP("Melee") and (Target:DebuffRemainsP(S.RendDebuff) <= Target:DebuffDuration(S.RendDebuff) * 0.3 and Target:TimeToDie() > 7) then
    if HR.Cast(S.Rend) then return "rend 40"; end
  end
  -- mortal_strike,if=buff.overpower.stack=2&talent.dreadnaught.enabled|buff.executioners_precision.stack=2
  if S.MortalStrike:IsReadyP("Melee") and (Player:BuffStackP(S.OverpowerBuff) == 2 and S.Dreadnaught:IsAvailable() or Player:BuffStackP(S.ExecutionersPrecisionBuff) == 2) then
    if HR.Cast(S.MortalStrike) then return "mortal_strike 42"; end
  end
  -- execute,if=buff.memory_of_lucid_dreams.up|buff.deadly_calm.up|debuff.colossus_smash.up|buff.test_of_might.up
  if S.Execute:IsReady("Melee") and (Player:BuffP(S.MemoryofLucidDreams) or Player:BuffP(S.DeadlyCalmBuff) or Target:DebuffP(S.ColossusSmashDebuff) or Player:BuffP(S.TestofMightBuff)) then
    if HR.Cast(S.Execute) then return "execute 50"; end
  end
  -- overpower
  if S.Overpower:IsCastableP("Melee") then
    if HR.Cast(S.Overpower) then return "overpower 54"; end
  end
  -- execute
  if S.Execute:IsReady("Melee") then
    if HR.Cast(S.Execute) then return "execute 56"; end
  end
end

local function FiveTarget()
  -- skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down)
  if S.Skullsplitter:IsCastableP("Melee") and (Player:Rage() < 60 and (not S.DeadlyCalm:IsAvailable() or Player:BuffDownP(S.DeadlyCalmBuff))) then
    if HR.Cast(S.Skullsplitter) then return "skullsplitter 58"; end
  end
  -- ravager,if=(!talent.warbreaker.enabled|cooldown.warbreaker.remains<2)
  if S.Ravager:IsCastableP(40) and HR.CDsON() and ((not S.Warbreaker:IsAvailable() or S.Warbreaker:CooldownRemainsP() < 2)) then
    if HR.Cast(S.Ravager, Settings.Arms.GCDasOffGCD.Ravager) then return "ravager 64"; end
  end
  -- colossus_smash,if=debuff.colossus_smash.down
  if S.ColossusSmash:IsCastableP("Melee") and HR.CDsON() and (Target:DebuffDownP(S.ColossusSmashDebuff)) then
    if HR.Cast(S.ColossusSmash, Settings.Arms.GCDasOffGCD.ColossusSmash) then return "colossus_smash 70"; end
  end
  -- warbreaker,if=debuff.colossus_smash.down
  if S.Warbreaker:IsCastableP("Melee") and HR.CDsON() and (Target:DebuffDownP(S.ColossusSmashDebuff)) then
    if HR.Cast(S.Warbreaker, Settings.Arms.GCDasOffGCD.Warbreaker) then return "warbreaker 74"; end
  end
  -- bladestorm,if=buff.sweeping_strikes.down&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.remains>4.5&!azerite.test_of_might.enabled)|buff.test_of_might.up)
  if S.Bladestorm:IsCastableP() and HR.CDsON() and (Player:BuffDownP(S.SweepingStrikesBuff) and (not S.DeadlyCalm:IsAvailable() or Player:BuffDownP(S.DeadlyCalmBuff)) and ((Target:DebuffRemainsP(S.ColossusSmashDebuff) > 4.5 and not S.TestofMight:AzeriteEnabled()) or Player:BuffP(S.TestofMightBuff))) then
    if HR.Cast(S.Bladestorm, Settings.Arms.GCDasOffGCD.Bladestorm, nil, 8) then return "bladestorm 78"; end
  end
  -- deadly_calm
  if S.DeadlyCalm:IsCastableP() then
    if HR.Cast(S.DeadlyCalm, Settings.Arms.OffGCDasOffGCD.DeadlyCalm) then return "deadly_calm 92"; end
  end
  -- cleave
  if S.Cleave:IsReadyP("Melee") then
    if HR.Cast(S.Cleave) then return "cleave 94"; end
  end
  -- execute,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|(buff.sudden_death.react|buff.stone_heart.react)&(buff.sweeping_strikes.up|cooldown.sweeping_strikes.remains>8)
  if S.Execute:IsReady("Melee") and ((not S.Cleave:IsAvailable() and Target:DebuffRemainsP(S.DeepWoundsDebuff) < 2) or (Player:BuffP(S.SuddenDeathBuff) or Player:BuffP(S.StoneHeartBuff)) and (Player:BuffP(S.SweepingStrikesBuff) or S.SweepingStrikes:CooldownRemainsP() > 8)) then
    if HR.Cast(S.Execute) then return "execute 96"; end
  end
  -- mortal_strike,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sweeping_strikes.up&buff.overpower.stack=2&(talent.dreadnaught.enabled|buff.executioners_precision.stack=2)
  if S.MortalStrike:IsReadyP("Melee") and ((not S.Cleave:IsAvailable() and Target:DebuffRemainsP(S.DeepWoundsDebuff) < 2) or Player:BuffP(S.SweepingStrikesBuff) and Player:BuffStackP(S.OverpowerBuff) == 2 and (S.Dreadnaught:IsAvailable() or Player:BuffStackP(S.ExecutionersPrecisionBuff) == 2)) then
    if HR.Cast(S.MortalStrike) then return "mortal_strike 110"; end
  end
  -- whirlwind,if=debuff.colossus_smash.up|(buff.crushing_assault.up&talent.fervor_of_battle.enabled)
  if S.Whirlwind:IsReadyP("Melee") and (Target:DebuffP(S.ColossusSmashDebuff) or (Player:BuffP(S.CrushingAssaultBuff) and S.FervorofBattle:IsAvailable())) then
    if HR.Cast(S.Whirlwind) then return "whirlwind 124"; end
  end
  -- whirlwind,if=buff.deadly_calm.up|rage>60
  if S.Whirlwind:IsReadyP("Melee") and (Player:BuffP(S.DeadlyCalmBuff) or Player:Rage() > 60) then
    if HR.Cast(S.Whirlwind) then return "whirlwind 132"; end
  end
  -- overpower
  if S.Overpower:IsCastableP("Melee") then
    if HR.Cast(S.Overpower) then return "overpower 136"; end
  end
  -- whirlwind
  if S.Whirlwind:IsReadyP("Melee") then
    if HR.Cast(S.Whirlwind) then return "whirlwind 138"; end
  end
end

local function Hac()
  -- rend,if=remains<=duration*0.3&(!raid_event.adds.up|buff.sweeping_strikes.up)
  if S.Rend:IsReadyP("Melee") and (Target:DebuffRemainsP(S.RendDebuff) <= S.RendDebuff:BaseDuration() * 0.3 and (not (Cache.EnemiesCount[8] > 1) or Player:BuffP(S.SweepingStrikesBuff))) then
    if HR.Cast(S.Rend) then return "rend 140"; end
  end
  -- skullsplitter,if=rage<60&(cooldown.deadly_calm.remains>3|!talent.deadly_calm.enabled)
  if S.Skullsplitter:IsCastableP("Melee") and (Player:Rage() < 60 and (S.DeadlyCalm:CooldownRemainsP() > 3 or not S.DeadlyCalm:IsAvailable())) then
    if HR.Cast(S.Skullsplitter) then return "skullsplitter 158"; end
  end
  -- deadly_calm,if=(cooldown.bladestorm.remains>6|talent.ravager.enabled&cooldown.ravager.remains>6)&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if S.DeadlyCalm:IsCastableP() and ((S.Bladestorm:CooldownRemainsP() > 6 or S.Ravager:IsAvailable() and S.Ravager:CooldownRemainsP() > 6) and (S.ColossusSmash:CooldownRemainsP() < 2 or (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 2))) then
    if HR.Cast(S.DeadlyCalm, Settings.Arms.OffGCDasOffGCD.DeadlyCalm) then return "deadly_calm 164"; end
  end
  -- ravager,if=(raid_event.adds.up|raid_event.adds.in>target.time_to_die)&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if S.Ravager:IsCastableP(40) and HR.CDsON() and (((Cache.EnemiesCount[8] > 1) or 10000000000 > Target:TimeToDie()) and (S.ColossusSmash:CooldownRemainsP() < 2 or (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 2))) then
    if HR.Cast(S.Ravager, Settings.Arms.GCDasOffGCD.Ravager) then return "ravager 178"; end
  end
  -- colossus_smash,if=raid_event.adds.up|raid_event.adds.in>40|(raid_event.adds.in>20&talent.anger_management.enabled)
  if S.ColossusSmash:IsCastableP("Melee") and HR.CDsON() and ((Cache.EnemiesCount[8] > 1) or 10000000000 > 40 or (10000000000 > 20 and S.AngerManagement:IsAvailable())) then
    if HR.Cast(S.ColossusSmash, Settings.Arms.GCDasOffGCD.ColossusSmash) then return "colossus_smash 188"; end
  end
  -- warbreaker,if=raid_event.adds.up|raid_event.adds.in>40|(raid_event.adds.in>20&talent.anger_management.enabled)
  if S.Warbreaker:IsCastableP("Melee") and HR.CDsON() and ((Cache.EnemiesCount[8] > 1) or 10000000000 > 40 or (10000000000 > 20 and S.AngerManagement:IsAvailable())) then
    if HR.Cast(S.Warbreaker, Settings.Arms.GCDasOffGCD.Warbreaker) then return "warbreaker 194"; end
  end
  -- bladestorm,if=(debuff.colossus_smash.up&raid_event.adds.in>target.time_to_die)|raid_event.adds.up&((debuff.colossus_smash.remains>4.5&!azerite.test_of_might.enabled)|buff.test_of_might.up)
  if S.Bladestorm:IsCastableP() and HR.CDsON() and ((Target:DebuffP(S.ColossusSmashDebuff) and 10000000000 > Target:TimeToDie()) or (Cache.EnemiesCount[8] > 1) and ((Target:DebuffRemainsP(S.ColossusSmashDebuff) > 4.5 and not S.TestofMight:AzeriteEnabled()) or Player:BuffP(S.TestofMightBuff))) then
    if HR.Cast(S.Bladestorm, Settings.Arms.GCDasOffGCD.Bladestorm, nil, 8) then return "bladestorm 200"; end
  end
  -- overpower,if=!raid_event.adds.up|(raid_event.adds.up&azerite.seismic_wave.enabled)
  if S.Overpower:IsCastableP("Melee") and (not (Cache.EnemiesCount[8] > 1) or ((Cache.EnemiesCount[8] > 1) and S.SeismicWave:AzeriteEnabled())) then
    if HR.Cast(S.Overpower) then return "overpower 212"; end
  end
  -- cleave,if=spell_targets.whirlwind>2
  if S.Cleave:IsReadyP("Melee") and (Cache.EnemiesCount[8] > 2) then
    if HR.Cast(S.Cleave) then return "cleave 220"; end
  end
  -- execute,if=!raid_event.adds.up|(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sudden_death.react
  if S.Execute:IsReady("Melee") and ((not S.Cleave:IsAvailable() and Target:DebuffRemainsP(S.DeepWoundsDebuff) < 2) or Player:BuffStackP(S.SuddenDeathBuff)) then
    if HR.Cast(S.Execute) then return "execute 222"; end
  end
  -- mortal_strike,if=!raid_event.adds.up|(!talent.cleave.enabled&dot.deep_wounds.remains<2)
  if S.MortalStrike:IsReadyP("Melee") and (not S.Cleave:IsAvailable() and Target:DebuffRemainsP(S.DeepWoundsDebuff) < 2) then
    if HR.Cast(S.MortalStrike) then return "mortal_strike 232"; end
  end
  -- whirlwind,if=raid_event.adds.up
  if S.Whirlwind:IsReadyP("Melee") then
    if HR.Cast(S.Whirlwind) then return "whirlwind 240"; end
  end
  -- overpower
  if S.Overpower:IsCastableP("Melee") then
    if HR.Cast(S.Overpower) then return "overpower 244"; end
  end
  -- whirlwind,if=talent.fervor_of_battle.enabled
  if S.Whirlwind:IsReadyP("Melee") and (S.FervorofBattle:IsAvailable()) then
    if HR.Cast(S.Whirlwind) then return "whirlwind 246"; end
  end
  -- slam,if=!talent.fervor_of_battle.enabled&!raid_event.adds.up
  if S.Slam:IsReadyP("Melee") and (not S.FervorofBattle:IsAvailable()) then
    if HR.Cast(S.Slam) then return "slam 250"; end
  end
end

local function SingleTarget()
  -- skullsplitter,if=rage<56&buff.deadly_calm.down&buff.memory_of_lucid_dreams.down
  if S.Skullsplitter:IsCastableP("Melee") and (Player:Rage() < 56 and Player:BuffDownP(S.DeadlyCalmBuff) and Player:BuffDownP(S.MemoryofLucidDreams)) then
    if HR.Cast(S.Skullsplitter) then return "skullsplitter 272"; end
  end
  -- ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if S.Ravager:IsCastableP(40) and HR.CDsON() and (Player:BuffDownP(S.DeadlyCalmBuff) and (S.ColossusSmash:CooldownRemainsP() < 2 or (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 2))) then
    if HR.Cast(S.Ravager, Settings.Arms.GCDasOffGCD.Ravager) then return "ravager 278"; end
  end
  -- colossus_smash,if=!essence.condensed_lifeforce.enabled&!talent.massacre.enabled&(target.time_to_pct_20>10|target.time_to_die>50)|essence.condensed_lifeforce.enabled&!talent.massacre.enabled&(target.time_to_pct_20>10|target.time_to_die>80)|talent.massacre.enabled&(target.time_to_pct_35>10|target.time_to_die>50)
  if S.ColossusSmash:IsCastableP("Melee") and HR.CDsON() and (not Spell:EssenceEnabled(AE.CondensedLifeForce) and not S.Massacre:IsAvailable() and (Target:TimeToX(20) > 10 or Target:TimeToDie() > 50) or Spell:EssenceEnabled(AE.CondensedLifeForce) and not S.Massacre:IsAvailable() and (Target:TimeToX(20) > 10 or Target:TimeToDie() > 80) or S.Massacre:IsAvailable() and (Target:TimeToX(35) > 10 or Target:TimeToDie() > 50)) then
    if HR.Cast(S.ColossusSmash, Settings.Arms.GCDasOffGCD.ColossusSmash) then return "colossus_smash 288"; end
  end
  -- warbreaker,if=!essence.condensed_lifeforce.enabled&!talent.massacre.enabled&(target.time_to_pct_20>10|target.time_to_die>50)|essence.condensed_lifeforce.enabled&!talent.massacre.enabled&(target.time_to_pct_20>10|target.time_to_die>80)|talent.massacre.enabled&(target.time_to_pct_35>10|target.time_to_die>50)
  if S.Warbreaker:IsCastableP("Melee") and HR.CDsON() and (not Spell:EssenceEnabled(AE.CondensedLifeForce) and not S.Massacre:IsAvailable() and (Target:TimeToX(20) > 10 or Target:TimeToDie() > 50) or Spell:EssenceEnabled(AE.CondensedLifeForce) and not S.Massacre:IsAvailable() and (Target:TimeToX(20) > 10 or Target:TimeToDie() > 80) or S.Massacre:IsAvailable() and (Target:TimeToX(35) > 10 or Target:TimeToDie() > 50)) then
    if HR.Cast(S.Warbreaker, Settings.Arms.GCDasOffGCD.Warbreaker) then return "warbreaker 292"; end
  end
  -- deadly_calm
  if S.DeadlyCalm:IsCastableP() then
    if HR.Cast(S.DeadlyCalm, Settings.Arms.OffGCDasOffGCD.DeadlyCalm) then return "deadly_calm 296"; end
  end
  -- execute,if=buff.sudden_death.react
  if S.Execute:IsReady("Melee") and (Player:BuffP(S.SuddenDeathBuff)) then
    if HR.Cast(S.Execute) then return "execute 298"; end
  end
  -- bladestorm,if=cooldown.mortal_strike.remains&debuff.colossus_smash.down&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.up&!azerite.test_of_might.enabled)|buff.test_of_might.up)&buff.memory_of_lucid_dreams.down&rage<40
  if S.Bladestorm:IsCastableP() and HR.CDsON() and (not S.MortalStrike:CooldownUpP() and Target:DebuffDownP(S.ColossusSmashDebuff) and (not S.DeadlyCalm:IsAvailable() or Player:BuffDownP(S.DeadlyCalmBuff)) and ((Target:DebuffP(S.ColossusSmashDebuff) and not S.TestofMight:AzeriteEnabled()) or Player:BuffP(S.TestofMight)) and Player:BuffDownP(S.MemoryofLucidDreams) and Player:Rage() < 40) then
    if HR.Cast(S.Bladestorm, Settings.Arms.GCDasOffGCD.Bladestorm, nil, 8) then return "bladestorm 302"; end
  end
  -- cleave,if=spell_targets.whirlwind>2
  if S.Cleave:IsReadyP("Melee") and (Cache.EnemiesCount[8] > 2) then
    if HR.Cast(S.Cleave) then return "cleave 316"; end
  end
  -- overpower,if=(!talent.rend.enabled&dot.deep_wounds.remains&rage<70&buff.memory_of_lucid_dreams.down&debuff.colossus_smash.down)|(talent.rend.enabled&dot.deep_wounds.remains&dot.rend.remains>gcd&rage<70&buff.memory_of_lucid_dreams.down&debuff.colossus_smash.down)
  if S.Overpower:IsCastableP("Melee") and ((not S.Rend:IsAvailable() and Target:DebuffP(S.DeepWoundsDebuff) and Player:Rage() < 70 and Player:BuffDownP(S.MemoryofLucidDreams) and Target:DebuffDownP(S.ColossusSmashDebuff)) or (S.Rend:IsAvailable() and Target:DebuffP(S.DeepWoundsDebuff) and Target:DebuffRemainsP(S.RendDebuff) > Player:GCD() and Player:Rage() < 70 and Player:BuffDownP(S.MemoryofLucidDreams) and Target:DebuffDownP(S.ColossusSmashDebuff))) then
    if HR.Cast(S.Overpower) then return "overpower 318"; end
  end
  -- mortal_strike
  if S.MortalStrike:IsReadyP("Melee") then
    if HR.Cast(S.MortalStrike) then return "mortal_strike 322"; end
  end
  -- rend,if=remains<=duration*0.3
  if S.Rend:IsReadyP("Melee") and (Target:DebuffRemainsP(S.RendDebuff) <= Target:DebuffDuration(S.RendDebuff) * 0.3) then
    if HR.Cast(S.Rend) then return "rend 324"; end
  end
  -- whirlwind,if=(((buff.memory_of_lucid_dreams.up)|(debuff.colossus_smash.up)|(buff.deadly_calm.up))&talent.fervor_of_battle.enabled)|((buff.memory_of_lucid_dreams.up|rage>89)&debuff.colossus_smash.up&buff.test_of_might.down&!talent.fervor_of_battle.enabled)
  if S.Whirlwind:IsReadyP("Melee") and ((((Player:BuffP(S.MemoryofLucidDreams)) or (Target:DebuffP(S.ColossusSmashDebuff)) or (Player:BuffP(S.DeadlyCalmBuff))) and S.FervorofBattle:IsAvailable()) or ((Player:BuffP(S.MemoryofLucidDreams) or Player:Rage() > 89) and Target:DebuffP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff) and not S.FervorofBattle:IsAvailable())) then
    if HR.Cast(S.Whirlwind) then return "whirlwind 326"; end
  end
  -- slam,if=!talent.fervor_of_battle.enabled&(buff.memory_of_lucid_dreams.up|debuff.colossus_smash.up)
  if S.Slam:IsReadyP("Melee") and (not S.FervorofBattle:IsAvailable() and (Player:BuffP(S.MemoryofLucidDreams) or Target:DebuffP(S.ColossusSmashDebuff))) then
    if HR.Cast(S.Slam) then return "slam 328"; end
  end
  -- overpower
  if S.Overpower:IsCastableP("Melee") then
    if HR.Cast(S.Overpower) then return "overpower 330"; end
  end
  -- whirlwind,if=talent.fervor_of_battle.enabled&(buff.test_of_might.up|debuff.colossus_smash.down&buff.test_of_might.down&rage>60)
  if S.Whirlwind:IsReadyP("Melee") and (S.FervorofBattle:IsAvailable() and (Player:BuffP(S.TestofMightBuff) or Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff) and Player:Rage() > 60)) then
    if HR.Cast(S.Whirlwind) then return "whirlwind 332"; end
  end
  -- slam,if=!talent.fervor_of_battle.enabled
  if S.Slam:IsReadyP("Melee") and (not S.FervorofBattle:IsAvailable()) then
    if HR.Cast(S.Slam) then return "slam 340"; end
  end
end

--- ======= ACTION LISTS =======
local function APL()
  UpdateRanges()
  Everyone.AoEToggleEnemiesUpdate()
  
  InExecuteRange = Target:HealthPercentage() < 20 or (S.Massacre:IsAvailable() and Target:HealthPercentage() < 35)

  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  if Everyone.TargetIsValid() then
    -- charge
    if S.Charge:IsReadyP() and S.Charge:ChargesP() >= 1 then
      if HR.Cast(S.Charge, Settings.Arms.GCDasOffGCD.Charge, nil, 25) then return "charge 351"; end
    end
    -- Interrupts
    local ShouldReturn = Everyone.Interrupt(5, S.Pummel, Settings.Commons.OffGCDasOffGCD.Pummel, StunInterrupts); if ShouldReturn then return ShouldReturn; end
    -- auto_attack
    if ((not Target:IsInRange("Melee")) and Target:IsInRange(40)) then
      return Movement();
    end
    -- potion,if=(target.health.pct<21|talent.massacre.enabled&target.health.pct<36)&(buff.memory_of_lucid_dreams.up|buff.guardian_of_azeroth.up)|!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major&(target.health.pct<21|talent.massacre.enabled&target.health.pct<36)&debuff.colossus_smash.up|target.time_to_die<25
    if I.PotionofFocusedResolve:IsReady() and Settings.Commons.UsePotions and (InExecuteRange and (Player:BuffP(S.MemoryofLucidDreams) or Player:BuffP(S.GuardianofAzerothBuff)) or not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and (Target:HealthPercentage() < 21 or S.Massacre:IsAvailable() and Target:HealthPercentage() < 36) and Target:DebuffP(S.ColossusSmashDebuff) or Target:TimeToDie() < 25) then
      if HR.CastSuggested(I.PotionofFocusedResolve) then return "potion 354"; end
    end
    if (HR.CDsON()) then
      -- blood_fury,if=buff.memory_of_lucid_dreams.up&buff.test_of_might.up|buff.guardian_of_azeroth.up&debuff.colossus_smash.up|buff.seething_rage.up|(!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major&!essence.blood_of_the_enemy.major&debuff.colossus_smash.up)
      if S.BloodFury:IsCastableP() and (Player:BuffP(S.MemoryofLucidDreams) and Player:BuffP(S.TestofMightBuff) or Player:BuffP(S.GuardianofAzerothBuff) and Target:DebuffP(S.ColossusSmashDebuff) or Player:BuffP(S.SeethingRageBuff) or (not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and not Spell:MajorEssenceEnabled(AE.BloodoftheEnemy) and Target:DebuffP(S.ColossusSmashDebuff))) then
        if HR.Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "blood_fury 356"; end
      end
      -- berserking,if=buff.memory_of_lucid_dreams.up&buff.test_of_might.up|buff.guardian_of_azeroth.up&debuff.colossus_smash.up|buff.seething_rage.up|(!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major&!essence.blood_of_the_enemy.major&debuff.colossus_smash.up)
      if S.Berserking:IsCastableP() and (Player:BuffP(S.MemoryofLucidDreams) and Player:BuffP(S.TestofMightBuff) or Player:BuffP(S.GuardianofAzerothBuff) and Target:DebuffP(S.ColossusSmashDebuff) or Player:BuffP(S.SeethingRageBuff) or (not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and not Spell:MajorEssenceEnabled(AE.BloodoftheEnemy) and Target:DebuffP(S.ColossusSmashDebuff))) then
        if HR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "berserking 360"; end
      end
      -- arcane_torrent,if=buff.memory_of_lucid_dreams.down&rage<50&(cooldown.mortal_strike.remains>gcd|(target.health.pct<20|talent.massacre.enabled&target.health.pct<35))
      if S.ArcaneTorrent:IsCastableP() and (Player:BuffP(S.MemoryofLucidDreams) and Player:Rage() < 50 and (S.MortalStrike:CooldownRemainsP() > Player:GCD() or InExecuteRange)) then
        if HR.Cast(S.ArcaneTorrent, Settings.Commons.OffGCDasOffGCD.Racials, nil, 8) then return "arcane_torrent 364"; end
      end
      -- lights_judgment,if=debuff.colossus_smash.down&buff.memory_of_lucid_dreams.down&cooldown.mortal_strike.remains
      if S.LightsJudgment:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.MemoryofLucidDreams) and not S.MortalStrike:CooldownUpP()) then
        if HR.Cast(S.LightsJudgment, Settings.Commons.OffGCDasOffGCD.Racials, nil, 40) then return "lights_judgment 370"; end
      end
      -- fireblood,if=buff.memory_of_lucid_dreams.up&buff.test_of_might.up|buff.guardian_of_azeroth.up&debuff.colossus_smash.up|buff.seething_rage.up|(!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major&!essence.blood_of_the_enemy.major&debuff.colossus_smash.up)
      if S.Fireblood:IsCastableP() and (Player:BuffP(S.MemoryofLucidDreams) and Player:BuffP(S.TestofMightBuff) or Player:BuffP(S.GuardianofAzerothBuff) and Target:DebuffP(S.ColossusSmashDebuff) or Player:BuffP(S.SeethingRageBuff) or (not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and not Spell:MajorEssenceEnabled(AE.BloodoftheEnemy) and Target:DebuffP(S.ColossusSmashDebuff))) then
        if HR.Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "fireblood 374"; end
      end
      -- ancestral_call,if=buff.memory_of_lucid_dreams.up&buff.test_of_might.up|buff.guardian_of_azeroth.up&debuff.colossus_smash.up|buff.seething_rage.up|(!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major&!essence.blood_of_the_enemy.major&debuff.colossus_smash.up)
      if S.AncestralCall:IsCastableP() and (Player:BuffP(S.MemoryofLucidDreams) and Player:BuffP(S.TestofMightBuff) or Player:BuffP(S.GuardianofAzerothBuff) and Target:DebuffP(S.ColossusSmashDebuff) or Player:BuffP(S.SeethingRageBuff) or (not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and not Spell:MajorEssenceEnabled(AE.BloodoftheEnemy) and Target:DebuffP(S.ColossusSmashDebuff))) then
        if HR.Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return "ancestral_call 378"; end
      end
      -- bag_of_tricks,if=debuff.colossus_smash.down&buff.memory_of_lucid_dreams.down&cooldown.mortal_strike.remains
      if S.BagofTricks:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.MemoryofLucidDreams) and not S.MortalStrike:CooldownUpP()) then
        if HR.Cast(S.BagofTricks, Settings.Commons.OffGCDasOffGCD.Racials, nil, 40) then return "bag_of_tricks 379"; end
      end
    end
    -- use_item,name=ashvanes_razor_coral,if=!debuff.razor_coral_debuff.up|((target.health.pct<20.1|talent.massacre.enabled&target.health.pct<35.1)&(buff.memory_of_lucid_dreams.up&(cooldown.memory_of_lucid_dreams.remains<106|cooldown.memory_of_lucid_dreams.remains<117&target.time_to_die<20&!talent.massacre.enabled)|buff.guardian_of_azeroth.up&debuff.colossus_smash.up))|essence.condensed_lifeforce.major&target.health.pct<20|(target.health.pct<30.1&debuff.conductive_ink_debuff.up&!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major)|(!debuff.conductive_ink_debuff.up&!essence.memory_of_lucid_dreams.major&!essence.condensed_lifeforce.major&debuff.colossus_smash.up)
    if I.AshvanesRazorCoral:IsEquipReady() and Settings.Commons.UseTrinkets and (Target:DebuffDownP(S.RazorCoralDebuff) or (InExecuteRange and (Player:BuffP(S.MemoryofLucidDreams) and (S.MemoryofLucidDreams:CooldownRemainsP() < 106 or S.MemoryofLucidDreams:CooldownRemainsP() < 117 and Target:TimeToDie() < 20 and not S.Massacre:IsAvailable()) or Player:BuffP(S.GuardianofAzerothBuff) and Target:DebuffP(S.ColossusSmashDebuff))) or Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and Target:HealthPercentage() < 20 or (Target:HealthPercentage() < 30.1 and Target:DebuffP(S.ConductiveInkDebuff) and not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce)) or (Target:DebuffDownP(S.ConductiveInkDebuff) and not Spell:MajorEssenceEnabled(AE.MemoryofLucidDreams) and not Spell:MajorEssenceEnabled(AE.CondensedLifeForce) and Target:DebuffP(S.ColossusSmashDebuff))) then
      if HR.Cast(I.AshvanesRazorCoral, nil, Settings.Commons.TrinketDisplayStyle, 40) then return "ashvanes_razor_coral 381"; end
    end
    -- avatar,if=cooldown.colossus_smash.remains<8|(talent.warbreaker.enabled&cooldown.warbreaker.remains<8)
    if S.Avatar:IsCastableP() and HR.CDsON() and (S.ColossusSmash:CooldownRemainsP() < 8 or (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 8)) then
      if HR.Cast(S.Avatar, Settings.Arms.GCDasOffGCD.Avatar) then return "avatar 382"; end
    end
    -- sweeping_strikes,if=spell_targets.whirlwind>1&(cooldown.bladestorm.remains>10|cooldown.colossus_smash.remains>8|azerite.test_of_might.enabled)
    if S.SweepingStrikes:IsCastableP() and (Cache.EnemiesCount[8] > 1 and (S.Bladestorm:CooldownRemainsP() > 10 or S.ColossusSmash:CooldownRemainsP() > 8 or S.TestofMight:AzeriteEnabled())) then
      if HR.Cast(S.SweepingStrikes) then return "sweeping_strikes 390"; end
    end
    -- blood_of_the_enemy,if=(buff.test_of_might.up|(debuff.colossus_smash.up&!azerite.test_of_might.enabled))&(target.time_to_die>90|(target.health.pct<20|talent.massacre.enabled&target.health.pct<35))
    if S.BloodoftheEnemy:IsCastableP() and ((Player:BuffP(S.TestofMightBuff) or (Target:DebuffP(S.ColossusSmashDebuff) and not S.TestofMight:IsAvailable())) and (Target:TimeToDie() > 90 or InExecuteRange)) then
      if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle, 12) then return "blood_of_the_enemy"; end
    end
    -- purifying_blast,if=!debuff.colossus_smash.up&!buff.test_of_might.up
    if S.PurifyingBlast:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff)) then
      if HR.Cast(S.PurifyingBlast, nil, Settings.Commons.EssenceDisplayStyle, 40) then return "purifying_blast"; end
    end
    -- ripple_in_space,if=!debuff.colossus_smash.up&!buff.test_of_might.up
    if S.RippleInSpace:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff)) then
      if HR.Cast(S.RippleInSpace, nil, Settings.Commons.EssenceDisplayStyle) then return "ripple_in_space"; end
    end
    -- worldvein_resonance,if=!debuff.colossus_smash.up&!buff.test_of_might.up
    if S.WorldveinResonance:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff)) then
      if HR.Cast(S.WorldveinResonance, nil, Settings.Commons.EssenceDisplayStyle) then return "worldvein_resonance"; end
    end
    -- focused_azerite_beam,if=!debuff.colossus_smash.up&!buff.test_of_might.up
    if S.FocusedAzeriteBeam:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff)) then
      if HR.Cast(S.FocusedAzeriteBeam, nil, Settings.Commons.EssenceDisplayStyle) then return "focused_azerite_beam"; end
    end
    -- reaping_flames,if=!debuff.colossus_smash.up&!buff.test_of_might.up
    if (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff)) then
      local ShouldReturn = Everyone.ReapingFlamesCast(Settings.Commons.EssenceDisplayStyle); if ShouldReturn then return ShouldReturn; end
    end
    -- concentrated_flame,if=!debuff.colossus_smash.up&!buff.test_of_might.up&dot.concentrated_flame_burn.remains=0
    if S.ConcentratedFlame:IsCastableP() and (Target:DebuffDownP(S.ColossusSmashDebuff) and Player:BuffDownP(S.TestofMightBuff) and Target:DebuffDownP(S.ConcentratedFlameBurn)) then
      if HR.Cast(S.ConcentratedFlame, nil, Settings.Commons.EssenceDisplayStyle, 40) then return "concentrated_flame"; end
    end
    -- the_unbound_force,if=buff.reckless_force.up
    if S.TheUnboundForce:IsCastableP() and (Player:BuffP(S.RecklessForceBuff)) then
      if HR.Cast(S.TheUnboundForce, nil, Settings.Commons.EssenceDisplayStyle, 40) then return "the_unbound_force"; end
    end
    -- guardian_of_azeroth,if=!talent.warbreaker.enabled&cooldown.colossus_smash.remains<5&(target.time_to_die>210|(target.health.pct<20|talent.massacre.enabled&target.health.pct<35)|target.time_to_die<31)
    if S.GuardianofAzeroth:IsCastableP() and (not S.Warbreaker:IsAvailable() and S.ColossusSmash:CooldownRemainsP() < 5 and (Target:TimeToDie() > 210 or InExecuteRange or Target:TimeToDie() < 31)) then
      if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "guardian_of_azeroth colossus_smash"; end
    end
    -- guardian_of_azeroth,if=talent.warbreaker.enabled&cooldown.warbreaker.remains<5&(target.time_to_die>210|(target.health.pct<20|talent.massacre.enabled&target.health.pct<35)|target.time_to_die<31)
    if S.GuardianofAzeroth:IsCastableP() and (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 5 and (Target:TimeToDie() > 210 or InExecuteRange or Target:TimeToDie() < 31)) then
      if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "guardian_of_azeroth warbreaker"; end
    end
    -- memory_of_lucid_dreams,if=!talent.warbreaker.enabled&cooldown.colossus_smash.remains<1&(target.time_to_die>150|(target.health.pct<20|talent.massacre.enabled&target.health.pct<35))
    if S.MemoryofLucidDreams:IsCastableP() and (not S.Warbreaker:IsAvailable() and S.ColossusSmash:CooldownRemainsP() < 1 and (Target:TimeToDie() > 150 or InExecuteRange)) then
      if HR.Cast(S.MemoryofLucidDreams, nil, Settings.Commons.EssenceDisplayStyle) then return "memory_of_lucid_dreams"; end
    end
    -- memory_of_lucid_dreams,if=talent.warbreaker.enabled&cooldown.warbreaker.remains<1&(target.time_to_die>150|(target.health.pct<20|talent.massacre.enabled&target.health.pct<35))
    if S.MemoryofLucidDreams:IsCastableP() and (S.Warbreaker:IsAvailable() and S.Warbreaker:CooldownRemainsP() < 1 and (Target:TimeToDie() > 150 or InExecuteRange)) then
      if HR.Cast(S.MemoryofLucidDreams, nil, Settings.Commons.EssenceDisplayStyle) then return "memory_of_lucid_dreams 2"; end
    end
    -- run_action_list,name=hac,if=raid_event.adds.exists
    if (Cache.EnemiesCount[8] > 1) then
      return Hac();
    end
    -- run_action_list,name=five_target,if=spell_targets.whirlwind>4
    if (Cache.EnemiesCount[8] > 4) then
      return FiveTarget();
    end
    -- run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
    if (InExecuteRange) then
      return Execute();
    end
    -- run_action_list,name=single_target
    if (true) then
      return SingleTarget();
    end
  end
end

local function Init()
  HL.RegisterNucleusAbility(152277, 8, 6)               -- Ravager
  HL.RegisterNucleusAbility(227847, 8, 6)               -- Bladestorm
  HL.RegisterNucleusAbility(845, 8, 6)                  -- Cleave
  HL.RegisterNucleusAbility(1680, 8, 6)                 -- Whirlwind
end

HR.SetAPL(71, APL, Init)
