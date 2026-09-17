extends RefCounted
class_name ScriptInterpreter

var scripts: Dictionary = {}
var tile_buffer: Array = []
var block: Dictionary = {}
var script_id: String = ""
var line_idx: int = 0
var flip_x: bool = false
var tiles: Array = []
var extended_view: bool = false
var buffer_w: int = 16
var buffer_h: int = 20

var stack: Array = []
var call_stack: Array = []
var while_depth: Array = []

func _init():
	_clear_tile_buffer()

func parse_scripts(text: String) -> void:
	scripts.clear()
	var current_script: String = ""
	var current_tiles: Array = []
	var current_lines: Array = []

	for raw_line in text.split("\n"):
		var l = raw_line.strip_edges()
		if l.begins_with("[") and l.ends_with("]"):
			if current_script != "" and current_lines.size() > 0:
				scripts[current_script] = {"tiles": current_tiles, "lines": current_lines}
			current_script = l.substr(1, l.length() - 2)
			current_tiles = []
			current_lines = []
		elif l.begins_with("TILES "):
			var parts = l.substr(6).split(",")
			current_tiles.clear()
			for p in parts:
				current_tiles.append(int(p.strip_edges()))
		elif l != "":
			var parsed = _parse_line(l)
			if parsed.size() > 0:
				current_lines.append(parsed)

	if current_script != "" and current_lines.size() > 0:
		scripts[current_script] = {"tiles": current_tiles, "lines": current_lines}

func _parse_line(text: String) -> Dictionary:
	var parts = text.split(" ", false, 1)
	var opcode = parts[0]

	match opcode:
		"JMP":
			var args = parts[1].split(",")
			return {"opcode": "JMP", "params": [args[0].strip_edges(), int(args[1].strip_edges())]}
		"LD":
			var eq_pos = parts[1].find(",")
			var reg = parts[1].substr(0, eq_pos).strip_edges()
			var expr = parts[1].substr(eq_pos + 1).strip_edges()
			return {"opcode": "LD", "params": [reg, expr]}
		"ADD":
			var eq_pos = parts[1].find(",")
			var reg = parts[1].substr(0, eq_pos).strip_edges()
			var expr = parts[1].substr(eq_pos + 1).strip_edges()
			return {"opcode": "ADD", "params": [reg, expr]}
		"WHILE":
			return {"opcode": "WHILE", "params": [parts[1].strip_edges()]}
		"ENDWHILE":
			return {"opcode": "ENDWHILE", "params": []}
		"PUSH":
			return {"opcode": "PUSH", "params": [parts[1].strip_edges()]}
		"POP":
			return {"opcode": "POP", "params": [parts[1].strip_edges()]}
		"DRAWTILE":
			return {"opcode": "DRAWTILE", "params": [parts[1].strip_edges()]}
		"INC":
			return {"opcode": "INC", "params": [parts[1].strip_edges()]}
		"DEC":
			return {"opcode": "DEC", "params": [parts[1].strip_edges()]}
		"END":
			return {"opcode": "END", "params": []}
		"CALL":
			return {"opcode": "CALL", "params": [parts[1].strip_edges()]}
		"CALLP":
			return {"opcode": "CALLP", "params": [parts[1].strip_edges()]}
		"FLIP":
			return {"opcode": "FLIP", "params": []}
	return {}

func execute_block(blk: Dictionary) -> void:
	block = {
		"type": int(blk.get("type", 0)),
		"x": int(blk.get("x", 0)),
		"y": int(blk.get("y", 0)),
		"height": int(blk.get("height", 0)),
		"param1": int(blk.get("param1", 0)),
		"param2": int(blk.get("param2", 0)),
		"depthx": 0,
		"depthy": 0
	}

	var type_val = int(blk.get("type", 0))
	script_id = "SCRIPT" + str(type_val >> 1)
	line_idx = 0
	flip_x = false
	stack.clear()
	call_stack.clear()
	while_depth.clear()

	if not scripts.has(script_id):
		return

	tiles = scripts[script_id].get("tiles", [])
	_execute_script(true)

func _execute_script(modify_tiles: bool) -> void:
	if modify_tiles and scripts.has(script_id):
		tiles = scripts[script_id].get("tiles", [])

	if block["height"] != 0xff:
		block["depthx"] = int(block["y"] + block["height"] / 2) + int(block["x"]) - 15
		block["depthy"] = int(block["y"] + block["height"] / 2) - int(block["x"]) + 16

	var end = false
	while not end:
		if not scripts.has(script_id):
			break
		var script_data = scripts[script_id]
		var lines = script_data["lines"]
		if line_idx >= lines.size():
			break

		var instr = lines[line_idx]
		line_idx += 1

		match instr["opcode"]:
			"JMP":
				script_id = instr["params"][0]
				line_idx = instr["params"][1]
			"LD":
				var res = int(_eval_expression(instr["params"][1]))
				var p = instr["params"][0]
				if flip_x:
					if p == "DEPTHX":
						p = "DEPTHY"
					elif p == "DEPTHY":
						p = "DEPTHX"
				if p == "DEPTHX" and block["depthx"] == 0:
					continue
				if p == "DEPTHY" and block["depthy"] == 0:
					continue
				if p.begins_with("DEPTH") and res > 100:
					res = 0
				block[p.to_lower()] = res
			"ADD":
				var add_res = int(_eval_expression(instr["params"][1]))
				var reg = instr["params"][0].to_lower()
				block[reg] = int(block[reg]) + add_res
			"WHILE":
				var val = int(block[instr["params"][0].to_lower()])
				_while_handler(val)
			"ENDWHILE":
				_end_while_handler()
			"PUSH":
				stack.append(int(block[instr["params"][0].to_lower()]))
			"POP":
				block[instr["params"][0].to_lower()] = stack.pop_back()
			"DRAWTILE":
				_draw_tile_handler(instr["params"][0])
			"DEC":
				var offset = -1
				if instr["params"][0] == "X" and flip_x:
					offset = 1
				var reg = instr["params"][0].to_lower()
				block[reg] = int(block[reg]) + offset
			"INC":
				var offset = 1
				if instr["params"][0] == "X" and flip_x:
					offset = -1
				var reg = instr["params"][0].to_lower()
				block[reg] = int(block[reg]) + offset
			"END":
				end = true
				if modify_tiles:
					flip_x = false
			"CALL":
				_call_handler(instr["params"][0], true)
			"CALLP":
				_call_handler(instr["params"][0], false)
			"FLIP":
				flip_x = not flip_x

