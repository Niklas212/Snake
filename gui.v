module main

//import ui
import gg
import gx
import time
import os
import sokol.sapp
//import math

const (
	win_width  = 800
	win_height = 620
	grid_width = 20
	grid_height = 15
	margin_top = 20
	head_col = gx.black
	body_col = gx.blue
	food_col = gx.red
	bgcolor = [gx.rgb(162, 209, 73), gx.rgb(170, 215, 81)]
	//moves per second
	mps = 10
	fps = 120
	
	rounded = 8
	snake_perc = 0.8
	snake_perc_to_top = (1 - snake_perc) / 2
	snake_perc_to_left = 1 - snake_perc_to_top

	text_normal = gx.TextCfg{
				color: gx.red
				align: gx.align_left
			}
	text_dead = gx.TextCfg{
				color: gx.black
				align: gx.align_left
			}
)

struct App {
mut:
	score	int
	snake	Snake = Snake{}
	gg 	&gg.Context = 0
	size	int	= 40
	margin_left	int
	time	time.StopWatch
	gameover bool
	//fps	int = 60 // only related to animation
	animation_progress	int
	grid	[][]int
	round_a	int = rounded
}

struct F2 {
	x	f32
	y	f32
}

fn f2_ (a V2) F2 {
	return F2 {f32(a.x), f32(a.y)}
}

fn v2_ (a F2) V2 {
	return V2 {int(a.x), int(a.y)}
}

fn (a F2) + (b F2) F2 {
	return F2{a.x + b.x, a.y + a.y}
}

fn min_max_f (a F2, b F2, c F2, d F2) (F2, F2) {
	return F2{ int(a.x<=b.x && a.x<=c.x && a.x<= d.x) * a.x + int(b.x<a.x && b.x<=c.x && b.x<= d.x) * b.x + int(c.x<b.x && c.x<a.x && c.x<= d.x) * c.x + int(d.x<b.x && d.x<c.x && d.x< a.x) * d.x, int(a.y<=b.y && a.y<=c.y && a.y<= d.y) * a.y + int(b.y<a.y && b.y<=c.y && b.y<= d.y) * b.y + int(c.y<b.y && c.y<a.y && c.y<= d.y) * c.y + int(d.y<b.y && d.y<c.y && d.y< a.y) * d.y}, F2{ int(a.x>=b.x && a.x>=c.x && a.x>= d.x) * a.x + int(b.x>a.x && b.x>=c.x && b.x>= d.x) * b.x + int(c.x>b.x && c.x>a.x && c.x>= d.x) * c.x + int(d.x>b.x && d.x>c.x && d.x> a.x) * d.x, int(a.y>=b.y && a.y>=c.y && a.y>= d.y) * a.y + int(b.y>a.y && b.y>=c.y && b.y>= d.y) * b.y + int(c.y>b.y && c.y>a.y && c.y>= d.y) * c.y + int(d.y>b.y && d.y>c.y && d.y> a.y) * d.y }
}

fn (a F2) mul(b int) (V2) {
	return V2{int(a.x * b), int(a.y * b)}
}

fn (a F2) mul_f(b f32) (F2) {
	return F2{int(a.x * b), int(a.y * b)}
}

