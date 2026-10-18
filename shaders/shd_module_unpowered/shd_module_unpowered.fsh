varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main() {
    vec4 colour = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    float luminance = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
    // Keep a little colour so parts remain recognisable while disconnected.
    colour.rgb = mix(colour.rgb, vec3(luminance), 0.85) * 0.8;
    gl_FragColor = colour;
}