func _while_handler(v: int) -> void:
	if v > 0:
		stack.append(line_idx)
		stack.append(script_id)
		stack.append(v)
		while_depth.append(stack.size())
	else:
		var depth = 1
		while depth > 0:
			if not scripts.has(script_id):
				break
			var lines = scripts[script_id]["lines"]
			if line_idx >= lines.size():
				break
			var op = lines[line_idx]["opcode"]
			if op == "WHILE":
				depth += 1
			elif op == "ENDWHILE":
				depth -= 1
			line_idx += 1

func _end_while_handler() -> void:
	if while_depth.is_empty():
		return
	var saved_depth = while_depth.pop_back()
	if stack.size() < saved_depth:
		return
	while stack.size() > saved_depth:
		stack.pop_back()
	if stack.size() >= 3:
		var v = int(stack.pop_back()) - 1
		var saved_script = str(stack.pop_back())
		var saved_line = int(stack.pop_back())
		if v > 0:
			stack.append(saved_line)
			stack.append(saved_script)
			stack.append(v)
			while_depth.append(stack.size())
			script_id = saved_script
			line_idx = saved_line

func _call_handler(s: String, modify_tiles: bool) -> void:
	call_stack.append(block.duplicate())
	call_stack.append(flip_x)
	call_stack.append(line_idx)
	call_stack.append(script_id)
	script_id = s
	line_idx = 0
	_execute_script(modify_tiles)
	script_id = str(call_stack.pop_back())
	line_idx = int(call_stack.pop_back())
	flip_x = bool(call_stack.pop_back())
	block = call_stack.pop_back()

func _draw_tile_handler(tile_ref: String) -> void:
	var tile_num: int
	if tile_ref.begins_with("T"):
		var idx = int(tile_ref.substr(1))
		if idx < tiles.size():
			tile_num = tiles[idx] + 1
		else:
			return
	else:
		tile_num = int(tile_ref) + 1

	var p_x: int
	var p_y: int
	if extended_view:
		p_x = int(block["x"])
		p_y = int(block["y"])
	else:
		p_x = int(block["x"]) - 8
		p_y = int(block["y"]) - 8
	if p_x < 0 or p_x >= buffer_w:
		return
	if p_y < 0 or p_y >= buffer_h:
		return

	var dx = int(block["depthx"])
	var dy = int(block["depthy"])

	tile_buffer[p_x][p_y].append({
		"tile": tile_num,
		"depthX": dx,
		"depthY": dy
	})

	var arr = tile_buffer[p_x][p_y]
	for i in range(arr.size() - 2, -1, -1):
		var t_old = arr[i]
		var t_new = arr[i + 1]
		if (t_old["depthX"] + t_old["depthY"]) > (t_new["depthX"] + t_new["depthY"]):
			if t_old["depthX"] > t_new["depthX"]:
				t_old["depthX"] = t_new["depthX"]
			if t_old["depthY"] > t_new["depthY"]:
				t_old["depthY"] = t_new["depthY"]

func _eval_expression(expression: String) -> float:
	var e = expression
	if flip_x:
		e = e.replace("X", "Z")
		e = e.replace("Y", "X")
		e = e.replace("Z", "Y")

	e = e.replace("DEPTHX", str(block["depthx"]))
	e = e.replace("DEPTHY", str(block["depthy"]))
	e = e.replace("PARAM1", str(block["param1"]))
	e = e.replace("PARAM2", str(block["param2"]))
	e = e.replace("HEIGHT", str(block["height"]))

	return _eval_addsub(e)

func _eval_addsub(expr: String) -> float:
	expr = expr.replace(" ", "")
	var result: float = 0.0
	var current_num: String = ""
	var op: String = "+"
	var i = 0
	while i < expr.length():
		var c = expr[i]
		if c == "(" or c == ")":
			i += 1
			continue
		if c == "+" or c == "-":
			if current_num != "":
				result = _apply_op(result, op, current_num)
				current_num = ""
			op = c
		else:
			current_num += c
		i += 1

	if current_num != "":
		result = _apply_op(result, op, current_num)

	return result

func _apply_op(a: float, op: String, b_str: String) -> float:
	var b: float
	if b_str.begins_with("-"):
		b = float(b_str)
	else:
		b = float(b_str)
	match op:
		"+":
			return a + b
		"-":
			return a - b
	return a

func _clear_tile_buffer() -> void:
	tile_buffer.clear()
	for x in range(buffer_w):
		var col = []
		for y in range(buffer_h):
			col.append([])
		tile_buffer.append(col)

func set_extended(extended: bool) -> void:
	extended_view = extended
	if extended:
		buffer_w = 32
		buffer_h = 32
	else:
		buffer_w = 16
		buffer_h = 20

func get_tile_buffer() -> Array:
	return tile_buffer

func clear_tile_buffer() -> void:
	_clear_tile_buffer()
