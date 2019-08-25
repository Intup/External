local Champions = {
    ['Ashe'] = true
}
--Checking Champion
if Champions[myHero.charName] == nil then
    print('does not support ' .. myHero.charName)
    return
end

require("DamageLib")
--Checking arquive
if FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
    require('GamsteronPrediction');
else
    print("Requires GamsteronPrediction please download the file thanks!");
    return
end


--Spells Interuppt
local Spell_Interrupt_Enemys = {
    ['GlacialStorm'] = {
        {slot = _R, 
        SpellName = 'GlacialStorm', DurationSpell = 6}
    },
    ['Caitlynaceinthehole'] = {
        {slot = _R, 
        SpellName = 'Caitlynaceinthehole', DurationSpell = 1}
    },
    ['ezrealtrueshotbarrage'] = {
        {slot = _R, 
        SpellName = 'ezrealtrueshotbarrage', DurationSpell = 1}
    },
    ['drain'] = {
        {slot = _W, 
        SpellName = 'drain', DurationSpell = 5},
    },
    ['gragasw'] = {
        {slot = _W, 
        SpellName = 'gragasw', DurationSpell = 0.75}
    },
    ['janna'] = {
        {slot = _R, 
        SpellName = 'reapthewhirlwind', DurationSpell = 3}
    },
    ['karthus'] = {
        {slot = _R, 
        SpellName = 'karthusfallenone', DurationSpell = 3}
    },
    ['katarina'] = {
        {slot = _R, 
        SpellName = 'katarinar', DurationSpell = 2.5}
    },
    ['lucianr'] = {
        {slot = _R, 
        SpellName = 'lucianr', DurationSpell = 2}
    },
    ['lux'] = {
        {slot = _R, 
        SpellName = 'luxmalicecannon', DurationSpell = 0.5}
    },
    ['malzahar'] = {
        {slot = _R, 
        SpellName = 'malzaharr', DurationSpell = 2.5}
    },
    ['masteryi'] = {
        {slot = _W, 
        SpellName = 'meditate', DurationSpell = 4}
    },
    ['missfortune'] = {
        {slot = _R, 
        SpellName = 'missfortunebullettime', DurationSpell = 3}
    },
    ['pantheon'] = {
        {slot = _R, 
        SpellName = 'pantheonrjump', DurationSpell = 2}
    },
    ['shen'] = {
        {slot = _R, 
        SpellName = 'shenr', DurationSpell = 3}
    },
    ['twistedfate'] = {
        {slot = _R, 
        SpellName = 'gate', DurationSpell = 1.5}
    },
    ['varus'] = {
        {slot = _Q, 
        SpellName = 'varusq', DurationSpell = 4}
    },
    ['warwick'] = {
        {slot = _R, 
        SpellName = 'warwickr', DurationSpell = 1.5}
    },
    ['xerath'] = {
        {slot = _R, 
        SpellName = 'xerathlocusofpower2', DurationSpell = 3}
    }
}

local function IsReady(spell)
    return Game.CanUseSpell(spell) == 0
end

--Target
local function TargetSelection(range) -- All scripts
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range, "AD")
	end
end

local function EnemyArea(pos, range)
	local enemies_in_range = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
		    if Hero and Hero.pos:DistanceTo(pos) < range and Hero.valid and Hero.visible and not Hero.dead then 
			    enemies_in_range[#enemies_in_range + 1] = Hero
            end
        end
	end
	return enemies_in_range
end

--Fix
class 'Ashe'

function Ashe:AsheBuff(unit, name)
    for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
    	if buff and string.lower(buff.name) == string.lower(name) then
    		if Game.Timer() <= buff.expireTime then
	      		return true, buff.startTime
    		end
    	end
  	end
  	return false, 0
end

function Ashe:MenuLoading()
    self.Menu = MenuElement({type = MENU, id = "Ashe", name = "IntAshe", leftIcon = "https://raw.githubusercontent.com/Intup/External/master/Champion%20AIO/Ashe.png"})
    self.Menu:MenuElement({id = "ac", name = "Combo Settings", type = MENU})
    self.Menu.ac:MenuElement({id = "cq", name = "Use Q", value = true})
    self.Menu.ac:MenuElement({id = "qaa", name = "^- Auto Attack reset", value = true})
    self.Menu.ac:MenuElement({id = "cw", name = "Use W", value = true})
    self.Menu.ac:MenuElement({id = "cr", name = "Use R", value = true})
    self.Menu.ac:MenuElement({id = "minenemy", name = "Min. Enemies for R", value = 3, min = 1, max = 5, step = 5})
    self.Menu.ac:MenuElement({id = "minhp", name = "^- in. Health Percent for R", value = 30, min = 1, max = 100, step = 1})
    self.Menu.ac:MenuElement({id = "combekey", name = "Combo", key = string.byte(" ")})
    --Harass
    self.Menu:MenuElement({id = "ah", name = "Harass Settings", type = MENU})
    self.Menu.ah:MenuElement({id = "hq", name = "Use Q", value = true})
    self.Menu.ah:MenuElement({id = "waa", name = "^- Auto Attack reset", value = true})
    self.Menu.ah:MenuElement({id = "hw", name = "Use W", value = true})
    self.Menu.ah:MenuElement({id = "harasskey", name = "Harass", key = string.byte("C")})
    --Misc
    self.Menu:MenuElement({id = "am", name = "Misc Settings", type = MENU})
    self.Menu.am:MenuElement({id = "rint", name = "Use R for Interrupt Spells", value = true})
    self.Menu.am:MenuElement({id = "rgap", name = "Use R for GapClosing", value = true})
end

function Ashe:OnTick()
    self.pred_w = {Delay = 0.25, Radius = (15 * math.pi / 57.5), Range = 1200, Speed = 1500, Collision = true}
    self.pred_r = {Delay = 0.25, Radius = 150, Range = 1500, Speed = 1600, Collision = false}
    --Interrupt
    if self.Menu.am.rint:Value() then 
        for i = 1, Game.HeroCount() do
            local Hero = Game.Hero(i)
            if Hero.isEnemy and Hero.visible and not Hero.dead then 
                if Hero and Hero.activeSpell and Hero.activeSpell.valid then
                    local distance = myHero.pos:DistanceTo(Hero.pos)
                    local spell = Hero.activeSpell
                    if Spell_Interrupt_Enemys[spell.name] and spell.isChanneling and spell.castEndTime - Game.Timer() > 0 and distance < 1200 then
                        Control.CastSpell(HK_R, Hero);
                    end
                end
            end
        end
    end
    --GapClose
    if self.Menu.am.rgap:Value() then
        for i = 1, Game.HeroCount() do
            local target = Game.Hero(i)
            local delayed = 0;
            if target.isEnemy and target.visible and not target.dead then 
                local distance = myHero.pos:DistanceTo(target.pos)
                if target.pathing and target.pathing.hasMovePath and target.pathing.isDashing and distance < 1200 and Game.Timer() > delayed + 1 then
                    Control.CastSpell(HK_R, target);
                    delayed = Game.Timer();
                end
            end 
        end
    end
    --Combo
    if self.Menu.ac.combekey:Value() then
        local target = TargetSelection(1200)
        if target and target.visible and not target.dead and target.valid then
            self:Combo(target)
        end
    end
    local Qlasthit = 0;
    if self:AsheBuff(myHero, 'asheqattack') and IsReady(_Q) and Game.Timer() > Qlasthit  then
        Qlasthit = Game.Timer();
    end
    --Harass
    if self.Menu.ah.harasskey:Value() then
        local target = TargetSelection(1200)
        if target and target.visible and not target.dead and target.valid then
            self:Harass(target)
        end
    end
end

function Ashe:Combo(target)
    if IsReady(_Q) and target.pos:DistanceTo(myHero.pos) <= 600 + myHero.boundingRadius then 
        Control.CastSpell(HK_Q);
    end
    if target.pos:DistanceTo(myHero.pos) > 600 + myHero.boundingRadius and self.Menu.ac.cw:Value() and IsReady(_W) then
        local wpred = GetGamsteronPrediction(target, self.pred_w, myHero)
        if wpred.Hitchance >= 2 then
            Control.CastSpell(HK_W, wpred.CastPosition)
        end
    end
    if self.Menu.ac.cr:Value() and IsReady(_R) and target.pos:DistanceTo(myHero.pos) > 600 + myHero.boundingRadius and target.pos:DistanceTo(myHero.pos) <= 1500 then                       
        if target.health >= 200 and (getdmg("R", target, myHero) * 4 > target.health)then
            local rpred = GetGamsteronPrediction(target, self.pred_r, myHero)
            if rpred.Hitchance >= 2 then
                Control.CastSpell(HK_R, rpred.CastPosition)
            end
        end
        if self.Menu.ac.cr:Value() and (myHero.health / myHero.maxHealth) * 100 <= self.Menu.ac.minhp:Value() and #EnemyArea(myHero.pos, 700) >= self.Menu.ac.minenemy:Value() then
            Control.CastSpell(HK_R, target)
        end
        if (getdmg("R", target, myHero) * 4 > target.health) and target.pos:DistanceTo(myHero.pos) > 600 + myHero.boundingRadius and target.pos:DistanceTo(myHero.pos) <= 1500 then
            local rpred = GetGamsteronPrediction(target, self.pred_r, myHero)
            if rpred.Hitchance >= 2 then
                Control.CastSpell(HK_R, rpred.CastPosition)
            end
        end
    end
end

function Ashe:Harass(target)
    if IsReady(_Q) and target.pos:DistanceTo(myHero.pos) <= 600 + myHero.boundingRadius then 
        Control.CastSpell(HK_Q);
    end
    if target.pos:DistanceTo(myHero.pos) > 600 + myHero.boundingRadius and self.Menu.ac.cw:Value() and IsReady(_W) then
        local wpred = GetGamsteronPrediction(target, self.pred_w, myHero)
        if wpred.Hitchance >= 2 then
            Control.CastSpell(HK_W, wpred.CastPosition)
        end
    end
end
Callback.Add("Load", function()
    _G.LATENCY = 0.05
    Ashe:MenuLoading();
      --OnTick
    Callback.Add("Tick", function()
        Ashe:OnTick();
    end)
    Callback.Add("Draw", function()
        if IsReady(_W) then 
            Draw.Circle(myHero.pos, 1200, 3,  Draw.Color(255, 104, 255, 162)) 
        end
    end)
end)
