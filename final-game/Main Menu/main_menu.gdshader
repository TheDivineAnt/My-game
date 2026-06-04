shader_type canvas_item;

// This takes a live snapshot of the UI rendering underneath this mask layer
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 mouse_position;
uniform float cone_radius = 160.0; // Change this number to make the light wider or narrower
uniform float feather = 0.25;       // Smoothness of the edges

void fragment() {
    // 1. Grab the UI pixels behind the mask
    vec4 ui_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // 2. Convert screen pixels to absolute coordinates for Godot 4
    vec2 pixel_screen_pos = SCREEN_UV / SCREEN_PIXEL_SIZE;
    
    // 3. Calculate how far this pixel is from the mouse cursor
    float distance_to_mouse = distance(pixel_screen_pos, mouse_position);
    
    // 4. Create the circle mask math
    float mask = smoothstep(cone_radius, cone_radius * (1.0 - feather), distance_to_mouse);
    
    // 5. Render the UI inside the circle, and leave everything else pitch black
    COLOR = vec4(ui_color.rgb * mask, ui_color.a);
}