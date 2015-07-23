-- Hide and Seek --

HideAndSeek = {
	lasthiderReady = 0,
	gameStart = 0,
	unitsAlive = {},
	unitsBlinded = {},
	wallNum = 1,
	killWalls = 0,
}

function HideAndSeek:New(o) -- o is the class we're objectifying (<- not the official term)
    o = o or {} -- if o exists then great, otherwise we will just sub in an empty table
    setmetatable(o, self) -- if we want to do funky things with o, we can do them from within o
    self.__index = self -- if we somehow try to find a variable or function within o that doesn't exist, nothing bad will happen
    return o -- return our newly created object
end
function HideAndSeek:Start()
	  ScriptCB_Freecamera = function()  end
	DisableSmallMapMiniMap()
    AddAIGoal(1, "Deathmatch", 100)
    AddAIGoal(2, "Deathmatch", 100)
	
	print("Hide and Seek game started")
	local win = CreateTimer("win")	
	SetTimerValue(win, 210)
	local grace = CreateTimer("grace")
	SetTimerValue(grace, 29.5)
    if ScriptCB_InMultiplayer() then
		AllowAISpawn(2, false)
		AllowAISpawn(1, false)
	end
	ScriptCB_SetCanSwitchSides(1)
	--AllowAISpawn(2, false)
	--AllowAISpawn(1, false)
	SetTeamAsNeutral(1, 2)
	SetTeamAsNeutral(2, 1)
	hiderMarker = OnCharacterDeath(function(character)
	if GetNumTeamMembersAlive(2) == 1 and self.gameStart == 1 and self.lasthiderReady == 0 then
		for i, v in pairs(self.unitsAlive) do
			if GetCharacterTeam(i) == 2 and GetNumTeamMembersAlive(2) == 1 then
				self.lasthiderReady = 1
				LastHider(i)
			end
		end
	end
end)
	unitSpawn = OnCharacterSpawn(
    function(character)
        self.unitsAlive[character] = character
    end)

      onfirstspawn = OnCharacterSpawn(
        function(character)
			if IsCharacterHuman(character) then
				ReleaseCharacterSpawn(onfirstspawn)
				onfirstspawn = nil
				StartTimer(grace)
				StartTimer(win)
				ShowTimer(win)
			end
        end
		)
	blindSpawn1 = OnCharacterSpawn(
    function(character)
		if GetCharacterTeam(character) == 1 and self.gameStart == 0 then
			Blind(character)
			self.unitsBlinded[character] = character
		end
    end)
	OnTimerElapse(
	  function(timer)
		MissionVictory(2)
		DestroyTimer(timer)
	  end,
	win
	)
	OnTimerElapse(
	  function(timer)
		DestroyTimer(timer)
		ShowMessageText("level.HNS.released")
		SetClassProperty("all_inf_twilek_blue", "PointsToUnlock", 1337)
		StartTimer(checker)
		StartTimer(checker2)
		self.gameStart = 1
		AllowAISpawn(2, false)
	  end,
	grace
	)
	checker = CreateTimer("checker")
	SetTimerValue(checker, 2)
	super = CreateTimer("super")
	SetTimerValue(super, 5)
	checker2 = CreateTimer("checker2")
	SetTimerValue(checker2, 2.5)
	deathRemove = OnCharacterDeath(function(character)
		print("Someone died, removing them from alive units table")
		--table.remove(unitsAlive, character)
		self.unitsAlive[character] = nil
		self.unitsBlinded[character] = nil
		if GetCharacterTeam(character) == 2 then
			print("Hiders left: ", GetNumTeamMembersAlive(2))
		end
	end)
	OnTimerElapse(
	  function(timer)
		--print("checker")
		for i, v in pairs(self.unitsAlive) do
		--for i in unitsAlive do
			--print("i ", i)
			if GetCharacterTeam(i) == 1 and i ~= nil and i then
				local seeker = GetCharacterUnit(i) --seeker
				if not self.unitsAlive[i] then
					self.unitsAlive[i] = i
					--ShowMessageText("level.HNS.4")
				end
				if i == nil or seeker == nil then return end
				local xseeker, yseeker, zseeker = GetWorldPosition(seeker)
				local seekerpos = {xseeker, yseeker, zseeker}
				for a, b in pairs(self.unitsAlive) do
					--print("a ", a)
					if GetCharacterTeam(a) == 2 and a ~= nil and a and i then
						local hider = GetCharacterUnit(a) --hider
						if not hider then
							self.unitsAlive[a] = a
							--ShowMessageText("level.HNS.5")
						end
						if a == nil or hider == nil then return end
						local xhider, yhider, zhider = GetWorldPosition(hider)
						local hiderpos = {xhider, yhider, zhider}
						local tagDist = 2
						--print("distx ", math.abs(xseeker - xhider))
						--print("disty ", math.abs(yseeker - yhider))
						--print("distz ", math.abs(zseeker - zhider))
						if math.abs(xseeker - xhider) < tagDist and
						math.abs(yseeker - yhider) < tagDist and
						math.abs(zseeker - zhider) < tagDist and
						i ~= nil and a ~= nil then
							--ShowMessageText("level.HNS.1")
							--hider has been tagged
							--print("Close enough, do Tag")
							local tagTable = {tagger = i, tagged = a}
							Tag(tagTable)
						end
					end
				end
			end
		end
		SetTimerValue(checker, 0.1)
		StartTimer(checker)
	  end,
	checker
	)
	OnTimerElapse(
	  function(timer)
		if GetNumTeamMembersAlive(2) == 0 then
			MissionVictory(1)
		end
		SetTimerValue(checker2, 5)
		StartTimer(checker2)
	  end,
	checker2
	)
