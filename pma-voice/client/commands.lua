local wasProximityDisabledFromOverride = false
disableProximityCycle = false
-- rb_code 定义全局变量，用于控制光圈的显示
local circleExpireTime = 0
local circleRadius = 0
local mutex = false

RegisterCommand('setvoiceintent', function(source, args)
	if GetConvarInt('voice_allowSetIntent', 1) == 1 then
		local intent = args[1]
		if intent == 'speech' then
			MumbleSetAudioInputIntent(`speech`)
		elseif intent == 'music' then
			MumbleSetAudioInputIntent(`music`)
		end
		LocalPlayer.state:set('voiceIntent', intent, true)
	end
end)
TriggerEvent('chat:addSuggestion', '/setvoiceintent', 'Sets the players voice intent', {
	{
		name = "intent",
		help = "speech is default and enables noise suppression & high pass filter, music disables both of these."
	},
})

-- TODO: Better implementation of this?
RegisterCommand('vol', function(_, args)
	if not args[1] then return end
	setVolume(tonumber(args[1]))
end)
TriggerEvent('chat:addSuggestion', '/vol', 'Sets the radio/phone volume', {
	{ name = "volume", help = "A range between 1-100 on how loud you want them to be" },
})

exports('setAllowProximityCycleState', function(state)
	type_check({ state, "boolean" })
	disableProximityCycle = state
end)

function setProximityState(proximityRange, isCustom)
	local voiceModeData = Cfg.voiceModes[mode]
	MumbleSetTalkerProximity(proximityRange + 0.0)
	LocalPlayer.state:set('proximity', {
		index = mode,
		distance = proximityRange,
		mode = isCustom and "Custom" or voiceModeData[2],
	}, true)
	sendUIMessage({
		-- JS expects this value to be - 1, "custom" voice is on the last index
		voiceMode = isCustom and #Cfg.voiceModes or mode - 1
	})
end

exports("overrideProximityRange", function(range, disableCycle)
	type_check({ range, "number" })
	setProximityState(range, true)
	if disableCycle then
		disableProximityCycle = true
		wasProximityDisabledFromOverride = true
	end
end)

exports("clearProximityOverride", function()
	local voiceModeData = Cfg.voiceModes[mode]
	setProximityState(voiceModeData[1], false)
	if wasProximityDisabledFromOverride then
		disableProximityCycle = false
	end
end)

RegisterCommand('cycleproximity', function()
	if mutex then return end
	mutex = true
	-- Proximity is either disabled, or manually overwritten.
	if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 or disableProximityCycle then 
		mutex = false
		return 
	end
	local newMode = mode + 1

	-- If we're within the range of our voice modes, allow the increase, otherwise reset to the first state
	if newMode <= #Cfg.voiceModes then
		mode = newMode
	else
		mode = 1
	end
	-- 更新光圈参数：光圈半径取当前说话距离，显示2秒
	circleRadius = Cfg.voiceModes[mode][1]
	circleExpireTime = GetGameTimer() + 1000

	setProximityState(Cfg.voiceModes[mode][1], false)
	TriggerEvent('pma-voice:setTalkingMode', mode)
	-- 每帧检查是否需要绘制光圈
	while GetGameTimer() < circleExpireTime do
		Citizen.Wait(0)
		local ped = PlayerPedId()
		local pos = GetEntityCoords(ped)
		-- 使用 marker 类型 1 绘制地面光圈，圆形直径为 (circleRadius*2)
		DrawMarker(1, pos.x, pos.y, pos.z - 0.95, 0, 0, 0, 0, 0, 0, circleRadius * 2, circleRadius * 2, 0.15, 0, 153, 255, 200, false, false, 2, nil, nil, false)
	end
	mutex = false
end, false)
if gameVersion == 'fivem' then
	RegisterKeyMapping('cycleproximity', '说话距离', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))
end

