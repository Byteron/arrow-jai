/*
    One Arrow Colosseum
    Reimplementation of the GMTK 2019 Game Jam Entry of the same name.
*/

#import "Basic";
#import "Math";
#import "Window_Creation";
#import "System";
#import "File";
#import "String";
#import "GL";
#import "Simp";
#import "Input";
#import "Random";
#import "Wav_File";
#import "Sound_Player";
#import "Thread";

#load "sfx.jai";
#load "gfx.jai";

WAV :: "wav";
OGG :: "ogg";

W :: 87;
A :: 65;
S :: 83;
D :: 68;

DRAW_COLLISIONS :: false;

WINDOW_SCALE :: 0.5;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

TILE_SIZE :: 32;

ARENA_WIDTH :: 40;
ARENA_HEIGHT :: 30;

PLAYER_SPEED :: 240.0;
CHARGE_LIMIT :: 3;

sound_bow_charge: [..]*Mixer_Sound_Data;

sound_player: *Sound_Player;

delta: float;

mouse_position: Vector2;

move_left: u32;
move_right: u32;
move_up: u32;
move_down: u32;

shoot: bool;
aiming: int;
charge_time := 1.0;
charge := 1;
prev_charge := 0;

arrow_texture: Texture;
player_body_texture: Texture;
player_legs_texture: Texture;
enemy_texture: Texture;
tile_texture: Texture;
heart_texture: Texture;
crosshair_texture: Texture;

Rect2 :: struct {
    position: Vector2;
    size: Vector2;
}

Entity :: struct {
    using position: Vector2;
    using sprite: Sprite;
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

Player :: struct {
    #as using entity: Entity;
    legs_sprite: Sprite;
    health: int;
    health_bar: Sprite;
    collider: Collider;
}

Enemy :: struct {
    #as using entity: Entity;
    speed: float;
    health: int;
    hit: bool;
    health_bar: Sprite;
    collider: Collider;
}

Tile :: struct {
    #as using entity: Entity;
}

Arrow :: struct {
    #as using entity: Entity;
    direction: Vector2;
    speed: float;
    distance: float;
    max_distance: float;
    dropped: bool;
    charge: int;
    hits: int;
    collider: Collider;
}

player: Player;
arrow: *Arrow;
enemies: [..]*Enemy;
tiles: [..]Tile;
crosshair: Entity;

camera_position: Vector2;
camera_offset: Vector2;

main :: () {
    width := cast(int) (WINDOW_WIDTH * WINDOW_SCALE);
    height := cast(int) (WINDOW_HEIGHT * WINDOW_SCALE);

    camera_offset.x = cast(float) width / 2;
    camera_offset.y = cast(float) height / 2;
    
    window := create_window(window_name = "One Arrow Colosseum", width = width, height = height);
    set_render_target(window);

    window_width, window_height := get_render_dimensions(window);

    sound_player = New(Sound_Player);
    sound_player.update_history = true;
    
    init_textures();
    init_sounds();

    success := init(sound_player, xx window, true, true);
    // assert(success); // @Incomplete We need an audio pass. Low priority (for now).
    
    spawn_player(300, 400);

    for y: 0..ARENA_HEIGHT-1 {
        for x: 0..ARENA_WIDTH-1 {
            spawn_tile(cast(int)random_get_within_range(0, 5), x * TILE_SIZE, y * TILE_SIZE);
        }
    }

    for 0..10 spawn_enemy(random_get_within_range(0, 500), random_get_within_range(0, 500));

    quit := false;
    time := get_time();

    while (!quit) {
        update_window_events();
        
        mouse_x, mouse_y := get_mouse_pointer_position();
        mouse_position = Vector2.{cast(float)mouse_x, -cast(float)mouse_y + window_height} - camera_offset;

        new_time := get_time();

        delta = cast(float) (new_time - time);
        time = new_time;
    
        for events_this_frame {
            if it.type == {
                case .QUIT; quit = true;
                case .KEYBOARD;
                    if it.key_pressed && it.key_code == .ESCAPE quit = true;

                    if it.key_code == W move_up = it.key_pressed;
                    if it.key_code == S move_down = it.key_pressed;
                    if it.key_code == A move_left = it.key_pressed;
                    if it.key_code == D move_right = it.key_pressed;

                    if it.key_code == .MOUSE_BUTTON_LEFT aiming = it.key_pressed;
                    if !arrow && it.key_code == .MOUSE_BUTTON_LEFT && !it.key_pressed shoot = true;                    
            }
        }

        // Simulation
        
        if !arrow {
            if aiming && charge < CHARGE_LIMIT {
                charge_time += delta;
                charge = cast(int) charge_time;
                if charge > prev_charge {
                    prev_charge = charge;
                    log("Charge: %", charge);
                    play_sound(sound_bow_charge[charge - 1]);
                }
            }
            
            if shoot {
                for enemies it.hit = false;
                direction := get_direction(player.position, crosshair.position);
                spawn_arrow(player.position, direction, charge);
                shoot = false;
                charge_time = 1;
                charge = 1;
                prev_charge = 0;
            }
            
        } else {
            move_arrow();
        }

        move_player();
        move_crosshair();
        move_camera();
        move_enemies();
        
        update_sound_player(delta);

        // Render 
        clear_render_target(0.15, 0.08, 0.08, 1.0);

        // Sprites
        for tiles render_sprite(it.position, it.sprite);
        
        for enemies render_sprite(it.position, it.sprite);
        
        render_sprite(player.position, player.legs_sprite);
        render_sprite(player.position, player.sprite);
        
        if arrow render_sprite(arrow.position, arrow.sprite);
        
        // UI
        for enemies render_sprite(it.position, it.health_bar);
        render_sprite(crosshair.position, crosshair.sprite);

        // Debug
        #if DRAW_COLLISIONS {
            for enemies render_collider(it.position, it.collider);
            render_collider(player.position, player.collider);
            if arrow render_collider(arrow.position, arrow.collider);
        }
        
        swap_buffers(window);
        
        // print("FPS: %, s: %\n", 1.0 / delta , delta);
    }
}

