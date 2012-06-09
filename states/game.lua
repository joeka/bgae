TILED_LOADER_PATH = nil
tileSetProperties = nil
Animations_legacy_support = nil

require "libs.AnAL"
local game = Gamestate.new()

game.player = { }

game.zombies = {}
local zombieImage = nil

local camMaxDist = 10
local fancyOption = 3

game.objects = {}

game.loader = require("libs.AdvTiledLoader.Loader")
game.loader.path = "maps/"
game.map = game.loader.load("city.tmx")
game.layer = game.map.tl["Ground"]

local function findSpawn()
	return Vector( math.random( 32 * 32 ), math.random( 32*32 ) )
end

local function spawnZombie()
	local zombie = {}

	zombie.pos = findSpawn()
	zombie.rot = 0
	zombie.velocity = 40
    function zombie:move(x,y)
        zombie.pos.x = zombie.pos.x+x
    	zombie.pos.y = zombie.pos.y+y
    	zombie.shape:move( x, y )
    end
    
    function zombie:update(dt)
        zombie:move(math.random(1)*dt,math.random(1)*dt)
    end
	zombie.anim = newAnimation(zombieImage, 32, 32, 0.1, 3)	
	zombie.shape = game.collider:addRectangle( zombie.pos.x-2.5, zombie.pos.y-1.5, 5, 3 )

	zombie.shape.zombie = zombie

	table.insert( game.zombies, zombie )
end

function game:init()
	game.player.pos = Vector ( 32*5, 32*5 )
	game.player.rot = 0

	game.player.hp = 100

    game.fg = love.graphics.newImage("assets/graphics/fg2.png")
	game.player.image = love.graphics.newImage( "assets/graphics/animation.png" )
	zombieImage = love.graphics.newImage( "assets/graphics/zombie.png" )
    zombieImage:setFilter("nearest", "nearest")
	game.player.image:setFilter("nearest","nearest")
	game.camera = Camera( 100, 100, 4 )

	game.collider = HC( 100, on_collision, collision_stop )
	game.collidable_tiles = game:findSolidTiles(game.map)
	game.player.shape = game.collider:addRectangle( game.player.pos.x, game.player.pos.y, 5, 3 )
	game.player.anim = newAnimation(game.player.image, 32, 32, 0.1, 3)
	game.projectiles = {}

	for i = 1 , 50 do
		spawnZombie()
	end
end

function game:findSolidTiles(map)

    local collidable_tiles = {}
    
    local layer = map.tl["Buildings"]

    for tileX=1,map.width do
        for tileY=1,map.height do

            local tileId

            if layer.tileData(tileX,tileY) then
                local ctile = game.collider:addRectangle((tileX)*32,(tileY)*32,32,32)
                game.collider:setPassive(ctile)
                table.insert(collidable_tiles, ctile)
            end

        end
    end

    return collidable_tiles
end

function drawCollidableTiles()
    for i,v in ipairs(game.collidable_tiles) do
        --v:draw("fill")
    end
end

function game.player:moveTo(x, y)
	game.player.pos.x = x
	game.player.pos.y = y
	game.player.shape:moveTo( x, y )
end
function game.player:move( dx, dy )
	game.player.pos.x = game.player.pos.x + dx
	game.player.pos.y = game.player.pos.y + dy
	game.player.shape:move( dx, dy )
end

function game:update(dt)
	movement(dt)
	smoothFollow(dt)

	updateBullets(dt)
	updateZombies(dt)
	game.collider:update(dt)
end

function hit ( mtv_x, mtv_y )
	local dir = Vector( mtv_x, mtv_y):normalize_inplace()
	game.player:move( dir.x * 10, dir.y * 10 )

	game.player.hp = game.player.hp - 51
	if game.player.hp <= 0 then
		game.player.hp = 0
		Gamestate.switch( states.fuckup )
	end
end

function on_collision( dt, shape_a, shape_b, mtv_x, mtv_y )
	if shape_a == game.player.shape then
		if shape_b.zombie then
			hit( mtv_x, mtv_y )
		else
			game.player:move( mtv_x, mtv_y )
		end
	end
	if shape_a.zombie then
		if shape_b == game.player.shape then
			hit( -mtv_x, -mtv_y )
		else
	    	shape_a.zombie:move( mtv_x, mtv_y )
		end
    end
	if shape_a.bullet and shape_b ~= game.player.shape then
	    print( "bang1" )
		shape_a.bullet = false
		game.collider:remove(shape_a)
		-- kill someone maybe
		if shape_b.zombie then
			shape_b.zombie = false
			game.collider:remove(shape_b)
		end
	elseif shape_b.bullet and shape_a ~= game.player.shape then
		print( "bang2" )
		shape_b.bullet = false
		game.collider:remove(shape_b)
		-- kill someone maybe		
		if shape_a.zombie then
			shape_a.zombie = false
			game.collider:remove(shape_a)
		end
	end
	
