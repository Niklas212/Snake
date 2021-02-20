module main

import rand

struct V2 {
	x	int
	y	int
}

enum Direction {
	left
	right
	top
	down
}

type Placeholder = fn ()

type Position = V2 | Direction

pub struct Map {
	width	int = 10
	height	int = 5
	mut:
	food 	V2 = V2{0, 0}
}

pub fn (mut m Map) set_food_random (sn Snake) {
		m.food = V2{x: rand.intn(m.width - 1),  y: rand.intn(m.height - 1)}
		if m.food in sn.body {m.set_food_random(sn)}
}

pub struct Snake {
	pub mut:
	orientation	V2	= V2{1, 0}
	body []V2 = [{x:2, y:0}, {x:1, y:0}, V2{x:0, y:0}]
	growing		bool
	on_dead		Placeholder = fn(){println("Hallo")}
	on_grow		Placeholder = fn(){println("Food")}
	field		Map
}

pub fn (mut sn Snake) grow () {
	sn.growing = true
}

pub fn (mut sn Snake) move () {
	if sn.growing {
		sn.body << sn.body[sn.body.len - 1]
	}

	for i := sn.body.len - 1; i > 1 - 1; i-- {
		sn.body[i] = sn.body[i - 1]
	}
	
	sn.body[0] = sn.body[0] + sn.orientation

	if sn.body[0] < {x:0, y:0} || sn.body[0] > {x:sn.field.width, y:sn.field.height} {
		sn.on_dead()
	}

	if sn.body[0] in sn.body[1..] {
		sn.on_dead()
	}
	if sn.body[0] == sn.field.food {
			sn.growing = true
			sn.on_grow()
			sn.field.set_food_random(sn)
		} else {
			sn.growing = false
			}

}

fn (a V2) + (b V2) V2 {
	return V2{a.x + b.x, a.y + b.y}
}

fn (a V2) == (b V2) bool {
	return a.x == b.x && a.y == b.y
}

fn (a V2) < (b V2) bool {
	return a.x < b.x || a.y < b.y
}
/*
fn (a V2) > (b V2) bool {
	return a.x > b.x || a.y > b.y
}
*/
pub fn (mut sn Snake) set_orientation(p Position) {
	if p is V2 {
		sn.orientation = p
	}
	else {
		sn.orientation = match p as Direction {
			.left {V2{-1, 0}}
			.right {V2{1, 0}}
			.top {V2{0, -1}}
			.down {V2{0, 1}}
		}
	}
}

pub fn (sn Snake) get_map () [][]int {
	// nothing	0
	// head		1
	// body		2
	// food 	3
	mut ret:= [][]int{len: sn.field.height, init: []int {len: sn.field.width}}

	
	ret[sn.field.food.y][sn.field.food.x] = 3

	for b in sn.body {
		ret[b.y][b.x] = 2
	}

	ret[sn.body[0].y][sn.body[0].x] = 1

	return ret
}

