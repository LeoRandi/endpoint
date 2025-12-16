// import "_imports.dart";

// class TileGrid {
//   final int width;
//   final int height;
//   final List<TileObject> tiles; // length == width * height

//   TileGrid(this.width, this.height, this.tiles);

//   TileObject tileAt(int x, int y) => tiles[y * width + x];

//   void setTile(int x, int y, TileObject tile) {
//     tiles[y * width + x] = tile;
//   }

//   static TileGrid buildFromTypes(
//     int width,
//     int height,
//     List<TileType> types,
//   ) {
//     final tiles = <TileObject>[];

//     int index(int x, int y) => y * width + x;

//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         tiles.add(TileObject.fromType(types[index(x, y)], x, y));
//       }
//     }

//     return TileGrid(width, height, tiles);
//   }
// }