end

function collision_stop( dt, shape_a, shape_b )
end

function movement(dt)
	local dir = Vector( 0, 0 )
	if love.keyboard.isDown("up") then
		dir.y = dir.y -1
	end
	if love.keyboard.isDown("down") then
		dir.y = dir.y +1
	end
	if love.keyboard.isDown("left") then
		dir.x = dir.x -1
	end
	if love.keyboard.isDown("right") then
		dir.x = dir.x +1
	end

	dir:normalize_inplace()
	
	if dir:len() > 0 then
	    game.player.anim:update(dt) 
		local rot = math.atan2(dir.x, -dir.y)
		if rot ~= game.player.rot then
			game.player.shape:rotate( rot - game.player.rot )
			game.player.rot = rot
		end
	else
	    game.player.anim:seek(3)
	end

	local newX = game.player.pos.x + dir.x * dt * 50
	local newY = game.player.pos.y + dir.y * dt * 50
	game.player:moveTo( newX, newY )
end

function game:keypressed(key)
    if key == " " then
        shoot()
    end
end

function shoot()
    local bullet = {}
    bullet.pos = Vector(game.player.pos.x, game.player.pos.y)
    bullet.dir = Vector(math.cos(game.player.rot-math.pi/2), math.sin(game.player.rot-math.pi/2))
    bullet.velocity = 200
	bullet.shape = game.collider:addRectangle(bullet.pos.x-3, bullet.pos.y-3,6,6)
	bullet.shape.bullet = true
    table.insert(game.projectiles, bullet)
end

function updateZombies(dt)

	for i, zombie in ipairs(game.zombies) do
		if zombie.shape.zombie then
            local dist = game.player.pos:dist(zombie.pos)
            
            if dist < 64 then
                local dir = game.player.pos - zombie.pos
                dir:normalize_inplace()
                zombie:move(dir.x*dt*zombie.velocity, dir.y*dt*zombie.velocity)
                local rot = math.atan2(dir.x, -dir.y)
        		if rot ~= zombie.rot then
        			zombie.shape:rotate( rot - zombie.rot )
        			zombie.rot = rot
        		end
        		zombie.anim:update(dt)
            end
		else
			table.remove(game.zombies, i)
		end
	end
end

function updateBullets(dt)
    for i,v in ipairs(game.projectiles) do
		if v.shape.bullet then
        	v.pos = v.pos + v.dir*dt*v.velocity
			v.shape:moveTo(v.pos.x, v.pos.y)
    	else
			table.remove(game.projectiles, i)
		end
	end
end

local function drawBullets()
    for i,v in ipairs(game.projectiles) do
        love.graphics.circle("fill", v.pos.x, v.pos.y, 1, 16)
    end
end

local function drawZombies()
	for i,zombie in ipairs(game.zombies) do
	    --zombie.shape:draw("fill")
		zombie.anim:draw( zombie.pos.x, zombie.pos.y, zombie.rot, 0.5, 0.5, 16, 16)
	end
end

function smoothFollow(dt)
	local dist = game.player.pos:dist( Vector(game.camera.x, game.camera.y) )
	if dist > camMaxDist then
		local dir = Vector(game.player.pos.x - game.camera.x, game.player.pos.y - game.camera.y)
		dir:normalize_inplace()
		dir.x = dir.x * dt * dist * fancyOption
		dir.y = dir.y * dt * dist * fancyOption
		game.camera:move( dir.x, dir.y )
	end
end

local function drawGUI()
	love.graphics.setColor(255,255,255,200)
	love.graphics.rectangle( "fill", 600, 10, 104, 14 )
	love.graphics.setColor(255,0,0,200)
	love.graphics.rectangle( "fill", 602, 12, game.player.hp, 10 )
end

function game:draw()
	love.graphics.setColor(255,255,255,255)
	
	game.camera:attach()
	local ftx, fty = math.floor(game.player.pos.x), math.floor(game.player.pos.y)
	game.map:draw()
	drawCollidableTiles()
	--game.player.shape:draw("fill")
	--love.graphics.draw( game.player.image, game.player.pos.x, game.player.pos.y, game.player.rot, 0.5,0.5, 16, 16 )
	game.player.anim:draw(game.player.pos.x, game.player.pos.y, game.player.rot, 0.5, 0.5, 16, 16 )
	drawZombies()
	drawBullets()
	game.camera:detach()
	love.graphics.setBlendMode("multiplicative")
	
    local x,y = game.camera:cameraCoords(game.player.pos.x, game.player.pos.y)
    love.graphics.setColor(255,255,255,200)
	love.graphics.draw(game.fg, x,y, 0,1,1,512,512)

	love.graphics.setBlendMode("alpha")

	drawGUI()
end


return game