function LastHider(character)
	if self.lasthiderReady == 1 and GetCharacterUnit(character) ~= nil then
		self.lasthiderReady = 2
		ShowMessageText("level.HNS.last")
		print("LastHider")
		lasttimer = CreateTimer("lasttimer")
		SetTimerValue(lasttimer, 0.1)
		lasthiderunit = GetCharacterUnit(character)
		local unitMatrix1 = GetEntityMatrix(lasthiderunit)
		--print("lasthiderunit ", lasthiderunit)
		local lasthidereffect = CreateEffect("lasthider")
		AttachEffectToMatrix(lasthidereffect, unitMatrix1)
		SetEffectActive(lasthidereffect, true)
		StartTimer(lasttimer)
		OnTimerElapse(
			function(timer)
				if lasthiderunit and GetObjectTeam(lasthiderunit) == 2 and IsObjectAlive(lasthiderunit) and GetObjectHealth(lasthiderunit) > 0 then
					--print("Effect Adjust")
					--RemoveEffect(lasthidereffect)
					local unitMatrix = GetEntityMatrix(lasthiderunit)
					--print("unitmatrix ", unitMatrix)
					--AttachEffectToMatrix(lasthidereffect, unitMatrix1)
					SetEffectMatrix(lasthidereffect, unitMatrix)
					--print("RestrictMovement")
					SetTimerValue(lasttimer, 0.01)
					StartTimer(lasttimer)
				else
					--print("Destroy effect adjust")
					DestroyTimer(timer)
					RemoveEffect(lasthidereffect)
				end
		end,
		lasttimer
		)
	end
