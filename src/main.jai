/*
    TODO
    - [x] Moving Character
    - [x] Moving Camera
    - [x] Draw Tiles
    - [ ] Draw Crosshair
    - [ ] Shoot Arrow
    - [ ] Move Enemies
    - [ ] Collision Detection
        - [ ] Arrow Entity
        - [ ] Entity Entity
        - [ ] Arrow / Entity Wall
    - [ ] Sprite Sheet Animations
    - [ ] limit camera to arena bounds
    - [ ] Health Display
*/

#import "Basic";
#import "Math";
#import "Window_Creation";
#import "System";
#import "String";
#import "GL";
#import "Simp";
#import "Input";
#import "Random";

f32 :: float32;
f64 :: float64;

W :: 87;
A :: 65;
S :: 83;
D :: 68;

WINDOW_SCALE :: 1;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

TEXTURE_SCALE :: 2;

TILE_SIZE :: 32;

ARENA_WIDTH :: 40;
ARENA_HEIGHT :: 20;

PLAYER_SPEED :: 240.0;

move_left: u32;
move_right: u32;
move_up: u32;
move_down: u32;

arrow_texture: Texture;
player_body_texture: Texture;
player_legs_texture: Texture;
enemy_texture: Texture;
tile_texture: Texture;

Sprite :: struct {
    texture: *Texture;
    scale := Vector2.{1, 1};
    centered := true;
    rotation := 0.0;
    
    h_frames := 0;
    v_frames := 0;
    frame := 0;
}

player: Player;
arrow: *Arrow;
enemies: [..]*Enemy;
tiles: [..]Tile;

camera_position: Vector2;
camera_offset: Vector2;

Entity :: struct {
    using position: Vector2;
}

Player :: struct {
    #as using entity: Entity;
    body_sprite: Sprite;
    legs_sprite: Sprite;
}

Enemy :: struct {
    #as using entity: Entity;
    using sprite: Sprite;
}

Tile :: struct {
    #as using entity: Entity;
    using sprite: Sprite;
}

Arrow :: struct {
    #as using entity: Entity;
    using sprite: Sprite;
}

main :: () {
    width := cast(int) (WINDOW_WIDTH * WINDOW_SCALE);
    height := cast(int) (WINDOW_HEIGHT * WINDOW_SCALE);

    camera_offset.x = cast(f32) width / 2;
    camera_offset.y = cast(f32) height / 2;
    
    window := create_window(window_name = "One Arrow Colosseum", width = width, height = height);
    set_render_target(window);

    window_width, window_height := get_render_dimensions(window);

    init_textures();

    spawn_player(200, 200);

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

        for events_this_frame {
            if it.type == {
                case .QUIT; quit = true;
                case .KEYBOARD;
                    if it.key_pressed && it.key_code == .ESCAPE {
                        quit = true;
                    }

                    if it.key_code == W move_up = it.key_pressed;
                    if it.key_code == S move_down = it.key_pressed;
                    if it.key_code == A move_left = it.key_pressed;
                    if it.key_code == D move_right = it.key_pressed;
            }
        }
        
        new_time := get_time();

        delta := cast(f32) (new_time - time);
        time = new_time;

        move_player(delta);
        move_camera(delta);
                
        clear_render_target(0.15, 0.08, 0.08, 1.0);

        for tiles render_sprite(it.position, it.sprite);
        for enemies render_sprite(it.position, it.sprite);
        render_sprite(player.position, player.legs_sprite);
        render_sprite(player.position, player.body_sprite);
        if arrow render_sprite(arrow.position, arrow.sprite);
        
        swap_buffers(window);
        
        print("FPS: %, s: %\n", 1.0 / delta , delta);
    }
}

init_textures :: () {
    arrow_texture = load_texture("assets/images/arrow.png");
    player_body_texture = load_texture("assets/images/mc-body.png");
    player_legs_texture = load_texture("assets/images/mc-legs.png");
    enemy_texture = load_texture("assets/images/enemy_1.png");
    tile_texture = load_texture("assets/images/tiles.png");
}

