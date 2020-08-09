attribute vec4 position;
attribute vec2 textureCoord;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec2 varyingCoord;

void main() {
    varyingCoord = textureCoord;
    gl_Position = projectionMatrix * modelViewMatrix * position;
}
