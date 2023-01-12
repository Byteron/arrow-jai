#import "Basic";
#import "Math";
#import "Window_Creation";
#import "System";
#import "String";
#import "GL";
#import "Simp";
#import "Input";

f32 :: float32;
f64 :: float64;

WINDOW_SCALE :: 0.5;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

Sprite :: struct {
    texture: *Texture;
    scale := Vector2.{1, 1};
    centered := true;
    rotation := 0.0;
    
    h_frames := 0;
    v_frames := 0;
    frame := 0;
}

Player :: struct {
    using position: Vector2;
    sprite: Sprite;
}

Enemy :: struct {
    using position: Vector2;
    sprite: Sprite;
}

Arrow :: struct {
    using position: Vector2;
    sprite: Sprite;
}

main :: () {
    width := cast(int) (WINDOW_WIDTH * WINDOW_SCALE);
    height := cast(int) (WINDOW_HEIGHT * WINDOW_SCALE);

    window := create_window(window_name = "One Arrow Colosseum", width = width, height = height);
    set_render_target(window);

    window_width, window_height := get_render_dimensions(window);

    texture: Texture;
    success := load_texture(*texture, "assets/images/enemy_1.png");
    assert(success);

    e := Enemy.{ 
        position = Vector2.{200, 200},
        sprite = Sprite.{ 
            texture = *texture,
            scale = Vector2.{2, 2},
            h_frames = 6,
            v_frames = 4,
        }
    };

    quit := false;
    time := get_time();
    secs := 0;

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
        new_secs := cast(int)new_time;

        delta := cast(f32) (new_time - time);
        time = new_time;

        if (new_secs != secs)
        {
            secs = new_secs;
            max := e.sprite.v_frames * e.sprite.h_frames;
            e.sprite.frame = (e.sprite.frame + 1) % max;
        }

        render_sprite(e.position, e.sprite);
        
        swap_buffers(window);
        
        print("FPS: %, s: %\n", 1.0 / delta , delta);
    }
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