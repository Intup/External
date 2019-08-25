--Requi
IntAIOVersion = 0.05
require("DamageLib")
--require('GamsteronPrediction')

--Checking arquive
if FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
    require('GamsteronPrediction');
else
    print("Requires GamsteronPrediction please download the file thanks!");
    return
end

local Champions = {
    ["Jax"] = true, -- JG
    ["Kayn"] = true, -- JG
    ["Jinx"] = true, -- ADC
    ["Ezreal"] = true, -- ADC
    ["Pyke"] = true, -- Sup
}

--Checking Champion 
if Champions[myHero.charName] == nil then
    print('IntAIO does not support ' .. myHero.charName) return
end

--Veryy
local function IsReady(spell)
    return Game.CanUseSpell(spell) == 0
end
local scale = {190, 240, 290, 340, 390, 440, 475, 510, 545, 580, 615, 635, 655};
local function r_damage()
    if myHero.levelData.lvl < 6 then return 0 end
	local dmg = scale[myHero.levelData.lvl - 5];
	local bonus = myHero.bonusDamage;
	return (dmg + (bonus * 0.6));
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

local OtherItems = {
    ["Hextech Protobelt-01"] = {ID = 3152, range = 800},
	["Hextech GLP-800"] = {ID = 3030, range = 800},
	["Hextech Gunblade"] = {ID = 3146, range = 700},
}

local function SlotingId(id)
    for i = 6, 12 do
        if myHero:GetItemData(i).itemID == id then
            return i
        end
    end
end

local function UseItem(id)
    local slot = SlotingId(id);
    if slot then
        local cd = myHero:GetSpellData(slot).currentCd == 0
        if cd then 
            return true 
        end
    end 
    return false
end

local function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

class 'Jax'

