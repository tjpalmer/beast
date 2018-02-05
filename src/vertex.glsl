uniform mat4 view;

attribute vec3 position;

void main(void) {
  gl_Position = view * vec4(position, 1.0);
}
