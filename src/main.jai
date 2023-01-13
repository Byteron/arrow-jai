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

WINDOW_SCALE :: 0.5;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

arrow_texture: Texture;
player_texture: Texture;

Sprite :: struct {
    texture: *Texture;
    scale := Vector2.{1, 1};
    centered := true;
    rotation := 0.0;
    
    h_frames := 0;
    v_frames := 0;
    frame := 0;
}

entities: [..]*Entity;

Entity :: struct {
    using position: Vector2;
    using sprite: Sprite;
    type: Type;
}

Player :: struct {
    #as using entity: Entity;
    type = Player;
}

Enemy :: struct {
    #as using entity: Entity;
    type = Enemy;
}

Arrow :: struct {
    #as using entity: Entity;
    type = Arrow;
}

main :: () {
    width := cast(int) (WINDOW_WIDTH * WINDOW_SCALE);
    height := cast(int) (WINDOW_HEIGHT * WINDOW_SCALE);

    window := create_window(window_name = "One Arrow Colosseum", width = width, height = height);
    set_render_target(window);

    window_width, window_height := get_render_dimensions(window);

    init_textures();

    for 0..100 spawn_arrow(random_get_within_range(0, 500), random_get_within_range(0, 500));
    for 0..50 spawn_player(random_get_within_range(0, 500), random_get_within_range(0, 500));
    
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

            }
        }

        clear_render_target(0.15, 0.08, 0.08, 1.0);

        new_time := get_time();

        delta := cast(f32) (new_time - time);
        time = new_time;

        for entities render_sprite(it.position, it.sprite);
        
        swap_buffers(window);
        
        print("FPS: %, s: %\n", 1.0 / delta , delta);
    }
}

init_textures :: () {
    arrow_texture = load_texture("assets/images/arrow.png");
    player_texture = load_texture("assets/images/mc-body.png");
}

load_texture :: (filename: string) -> Texture {
    result: Texture;
    success := texture_load_from_file(*result, filename);
    assert(success);
    return result;
}

spawn_arrow :: (x: float, y: float) {
    arrow := New(Arrow);
    <<arrow = Arrow.{
        x = x,
        y = y,
        sprite = Sprite.{
            texture = *arrow_texture,
        },
    };
    array_add(*entities, arrow);
}

spawn_player :: (x: float, y: float) -> *Player {
    player := New(Player);
    <<player = Player.{
        x = x,
        y = y,
        sprite = Sprite.{
            texture = *player_texture,
        },
    };
    array_add(*entities, player);
    return player;
}

render_sprite :: (position: Vector2, using sprite: Sprite) {
    size := Vector2.{cast(f32)texture.width, cast(f32)texture.height};

    if (h_frames > 0 || v_frames > 0) {
        width := texture.width / h_frames;
        height := texture.height / v_frames;
        size = Vector2.{cast(float)width, cast(float)height};
    };

    size *= scale;

    offset := ifx centered then size / 2 else Vector2.{0, 0};
    
    set_shader_for_images(texture);
    immediate_begin();
    
    pos := position - offset;
    
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

        texel_x := cast(float)width / texture.width;
        texel_y := cast(float)height / texture.height;

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

load_texture :: (tex : *Texture, path : string) -> bool {
    result := texture_load_from_file(tex, path);
    if !result {
        log_error("Unable to load texture %", path);
    }

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    return result;
}