function Jax:MenuLoading()
    self.Menu = MenuElement({type = MENU, id = "Jax", name = "IntAIO - Jax", leftIcon = "https://raw.githubusercontent.com/Intup/External/master/Champion%20AIO/Jax.png"})
    --Combo
    self.Menu:MenuElement({id = "jc", name = "Combo", type = MENU})
    -->>Config Q <<--
    self.Menu.jc:MenuElement({id = "qmode", name = "Combo Mode", value = 2, drop = {"Q > E", "E > Q"}})
    self.Menu.jc:MenuElement({id = "cq", name = "Use Q", value = true})
    self.Menu.jc:MenuElement({id = "minq", name = "^- Min. Range", value = 300, min = 1, max = 400, step = 5})
    -->>Config W <<--
    self.Menu.jc:MenuElement({id = "cw", name = "Use W", value = true})
    self.Menu.jc:MenuElement({id = "waa", name = "^- Only for Auto Attack reset", value = false})
    -->Config E <<--
    self.Menu.jc:MenuElement({id = "ce", name = "Use E", value = true})
    self.Menu.jc:MenuElement({id = "modee", name = "E Mode", value = 2, drop = {"Stun", "Blocking"}})
    self.Menu.jc:MenuElement({id = "changemode", name = "Mode Changing: ", key = string.byte("T"), toggle = true})
    self.Menu.jc:MenuElement({id = "eda", name = "E Delay", value = 1150, min = 0, max = 2000, step = 0})
    -->Config R <<--
    self.Menu.jc:MenuElement({id = "cr", name = "Use R", value = true})
    self.Menu.jc:MenuElement({id = "minenemy", name = "Min. Enemies for R", value = 2, min = 1, max = 5, step = 5})
    self.Menu.jc:MenuElement({id = "minhp", name = "^- in. Health Percent for R", value = 30, min = 1, max = 100, step = 1})
    -->Config Item <<--
    self.Menu.jc:MenuElement({id = "citem", name = "Use Items", value = true})
    -->>Key >>--
    self.Menu.jc:MenuElement({id = "combekey", name = "Combo", key = string.byte(" ")})

    --Harass
    self.Menu:MenuElement({id = "jh", name = "Harass", type = MENU})
    self.Menu.jh:MenuElement({id = "qmode", name = "Harass Mode", value = 2, drop = {"Q > E", "E > Q"}})
    self.Menu.jh:MenuElement({id = "hq", name = "Use Q", value = true})
    self.Menu.jh:MenuElement({id = "minq", name = "^- Min. Range", value = 300, min = 1, max = 400, step = 5})
    -->>Config W <<--
    self.Menu.jh:MenuElement({id = "hw", name = "Use W", value = true})
    self.Menu.jh:MenuElement({id = "waa", name = "^- Only for Auto Attack reset", value = true})
    -->Config E <<--
    self.Menu.jh:MenuElement({id = "he", name = "Use E", value = true})
    self.Menu.jh:MenuElement({id = "eda", name = "E Delay", value = 1150, min = 0, max = 2000, step = 0})
    -->>Key
    self.Menu.jh:MenuElement({id = "harasskey", name = "Harass", key = string.byte("C")})

    --Farming
    self.Menu:MenuElement({id = "jl", name = "Farming", type = MENU})
    self.Menu.jl:MenuElement({id = "lw", name = "Use W In Farm/Jungle", value = true})
    self.Menu.jl:MenuElement({id = "lq", name = "Use Q In Jungle", value = true})
    self.Menu.jl:MenuElement({id = "le", name = "Use E In Jungle", value = true})
    self.Menu.jl:MenuElement({id = "eda", name = "E Delay", value = 1150, min = 0, max = 2000, step = 0})
    -->>fARMIG
    self.Menu.jl:MenuElement({id = "farmingkey", name = "Farming", key = string.byte("V")})

    self.Menu:MenuElement({id = "jd", name = "Drawing", type = MENU})
    self.Menu.jd:MenuElement({id = "dq", name = "Drawing --> Q", value = true})

    self.Menu:MenuElement({id = "jm", name = "Misc", type = MENU})
    self.Menu.jm:MenuElement({id = "wardjump", name = "Use Q to Wardjump", value = true})
    self.Menu.jm:MenuElement({id = "keywrd", name = "Wardjump Key: ", key = string.byte("G")})
end

function Jax:EBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 and buff.expireTime > Game.Timer() then 
			return true
		end
	end
    return false
end


function Jax:DrawingSpells()
    if IsReady(_Q) and (self.Menu.jd.dq:Value()) then 
        Draw.Circle(myHero.pos, 700, 3,  Draw.Color(255, 104, 255, 162)) 
    end
    --Keyed Mode is stun or blocked
    if self.Menu.jc.changemode:Value() then
        Draw.Text("Mode: Stun", 22, myHero.pos:To2D().x - 60, myHero.pos:To2D().y + 20, Draw.Color(255, 222, 255, 255)) 
    else
        Draw.Text("Mode: Blocking", 22, myHero.pos:To2D().x - 60, myHero.pos:To2D().y + 20, Draw.Color(255, 222, 255, 255)) 
    end
end

function Jax:GetJumpObject(pos, rad)
	local distance = math.huge
	local objToJump = nil
	local radi = rad or 300
	for i = 1, Game.ObjectCount() do
		local obj = Game.Object(i)
		if obj and (obj.type == Obj_AI_Minion or obj.type == Obj_AI_Hero) and obj ~= nil and obj.valid and obj.visible and not obj.dead then
			if obj.pos:DistanceTo(pos) <= radi and obj.pos:DistanceTo(pos) < distance then
				distance = obj.pos:DistanceTo(pos)
				objToJump = obj
			end
		end
	end
	return objToJump
end

