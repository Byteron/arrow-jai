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

f32 :: float32;
f64 :: float64;

WAV :: "wav";
OGG :: "ogg";

W :: 87;
A :: 65;
S :: 83;
D :: 68;

sound_bow_charge: [..]*Mixer_Sound_Data;

sound_player: *Sound_Player;

WINDOW_SCALE :: 0.5;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

TILE_SIZE :: 32;

ARENA_WIDTH :: 40;
ARENA_HEIGHT :: 30;

PLAYER_SPEED :: 240.0;

delta: f32;

mouse_position: Vector2;

move_left: u32;
move_right: u32;
move_up: u32;
move_down: u32;

shoot: bool;
aiming: u32;
charge_time: f32;
charge: s8;
prev_charge: s8 = -1;

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
    health: u8;
    health_bar: Sprite;
    collider: Collider;
}

Enemy :: struct {
    #as using entity: Entity;
    health: u8;
    speed: f32;
    health_bar: Sprite;
    collider: Collider;
}

Tile :: struct {
    #as using entity: Entity;
}

Arrow :: struct {
    #as using entity: Entity;
    direction: Vector2;
    speed: f32;
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

    camera_offset.x = cast(f32) width / 2;
    camera_offset.y = cast(f32) height / 2;
    
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
        mouse_position = Vector2.{cast(f32)mouse_x, -cast(f32)mouse_y + window_height} - camera_offset;

        new_time := get_time();

        delta = cast(f32) (new_time - time);
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
                    if it.key_code == .MOUSE_BUTTON_LEFT && !it.key_pressed shoot = true;                    
            }
        }

        // Simulation
        
        if aiming && charge < 2 {
            charge_time += delta;
            charge = cast(s8) charge_time;
            if charge > prev_charge {
                prev_charge = charge;
                log("Charge: %", charge);
                play_sound(sound_bow_charge[charge]);
            }
        }
        
        if shoot {
            direction := get_direction(player.position, crosshair.position);
            spawn_arrow(player.position, direction, 600.0 + 300 * charge);
            shoot = false;
            charge_time = 0;
            charge = 0;
            prev_charge = -1;
        }

        move_player();
        move_arrow();
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
        for enemies render_collider(it.position, it.collider);
        render_collider(player.position, player.collider);
        if arrow render_collider(arrow.position, arrow.collider);
        
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

