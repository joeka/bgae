local hello = Gamestate.new()

function hello:init()
	love.event.push( "quit" )
end

return hello
