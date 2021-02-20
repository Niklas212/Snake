module main

import ui

const (
	win_width	= 600
	win_height	= 400
	grid_width	= 20
	grid_height = 15

)

struct App {
	mut:
	window &ui.Window = 0
	snake Snake = Snake{}
}

fn main() {
	mut app := &App{}

	app.window = &ui.Window{
		width: win_width
		height: win_height
		title: 'Snake'
		state: app
	}

	ui.run(app.window)
}