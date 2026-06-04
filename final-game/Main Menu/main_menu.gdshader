shader_type canvas_item;

// This grabs the screen pixels behind the mask
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 mouse_position;
uniform float cone_radius = 160.0;
uniform float feather = 0.25;

void fragment() {
    // 1. Take a picture of the UI beneath this layer
    vec4 ui_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // 2. Godot 4 Canvas Item shaders map SCREEN_UV from (0,0) to (1,1). 
    // We get the current pixel's absolute screen coordinate like this:
    vec2 pixel_screen_pos = SCREEN_UV / SCREEN_PIXEL_SIZE;
    
    // 3. Calculate distance to the mouse cursor
    float distance_to_mouse = distance(pixel_screen_pos, mouse_position);
    
    // 4. Create the circle mask
    float mask = smoothstep(cone_radius, cone_radius * (1.0 - feather), distance_to_mouse);
    
    // 5. Apply the mask
    COLOR = vec4(ui_color.rgb * mask, ui_color.a);
}
