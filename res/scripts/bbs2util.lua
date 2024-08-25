local audioutil = require "audioutil"

local soundeffectsutil = { }

function soundeffectsutil.sampleCurve(nodes, x)
	local value = 0.0
	
	if 1 < #nodes then
		local n0
		local n1
		for i = 2, #nodes do
			n0 = nodes[i - 1]
			n1 = nodes[i]
			if x <= n1[1] then break end
		end
		value = math.mapClamp(x, n0[1], n1[1], n0[2], n1[2])
	else
		value = nodes[1][2]
	end
	
	return value
end

function soundeffectsutil.makeRoadVehicle2(speeds, idleSpeed, idleGain0, driveSpeed, speed01)
	tracks = audioutil.makeRoadVehicle2(speeds, "", idleSpeed, idleGain0, "", driveSpeed, 0.0)
	
	return {
		{
			gain = soundeffectsutil.sampleCurve(tracks[1].gainCurve.nodes, speed01),
			pitch = soundeffectsutil.sampleCurve(tracks[1].pitchCurve.nodes, speed01)
		},
		{
			gain = soundeffectsutil.sampleCurve(tracks[2].gainCurve.nodes, speed01),
			pitch = soundeffectsutil.sampleCurve(tracks[2].pitchCurve.nodes, speed01)
		}
	}
end

function soundeffectsutil.squeal(speed, sideForce, maxSideForce)
	local gain = 0.0
	local pitch = 1.0
	
	local speedGain = math.mapClamp(speed, 20.0, 40.0, 1.0, 0.0)
	
	local diff = math.max(maxSideForce - sideForce, 0.0)
	gain = math.min(math.max(1.0 - 2.0 * diff, 0.0), 1.0)

	return {
		gain = gain * speedGain,
		pitch = pitch
	}
end

function soundeffectsutil.chuffs(speed, chuffStep, chuffsFastFreq, weight, refWeight)
	local fastSpeed = chuffStep * chuffsFastFreq
	local transitionSpeed = 1.0 * fastSpeed
	local fastSpeed0 = 0.85 * transitionSpeed
	local fastSpeed1 = 1.15 * transitionSpeed
	local fastGain = math.mapClamp(speed, fastSpeed0, fastSpeed1, 0.0, 1.0)
	local gain = math.mapClamp(speed, 0.0, fastSpeed0, 1.0, 0.5) * (1.0 - fastGain)
	local pitch = 1.0
	
	local weightGain = math.min(weight / refWeight, 1.0)
	local weightGain2 = math.sqrt(weightGain)

	return {
		idleTrack = {
			gain = gain * weightGain2,
			pitch = pitch
		},
		fastTrack = {
			gain = fastGain * weightGain2,
			pitch = math.sqrt(speed / fastSpeed)
		},
		event = {
			gain = gain * weightGain2,
			pitch = 1.0
		}
	}
end

function soundeffectsutil.clacks(speed, weight, numAxles, axleRefWeight, gameSpeedUp)
	local speedupGain = 0.5
	if gameSpeedUp <= 2.0 then speedupGain = 0.707 end
	if gameSpeedUp <= 1.0 then speedupGain = 1.0 end
	
	local axleWeight = weight / numAxles
	local axleWeightGain = math.min(axleWeight / axleRefWeight, 1.0)
	local axleWeightGain2 = math.sqrt(axleWeightGain)
	local gain = math.mapClamp(speed, 0.0, 10.0, 0.25, 1.0)
	local pitch = math.mapClamp(weight, 10.0, 100.0, 1.0, 0.5)
	
	return {
		gain = gain * axleWeightGain2 * speedupGain,
		pitch = pitch
	}
end

function soundeffectsutil.brake(speed, brakeDecel, maxGain)
	local gain = 0.0
	if 0.5 < brakeDecel then
		local maxBrakeDecel = 2.25
		local brakeGain = math.sqrt(math.min(brakeDecel / maxBrakeDecel))
		local speed0 = 1.0
		local speed1 = 3.75 * (brakeGain + 1.0)
		local speed2 = 6.75 * (brakeGain + 1.0)
		local speedFadeIn = math.mapClamp(speed, speed1, speed2, 1.0, 0.0)
		local speedFadeOut = math.mapClamp(speed, 0.0, speed0, 0.0, 1.0)
		gain = speedFadeIn * speedFadeOut * brakeGain * maxGain
	end
	local pitch = 1.0
	
	return {
		gain = gain,
		pitch = pitch
	}
end

function soundeffectsutil.slow(speed, brakeDecel, maxGain, speed01)
	local gain = 0.0
	if 0.7 < brakeDecel then
		local maxBrakeDecel = 2.5
		local brakeGain = math.sqrt(math.min(brakeDecel / maxBrakeDecel))
		local speed0 = 1.0
		local speed1 = 10.0 * (brakeGain + 1.0)
		local speed2 = 40.0 * (brakeGain + 1.0)
		local speedFadeIn = math.mapClamp(speed, speed1, speed2, 1.0, 0.0)
		local speedFadeOut = math.mapClamp(speed, 0.0, speed0, 0.0, 1.0)
		gain = speedFadeIn * speedFadeOut * brakeGain * maxGain
	end
	local pitch = 1.0
	
	return {
		gain = gain,
		pitch = pitch
	}
end


return soundeffectsutil
