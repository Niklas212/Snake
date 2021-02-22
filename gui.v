module main

import ui
import gg
import gx
import time

const (
	win_width  = 800
	win_height = 620
	grid_width = 20
	grid_height = 15
	margin_top = 20
	color	= [gx.green, gx.black, gx.blue, gx.red]
	//moves per second
	mps = 6
)

struct App {
mut:
	score	int
	//label	&ui.TextBox = 0
	snake	Snake = Snake{}
	window  &ui.Window = 0
	size	int	= 40
	gameover bool	= false
	grid	[][]int
}

fn main() {
	mut app := &App{
		grid: [][]int{len:grid_width, init:[]int{len:grid_height}}
		snake: Snake{
			field: Map{
				width : grid_width
				height : grid_height
				food : V2{x: 4, y: 4}
			}
			on_dead: on_dead
			on_grow: on_grow
			}

		}
	mut p:=""
	/*app.label=ui.textbox({
		text: &p
		read_only: true
	})*/
	app.snake.data = app
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Snake'
		state: app
		on_key_down: key_press
	}, [
		ui.canvas({
			draw_fn : draw_grid
		})
	])
	
	go app.game()
	ui.run(app.window)
}

fn draw_grid (gg &gg.Context, mut app &App, can &ui.Canvas) {
	
	if app.gameover {
		gg.draw_text(4, 4, "Game Over, press Space, your score:$app.score", 
			gx.TextCfg{
				color: gx.red
				align: gx.align_left
			}
		)
	}
	else {
		gg.draw_text(4, 4, "$app.score", 
			gx.TextCfg{
				color: gx.black
				align: gx.align_left
			}
		)
	}
	
	m:=app.grid
	for x in 0..app.snake.field.width {
		for y in 0..app.snake.field.height {
			gg.draw_rect(x * app.size, y * app.size + margin_top, app.size, app.size, color[m[y][x]])
		}
	}
}
/*
fn (mut app App) set_gameover() {
	app.gameover = true
}
*/
fn on_dead(mut app App) {
	app.gameover = true
}

fn on_grow(mut app App) {
	app.score ++
}

fn key_press(e ui.KeyEvent, mut app App) {
	
		if int(e.key) == 32 {
			space_pressed(mut app)
		} else {
		app.snake.set_orientation((
		match int(e.key){
			//32	{space_pressed(mut app)}
			263	{Direction.left}
			262	{Direction.right}
			265	{Direction.top}
			264	{Direction.down}
			else	{Direction.right}
		}
	))
	}
	app.window.refresh()
}

fn space_pressed(mut app App){
	if app.gameover {
		app.snake.body= [{x:2, y:0},{x:1, y:0},V2{x:0, y:0}]
		app.snake.field.set_food_random(app.snake)
		app.score = 0
		app.gameover = false
		app.snake.orientation = V2{x: 1, y:0}
		go app.game()
	}
}

fn (mut app App) game() {
	//println("start")
	for !app.gameover {
		//println("1")
		app.snake.move()
		if !app.gameover {
			//println("2")
			app.grid = app.snake.get_map()
			app.window.refresh()
		}
		time.sleep_ms(1000/ mps)
	}
	//println("stop")
	//println(app.snake)
}