end
function Blind(character)
	print("Blind")
	local playerObj = GetCharacterUnit(character)
	if playerObj and not ScriptCB_InMultiplayer() then
		--local xw, yw, zw = GetWorldPosition(playerObj)
		local OldunitMatrix = GetEntityMatrix(playerObj)
		--local effect = CreateEffect("blind")
		--AttachEffectToMatrix(effect, NewunitMatrix)
		local movement = CreateTimer("movement")
		SetTimerValue(movement, 2)
		StartTimer(movement)
		local pie2 = math.pi/2
		wallMatrix1 = CreateMatrix(0,0,0,0,1.3,0,0,OldunitMatrix)
		wallMatrix2 = CreateMatrix(0,0,0,0,-1.3,0,0,OldunitMatrix)
		wallMatrix3 = CreateMatrix(pie2,0,1,0,0,0,1.3,OldunitMatrix)
		wallMatrix4 = CreateMatrix(pie2,0,1,0,0,0,-1.3,OldunitMatrix)
		wallMatrix6 = CreateMatrix(0,0,0,0,1.9,0,0,OldunitMatrix)
		wallMatrix7 = CreateMatrix(0,0,0,0,-1.9,0,0,OldunitMatrix)
		wallMatrix8 = CreateMatrix(pie2,0,1,0,0,0,1.9,OldunitMatrix)
		wallMatrix9 = CreateMatrix(pie2,0,1,0,0,0,-1.9,OldunitMatrix)
		wallMatrix5 = CreateMatrix(pie2,0,0,1,1.3,2.3,0,OldunitMatrix) --ceiling, lol
		wallMatrix10 = CreateMatrix(pie2,0,0,1,1.3,-0.15,0,OldunitMatrix) --floor, lol
		local matrix5 = CreateMatrix(0,0,0,0,0,1,0,OldunitMatrix)
		local wall1 = CreateEntity("blindwall", wallMatrix1, "wall1")
		local wall2 = CreateEntity("blindwall", wallMatrix2, "wall2")
		local wall3 = CreateEntity("blindwall", wallMatrix3, "wall3")
		local wall4 = CreateEntity("blindwall", wallMatrix4, "wall4")
		local wall6 = CreateEntity("blindwall", wallMatrix1, "wall6")
		local wall7 = CreateEntity("blindwall", wallMatrix2, "wall7")
		local wall8 = CreateEntity("blindwall", wallMatrix3, "wall8")
		local wall9 = CreateEntity("blindwall", wallMatrix4, "wall9")
		local wall5 = CreateEntity("blindwall", wallMatrix5, "wall5")
		local wall10 = CreateEntity("blindwall", wallMatrix10, "wall10")
		OnTimerElapse(
			function(timer)
			if self.gameStart == 1 then
				print("Kill walls")
				SetProperty(wall1, "CurHealth", 0)
				SetProperty(wall2, "CurHealth", 0)
				SetProperty(wall3, "CurHealth", 0)
				SetProperty(wall4, "CurHealth", 0)
				SetProperty(wall6, "CurHealth", 0)
				SetProperty(wall7, "CurHealth", 0)
				SetProperty(wall8, "CurHealth", 0)
				SetProperty(wall9, "CurHealth", 0)
				SetProperty(wall5, "CurHealth", 0)
				SetProperty(wall10, "CurHealth", 0)
				DestroyTimer(timer)
			else
				SetTimerValue(movement, 1)
				StartTimer(movement)
			end
				
		end,
		movement
		)
	else
		if self.gameStart ~= 1 then
			KillObject(playerObj)
		end
	end
end
function Tag(args)
	--print("Tag")
	--ShowMessageText("level.HNS.2")
	ucPlayer = args.tagged
	matrix = CreateMatrix(0,0,0,0,0,-500,2,GetEntityMatrix(GetCharacterUnit(ucPlayer)))
	ucClassTo = "all_inf_twilek_red"
	ucMatrix = GetEntityMatrix(GetCharacterUnit(ucPlayer))
	SetEntityMatrix(GetCharacterUnit(ucPlayer), matrix) --teleport the guy away
	KillObject(GetCharacterUnit(ucPlayer)) --kill them
	SelectCharacterTeam(ucPlayer, 1)
	SelectCharacterClass(ucPlayer, ucClassTo) --pick their new class
	SpawnCharacter(ucPlayer, ucMatrix) --spawn them back
	SelectCharacterTeam(ucPlayer, 1)
	--ShowMessageText("level.HNS.3")
	print("Unit "..args.tagged.." tagged unit "..args.tagger)
end
end
