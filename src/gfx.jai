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
    size := Vector2.{cast(float)texture.width, cast(float)texture.height};

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