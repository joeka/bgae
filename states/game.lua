local game = Gamestate.new()

game.player = { }

camMaxDist = 50

game.objects = {}

function game:init()
	game.player.pos = Vector ( 100, 100 )
	game.player.rot = 0

	game.player.image = love.graphics.newImage( "assets/graphics/dummy.png" )

	game.camera = Camera( 100, 100 )

	game.collider = HC( 100, on_collision, collision_stop )
	game.player.shape = game.collider:addRectangle( game.player.pos.x, game.player.pos.y, 40, 15 )
	game.objects.rect1 = game.collider:addRectangle( 50, 50, 20, 20 )

	game.projectiles = {}
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
	game.collider:update(dt)
end

function on_collision( dt, shape_a, shape_b, mtv_x, mtv_y )
	if shape_a == game.player.shape then
		game.player:move( mtv_x, mtv_y )
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
		local rot = math.atan2(dir.x, -dir.y)
		if rot ~= game.player.rot then
			game.player.shape:rotate( rot - game.player.rot )
			game.player.rot = rot
		end
	end

	local newX = game.player.pos.x + dir.x * dt * 100
	local newY = game.player.pos.y + dir.y * dt * 100
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
	
	love.graphics.rectangle( "fill", 50, 50, 20, 20 )
	
	game.player.shape:draw("fill")
	love.graphics.draw( game.player.image, game.player.pos.x, game.player.pos.y, game.player.rot, 1, 1, 25, 10 )
    drawBullets()
	game.camera:detach()
end

return game
