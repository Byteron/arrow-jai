#import "Basic";
#import "Math";
#import "Window_Creation";
#import "System";
#import "String";
#import "GL";
#import "Simp";
#import "Input";
#import "Hash_Table";

f32 :: float32;
f64 :: float64;

TEXTURE_SCALE :: 2;

WINDOW_SCALE :: 0.5;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

Arrow :: struct {
    using position: Vector2;
    using sprite: Sprite;
}

Position :: #type,isa Vector2;

Sprite :: struct {
    texture: *Texture;
    centered := true;
    rotation := 0.0;
}

main :: () {
    width := cast(int) (WINDOW_WIDTH * WINDOW_SCALE);
    height := cast(int) (WINDOW_HEIGHT * WINDOW_SCALE);

    window := create_window(window_name = "One Arrow Colosseum", width = width, height = height);
    set_render_target(window);

    window_width, window_height := get_render_dimensions(window);

    texture: Texture;
    success := load_texture(*texture, "assets/images/arrow.png");
    assert(success);

    a1 := Arrow.{position = Vector2.{100, 200}, texture = *texture};
    a2 := Arrow.{position = Vector2.{300, 100}, texture = *texture};
    a3 := Arrow.{position = Vector2.{500, 300}, texture = *texture};

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
        
        swap_buffers(window);
        
        print("FPS: %, s: %\n", 1.0 / delta , delta);
    }
}

render_sprite :: (position: Vector2, using sprite: *Sprite) {
    size := Vector2.{cast(f32)texture.width, cast(f32)texture.height} * TEXTURE_SCALE;
    offset := ifx centered then size / 2 else Vector2.{0, 0};
    
    set_shader_for_images(texture);
    immediate_begin();
    
    pos := position - offset;

    v1 := Vector2.{pos.x, pos.y};
    v2 := Vector2.{pos.x + size.x, pos.y};
    v3 := Vector2.{pos.x + size.x, pos.y + size.y};
    v4 := Vector2.{pos.x, pos.y + size.y};

    v1 = rotate(v1 - position, rotation) + position;
    v2 = rotate(v2 - position, rotation) + position;
    v3 = rotate(v3 - position, rotation) + position;
    v4 = rotate(v4 - position, rotation) + position;

    immediate_quad(v1, v2, v3, v4);

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