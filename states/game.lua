local game = Gamestate.new()

game.player = { }

camMaxDist = 50

function game:init()
	game.player.pos = Vector ( 100, 100 )
	game.player.rot = 0

	game.player.image = love.graphics.newImage( "assets/graphics/dummy.png" )

	game.camera = Camera( 100, 100 )
	game.projectiles = {}
end

function game:update(dt)
	movement(dt)
	smoothFollow(dt)
	updateBullets(dt)
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
		game.player.rot = math.atan2(dir.x, -dir.y)
	end

	game.player.pos.x = game.player.pos.x + dir.x * dt * 100
	game.player.pos.y = game.player.pos.y + dir.y * dt * 100
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
    table.insert(game.projectiles, bullet)
end

function updateBullets(dt)
    for i,v in ipairs(game.projectiles) do
        v.pos = v.pos + v.dir*dt*v.velocity
    end
end

function drawBullets()
    for i,v in ipairs(game.projectiles) do
        love.graphics.circle("fill", v.pos.x,v.pos.y,2,16)
    end
end

function smoothFollow(dt)
	local dist = game.player.pos:dist( Vector(game.camera.x, game.camera.y) )
	if dist > camMaxDist then
		local dir = Vector(game.player.pos.x - game.camera.x, game.player.pos.y - game.camera.y)
		dir:normalize_inplace()
		dir.x = dir.x * dt * dist
		dir.y = dir.y * dt * dist
		game.camera:move( dir.x, dir.y )
	end
end

function game:draw()
	game.camera:attach()

	love.graphics.draw( game.player.image, game.player.pos.x, game.player.pos.y, game.player.rot, 1, 1, 25, 10 )
    drawBullets()
	game.camera:detach()
end

return game
