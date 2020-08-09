precision highp float;
varying lowp vec2 varyingCoord;
uniform sampler2D colorMap;

void main() {
    gl_FragColor = texture2D(colorMap, varyingCoord);
}
