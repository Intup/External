--Spells Readys

local Args;
local Champions = {
    ["MasterYi"] = true,
}
--Checking Champion
if Champions[myHero.charName] == nil then
    print('does not support ' .. myHero.charName) return
end

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

local UserItems = {
	["Tiamat"] = {ID = 3077, range = 300},
	["Ravenous Hydra"] = {ID = 3074, range = 300},
	["Titanic Hydra"] = {ID = 3748, range = 300},
	["Blade of the Ruined King"] = {ID = 3153, range = 600},
	["Bilgewater Cutlass"] = {ID = 3144, range = 600},
}

local function DisableMovement(bool)
    if _G.SDK then
        return _G.SDK:SetMovement(bool)
    elseif _G.EOW then
        return _G.EOW:SetMovements(bool)
    end
end
class 'Master'

function Master:MenuLoading()
    self.Menu = MenuElement({type = MENU, id = "Master Yi", name = "IntYi", leftIcon = "https://raw.githubusercontent.com/Intup/External/master/Champion%20AIO/MasterYi.png"})
    --Combo Sttings
    self.Menu:MenuElement({id = "mistec", name = "Combo Settings", type = MENU})
    self.Menu.mistec:MenuElement({id = "magnet", name = "Magnet Movement", value = true})
    self.Menu.mistec:MenuElement({id = "q", name = "Use Q", value = true})
    self.Menu.mistec:MenuElement({id = "w", name = "Use W as AA reset", value = true})
    self.Menu.mistec:MenuElement({id = "e", name = "Use E", value = true})
    self.Menu.mistec:MenuElement({id = "r", name = "Use R", value = true})
    --Jungle Clear
    self.Menu:MenuElement({id = "jungle", name = "Jungle Settings", type = MENU})
    self.Menu.jungle:MenuElement({id = "q", name = "Use Q", value = true})
    self.Menu.jungle:MenuElement({id = "e", name = "Use E", value = true})
    self.Menu.jungle:MenuElement({id = "farmingkey", name = "Farming", key = string.byte("V")})
    --Misc
    self.Menu:MenuElement({id = "misc", name = "Misc Settings", type = MENU})
    self.Menu.misc:MenuElement({id = "follow", name = "Use Q to follow dashes / blinks", value = true})
    self.Menu.misc:MenuElement({id = "q", name = "Use Q to dodge spells", value = true}) --Use W when you can't dodge
    self.Menu.misc:MenuElement({id = "w", name = "Use W when you can't dodge", value = true})
    -->>Key >>--
    self.Menu.mistec:MenuElement({id = "combekey", name = "Combo", key = string.byte(" ")})
end

function Master:Buffer(unit, name)
	--[[for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 and buff.expireTime > Game.Timer() then 
			return true
		end
	end
    return false]]
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

function Master:ComboYi(target)
    --print('Worked 1')
    if target and target.visible and not target.dead and target.valid then
		local dist = myHero.pos:DistanceTo(target.pos)
        local aaRange = 125 + myHero.boundingRadius
        --print('Worked 2')
		if self.Menu.mistec.r:Value() and IsReady(_R) and dist <= 1200 then
            Control.CastSpell(HK_R);
		end
		if dist > aaRange then
			if self.Menu.mistec.q:Value() and IsReady(_Q) then
                Control.CastSpell(HK_Q, target);
			end
		else
			if self.Menu.mistec.e:Value() and IsReady(_E) then
                Control.CastSpell(HK_E);
			end
		end
        for i = 6, 11 do
			local item = myHero:GetSpellData(i).name
			if item and item == "YoumusBlade" then
				if IsReady(i) and dist <= 1200 then
                    Control.CastSpell(item);
				end
			elseif item and item == "ItemTiamatCleave" then
				if IsReady(i) and dist <= 400 then
                    Control.CastSpell(item);
				end
			elseif item and item == "BilgewaterCutlass" or item == "ItemSwordOfFeastAndFamine" then
				if IsReady(i) then
                    Control.CastSpell(item, target);
				end
			end
		end
        if dist < 900 and self.Menu.mistec.magnet:Value() and dist > aaRange then
            DisableMovement(true);
			local pos = target.pos
			if target.pathing.hasMovePath then
				pos = target.pos:Lerp(target.pathing[0], -75 / target.pos:DistanceTo(target.pathing[0]))
			end
            Control.Move(pos);
        else
            -- return nil
		end
	end
end