fn main() {
	mut app := &App{
		grid: [][]int{len:grid_width, init:[]int{len:grid_height}}
		snake: Snake{
			field: Map{
				width : grid_width
				height : grid_height
				food : V2{x: 6, y: 0}
			}
			on_dead: on_dead
			on_grow: on_grow
			}
		time: time.new_stopwatch({})
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
	//go app.animate()
	app.gg.run()
}

fn event(e &gg.Event, mut app App) {
			match e.typ {
			.resized, .restored, .resumed {
				handle_size(mut app)
			}
			else {}
		}
}

fn frame(mut app App) {
	//app.time.restart()
	
	//println(1_000_000_000 / app.time.elapsed()) /* shows fps */
	app.gg.begin()
	draw_grid(app)
	app.gg.end()
}

fn draw_grid (app &App) {
	
		animation_progress:= f32(app.animation_progress / f32(fps) * f32(mps) )
		head_position:=F2{f32(app.snake.last_orientation.x) * animation_progress + app.snake.body[1].x, f32(app.snake.last_orientation.y) * animation_progress + app.snake.body[1].y}
	
	//text
	gg:=app.gg
	if app.gameover {
		gg.draw_text(4, 4, "Game Over, press Space, your score:$app.score", text_normal)
	}
	else {
		gg.draw_text(4, 4, "$app.score", text_dead)
	}
	//grid
	for x in 0..app.snake.field.width {
		for y in 0..app.snake.field.height {
			gg.draw_rect(x * app.size + app.margin_left, y * app.size + margin_top, app.size, app.size, bgcolor[(x + y) % 2])
		}
	}
	
	
	//body
	mut last:=app.snake.body[1]
	for part in app.snake.body[2..app.snake.body.len] {

		p1:=F2{f32(last.x) + snake_perc_to_top, f32(last.y) + snake_perc_to_top}
		p2:=F2{f32(last.x) + snake_perc_to_left, f32(last.y) + snake_perc_to_left}
		p3:=F2{f32(part.x) + snake_perc_to_top, f32(part.y) + snake_perc_to_top}
		p4:=F2{f32(part.x) + snake_perc_to_left, f32(part.y) + snake_perc_to_left}
		x, y:= min_max_f(p1, p2, p3, p4)

		draw_rect_by_points(gg, x.mul(app.size) + V2{app.margin_left, margin_top}, y.mul(app.size) + V2{app.margin_left, margin_top}, body_col, app.round_a)
		last=part
	}

	// last part
	len := app.snake.body.len - 1
	e:= app.snake.end_orientation
	end_position := F2{f32(app.snake.body[len].x) - f32(e.x) * (1 - animation_progress), f32(app.snake.body[len].y) - f32(e.y) * (1 - animation_progress)}
	last = app.snake.body[len]
		mut p1:=F2{f32(last.x) + snake_perc_to_top, f32(last.y) + snake_perc_to_top}
		mut p2:=F2{f32(last.x) + snake_perc_to_left, f32(last.y) + snake_perc_to_left}
		mut p3:=F2{end_position.x + snake_perc_to_top, end_position.y + snake_perc_to_top}
		mut p4:=F2{end_position.x + snake_perc_to_left, end_position.y + snake_perc_to_left}
		mut x, mut y:= min_max_f(p1, p2, p3, p4)
		draw_rect_by_points(gg, x.mul(app.size) + V2{app.margin_left, margin_top}, y.mul(app.size) + V2{app.margin_left, margin_top}, body_col, app.round_a)


	// between head and 2nd part
		
		snd := app.snake.body[1]
		p1=F2{f32(snd.x) + snake_perc_to_top, f32(snd.y) + snake_perc_to_top}
		p2=F2{f32(snd.x) + snake_perc_to_left, f32(snd.y) + snake_perc_to_left}
		p3=F2{head_position.x + snake_perc_to_top, head_position.y + snake_perc_to_top}
		p4=F2{head_position.x + snake_perc_to_left, head_position.y + snake_perc_to_left}
		x, y= min_max_f(p1, p2, p3, p4)
		draw_rect_by_points(gg, x.mul(app.size) + V2{app.margin_left, margin_top}, y.mul(app.size) + V2{app.margin_left, margin_top}, body_col, app.round_a)	
		
	//food
	gg.draw_circle(int(app.snake.field.food.x * app.size + app.size / 2 + app.margin_left), int(app.snake.field.food.y * app.size + margin_top + app.size / 2), app.size / 2, food_col)

	//head
	gg.draw_rect( head_position.x * f32(app.size) + f32(app.margin_left), head_position.y * f32(app.size) + f32(margin_top), app.size, app.size, head_col)

}

fn on_dead(mut app App) {
	app.gameover = true
}

fn on_grow(mut app App) {
	app.score ++
}

fn key_press(e gg.KeyCode, m gg.Modifier, mut app App) {
	
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
		app.animation_progress = 0
		go app.game()
	}
}

fn (mut app App) game() {
	for !app.gameover {
		app.snake.move()
		if !app.gameover {
			app.animation_progress = 0
			for app.animation_progress < fps / mps {
				app.animation_progress ++
				time.sleep_ms(1000 / fps)
		}
		
	}
	}
}
/*
[unsafe]
fn animation(gameover bool) int {
	//static progress:= 0
	if gameover {
		return 1
	}
	else {
		return prog0ress
	}
}
*/
fn handle_size(mut app App) {
	//size:=gg.screen_size()
	mut width, mut height := sapp.width(), sapp.height()
	if sapp.dpi_scale() != 0.0 && sapp.dpi_scale() != 1.0 {
		width = int(f32(width) / sapp.dpi_scale())
		height = int(f32(height) / sapp.dpi_scale())
	}
	mw:= width / grid_width
	mh:= (height - margin_top) / grid_height
	app.size = if mw > mh {mh} else {mw}
	app.margin_left = (width - app.size * grid_width) / 2
	app.round_a = rounded * int(app.size > 2 * rounded)
}

fn draw_rect_by_points (gg &gg.Context, left_top V2, right_bottom V2, color gx.Color, round int) {
	gg.draw_rounded_rect(left_top.x, left_top.y, (right_bottom.x - left_top.x) / 2, (right_bottom.y - left_top.y) / 2, round, color)
}

