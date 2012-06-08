require "libs.strict"

Vector = require "libs.hump.vector"
Gamestate = require "libs.hump.gamestate"

states = {}

function love.load()
	states.game = require "states.game"

	Gamestate.registerEvents()
	Gamestate.switch(states.game)
end
