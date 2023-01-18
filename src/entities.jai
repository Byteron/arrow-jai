
unused_ids: [..]u32;
entities: [..]EntityData;
gens: [..]s32;

Entity :: struct {
	id: u32;
	gen: u16;
}

operator == :: inline (a: Entity, b: Entity) -> bool {
	return a.id == b.id && a.gen == b.gen;
}

EntityData :: struct {
    // Common
    using position: Vector2;

    // Rendering
    sprite: Option(Sprite);
    sprite2: Option(Sprite);
    
    // Physics
    collider: Collider;
    
    // Health
    health: Option(Health);
    health_bar: Sprite = ---;
    hit: bool;
    
    // Movement
    speed: f32;
    direction: Vector2;

    // Arrow
    charge: s16;
}

Option :: struct ($T: Type) {
    exists: bool;
    #as using _v: T = ---;
}

Some :: (value: $T) -> Option(T) {
    return Option(T).{ exists = true, _v = value };
}

Sprite :: struct {
    texture: *Texture;
    offset := Vector2.{0, 0};
    centered := true;
    rotation := 0.0;

    clip_to_region := false;
    region: Rect2;
    
    h_frames := 0;
    v_frames := 0;
    frame := 0;
}

Collider :: struct {
    radius := 16.0;
}

Health :: struct {
    value: s16;
}

spawn :: (value: EntityData = .{}) -> Entity {
	id: u32;
	
	if (unused_ids.count == 0) {
		id = cast(u32) entities.count;
		array_add(*entities, .{});
		array_add(*gens, 0);
	} else {
		id = pop(*unused_ids);
	}

	// print("Id: %, Entities: %, Gens: %\n", id, entities.count, gens.count);
	gen := -gens[id] + 1;
	gens[id] = gen;

	entities[id] = value;
	
	return .{ id = id, gen = cast(u16) gen };
}


despawn :: (entity: Entity) {
	gens[entity.id] *= -1;
	array_add(*unused_ids, entity.id);
}

set :: (entity: Entity, value: EntityData) {
	data := *entities[entity.id];
	<<data = value;
}

get :: (entity: Entity) -> *EntityData {
	return *entities[entity.id];
}

is_alive :: (entity: Entity) -> bool {
	if entity.id > gens.count return false;
	return gens[entity.id] > 0;
}