function Master:CastDodge()
    local target = nil
	local bestchamp = { hero = nil, health = math.huge, maxHealth = math.huge }
	if Game.HeroCount() > 0 then
		for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
			if hero.IsEnemy and hero.visible and myHero.pos:DistanceTo(hero.pos) <= 600 then
				if hero.maxHealth < bestchamp.maxHealth then
					bestchamp.hero = hero
					bestchamp.health = hero.health
					bestchamp.maxHealth = hero.maxHealth
				end
			end
		end
		target = bestchamp.hero
	end
	if target then
		local enemiesInRange = 0
		for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
			if hero.IsEnemy and hero.team ~= target.team and target.pos:DistanceTo(hero.pos) < 1000 then
				enemiesInRange = enemiesInRange + 1
			end
		end
		if enemiesInRange > 1 then
            for i = 1, Game.MinionCount() do
                local obj = Game.Minion(i)
                if obj.team ~= myHero.team then
					if obj and myHero.pos:DistanceTo(obj.pos) < 600 then
						target = obj
						break
					end
				end
			end
		end
	else
		for i = 1, Game.MinionCount() do
            local obj = Game.Minion(i)
            if obj.team ~= myHero.team then
				if obj and myHero.pos:DistanceTo(obj.pos) < 600 then
					target = obj
					break
				end
			end
		end
	end
	if target then
		if self.Menu.misc.q:Value() then
            Control.CastSpell(HK_Q, target);
		end
	else
		if self.Menu.misc.w:Value() then
            Control.CastSpell(HK_W);
		end
	end
end

function Master:Dodge()
    local spell = myHero.activeSpell
	if IsReady(_Q) and spell and spell.owner and spell.owner.team == myHero.team and not myHero.attackData.state == STATE_ATTACK then
		if spell.target and spell.target == myHero then
			self:CastDodge()
		else
			if myHero.pos:DistanceTo(spell.endPos) <= (150 + myHero.boundingRadius) / 2 then
				self:CastDodge()
			end
		end
	end
end

function Master:FollowDash(target)
    if self.Menu.misc.follow:Value() and target and target.visible and not target.dead and target.pathing and target.pathing.hasMovePath and target.pathing.isDashing then
        Control.CastSpell(HK_Q, target);
	end
end

--[[function Master:FollowBlink(spell)
	--Retir
end]]

function Master:OnRecvSpell(target)
    self:Dodge();
    --[[if self.Menu.misc.follow:Value() and self.Menu.mistec.combekey:Value() and target then
        local spell = target.activeSpell
        if spell and spell.valid then
            self:FollowBlink(spell)
        end
	end]]
end

function Master:OnTick()
    --print('Worked')
    DisableMovement(true);
    local target = TargetSelection(1000)

    if target and target.visible and not target.dead and target.valid then
        if self.Menu.mistec.combekey:Value() then
            self:ComboYi(target);
        end
        self:OnRecvSpell(target);
    end
    if target then
        self:FollowDash(target);
    end
    if self.Menu.jungle.farmingkey:Value()  then
        for i = 1, Game.MinionCount() do
            local obj = Game.Minion(i)
            if obj.team ~= myHero.team then
                if obj ~= nil and obj.valid and obj.visible and not obj.dead then
                    if IsReady(_Q) and self.Menu.jungle.q:Value() and obj and obj.team == 300 and obj.valid and obj.visible and not obj.dead and obj.pos:DistanceTo(myHero.pos) < 450 then
                        Control.CastSpell(HK_Q, obj);
                    end
                end
            end
            if IsReady(_E) and self.Menu.jungle.e:Value()  and obj and obj.team == 300 and obj.valid and obj.visible and not obj.dead and obj.pos:DistanceTo(myHero.pos) < 125 + myHero.boundingRadius then
                Control.CastSpell(HK_E);
            end
        end
    end
    local AutoAttack = false;
    if myHero.activeSpell.isAutoAttack then
        AutoAttack = true
    end
    if self.Menu.mistec.w:Value() then 
        if AutoAttack == true then 
            --print('wokr')
            --Control.CastSpell(HK_W);
            if target and target.visible and not target.dead and target.valid and target.pos:DistanceTo(myHero.pos) <= 125 + myHero.boundingRadius then 
                Control.CastSpell(HK_W);
            end
        end
    end
end

Callback.Add("Load", function()
    Master:MenuLoading();
      --OnTick
      Callback.Add("Tick", function()
        Master:OnTick();
        --_IsHero:ItemChamps();
    end)
end)