local Cook = 0
local EWepQ = 0
local Loputs = 0
function Jax:Tick()
    if IsReady(_Q) then
		EWepQ = 700 + 100
	else
		EWepQ = 300 + 100
    end
    if self.Menu.jm.keywrd:Value() and self.Menu.jm.wardjump:Value() then 
        Control.Move(mousePos);
        if IsReady(_Q) then
            if Loputs < os.clock() then
                --if self:GetItemSlot('JammerDevice') or self:GetItemSlot("TrinketTotemLvl1") then
                    local jumpPos = mousePos
                    if jumpPos:DistanceTo(myHero.pos) > 700 then
                        jumpPos = myHero.pos + (jumpPos - myHero.pos):Normalized() * 600
                    end
                    local jumpObject = self:GetJumpObject(jumpPos)
                    --local ward = self:GetWardSlot();
                    if not jumpObject then
                        --Control.CastSpell(ward, jumpPos) WARD ERROR!
                        Loputs = os.clock() + 1
                    end
                --end
            end
			if IsReady(_Q) then
				local jumpPos = mousePos
				if jumpPos:DistanceTo(myHero.pos) > 700 then
					jumpPos = myHero.pos + (jumpPos - myHero.pos):Normalized() * 700
				end
				local jumpObject = self:GetJumpObject(jumpPos)
				if jumpObject then
					Control.CastSpell(HK_Q, jumpObject)
				end
			end
		end
    end
    if myHero:GetSpellData(_E).name == 'JaxCounterStrike' then
        if self.Menu.jl.farmingkey:Value() then
			Cook = Game.Timer() + self.Menu.jl.eda:Value() / 1000
		end
		if  self.Menu.jh.harasskey:Value() then
			Cook = Game.Timer() + self.Menu.jh.eda:Value() / 1000
		end
		if self.Menu.jc.combekey:Value() then
			Cook = Game.Timer() + self.Menu.jc.eda:Value() / 1000
		end
    end
    if self.Menu.jl.farmingkey:Value() and self.Menu.jl.lw:Value() and IsReady(_W) then
        for i = 1, Game.MinionCount() do
            local obj = Game.Minion(i)
            if obj.team ~= myHero.team then
                if obj ~= nil and obj.valid and obj.visible and not obj.dead then
                    if obj.pos:DistanceTo(myHero.pos) < 300 then
                        Control.CastSpell(HK_W);
                        Control.Attack(obj);
                    end
                end
            end
            if IsReady(_Q) and obj and obj.team == 300 and obj.valid and obj.visible and not obj.dead and 
            obj.pos:DistanceTo(myHero.pos) < 700 then
                Control.CastSpell(HK_Q, obj);
            end
            if IsReady(_E) and obj and obj.team == 300 and obj.valid and obj.visible and not obj.dead and obj.pos:DistanceTo(myHero.pos) < 700 then
                if not self:EBuff(myHero, 'JaxCounterStrike') then
                    Control.CastSpell(HK_E);
                end
                if self:EBuff(myHero, 'JaxCounterStrike') then
                    if Game.Timer() > Cook then
                        Control.CastSpell(HK_E);
                    end
                end
            end
        end
    end
    if self.Menu.jc.combekey:Value() then
        self:ComboCook();
    end
    if self.Menu.jh.harasskey:Value() then
		self:HarassCook();
	end
end

