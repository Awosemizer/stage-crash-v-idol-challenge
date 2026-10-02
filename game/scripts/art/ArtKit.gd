class_name ArtKit
extends Object
## Pixel-art placeholders (procedural PNGs). Keeps collision shapes untouched.
## Original SynthoCorp / Miku×Teto look — not Capcom assets.

const TILE_SIZE := 16

const BOSS_TEX := {
	"beatfire": "res://assets/sprites/bosses/beatfire.png",
	"echo_wind": "res://assets/sprites/bosses/echo_wind.png",
	"neon_volt": "res://assets/sprites/bosses/neon_volt.png",
	"glitch_ice": "res://assets/sprites/bosses/glitch_ice.png",
	"chorus_bloom": "res://assets/sprites/bosses/chorus_bloom.png",
	"bassquake": "res://assets/sprites/bosses/bassquake.png",
	"metronome": "res://assets/sprites/bosses/metronome.png",
	"static_shadow": "res://assets/sprites/bosses/static_shadow.png",
	"core9": "res://assets/sprites/bosses/core9.png",
	"overdub": "res://assets/sprites/bosses/overdub.png",
	"refrain": "res://assets/sprites/bosses/refrain.png",
}

const COLOR_TO_THEME := {
	# Approximate matches used by level Color args → tile theme
}


static func load_tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func nearest_tex(path: String) -> Texture2D:
	var tex := load_tex(path)
	if tex and tex is ImageTexture:
		pass
	# Ensure import flags: caller uses texture_filter on parent
	return tex


static func theme_from_color(color: Color) -> String:
	## Map legacy flat platform colors to tile themes.
	var r := color.r
	var g := color.g
	var b := color.b
	if r > 0.55 and g < 0.4 and b < 0.35:
		return "beatfire"
	if g > 0.45 and b > 0.4 and r < 0.45:
		return "echo_wind"
	if r > 0.55 and g > 0.55 and b < 0.4:
		return "neon_volt"
	if b > 0.55 and g > 0.4 and r < 0.5:
		return "glitch_ice"
	if r > 0.5 and b > 0.4 and g < 0.5:
		return "chorus_bloom"
	if r > 0.4 and g > 0.3 and b < 0.3:
		return "bassquake"
	if r > 0.35 and g > 0.35 and b > 0.4 and absf(r - g) < 0.15:
		return "metronome"
	if b > 0.35 and r < 0.4 and g < 0.35:
		return "static_shadow"
	if r > 0.3 and b > 0.4 and g < 0.35:
		return "fortress"
	return "default"


static func make_tile_sprite(theme: String, variant: int = 0) -> Sprite2D:
	var path := "res://assets/sprites/tiles/%s.png" % theme
	if not ResourceLoader.exists(path):
		path = "res://assets/sprites/tiles/default.png"
	var sheet := load_tex(path)
	var spr := Sprite2D.new()
	spr.texture = sheet
	spr.region_enabled = true
	var v := clampi(variant, 0, 2)
	spr.region_rect = Rect2(v * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
	spr.centered = true
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return spr


static func add_tiled_platform_visuals(body: Node2D, w: float, h: float, color: Color, theme_override: String = "") -> void:
	## Replace flat ColorRect kids with 16×16 tiled sprites. Collision unchanged.
	var theme := theme_override if theme_override != "" else theme_from_color(color)
	# Remove existing ColorRect visuals only
	var to_free: Array = []
	for c in body.get_children():
		if c is ColorRect:
			to_free.append(c)
	for c2 in to_free:
		c2.queue_free()

	var cols := maxi(1, int(round(w / float(TILE_SIZE))))
	var rows := maxi(1, int(round(h / float(TILE_SIZE))))
	# Use actual w/h so non-multiple sizes still cover (stretch last row/col via scale)
	var origin := Vector2(-w * 0.5, -h * 0.5)
	var holder := Node2D.new()
	holder.name = "TileVisuals"
	holder.z_index = 0
	body.add_child(holder)
	# Keep under collision? add first so collision stays; move to back
	body.move_child(holder, 0)

	for row in range(rows):
		for col in range(cols):
			var spr := make_tile_sprite(theme, (col + row * 3) % 3)
			var tw := w / float(cols)
			var th := h / float(rows)
			spr.position = origin + Vector2(col * tw + tw * 0.5, row * th + th * 0.5)
			spr.scale = Vector2(tw / float(TILE_SIZE), th / float(TILE_SIZE))
			holder.add_child(spr)

	# Top edge highlight strip (thin ColorRect ok for polish)
	var edge := ColorRect.new()
	edge.name = "TopEdge"
	edge.size = Vector2(w, 2)
	edge.position = Vector2(-w * 0.5, -h * 0.5)
	edge.color = color.lightened(0.35)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(edge)


static func skin_boss_visual(visual: CanvasItem, boss_id: String, hide_legacy_parts: bool = true) -> Sprite2D:
	## Hide flat ColorRect Visual and attach pixel boss sprite aligned to feet.
	var path: String = str(BOSS_TEX.get(boss_id, ""))
	var tex := load_tex(path)
	if tex == null:
		return null
	var parent := visual.get_parent()
	if parent == null:
		return null
	var existing := parent.get_node_or_null("SpriteArt") as Sprite2D
	if existing:
		existing.texture = tex
		return existing
	var spr := Sprite2D.new()
	spr.name = "SpriteArt"
	spr.texture = tex
	spr.centered = true
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Boss ColorRects are typically offset_top=-36 bottom=0 → feet at y=0, center ~-18
	spr.position = Vector2(0, -18)
	parent.add_child(spr)
	parent.move_child(spr, 0)
	if visual is CanvasItem:
		visual.visible = false
	if hide_legacy_parts:
		for n in ["Drum", "Trim", "Scarf", "Core", "StaticFx"]:
			var part := parent.get_node_or_null(n)
			if part and part is CanvasItem:
				(part as CanvasItem).visible = false
	return spr


static func sync_boss_flash(sprite: Sprite2D, flash_white: bool, base_mod: Color = Color.WHITE) -> void:
	if sprite == null:
		return
	sprite.modulate = Color(1, 1, 1, 1) if flash_white else base_mod


static func boss_portrait_tex(boss_id: String) -> Texture2D:
	var path := "res://assets/sprites/ui/portrait_%s.png" % boss_id
	if boss_id == "overdub_titan":
		path = "res://assets/sprites/ui/portrait_overdub.png"
	if boss_id == "refrain_unit":
		path = "res://assets/sprites/ui/portrait_refrain.png"
	return load_tex(path)


static func char_portrait_tex(is_teto: bool) -> Texture2D:
	return load_tex("res://assets/sprites/ui/portrait_teto.png" if is_teto else "res://assets/sprites/ui/portrait_miku.png")


static func title_banner_tex() -> Texture2D:
	return load_tex("res://assets/sprites/ui/title_banner.png")


static func make_texture_rect(tex: Texture2D, size: Vector2, pos: Vector2 = Vector2.ZERO) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.position = pos
	tr.size = size
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr
