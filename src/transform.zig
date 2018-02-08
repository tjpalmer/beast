pub fn Mat(
  comptime Value: type, comptime nrows: u32, comptime ncols: u32,
) type {
  const len = nrows * ncols;
  return struct {

    const Self = this;

    values: [len]Value,

    fn init() Self {
      return Self {
        // TODO Default to identity?
        .values = []Value{0} ** len,
      };
    }

  };
}

pub const Mat3 = Mat(f32, 3, 3);

pub const Mat34 = Mat(f32, 3, 4);

// TODO Different customizations on transforms vs other matrices?
pub const T3 = Mat34;

pub fn Vec(comptime Value: type, comptime len: u32) type {
  return struct {

    const Self = this;

    values: [len]Value,

    fn init() Self {
      return Self {
        .values = []Value{0} ** len,
      };
    }

  };
}

pub const Vec2 = Vec(f32, 2);

pub const Vec3 = Vec(f32, 3);
