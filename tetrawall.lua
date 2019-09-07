-- title:   Tetrawall
-- author:  Lowcase
-- desc:    Submission to https://itch.io/jam/olc-codejam-2019
-- script:  lua
-- input:   mouse
-- version: 1.0

maxX = 29
maxY = 15
maxXpix = (maxX + 1) * 8
maxYpix = (maxY + 1) * 8

function createTetrisShapes()
    local s = {}
    -- XXX
    --  X
    s[0] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 2, y = 0}, {x = 1, y = 1}}
    -- XX
    -- XX
    s[1] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}}
    -- XXXX
    s[2] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 2, y = 0}}
    -- XX
    --  XX
    s[3] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}}
    --  XX
    -- XX
    s[4] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 0, y = -1}, {x = 1, y = -1}}
    -- XXX
    --   X
    s[5] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}}
    --   X
    -- XXX
    s[6] = {{x = -1, y = 0}, {x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = -1}}

    return s
end

tetrisShapes = createTetrisShapes()

function rand_v_dir()
    vx = math.random()
    vy = math.random()

    norm = math.sqrt(vx * vx + vy * vy)
    vx = vx / norm
    vy = vy / norm

    if math.random(0, 1) == 0 then
        vx = -vx
    end

    if math.random(0, 1) == 0 then
        vy = -vy
    end

    return vx, vy
end

function printWithShadow(str, x, y, c)
    print(str, x+1, y+1, 0)
    return print(str, x, y, c)
end

function createShake(intensity, duration)
    local shake = 0
    local d = intensity
    return {
        start=function(self)
            shake = duration
        end,
        reset=function(self)
            shake = 0
            memset(0x3FF9,0,2)
        end,
        update=function(self)
            if shake>0 then
                poke(0x3FF9,math.random(-d,d))
                poke(0x3FF9+1,math.random(-d,d))
                shake=shake-1
                if shake==0 then memset(0x3FF9,0,2) end
            end
        end
    }
end