init_textures :: () {
    arrow_texture = load_texture("assets/images/arrow.png");
    player_body_texture = load_texture("assets/images/mc-body.png");
    player_legs_texture = load_texture("assets/images/mc-legs.png");
    enemy_texture = load_texture("assets/images/enemy_1.png");
    tile_texture = load_texture("assets/images/tiles.png");
    heart_texture = load_texture("assets/images/heart.png");
    crosshair_texture = load_texture("assets/images/crosshair.png");
}

init_sounds :: () {
    sound_bow_charge_1 := load_sound("assets/sfx/bow_charge_1.wav");
    sound_bow_charge_2 := load_sound("assets/sfx/bow_charge_2.wav");
    sound_bow_charge_3 := load_sound("assets/sfx/bow_charge_3.wav");
    array_add(*sound_bow_charge, sound_bow_charge_1);
    array_add(*sound_bow_charge, sound_bow_charge_2);
    array_add(*sound_bow_charge, sound_bow_charge_3);
}

spawn_tile :: (id: int, x: int, y: int) {
    tile := Tile.{
        x = cast(float)x,
        y = cast(float)y,
        sprite = .{
            texture = *tile_texture,
            v_frames = 2,
            h_frames = 3,
            frame = id,
        }
    };
    array_add(*tiles, tile);
}

spawn_arrow :: (position: Vector2, direction: Vector2, charge: int) {
    arrow = New(Arrow);
    speed := 800.0 + 500.0 * charge;
    dist := cast(float) 200 + charge * 200;
    <<arrow = .{
        position = position,
        direction = direction,
        charge = charge,
        speed = speed,
        max_distance = dist,
        sprite = .{
            texture = *arrow_texture,
        },
    };
}