local Heregoooo = 0
function Jax:ComboCook()
    local target = TargetSelection(700); --COMBO Mode Q > E
    local target2 = TargetSelection(800); --Combo E > Q

    if target and target.valid and target.visible and not target.dead then
		if self.Menu.jc.qmode:Value() == 1 then
			if self.Menu.jc.cq:Value() and (target.pos:DistanceTo(myHero.pos) <= 700) then
				if target.pos:DistanceTo(myHero.pos) > self.Menu.jc.minq:Value() then
                    Control.CastSpell(HK_Q, target)
				end
				if getdmg("Q", target, myHero) >= target.health then
                    Control.CastSpell(HK_Q, target)
				end
				if target.pathing.hasMovePath then
                    Control.CastSpell(HK_Q, target)
				end
            end
            if self.Menu.jc.cw:Value() then
                if getdmg("W", target, myHero) >= target.health and myHero.pos:DistanceTo(target.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
			end
			if self.Menu.jc.cw:Value() and not self.Menu.jc.waa:Value() then
				if myHero.pos:DistanceTo(target.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
			end
			if self.Menu.jc.ce:Value() and target.pos:DistanceTo(myHero.pos) <= 300 then
				if self.Menu.jc.changemode:Value() == true then
					if not self:EBuff(myHero, "JaxCounterStrike") then
						Control.CastSpell(HK_E)
					end

					if self:EBuff(myHero, "JaxCounterStrike") then
						Control.CastSpell(HK_E)
					end
				end
				if  self.Menu.jc.changemode:Value() == false  then
					if not self:EBuff(myHero, "JaxCounterStrike") then
						Control.CastSpell(HK_E)
					end
					if self:EBuff(myHero, "JaxCounterStrike") and Game.Timer() > Cook then
						Control.CastSpell(HK_E)
					end
				end
			end
		end
    end
    if target2 and target2.valid and target2.visible and not target2.dead then
		if self.Menu.jc.qmode:Value() == 2 then
			if self.Menu.jc.modee:Value() and target2.pos:DistanceTo(myHero.pos) <= EWepQ and IsReady(_E) then
				if self.Menu.jc.modee:Value() == true then
					if not self:EBuff(myHero, "JaxCounterStrike") then
                        Control.CastSpell(HK_E)
						Heregoooo = Game.Timer() + 0.1
					end

					if self:EBuff(myHero, "JaxCounterStrike") then
                        Control.CastSpell(HK_E)
					end
				end
				if self.Menu.jc.modee:Value() == 2 then
					if not self:EBuff(myHero, "JaxCounterStrike") then
                        Control.CastSpell(HK_E)
						Heregoooo =  Game.Timer() + 0.1
					end

					if
                    self:EBuff(myHero, "JaxCounterStrike") and  Game.Timer() > Cook and
							target2.pos:DistanceTo(myHero.pos) <= 300
					 then
                        Control.CastSpell(HK_E)
					end
				end
			end

			if Heregoooo < Game.Timer() then
				if self.Menu.jc.cq:Value() and (target2.pos:DistanceTo(myHero.pos) <= 700) then
					if target2.pos:DistanceTo(myHero.pos) > self.Menu.jc.minq:Value() then
                        Control.CastSpell(HK_Q, target2)
					end
					if getdmg("Q", target2, myHero) >= target2.health then
                        Control.CastSpell(HK_Q, target2)
                    end
					if target2.pathing.hasMovePath then
                        Control.CastSpell(HK_Q, target2)
                    end
				end
			end
			if self.Menu.jc.cw:Value() then
                if getdmg("W", target2, myHero) >= target2.health and myHero.pos:DistanceTo(target2.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
            end
            if self.Menu.jc.cw:Value() and not self.Menu.jc.waa:Value() then
                if myHero.pos:DistanceTo(target2.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
            end
		end
    end
    if self.Menu.jc.cr:Value() and (myHero.health / myHero.maxHealth) * 100 <= self.Menu.jc.minhp:Value() and #EnemyArea(myHero.pos, 700) >= self.Menu.jc.minenemy:Value() then
		Control.CastSpell(HK_R)
	end
end

function Jax:HarassCook()
    local target = TargetSelection(700); --COMBO Mode Q > E
    local target2 = TargetSelection(800); --Combo E > Q

    if target and target.valid and target.visible and not target.dead then
		if self.Menu.jc.qmode:Value() == 1 then
			if self.Menu.jc.cq:Value() and (target.pos:DistanceTo(myHero.pos) <= 700) then
				if target.pos:DistanceTo(myHero.pos) > self.Menu.jc.minq:Value() then
                    Control.CastSpell(HK_Q, target)
				end
				if getdmg("Q", target, myHero) >= target.health then
                    Control.CastSpell(HK_Q, target)
				end
				if target.pathing.hasMovePath then
                    Control.CastSpell(HK_Q, target)
				end
			end
            if self.Menu.jc.cw:Value() then
                if getdmg("W", target, myHero) >= target.health and myHero.pos:DistanceTo(target.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
			end
			if self.Menu.jc.cw:Value() and not self.Menu.jc.waa:Value() then
				if myHero.pos:DistanceTo(target.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
			end
			if self.Menu.jc.ce:Value() and target.pos:DistanceTo(myHero.pos) <= 300 then
				if self.Menu.jc.changemode:Value() == true then
					if not self:EBuff(myHero, "JaxCounterStrike") then
						Control.CastSpell(HK_E)
					end

					if self:EBuff(myHero, "JaxCounterStrike") then
						Control.CastSpell(HK_E)
					end
				end
				if  self.Menu.jc.changemode:Value() == false  then
					if not self:EBuff(myHero, "JaxCounterStrike") then
						Control.CastSpell(HK_E)
					end
					if self:EBuff(myHero, "JaxCounterStrike") and Game.Timer() > Cook then
						Control.CastSpell(HK_E)
					end
				end
			end
		end
    end
    if target2 and target2.valid and target2.visible and not target2.dead then
		if self.Menu.jc.qmode:Value() == 2 then
			if self.Menu.jc.modee:Value() and target2.pos:DistanceTo(myHero.pos) <= EWepQ and IsReady(_E) then
				if self.Menu.jc.modee:Value() == true then
					if not self:EBuff(myHero, "JaxCounterStrike") then
                        Control.CastSpell(HK_E)
						Heregoooo = Game.Timer() + 0.1
					end

					if self:EBuff(myHero, "JaxCounterStrike") then
                        Control.CastSpell(HK_E)
					end
				end
				if self.Menu.jc.modee:Value() == 2 then
					if not self:EBuff(myHero, "JaxCounterStrike") then
                        Control.CastSpell(HK_E)
						Heregoooo =  Game.Timer() + 0.1
					end

					if
                    self:EBuff(myHero, "JaxCounterStrike") and  Game.Timer() > Cook and
							target2.pos:DistanceTo(myHero.pos) <= 300
					 then
                        Control.CastSpell(HK_E)
					end
				end
			end

			if Heregoooo < Game.Timer() then
				if self.Menu.jc.cq:Value() and (target2.pos:DistanceTo(myHero.pos) <= 700) then
					if target2.pos:dist(myHero.pos) > self.Menu.jc.minq:Value() then
                        Control.CastSpell(HK_Q, target2)
					end
					if getdmg("Q", target2, myHero) >= target2.health then
                        Control.CastSpell(HK_Q, target2)
                    end
					if target2.pathing.hasMovePath then
                        Control.CastSpell(HK_Q, target2)
                    end
				end
			end
			if self.Menu.jc.cw:Value() then
                if getdmg("W", target2, myHero) >= target2.health and myHero.pos:DistanceTo(target2.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
            end
            if self.Menu.jc.cw:Value() and not self.Menu.jc.waa:Value() then
                if myHero.pos:DistanceTo(target2.pos) < 250 then
                    Control.CastSpell(HK_W)
                end
            end
		end
	end
end

class 'Kayn'
--Soon
class 'Jinx'

function Jinx:hero_buff(unit, name)
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

function Jinx:minigun()
	if self:hero_buff(myHero,"jinxqicon") then
		return true;
	end
	return false;
end

local spots = {
	{9704,56,3262},{8214,52,3264},{8812,54,4266},{6882,49,4254},{6008,50,4146},{6142,51,3376},{6094,53,2200},{7532,52,2388},{10000,50,2488},{7484,53,6026},{4822,52,5974},{4646,52,6878},{3896,52,7280},{2604,58,6648},{2352,52,9144},{3518,52,8486},{5598,52,7562},{9214,53,7338},{10888,53,7606},{11600,53,8002},{10124,55,8268},{8276,51,10218},{8760,51,10638},{8658,54,11536},{8722,57,12496},{6626,55,11510},{6038,56,10426},{6582,49,4722},{11204,-13,5592},{11878,53,5146},{12528,53,5710},{12204,52,6622},{12228,53,8180},{11900,52,7166},{4884,57,12428},{5224,57,11574},{6818,55,13020},{7208,53,8956},{3568,33,9234},{3980,-15,11392},{6208,-68,9318},{8610,-50,5556},{9944,0,6324},{4820,4,8526}
};

function Jinx:CountBounigs(unit, range)
	local Enemys = 0;
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
        if Hero.isEnemy and Hero.visible and not Hero.dead then 
    		if Hero.pos:DistanceTo(unit.pos) <= range then
    			Enemys = Enemys + 1;
    		end
    	end
    end
    return Enemys;
end
function Jinx:MenuLoading()
    self.Menu = MenuElement({type = MENU, id = "Jinx", name = "IntAIO - Jinx", leftIcon = "https://raw.githubusercontent.com/Intup/External/master/Champion%20AIO/Jinx.png"})
    --Combo 
    --Q
    self.Menu:MenuElement({id = "pc", name = "Combo", type = MENU})
    self.Menu.pc:MenuElement({id = "cq", name = "Use Q", value = true})
    self.Menu.pc:MenuElement({id = "mana", name = "^- Don't use rockets under mana percent", value = 25, min = 1, max = 100, step = 1})
    --W
    self.Menu.pc:MenuElement({id = "cw", name = "Use Only use W when out of AA range", value = true})
    self.Menu.pc:MenuElement({id = "manaw", name = "^- Don't use W under mana percent", value = 25, min = 1, max = 100, step = 1})
    --E
    self.Menu.pc:MenuElement({id = "ce", name = "Auto E on stunned targets", value = true})
    self.Menu.pc:MenuElement({id = "auto", name = "Auto E on good spots", value = true})
    self.Menu.pc:MenuElement({id = "manue", name = "Manual E", key = string.byte("C")})
    --R
    self.Menu.pc:MenuElement({id = "bu", name = "Base Ult", value = true})
    self.Menu.pc:MenuElement({id = "manur", name = "Manual R", key = string.byte("T")})
    self.Menu.pc:MenuElement({id = "range", name = "^- Max manual ult range", value = 5000, min = 1, max = 25000, step = 1})
    --Key
    self.Menu.pc:MenuElement({id = "combekey", name = "Combo", key = string.byte(" ")})
end
function Jinx:Tick()
    self.pred_W = {Delay = 0.5, Radius = 55, Range = 1450, Speed = 3200, Collision = true}
    self.pred_E = {Delay = 0.95, Radius = 50, Range = 890, Speed = 1100, Collision = false}
    self.pred_r = {Delay = 0.65, Radius = 120, Range = math.huge, Speed = 1700, Collision = false, Type = 0, CollisionTypes = 2}
    local target = TargetSelection(1000)
    if not target then
		if not self:minigun() then
            Control.CastSpell(HK_Q)
		end
	 	return
    end
    
    if self.Menu.pc.ce:Value() then
        self:Chulipin(target);
    end
    self:e_spot(target);
    
    if self.Menu.pc.combekey:Value() then
        if target and target.visible and not target.dead and target.valid then
            self:ZapZap(target);
            --
            if (myHero.mana/myHero.maxMana*100) < self.Menu.pc.mana:Value() then return end
            if self:minigun() and myHero.pos:DistanceTo(target.pos) > 525 then
                Control.CastSpell(HK_Q)
            end
        end
    end
    --[[for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
        if Hero.isEnemy then
            if Hero and Hero.visible and not Hero.dead and Hero.valid then
                if self:hero_buff(Hero, 'Recall') then
                if not Hero.pathing.hasMovePath then 
                        if IsReady(_R) then
                            Control.CastSpell(HK_R,Hero.pos)
                        end
                    end
                end
            end
        end 
    end]]
    self:FishMinigun(target);
    self:UltMate();
end

function Jinx:UltMate()
    local target = TargetSelection(self.Menu.pc.range:Value())
    if target and not target.dead and target.valid then
        if self.Menu.pc.bu:Value() then 
            if IsReady(_R) then 
                local dist = myHero.pos:DistanceTo(target.pos);
                if not target.dead and dist <= self.Menu.pc.range:Value() and dist > 525 and getdmg("R", target, myHero) >= target.health then
                    local Rpred = GetGamsteronPrediction(target, self.pred_r, myHero)
                    if Rpred.Hitchance >= 3 then
                        Control.CastSpell(HK_R, Rpred.CastPosition)
                    end
                end
            end
        end
    end
end
function Jinx:FishMinigun(target)
    if target and target.visible and not target.dead and target.valid then
        local nerds = self:CountBounigs(target, 100);
        if not self:minigun() then
             if myHero.pos:DistanceTo(target.pos) <= 525 and nerds == 1 or (myHero.mana/myHero.maxMana*100 < self.Menu.pc.mana:Value()) then
                Control.CastSpell(HK_Q)
            end
        else
            if nerds > 1 then
                Control.CastSpell(HK_Q)
            end
        end
    end
end
function Jinx:e_spot(target)
	if not self.Menu.pc.auto:Value() then return end
	if not IsReady(_E) then return end
	for i = 1, #spots do
		local spot_pos = Vector(spots[i][1], spots[i][2], spots[i][3]);
		if spot_pos:DistanceTo(target.pos) < 200 and myHero.pos:DistanceTo(spot_pos) > 100 then
			
            local epred = GetGamsteronPrediction(target, self.pred_E, myHero)
            if epred.Hitchance >= 1 then
                Control.CastSpell(HK_E, epred.CastPosition)
            end
        end
	end
end
function Jinx:Chulipin(target)
    if target and target.visible and not target.dead and target.valid then
        if self.Menu.pc.manue:Value() then
            Control.Move(mousePos);
        end
        if IsReady(_E) then
            if target.pos:DistanceTo(myHero.pos) < 890 then
                local epred = GetGamsteronPrediction(target, self.pred_E, myHero)
                if epred.Hitchance >= 1 then
                    Control.CastSpell(HK_E, epred.CastPosition)
                end
            end
        end
    end
end
function Jinx:ZapZap(target)
    if IsReady(_W) then
        if (target) and (target.pos:DistanceTo(myHero.pos) > 525) then
            local Pred = GetGamsteronPrediction(target, self.pred_W, myHero)
            if Pred.Hitchance >= 3  then
                Control.CastSpell(HK_W, Pred.CastPosition)
            end
        end
    end
end

function Jinx:DrawingSpells()
    if IsReady(_W) then 
        Draw.Circle(myHero.pos, 1450, 3,  Draw.Color(255, 104, 255, 162)) 
    end
end

class 'Ezreal'

class 'Pyke'

--[[local last_execute = 0;
local q_pred = {Type = _G.SPELLTYPE_LINE, Collision = true, Delay = 0.25; Radius = 70; Speed = 2000;}
local Last_r = { };
function Pyke:Tick()
    self:UpdateBuffe();

    --EXECUTED:?
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
        if Hero.isEnemy and Hero.visible and not Hero.dead then 
            if not Last_r[Hero.networkID] then Last_r[Hero.networkID] = {} end
            Last_r[Hero.networkID].kill = false;
            if  getdmg("R", Hero, myHero) >= Hero.health and not Hero.dead and Hero.visible then
                Last_r[Hero.networkID].kill = true;
                self:Executed(Hero);
            end
        end
    end
    if self.Menu.pc.combekey:Value() then
        if IsReady(_Q) then
            if (IsReady(_E) and target.pos:DistanceTo(myHero.pos) < 400) and not self:BuffePyke(myHero, "PykeQ") then return end
            if target.pos:DistanceTo(myHero.pos) > self:Q_range() then return end

            local Pred = GetGamsteronPrediction(target, q_pred, myHero)
            if not qpred then return end
            ---- SOON
        end
    end
end


local pred_r = { Delay = 0.325; Radius  = 50; Speed = 1100;}
function Pyke:Executed(unit)
    if myHero.pos:DistanceTo(unit.pos) > 700 then return end
	if not unit.dead and unit.visible and unit.isTargetable then 
       
    end
end
function Pyke:BuffePyke(unit, name)
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

local last_Q = 0;
function Pyke:UpdateBuffe()
	local buff, time = self:BuffePyke(myHero, "PykeQ");
	if buff then
		last_Q = time;
	end
end

function Pyke:Q_range()
    local t = Game.Timer() - last_Q;
    local range = 400;

    if t > 0.5 then
        range = range + (t/.1 * 62);
    end
    if range > 1050 then
        return 1050
    end

     return range
end


function Pyke:MenuLoading()
    self.Menu = MenuElement({type = MENU, id = "Pyke", name = "IntAIO - Pyke", leftIcon = "https://raw.githubusercontent.com/Intup/External/master/Champion%20AIO/Pyke.png"})
    --Combo
    self.Menu:MenuElement({id = "pc", name = "Combo", type = MENU})
    self.Menu.pc:MenuElement({id = "cq", name = "Use Q", value = true})
    self.Menu.pc:MenuElement({id = "minq", name = "^- Min. Range", value = 450, min = 1, max = 500, step = 5})
    -->> E << --
    self.Menu.pc:MenuElement({id = "ce", name = "Use E", value = true})
    -->> R << --
    self.Menu.pc:MenuElement({id = "cr", name = "Use R", value = true})
    self.Menu.pc:MenuElement({id = "combekey", name = "Combo", key = string.byte(" ")})
end

function Pyke:DrawingSpells()
    if IsReady(_Q) then
        Draw.Circle(myHero.pos, self:Q_range(), 3,  Draw.Color(255, 104, 255, 162))
    end
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
        if Hero.isEnemy and Hero.pos:ToScreen().onScreen then  
            Draw.Circle(Hero.pos, 150, 3,  Draw.Color(255, 104, 255, 162))
        end
    end
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
    	if not Hero.isEnemy then return end

    	local data = Last_r[nerd.networkID];
    	if not data then return end

    	if data.kill and data.draw then
			Draw.Line(data.draw[1], data.draw[2], 50,  Draw.Color(100, 192, 57, 43))
			Draw.Line(data.draw[3], data.draw[4], 50,  Draw.Color(100, 192, 57, 43))
		end
	end
end]]
Callback.Add("Load", function()
    _G.LATENCY = 0.05
    --Loading champs
    local _IsHero = _G[myHero.charName]();
    --Return Callbacks
    _IsHero:MenuLoading();
    Callback.Add("Draw", function()
        _IsHero:DrawingSpells();
    end)
    --OnTick
    Callback.Add("Tick", function()
        _IsHero:Tick();
        --_IsHero:ItemChamps();
    end)
    GetWebResultAsync("https://raw.githubusercontent.com/Intup/External/master/IntAIO/IntAIOVersion.version", function(data)
        if tonumber(data) > IntAIOVersion then
          print("<b><font color='#EE2EC'>IntAIO - </font></b> New version found! " ..data.." Downloading update, please wait...")
          DownloadFileAsync("https://raw.githubusercontent.com/Intup/External/master/IntAIO/IntAIO.lua", SCRIPT_PATH .. "IntAIO.lua", function() print("<b><font color='#EE2EC'>IntAIO - </font></b> Updated from v"..tostring(IntAIOVersion).." to v"..data..". Please press F6 twice to reload.") return end)
        end
    end)
end)

