module main

import rand

pub struct V2 {
	x	int
	y	int
}

pub enum Direction {
	left
	right
	top
	down
}

type Placeholder = fn (voidptr)

pub type Position = V2 | Direction

pub struct Map {
	width	int = 10
	height	int = 5
	mut:
	food 	V2 = V2{0, 0}
}

pub fn (mut m Map) set_food_random (sn Snake) {
		/*m.food = V2{x: rand.intn(m.width - 1),  y: rand.intn(m.height - 1)}
		if m.food in sn.body {m.set_food_random(sn)}*/
		position:=rand.intn(m.width * m.height - sn.body.len)
		mut counter:=0
		outer: for x in 0..m.width {
			 for y in 0..m.height {
				p:=V2{x, y}
				if !( p in sn.body)  {
					if counter == position {
						m.food = V2{x, y}
						break outer
						break
					}
					else {
						counter++
					}
					}
			}
		}
}

pub struct Snake {
	pub mut:
	orientation	V2	= V2{1, 0}
	last_orientation V2 = V2{1, 0}
	end_orientation V2 = V2{1, 0}
	body []V2 = [{x:2, y:0}, {x:1, y:0}, V2{x:0, y:0}]
	growing		bool
	//last_grow	bool
	data		voidptr
	on_dead		Placeholder
	on_grow		Placeholder
	field		Map
}

pub fn (mut sn Snake) grow () {
	sn.growing = true
}

pub fn (mut sn Snake) move () {
	sn.last_orientation = sn.orientation
	head:= sn.body[0] + sn.orientation
	
	if head < {x:0, y:0} || head > {x:sn.field.width - 1, y:sn.field.height - 1} {
		sn.on_dead(sn.data)
	} else if head in sn.body[1..] {
		sn.on_dead(sn.data)
	} else {
	
		if sn.growing {
			sn.body << sn.body[sn.body.len - 1]
		} else {
				sn.end_orientation = sn.body[sn.body.len - 2] - sn.body[sn.body.len - 1]
		}
	
		for i := sn.body.len - 1; i > 0; i-- {
			sn.body[i] = sn.body[i - 1]
		}
		
		sn.body[0] = head

		if sn.body[0] == sn.field.food {
				sn.growing = true
				sn.on_grow(sn.data)
				sn.field.set_food_random(sn)
				sn.end_orientation = V2{0, 0}
			} else {
				sn.growing = false
				}
	}
}

fn (a V2) + (b V2) V2 {
	return V2{a.x + b.x, a.y + b.y}
}

fn (a V2) - (b V2) V2 {
	return V2{a.x - b.x, a.y - b.y}
}

fn (a V2) == (b V2) bool {
	return a.x == b.x && a.y == b.y
}

fn (a V2) < (b V2) bool {
	return a.x < b.x || a.y < b.y
}

fn (a V2) mul (b int) V2 {
	return V2{x:a.x * b, y:a.y * b}
}

fn min_max(a V2, b V2) (V2, V2) {
	return V2{x:(int(a.x <= b.x) * a.x) + (int(b.x < a.x) * b.x) , y:(int(a.y <= b.y) * a.y) + (int(b.y < a.y) * b.y) }, V2{x:(int(a.x >= b.x) * a.x) + (int(b.x > a.x) * b.x) , y:(int(a.y >= b.y) * a.y) + (int(b.y > a.y) * b.y) }
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