spawn_enemy :: (x: float, y: float) {
    health := floor(random_get_within_range(1, 4));
    speed := floor(random_get_within_range(50, 160));
    
    texture_width := 19.0 * health;
    
    enemy := New(Enemy);
    <<enemy = .{
        x = x,
        y = y,
        sprite = .{
            texture = *enemy_texture,
            v_frames = 4,
            h_frames = 6,
            frame = 0,
        },
        health_bar = .{
            texture = *heart_texture,
            clip_to_region = true,
            region = Rect2.{ size = Vector2.{ texture_width, 14 } },
            offset = .{0, 32},
        },
        health = cast(u8) health,
        speed = speed,
    };

    array_add(*enemies, enemy);
}

spawn_player :: (x: float, y: float) {
    player = Player.{
        x = x,
        y = y,
        sprite = .{
            texture = *player_body_texture,
        },
        legs_sprite = .{
            texture = *player_legs_texture,
            h_frames = 6,
            v_frames = 2,
        },
    };

    crosshair = Entity.{
        sprite = .{
            texture = *crosshair_texture,
        }
    };
}

damage_enemy :: (using enemy: *Enemy, damage: int) {
    hit = true;
    prev_health := health;
    health -= damage;
    Clamp(*health, 0, prev_health);
    print("Health: %\n", health);
    
    if health == 0 {
        array_unordered_remove_by_value(*enemies, enemy);
        free(enemy);
    } else {
        health_bar.region.size.x = 19.0 * health;
    }
}

move_player :: () {
    direction := Vector2.{0, 0};
    
    if move_right direction.x += 1;
    if move_left direction.x -= 1;
    if move_up direction.y += 1;
    if move_down direction.y -= 1;

    if (length(direction) > 1) direction = unit_vector(direction);

    velocity := direction * PLAYER_SPEED * delta;
    player.position += velocity;

    for enemies {
        min_distance := player.collider.radius + it.collider.radius;
        if distance(player.position, it.position) < min_distance log("OVERLAP!");
    }

    if !arrow return;
    
    dist := arrow.collider.radius + player.collider.radius;
    collide := distance(arrow.position, player.position) < dist;

    if arrow.dropped && collide {
        log("arrow collected");
        free(arrow);
        arrow = null;
    }
}

move_arrow :: () {
    if !arrow return;
    if arrow.dropped return;

    vel := arrow.direction * arrow.speed * delta;
    dist := distance(arrow.position, arrow.position + vel);
    arrow.position += vel;
    arrow.distance += dist;
    
    for enemies {
        if it.hit continue;
        min_distance := arrow.collider.radius + it.collider.radius;
        if distance(arrow.position, it.position) < min_distance {
            arrow.hits += 1;
            damage_enemy(it, arrow.charge);
        }
    }

    if arrow.distance > arrow.max_distance || arrow.hits == arrow.charge {
        arrow.speed = 0;
        arrow.dropped = true;
        arrow.hits = 0;
    }
}

move_crosshair :: () {
    world_position := mouse_position + camera_position;
    direction := get_direction(player.position, world_position);
    position := direction * 100;
    crosshair.position = player.position + direction * 100;
}

move_camera :: () {
    camera_position = lerp(camera_position, player.position, 0.01);
    Clamp(*camera_position.x, camera_offset.x + 16, TILE_SIZE * ARENA_WIDTH - camera_offset.x - 16);
    Clamp(*camera_position.y, camera_offset.y + 16, TILE_SIZE * ARENA_HEIGHT - camera_offset.y - 16);
}

move_enemies :: () {
    for enemies {
        direction := get_direction(it.position, player.position);
        
        for other: enemies {
            if (distance(it.position, other.position) < 40) {
                direction += get_direction(other.position, it.position);
                direction /= 2;
            }
        }
        
        it.position += direction * it.speed * delta;
    }
}
