/obj/machinery/shieldgenerator/energy_shield
	name = "Energy-Shield Generator"
	desc = "Solid matter can pass through the shields generated by this generator."
	icon = 'icons/obj/meteor_shield.dmi'
	icon_state = "energyShield"
	density = 0
	var/orientation = 1  //shield extend direction 0 = north/south, 1 = east/west
	power_level = 1 //1 for atmos shield, 2 for liquid, 3 for solid material
	var/const/MAX_POWER_LEVEL = 3
	var/const/MIN_POWER_LEVEL = 1
	min_range = 1
	max_range = 4
	direction = "dir"
	layer = 3

	New()
		..()
		display_active.icon_state = "energyShieldOn"
		src.power_usage = 5

	get_desc(dist, mob/user)
		..()
		var/charge_percentage = 0
		if (PCEL?.charge > 0 && PCEL.maxcharge > 0)
			charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
			. += "It has [PCEL.charge]/[PCEL.maxcharge] ([charge_percentage]%) battery power left."
		else
			. += "It seems to be missing a usable battery."
		. += "The unit will consume [10 * src.range * (src.power_level * src.power_level)] power a second."
		. += "The range setting is set to [src.range]."
		. += "The power setting is set to [src.power_level]."

	shield_on()
		if (!PCEL)
			if (!powered()) //if NOT connected to power grid and there is power
				src.power_usage = 0
				return
			else //no power cell, not connected to grid: power down if active, do nothing otherwise
				src.power_usage = 10 * (src.range) * (power_level * power_level)
				generate_shield()
				return
		else
			if (PCEL.charge > 0)
				generate_shield()
				return

	pulse(var/mob/user)
		if(active)
			boutput(user, "<span class='alert'>You can't change the power level or range while the generator is active.</span>")
			return
		var/input = input("Select a config to modify!", "Config", null) as null|anything in list("Set Range","Set Power Level")
		if(input && (user in range(1,src)))
			switch(input)
				if("Set Range")
					src.set_range(user)
				if("Set Power Level")
					var/the_level = input("Enter a power level from [src.MIN_POWER_LEVEL]-[src.MAX_POWER_LEVEL]. Higher levels use more power.","[src.name]",1) as null|num
					if(!the_level)
						return
					if(BOUNDS_DIST(user, src) > 0)
						boutput(user, "<span class='alert'>You flail your arms at [src] from across the room like a complete muppet. Move closer, genius!</span>")
						return
					the_level = clamp(the_level, MIN_POWER_LEVEL, MAX_POWER_LEVEL)
					src.power_level = the_level
					boutput(user, "<span class='notice'>You set the power level to [src.power_level].</span>")

	//Code for placing the shields and adding them to the generator's shield list
	proc/generate_shield()
		update_orientation()
		var/xa= -range-1
		var/ya= -range-1
		var/turf/T
		if (range == 0)
			var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield ( locate((src.x),(src.y),src.z), src , 1 )
			S.icon_state = "enshieldw"
			src.deployed_shields += S
		else
			for (var/i = 0-range, i <= range, i++)
				if (orientation)
					T = locate((src.x+i),(src.y),src.z)
					xa++
					ya = 0
				else
					T = locate((src.x),(src.y+i), src.z)
					ya++
					xa = 0

				if (T.canpass())
					createForcefieldObject(xa, ya);

		src.anchored = 1
		src.active = 1

		// update_nearby_tiles()
		playsound(src.loc, src.sound_on, 50, 1)
		if (src.power_level == 1)
			display_active.color = "#0000FA"
		else if (src.power_level == 2)
			display_active.color = "#00FF00"
		else
			display_active.color = "#FA0000"
		build_icon()

	//Changes shield orientation based on direction the generator is facing
	proc/update_orientation()
		if (src.dir == NORTH || src.dir == SOUTH)
			orientation = 0
		else
			orientation = 1

	//this is so long because I wanted the tiles to look like one seamless object. Otherwise it could just be a single line
	proc/createForcefieldObject(var/xa as num, var/ya as num)
		var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield (locate((src.x + xa),(src.y + ya),src.z), src, 1 ) //1 update tiles
		S.layer = 2
		if (xa == -range)
			S.set_dir(SOUTHWEST)
		else if (xa == range)
			S.set_dir(SOUTHEAST)
		else if (ya == -range)
			S.set_dir(NORTHWEST)
		else if (ya == range)
			S.set_dir(NORTHEAST)
		else if (orientation)
			S.set_dir(NORTH)
		else if (!orientation)
			S.set_dir(EAST)

		src.deployed_shields += S

		return S