spawn_arrow :: (position: Vector2, direction: Vector2, speed: f32) {
    if !arrow arrow = New(Arrow);
    <<arrow = .{
        position = position,
        direction = direction,
        speed = speed,
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

update_sound_player :: (delta: float) {
    //
    // Move sound streams forward by dt.
    //
    lock(*sound_player.sound_mutex);
    defer unlock(*sound_player.sound_mutex);

    pre_entity_update(sound_player);

    //
    // @Incomplete We're not removing sound streams once they're consumed.
    //
    for sound_player.streams {
        it.marked = true;
    }

    post_entity_update(sound_player, delta);
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
}

move_arrow :: () {
    if !arrow return;
    arrow.position += arrow.direction * arrow.speed * delta;
    for enemies {
        min_distance := arrow.collider.radius + it.collider.radius;
        if distance(arrow.position, it.position) < min_distance log("ARROW HIT!");
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

render_collider :: (position: Vector2, using collider: Collider) {
    set_shader_for_color();
    immediate_begin();

    pos := position - camera_position + camera_offset;
    
    x0 := pos.x - radius;
    y0 := pos.y - radius;
    x1 := pos.x + radius;
    y1 := pos.y + radius; 
    
    v0 := Vector2.{x0, y0};
    v1 := Vector2.{x1, y0};
    v2 := Vector2.{x1, y1};
    v3 := Vector2.{x0, y1};

    immediate_quad(v0, v1, v2, v3, rgba(1.0, 1.0, 1.0, 0.1));
    immediate_flush();
}

render_sprite :: (position: Vector2, using sprite: Sprite) {
    size := Vector2.{cast(f32)texture.width, cast(f32)texture.height};

    if clip_to_region size = region.size;
    
    if h_frames > 0 || v_frames > 0 {
        width := size.x / h_frames;
        height := size.y / v_frames;
        size = Vector2.{cast(float)width, cast(float)height};
    };

    center_offset := ifx centered then size / 2 else Vector2.{0, 0};
    
    set_shader_for_images(texture);
    immediate_begin();
    
    pos := position - center_offset - camera_position + camera_offset + offset;
    
    uv0 := Vector2.{0,0};
    uv1 := Vector2.{1,0};
    uv2 := Vector2.{1,1};
    uv3 := Vector2.{0,1};

    if clip_to_region {
        x0 := region.position.x / texture.width;
        y0 := region.position.y / texture.height;
        x1 := (region.position.x + region.size.x) / texture.width;
        y1 := (region.position.y + region.size.y) / texture.height;

        uv0 = Vector2.{x0, y0};
        uv1 = Vector2.{x1, y0};
        uv2 = Vector2.{x1, y1};
        uv3 = Vector2.{x0, y1};
    } 
    
    if h_frames > 0 || v_frames > 0 {
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

load_sound :: (name: string) -> *Mixer_Sound_Data {
    data := load_audio_file(name);

    if !data {
        print("Error: Could not load wav file: %\n", name);
        exit(1); // Hard-exit for now.
        return null;
    }

    return data;
}

load_audio_file :: (name : string) -> *Mixer_Sound_Data {
    data : *Mixer_Sound_Data = null;

    file_data, success := read_entire_file(name);
    if !success return data;

    has_extension :: (name: string, extension: string) -> bool {
        if name.count < extension.count  return false;
        test := name;
        advance(*test, name.count - extension.count);
        return test == extension;
    }

    if has_extension(name, WAV) {
        data = New(Mixer_Sound_Data);
        data.name = copy_string(name);
        data.buffer = file_data;

        format, samples, success2, extra := get_wav_header(data.buffer);
        if !success2 {
            log_error("Unable to parse '%' as wav.\n", data.full_path);
            return data;
        }

        if format.wFormatTag == WAVE_FORMAT_PCM {
            data.type = .LINEAR_SAMPLE_ARRAY;
            data.nchannels = cast(u16) format.nChannels;
            data.nsamples_times_nchannels = samples.count/2;
        } else if format.wFormatTag == WAVE_FORMAT_DVI_ADPCM {
            data.type = .ADPCM_COMPRESSED;
            data.wSamplesPerBlock = extra.wSamplesPerBlock;
            data.nBlockAlign = format.nBlockAlign;

            data.nchannels = cast(u16) format.nChannels;
            // The value in the FACT chunk is number of samples by time. 
            data.nsamples_times_nchannels = extra.wSamplesAccordingToFactChunk * data.nchannels;
        } else {
            assert(false);
        }

        data.samples = cast(*s16) samples.data;
        data.sampling_rate = cast(u32) format.nSamplesPerSec;
    } else if has_extension(name, OGG) {
        data = New(Mixer_Sound_Data);
        data.name = copy_string(name);
        data.buffer = file_data;
        data.type = .OGG_COMPRESSED;
    } else {
        // Unsupported format.
        assert(false);
    }

    return data;
}

play_sound :: (data: *Mixer_Sound_Data, perturb: bool = true) -> *Sound_Stream {
    stream := make_stream(sound_player, data);

    if stream {
        stream.sound_data = data;
    }

    if perturb && stream {
        stream.user_volume_scale = random_get_within_range(0.7, 1);
        stream.desired_rate = random_get_within_range(0.7, 1.22);
    }

    stream.repeat_end_position = cast(int)(data.sampling_rate * 234.475);  // @Temporary @Hack! We do not get the duration by default from an ogg file...
    
    return stream;
}

get_direction :: (a: Vector2, b: Vector2) -> Vector2 {
    direction := Vector2.{ b.x - a.x,b.y - a.y };
    return unit_vector(direction);
}