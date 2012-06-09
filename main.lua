HC = require "libs.HardonCollider"

require "libs.strict"

Vector = require "libs.hump.vector"
Gamestate = require "libs.hump.gamestate"
Camera = require "libs.hump.camera"

states = {}

function love.load()
	states.game = require "states.game"
	
	states.fuckup = require "states.hello"

	Gamestate.registerEvents()
	Gamestate.switch(states.game)
end