spawn_tile :: (id: int, x: int, y: int) {
    tile := Tile.{
        x = cast(float)x * TEXTURE_SCALE,
        y = cast(float)y * TEXTURE_SCALE,
        sprite = .{
            texture = *tile_texture,
            v_frames = 2,
            h_frames = 3,
            frame = id,
            scale = .{TEXTURE_SCALE, TEXTURE_SCALE},
        }
    };
    array_add(*tiles, tile);
}

spawn_arrow :: (x: float, y: float) {
    arrow = New(Arrow);
    <<arrow = .{
        x = x,
        y = y,
        sprite = .{
            texture = *arrow_texture,
            scale = .{TEXTURE_SCALE, TEXTURE_SCALE},
        },
    };
}

spawn_enemy :: (x: float, y: float) {
    enemy := New(Enemy);
    <<enemy = .{
        x = x,
        y = y,
        sprite = .{
            texture = *enemy_texture,
            v_frames = 4,
            h_frames = 6,
            frame = 0,
            scale = .{TEXTURE_SCALE, TEXTURE_SCALE},
        },
    };
    array_add(*enemies, enemy);
}

spawn_player :: (x: float, y: float) {
    player = Player.{
        x = x,
        y = y,
        body_sprite = .{
            texture = *player_body_texture,
            scale = .{TEXTURE_SCALE, TEXTURE_SCALE},
        },
        legs_sprite = .{
            texture = *player_legs_texture,
            h_frames = 6,
            v_frames = 2,
            scale = .{TEXTURE_SCALE, TEXTURE_SCALE},
        },
    };
}


move_player :: (delta: f32) {
    direction := Vector2.{0, 0};
    
    if move_right direction.x += 1;
    if move_left direction.x -= 1;
    if move_up direction.y += 1;
    if move_down direction.y -= 1;

    if (length(direction) > 1) direction = unit_vector(direction);

    velocity := direction * PLAYER_SPEED * delta;
    player.position += velocity;
}

move_camera :: (delta: f32) {
    camera_position = player.position;
}

render_sprite :: (position: Vector2, using sprite: Sprite) {
    size := Vector2.{cast(f32)texture.width, cast(f32)texture.height};

    if (h_frames > 0 || v_frames > 0) {
        width := texture.width / h_frames;
        height := texture.height / v_frames;
        size = Vector2.{cast(float)width, cast(float)height};
    };

    size *= scale;

    center_offset := ifx centered then size / 2 else Vector2.{0, 0};
    
    set_shader_for_images(texture);
    immediate_begin();
    
    pos := position - center_offset - camera_position + camera_offset;
    
    uv0 := Vector2.{0,0};
    uv1 := Vector2.{1,0};
    uv2 := Vector2.{1,1};
    uv3 := Vector2.{0,1};
    
    if (h_frames > 0 || v_frames > 0)
    {
        width := texture.width / h_frames;
        height := texture.height / v_frames;

        frame_x := frame % h_frames;
        frame_y := frame / h_frames;
        
        pos_x := frame_x * width;
        pos_y := frame_y * height;
        end_x := pos_x + width;
        end_y := pos_y + height;

        x0 := cast(float)pos_x / texture.width;
        y0 := cast(float)pos_y / texture.height;
        x1 := cast(float)end_x / texture.width;
        y1 := cast(float)end_y / texture.height;

        uv0 = Vector2.{x0, y0};
        uv1 = Vector2.{x1, y0};
        uv2 = Vector2.{x1, y1};
        uv3 = Vector2.{x0, y1};
        
    }

    v0 := Vector2.{pos.x, pos.y};
    v1 := Vector2.{pos.x + size.x, pos.y};
    v2 := Vector2.{pos.x + size.x, pos.y + size.y};
    v3 := Vector2.{pos.x, pos.y + size.y};


    v0 = rotate(v0 - position, rotation) + position;
    v1 = rotate(v1 - position, rotation) + position;
    v2 = rotate(v2 - position, rotation) + position;
    v3 = rotate(v3 - position, rotation) + position;

    immediate_quad(v0, v1, v2, v3, uv0 = uv0, uv1 = uv1, uv2 = uv2, uv3 = uv3);

    immediate_flush();
}

load_texture :: (filename: string) -> Texture {
    result: Texture;
    success := texture_load_from_file(*result, filename);
    assert(success);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    return result;
}