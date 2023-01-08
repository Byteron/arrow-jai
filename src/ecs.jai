#import "Basic";
#import "Hash_Table";
#import "Compiler";

entities: Entities;

Entity :: struct {
	id: u32 = 0;
	gen: u32 = 0;
}

Component :: struct {};

EntityMeta :: struct {
	gen: s32 = 0;
}

Storage :: struct ($T: Type) {
    indices: []u32;
    items: [..]T;
}

Entities :: struct {
	entities: [..]EntityMeta;
	unused_ids: [..]u32;
	types: Table(int, int);
	storages: [..]*void;
}

Query :: struct {
	entities: [..]Entity;
}

init_ecs :: () {
	entities = .{};
	init(*entities.types, 32);
	array_add(*entities.storages, new_void_storage(Entity));
}

deinit_ecs :: () {
	// TODO: deinit world here;
}

register :: ($T: Type) {
	using entities;
	key := cast(int) T;
    existing, found := table_find(*types, key);
    assert(!found);
    existing = types.count;
    table_add(*types, key, existing);
	array_add(*storages, new_void_storage(T));
}

new_void_storage :: ($T: Type) -> *void {
	storage := New(Storage(T));
	storage.indices = NewArray(1, u32);
	return cast(*void)storage;
}

spawn :: () -> Entity {
	using entities;
	id: u32;
	
	if (unused_ids.count == 0) {
		id = cast(u32) entities.count;
		array_add(*entities, .{});
	} else {
		id = pop(*unused_ids);
	}

	meta := *entities[id];
	meta.gen = -meta.gen + 1;

	entity := Entity.{ id = id, gen = cast(u16) meta.gen };

	storage := cast(*Storage(Entity))storages[0];
	// array
	return entity;
}

despawn :: (entity: Entity) {
	using entities;
	meta := *entities[entity.id];
	meta.gen = -meta.gen;
	array_add(*unused_ids, entity.id);

	// TODO: remove all components
}

set :: (using s: *Storage($T), entity: Entity, component: T) {
	if indices.count <= entity.id {
		array_resize(*indices, entity.id << 1);
	}

	if indices[entity.id] == 0 {
		index := cast(u32) items.count;
		indices[entity.id] = index + 1;
		array_add(*items, component);
	}
	else {
		items[indices[entity.id]-1] = component;
	}
}

set :: (entity: Entity, component: $T) {
	using entities;
	type_id := get_type_id(T);
	storage := cast(*Storage(T)) storages[type_id];
	set(storage, entity, component);
}

get :: (using s: *Storage($T), entity: Entity) -> *T {
	return *items[indices[entity.id]-1];
}

get :: (entity: Entity, $T: Type) -> *T {
	using entities;
	type_id := get_type_id(T);
	storage := cast(*Storage(T)) storages[type_id];
	return get(storage, entity);
}

get_type_id :: (T: Type) -> int {
	using entities;
    key := cast(int) T;
    existing, found := table_find(*types, key);
    assert(found);
	return existing;
}

// get :: (using s: *Storage($T), entity: Entity) -> T {
//     return components[indices[entity.id]];
// }

// get_mut :: (using s: *Storage($T), entity: Entity) -> *T {
//     if indices[index] == 0 {
//         array_add(*indices, components.count);
// 		component: T = ---;
//         array_add(*components, component);
//     }

//     return *components[indices[entity.id]];
// }

// set :: (using s: *Storage($T), entity: Entity, component) {
//     get_mut(s, entity) = component;
// }

// get_storage :: (using e: *Entities, $T: Type) -> []T {
// 	raw_storage := get_raw_storage(e, type);
// 	storage := <<(cast(*[]T)*raw_storage);
// 	storage.count /= type.size;
// 	return storage;
// }

// get_raw_storage :: (using e: *Entities, type: StorageType) -> []u8 {
// 	index := 0;
// 	for types {
// 		if it.type == type.type return storages[index];
// 		index += 1;
// 	}
// 	return .[];
// }

// spawn_entity :: (world: *World) -> Entity {
// 	spawn :: (using e: *Entities) -> Entity {
// 		id: u32;
		
// 		if (unused_ids.count == 0) {
// 			id = cast(u32) entities.count;
// 			array_add(*entities, .{});
// 		} else {
// 			id = pop(*unused_ids);
// 		}

// 		record := *entities[id];
// 		record.gen = -record.gen + 1;

// 		entity := Entity.{ id = id, gen = cast(u16) record.gen };

// 		return entity;
// 	};
	
// 	return spawn(*world.entities);
// }

// despawn_entity :: (world: *World, entity: Entity) {
// 	despawn :: (using e: *Entities, entity: Entity) {
// 		record := *entities[entity.id];
// 		record.gen = -record.gen;
// 		array_add(*unused_ids, entity.id);
// 	} 
	
// 	despawn(*world.entities, entity);
// }

// get_component :: (world: *World, $T: Type, entity: Entity) -> *T {
// 	get_component :: (using e: *Entities, $T: Type, entity: Entity) -> *T {
// 		record := *entities[entity.id];
// 		storage := get_storage(table, T);
// 		return *storage[record.row];
// 	}

// 	return get_component(*world.entities, T, entity);
// }

// set_component :: (world: *World, $T: Type, entity: Entity, component: T) {

// }

// is_alive :: (world: *World, entity: Entity) -> bool {
// 	is_alive :: (using e: *Entities, entity: Entity) -> bool {
// 		return entities[entity.id].gen == entity.gen;
// 	}

// 	return is_alive(*world.entities, entity);
// }