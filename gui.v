module main

//import ui
import gg
import gx
import time
import os
import sokol.sapp
import math

const (
	win_width  = 800
	win_height = 620
	grid_width = 20
	grid_height = 15
	margin_top = 20
	head_col = gx.black
	body_col = gx.blue
	food_col = gx.red
	bgcolor = [gx.green, gx.yellow]
	//moves per second
	mps = 6
)

struct App {
mut:
	score	int
	snake	Snake = Snake{}
	gg 	&gg.Context = 0
	size	int	= 40
	margin_left	int
	gameover bool
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


	mut font_path := os.resource_abs_path(os.join_path('..', 'assets', 'fonts', 'RobotoMono-Regular.ttf'))
	$if android {
		font_path = 'fonts/RobotoMono-Regular.ttf'
	}
	
	app.snake.data = app
	app.gg = gg.new_context({
		width: win_width
		height: win_height
		window_title: 'Snake'
		user_data: app
		use_ortho: true
		keydown_fn: key_press
		create_window: true
		frame_fn: frame
		bg_color: gx.white
		font_path: font_path
		event_fn: event
		//sample_count: 8
	})
	
	go app.game()
	app.gg.run()
}

fn event(e &sapp.Event, mut app App) {
	match e.typ {
		.resized, .restored, .resumed {
			handle_size(mut app)
		}
		else {}
	}
}

fn frame(app &App) {
	app.gg.begin()
	draw_grid(app)
	app.gg.end()
}

fn draw_grid (app &App) {
	//text
	gg:=app.gg
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
	//grid
	for x in 0..app.snake.field.width {
		for y in 0..app.snake.field.height {
			gg.draw_rect(x * app.size + app.margin_left, y * app.size + margin_top, app.size, app.size, bgcolor[(x + y) % 2])
		}
	}
	//head
	gg.draw_rect(app.snake.body[0].x * app.size + app.margin_left, app.snake.body[0].y * app.size + margin_top, app.size, app.size, head_col)
	//body
	for b in app.snake.body[1..] {
		gg.draw_rect(b.x * app.size + app.margin_left, b.y * app.size + margin_top, app.size, app.size, body_col)
	}
	//food
	gg.draw_circle(int(app.snake.field.food.x * app.size + app.size / 2 + app.margin_left), int(app.snake.field.food.y * app.size + margin_top + app.size / 2), app.size / 2, food_col)
}

fn on_dead(mut app App) {
	app.gameover = true
}

fn on_grow(mut app App) {
	app.score ++
}

fn key_press(e sapp.KeyCode, m sapp.Modifier, mut app App) {
	
		if int(e) == 32 {
			space_pressed(mut app)
		} else {
		app.snake.set_orientation((
		match int(e){
			263, 65	{Position(Direction.left)}
			262, 68	{Position(Direction.right)}
			265, 87	{Position(Direction.top)}
			264, 83	{Position(Direction.down)}
			else	{Position(app.snake.orientation)}
		}
	))
	}
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
	for !app.gameover {
		app.snake.move()
		time.sleep_ms(1000/ mps)
	}
}

fn handle_size(mut app App) {
	width, height := sapp.width(), sapp.height()
	mw:= width / grid_width
	mh:= (height - margin_top) / grid_height
	app.size = if mw > mh {mh} else {mw}
	app.margin_left = (width - app.size * grid_width) / 2
}