function createBall(map, score)
    local velocityx, velocityy = rand_v_dir()
    local shake = createShake(1, 8)

    local startx = math.random((maxXpix / 4) * 3, maxXpix - 10)
    local starty = math.random(10, maxYpix - 10)
    make_magicsparks_ps(startx, starty)
    sfx(5, "E-4")

    return {
        x = startx,
        y = starty,
        speed = 1,
        velx = velocityx,
        vely = velocityy,
        isBlocked = function(self, x, y)
            return (self.x // 8) == x and (self.y // 8) == y
        end,
        update = function(self)
            shake:update()
            self.x = self.x + (self.velx * self.speed)
            self.y = self.y + (self.vely * self.speed)

            if self.x <= 3 then
                sfx(4, "E-1")
                self.velx = -self.velx
            end
            if self.y <= 3 then
                sfx(4, "E-1")
                self.vely = -self.vely
            end
            if self.x >= maxXpix - 3 then
                sfx(4, "E-1")
                self.velx = -self.velx
            end
            if self.y >= maxYpix - 3 then
                sfx(4, "E-1")
                self.vely = -self.vely
            end

            if map[self.x // 8][self.y // 8] then
                score:add()
                shake:start()
                sfx(0, "E-1")
                make_sparks_ps(self.x, self.y)
                map[self.x // 8][self.y // 8] = false
                if self.x - (self.velx * self.speed) <= (self.x // 8) * 8 then self.velx = -self.velx end
                if self.y - (self.vely * self.speed) <= (self.y // 8) * 8 then self.vely = -self.vely end
                if self.x - (self.velx * self.speed) >= ((self.x // 8) + 1) * 8 then self.velx = -self.velx end
                if self.y - (self.vely * self.speed) >= ((self.y // 8) + 1) * 8 then self.vely = -self.vely end
            end
        end,
        draw = function(self)
            spr(2, self.x-5, self.y-5, 0)
        end
    }
end

function createTarget(balls, map, score)
    local wallProgress = 80
    local wallTime = time()
    local ballProgress = 80
    local ballTime = time()
    local ready = true
    return {
        x = (math.random(20, maxXpix / 4) // 8) * 8,
        y = (math.random(20, maxYpix - 20) // 8) * 8,
        isHit = false,
        isReady = function(self)
            return wallProgress == 80
        end,
        start = function(self)
            wallProgress = 0
            wallTime = time()
        end,
        isBlocked = function(self, x, y)
            return ((self.x // 8) == x or (self.x // 8) == x + 1) and ((self.y // 8) == y or (self.y // 8) == y + 1)
        end,
        update = function(self)
            if ballProgress < 80 then
                ballProgress = math.min(math.floor(((time()-ballTime)/100)), 80)
            else
                ballProgress = 0
                ballTime = time()
                balls[#balls + 1] = createBall(map, score)
            end
            if wallProgress < 80 then
                wallProgress = math.min(math.floor(((time()-wallTime)/15)), 80)
            end
            for _,ball in pairs(balls) do
                -- TODO: Calculate distance properly and not like these circular things are squares
                if ball.x > (self.x-6) and ball.y > (self.y-6) and ball.x < (self.x+6) and ball.y < (self.y+6) then
                    self.isHit = true
                end
            end
        end,
        draw = function(self)
            local i = 96 + (2 * (math.floor(time()/100) % 8))
            spr(i, self.x-7, self.y-7, 0, 1, 0, 0, 2, 2)

            rect(1, maxYpix+1, 78, 6, 0)
            rect(1, maxYpix+1, wallProgress-2, 6, 9)
            printWithShadow("NEXT WALL", 2, maxYpix + 1, 15)

            rect(81, maxYpix+1, 78, 6, 0)
            rect(81, maxYpix+1, ballProgress-2, 6, 6)
            printWithShadow("NEXT BALL", 82, maxYpix + 1, 15)
        end
    }
end

function createUser(map, tetrisShapes, target, balls)
    local drawSquare = function(sprite, x, y)
        if x > maxX or x < 0 or y > maxY or y < 0 then return end
        if map[x][y] then
            spr(sprite - 1, x * 8, y * 8)
        else
            spr(sprite, x * 8, y * 8)
        end
    end

    local isSquareBlocked = function(x, y)
        local isBlocked = false
        isBlocked = isBlocked or x > maxX or x < 0 or y > maxY or y < 0 or map[x][y] or target:isBlocked(x, y)
        for _,ball in pairs(balls) do isBlocked = isBlocked or ball:isBlocked(x, y) end
        return isBlocked
    end

    local currentShape = 3;
    local canDraw = target:isReady()

    return {
        x = 0,
        y = 0,
        rotation = 0,
        out = true,
        prevRight = true,
        prevLeft = true,
        free = true,
        update = function(self)
            canDraw = target:isReady()
            local x, y, left, middle, right = mouse()
            self.out = (x > maxXpix) or (y > maxYpix)
            if self.out or not canDraw then return end

            self.x = (x // 8)
            self.y = (y // 8)
            self.free = true

            for _, square in pairs(tetrisShapes[currentShape]) do
                if self.rotation == 0 then
                    self.free = self.free and not isSquareBlocked(self.x + square.x, self.y + square.y)
                elseif self.rotation == 1 then
                    self.free = self.free and not isSquareBlocked(self.x - square.y, self.y + square.x)
                elseif self.rotation == 2 then
                    self.free = self.free and not isSquareBlocked(self.x - square.x, self.y - square.y)
                elseif self.rotation == 3 then
                    self.free = self.free and not isSquareBlocked(self.x + square.y, self.y - square.x)
                end
            end

            if left then
                if not self.prevLeft then
                    self.prevLeft = true
                    if self.free then
                        canDraw = false
                        target:start()
                        sfx(1, "E-2")
                        for _, square in pairs(tetrisShapes[currentShape]) do
                            if self.rotation == 0 then
                                map[(self.x + square.x)][(self.y + square.y)] = true
                            elseif self.rotation == 1 then
                                map[(self.x - square.y)][(self.y + square.x)] = true
                            elseif self.rotation == 2 then
                                map[(self.x - square.x)][(self.y - square.y)] = true
                            elseif self.rotation == 3 then
                                map[(self.x + square.y)][(self.y - square.x)] = true
                            end
                        end
                        currentShape = math.random(0, #tetrisShapes)
                    else
                        sfx(2, "E-3")
                    end
                end
            else
                self.prevLeft = false
            end

            if right then
                if not self.prevRight then
                    sfx(1, "E-4")
                    self.prevRight = true
                    self.rotation = (self.rotation + 1) % 4;
                end
            else
                self.prevRight = false
            end
        end,
        draw = function(self)
            if self.out or not canDraw then return end
            local index = 1
            if not self.free then index = index + 16 end
            for _, square in pairs(tetrisShapes[currentShape]) do
                if self.rotation == 0 then
                    drawSquare(index, self.x + square.x, self.y + square.y)
                elseif self.rotation == 1 then
                    drawSquare(index, self.x - square.y, self.y + square.x)
                elseif self.rotation == 2 then
                    drawSquare(index, self.x - square.x, self.y - square.y)
                elseif self.rotation == 3 then
                    drawSquare(index, self.x + square.y, self.y - square.x)
                end
            end
        end
    }
end

function createScore(balls)
    local score = 0
    return {
        getScore = function()
            return score
        end,
        add = function()
            score = score + #balls
        end,
        update = function()
        end,
        draw = function()
            local str = "Score: " .. score
            local w = print(str, 0, -20)

            printWithShadow(str, maxXpix - w - 1, maxYpix + 1, 15)
        end
    }
end

function createGameScene()
    local map = {}

    for i=0,maxX do
        map[i] = {}
        for j=0,maxY do
        map[i][j] = false
        end
    end

    local balls = {}
    local score = createScore(balls)
    local target = createTarget(balls, map, score)
    local user = createUser(map, tetrisShapes, target, balls)
    local shake = createShake(6, 120)
    local wasHit = false
    local hitTime = -1

    return {
        update = function()
            if target.isHit then
                if hitTime == -1 then
                    shake:start()
                    hitTime = time()
                    sfx(3, "E-3", 120)
                end
                shake:update()
                if (time() - hitTime) > 2000 then
                    shake:reset()
                    currentScene = createGameOverScene(score:getScore())
                end
            else
                user:update()
                for _,b in pairs(balls)   do b:update() end
                target:update()
                score:update()
            end
            update_psystems()
        end,
        draw = function()
            cls(3)
            rect(0, 0, maxXpix, maxYpix, 2)

            for i=0,maxX do
                for j=0,maxY do
                    if map[i][j] then spr(0, i * 8, j * 8) end
                end
            end

            user:draw()

            for _,b in pairs(balls)   do b:draw() end
            target:draw()
            score:draw()
            draw_psystems()
        end
    }
end

function createGameOverScene(score)
    local topScore = pmem(0)
    local prevLeft = true
    local prevRight = true
    local goNext = function()
        sfx(5, "E-4")
        currentScene = createTitleScene()
    end

    if score > topScore then
        pmem(0, score)
    end

    return {
        update = function()
            if btnp() ~= 0 then goNext() end
            local x, y, left, middle, right = mouse()
            if left then
                if not prevLeft then
                    prevLeft = true
                    goNext()
                end
            else
                prevLeft = false
            end
            if right then
                if not prevRight then
                    prevRight = true
                    goNext()
                end
            else
                prevRight = false
            end
        end,
        draw = function()
            cls(2)
            local w = printWithShadow("Your score: " .. score, 10, 10, 15)
            if (score > topScore) and ((time()/300)%2 > 1) then
                printWithShadow(" NEW RECORD", 10 + w, 10, 14)
            end
            printWithShadow("Top score: " .. topScore, 10, 20, 15)
            print("Game", 68, 43, 0, false, 4)
            print("Game", 65, 40, 15, false, 4)
            print("Over", 68, 73, 0, false, 4)
            print("Over", 65, 70, 15, false, 4)
            printWithShadow("click to start", 153, 122, 15)
        end
    }
end

function createTitleScene()
    local prevLeft = true
    local prevRight = true
    local goToGameScene = function()
        currentScene = createGameScene()
    end
    return {
        update = function()
            if btnp() ~= 0 then goToGameScene() end
            local x, y, left, middle, right = mouse()
            if left then
                if not prevLeft then
                    prevLeft = true
                    goToGameScene()
                end
            else
                prevLeft = false
            end
            if right then
                if not prevRight then
                    prevRight = true
                    goToGameScene()
                end
            else
                prevRight = false
            end
        end,
        draw = function()
            cls(2)
            print("Tetrawall", 18, 13, 0, false, 4)
            print("Tetrawall", 15, 10, 15, false, 4)
            printWithShadow("Prevent the destruction of the atom", 19, 40, 15)
            print("destruction", 87, 40, 5)
            print("atom", 192, 40, 9)
            printWithShadow("Left mouse click", 18, 60, 14)
            printWithShadow("......... place the wall", 110, 60, 14)
            printWithShadow("Right mouse click", 16, 70, 14)
            printWithShadow("......... rotate the wall", 110, 70, 14)

            printWithShadow("lowcase.itch.io", 5, 118, 7)
            printWithShadow("OLC CodeJam 2019", 5, 125, 7)

            printWithShadow("click to start", 153, 122, 15)
        end
    }
end

currentScene = createTitleScene()

function TIC()
    currentScene:update()
    currentScene:draw()
end




--==================================================================================--
-- PARTICLE SYSTEM LIBRARY =========================================================--
--==================================================================================--

particle_systems = {}

-- Call this, to create an empty particle system, and then fill the emittimers, emitters,
-- drawfuncs, and affectors tables with your parameters.
function make_psystem(minlife, maxlife, minstartsize, maxstartsize, minendsize, maxendsize)
	local ps = {
	-- global particle system params

	-- if true, automatically deletes the particle system if all of it's particles died
	autoremove = true,

	minlife = minlife,
	maxlife = maxlife,

	minstartsize = minstartsize,
	maxstartsize = maxstartsize,
	minendsize = minendsize,
	maxendsize = maxendsize,

	-- container for the particles
	particles = {},

	-- emittimers dictate when a particle should start
	-- they called every frame, and call emit_particle when they see fit
	-- they should return false if no longer need to be updated
	emittimers = {},

	-- emitters must initialize p.x, p.y, p.vx, p.vy
	emitters = {},

	-- every ps needs a drawfunc
	drawfuncs = {},

	-- affectors affect the movement of the particles
	affectors = {},
	}

	table.insert(particle_systems, ps)

	return ps
end

-- Call this to update all particle systems
function update_psystems()
	local timenow = time()
	for key,ps in pairs(particle_systems) do
		update_ps(ps, timenow)
	end
end

-- updates individual particle systems
-- most of the time, you don't have to deal with this, the above function is sufficient
-- but you can call this if you want (for example fast forwarding a particle system before first draw)
function update_ps(ps, timenow)
	for key,et in pairs(ps.emittimers) do
		local keep = et.timerfunc(ps, et.params)
		if (keep==false) then
			table.remove(ps.emittimers, key)
		end
	end

	for key,p in pairs(ps.particles) do
		p.phase = (timenow-p.starttime)/(p.deathtime-p.starttime)

		for key,a in pairs(ps.affectors) do
			a.affectfunc(p, a.params)
		end

		p.x = p.x + p.vx
		p.y = p.y + p.vy

		local dead = false
		if (p.x<0 or p.x>240 or p.y<0 or p.y>136) then
			dead = true
		end

		if (timenow>=p.deathtime) then
			dead = true
		end

		if (dead==true) then
			table.remove(ps.particles, key)
		end
	end

	if (ps.autoremove==true and #ps.particles<=0) then
		local psidx = -1
		for pskey,pps in pairs(particle_systems) do
			if pps==ps then
				table.remove(particle_systems, pskey)
				return
			end
		end
	end
end

-- draw a single particle system
function draw_ps(ps, params)
	for key,df in pairs(ps.drawfuncs) do
		df.drawfunc(ps, df.params)
	end
end

-- draws all particle system
-- This is just a convinience function, you probably want to draw the individual particles,
-- if you want to control the draw order in relation to the other game objects for example
function draw_psystems()
	for key,ps in pairs(particle_systems) do
		draw_ps(ps)
	end
end

-- This need to be called from emitttimers, when they decide it is time to emit a particle
function emit_particle(psystem)
	local p = {}

	local ecount = nil
	local e = psystem.emitters[math.random(#psystem.emitters)]
	e.emitfunc(p, e.params)

	p.phase = 0
	p.starttime = time()
	p.deathtime = time()+frnd(psystem.maxlife-psystem.minlife)+psystem.minlife

	p.startsize = frnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
	p.endsize = frnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

	table.insert(psystem.particles, p)
end

function frnd(max)
	return math.random()*max
end


--================================================================--
-- MODULES =======================================================--
--================================================================--

-- You only need to copy the modules you actually use to your program


-- EMIT TIMERS ==================================================--

-- Spawns a bunch of particles at the same time, then removes itself
-- params:
-- num - the number of particle to spawn
function emittimer_burst(ps, params)
	for i=1,params.num do
		emit_particle(ps)
	end
	return false
end

-- Emits a particle every "speed" time
-- params:
-- speed - time between particle emits
function emittimer_constant(ps, params)
	if (params.nextemittime<=time()) then
		emit_particle(ps)
		params.nextemittime = params.nextemittime + params.speed
	end
	return true
end

-- EMITTERS =====================================================--

-- Emits particles from a single point
-- params:
-- x,y - the coordinates of the point
-- minstartvx, minstartvy and maxstartvx, maxstartvy - the start velocity is randomly chosen between these values
function emitter_point(p, params)
	p.x = params.x
	p.y = params.y

	p.vx = frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

-- Emits particles from the surface of a rectangle
-- params:
-- minx,miny and maxx, maxy - the corners of the rectangle
-- minstartvx, minstartvy and maxstartvx, maxstartvy - the start velocity is randomly chosen between these values
function emitter_box(p, params)
	p.x = frnd(params.maxx-params.minx)+params.minx
	p.y = frnd(params.maxy-params.miny)+params.miny

	p.vx = frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

-- AFFECTORS ====================================================--

-- Constant force applied to the particle troughout it's life
-- Think gravity, or wind
-- params:
-- fx and fy - the force vector
function affect_force(p, params)
	p.vx = p.vx + params.fx
	p.vy = p.vy + params.fy
end

-- A rectangular region, if a particle happens to be in it, apply a constant force to it
-- params:
-- zoneminx, zoneminy and zonemaxx, zonemaxy - the corners of the rectangular area
-- fx and fy - the force vector
function affect_forcezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = p.vx + params.fx
		p.vy = p.vy + params.fy
	end
end

-- A rectangular region, if a particle happens to be in it, the particle stops
-- params:
-- zoneminx, zoneminy and zonemaxx, zonemaxy - the corners of the rectangular area
function affect_stopzone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = 0
		p.vy = 0
	end
end

-- A rectangular region, if a particle cames in contact with it, it bounces back
-- params:
-- zoneminx, zoneminy and zonemaxx, zonemaxy - the corners of the rectangular area
-- damping - the velocity loss on contact
function affect_bouncezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = -p.vx*params.damping
		p.vy = -p.vy*params.damping
	end
end

-- A point in space which pulls (or pushes) particles in a specified radius around it
-- params:
-- x,y - the coordinates of the affector
-- radius - the size of the affector
-- strength - push/pull force - proportional with the particle distance to the affector coordinates
function affect_attract(p, params)
	if (math.abs(p.x-params.x)+math.abs(p.y-params.y)<params.mradius) then
		p.vx = p.vx + (p.x-params.x)*params.strength
		p.vy = p.vy + (p.y-params.y)*params.strength
	end
end

-- Moves particles around in a sin/cos wave or circulary. Directly modifies the particle position
-- params:
-- speed - the effect speed
-- xstrength, ystrength - the amplituse around the x and y axes
function affect_orbit(p, params)
	params.phase = params.phase + params.speed
	p.x = p.x + math.sin(params.phase)*params.xstrength
	p.y = p.y + math.cos(params.phase)*params.ystrength
end

-- DRAW FUNCS ===================================================--

-- Filled circle particle drawer, the particle animates it's size and color trough it's life
-- params:
-- colors array - indexes to the palette, the particle goes trough these in order trough it's lifetime
-- startsize and endsize is coming from the particle system parameters, not the draw func params!
function draw_ps_fillcirc(ps, params)
	for key,p in pairs(ps.particles) do
		c = math.floor(p.phase*#params.colors)+1
		r = (1-p.phase)*p.startsize+p.phase*p.endsize
		circ(p.x,p.y,r,params.colors[c])
	end
end

-- Single pixel particle, which animates trough the given colors
-- params:
-- colors array - indexes to the palette, the particle goes trough these in order trough it's lifetime
function draw_ps_pixel(ps, params)
	for key,p in pairs(ps.particles) do
		c = math.floor(p.phase*#params.colors)+1
		pix(p.x,p.y,params.colors[c])
	end
end

-- Draws a line between the particle's previous and current position, kind of "motion blur" effect
-- params:
-- colors array - indexes to the palette, the particle goes trough these in order trough it's lifetime
function draw_ps_streak(ps, params)
	for key,p in pairs(ps.particles) do
		c = math.floor(p.phase*#params.colors)+1
		line(p.x,p.y,p.x-p.vx,p.y-p.vy,params.colors[c])
	end
end

-- Animates trough the given frames with the given speed
-- params:
-- frames array - indexes to sprite tiles
function draw_ps_animspr(ps, params)
	params.currframe = params.currframe + params.speed
	if (params.currframe>#params.frames) then
		params.currframe = 1
	end
	for key,p in pairs(ps.particles) do
		-- pal(7,params.colors[math.floor(p.endsize)])
		spr(params.frames[math.floor(params.currframe+p.startsize)%#params.frames],p.x,p.y,0)
	end
	-- pal()
end

-- Maps the given frames to the life of the particle
-- params:
-- frames array - indexes to sprite tiles
function draw_ps_agespr(ps, params)
	for key,p in pairs(ps.particles) do
		local f = math.floor(p.phase*#params.frames)+1
		spr(params.frames[f],p.x,p.y,0)
	end
end

-- Each particle is randomly chosen from the given frames
-- params:
-- frames array - indexes to sprite tiles
function draw_ps_rndspr(ps, params)
	for key,p in pairs(ps.particles) do
		-- pal(7,params.colors[math.floor(p.endsize)])
		spr(params.frames[math.floor(p.startsize)],p.x,p.y,0)
	end
	-- pal()
end


--==================================================================================--
-- SAMPLES PARTICLE SYSTEMS ========================================================--
--==================================================================================--

function make_magicsparks_ps(ex,ey)
	local ps = make_psystem(300,1700, 1,5,1,5)

	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 10}
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc = emitter_box,
			params = { minx = ex-8, maxx = ex+8, miny = ey-8, maxy= ey+8, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -3, maxstartvy=-2 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_rndspr,
			params = { frames = {32,33,34,35,36} }
			-- params = { frames = {32,33,34,35,36}, colors = {8,9,11,12,14} }
		}
	)
	table.insert(ps.affectors,
		{
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.3 }
		}
	)

end

function make_sparks_ps(ex,ey)
	local ps = make_psystem(300,700, 1,2, 0.5,0.5)

	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 10 }
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -3, maxstartvy=-2 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {15,14,12,9,4,3} }
		}
	)
	table.insert(ps.affectors,
		{
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.3 }
		}
	)
end