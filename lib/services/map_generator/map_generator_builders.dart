import "_imports.dart";

extension MapGeneratorBuilders on MapGenerator {
  // ---------- builders ----------

  // GENERATE EMPTY
  static TileGrid generateEmpty(int height, int width) {
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);
    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE RANDOM
  static TileGrid generateRandomMap(int height, int width) {
    final random = Random();
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.fillCompletelyRandom(types, width, height, random);

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE SQUARE WALLS
  static TileGrid generateSquareWallsMap(int height, int width) {
    final random = Random();
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.addTypeSquares(types, width, height, random);

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE SQUARE WALLS WITH CHASMS
  static TileGrid generateSquareWallsMapWithChasms(int height, int width) {
    final random = Random();
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.addTypeChunks(types, width, height, random,
        chunkType: TileType.chasm);

    MapGenerator.addTypeSquares(types, width, height, random);

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE CHASM FILLED WITH PATH CHUNKS
  static TileGrid generateChasmFilledWithPathChunks(int height, int width) {
    final random = Random();
    final types = MapGeneratorHelpers.createBaseTypes(width, height,
        fill: TileType.chasm);

    MapGenerator.addTypeChunks(types, width, height, random,
        chunkType: TileType.path, baseType: TileType.chasm);

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE CHASM FILLED WITH PATH SQUARES
  static TileGrid generateChasmFilledWithPathSquares(int height, int width) {
    final random = Random();
    final types = MapGeneratorHelpers.createBaseTypes(width, height,
        fill: TileType.chasm);

    MapGenerator.addTypeSquares(types, width, height, random,
        tileType: TileType.path, baseType: TileType.chasm);

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE PATH MAP WITH HORIZONTAL RIVER
  static TileGrid generatePathMapWithHorizontalRiver(int height, int width) {
    final random = Random();
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.addRiver(
      types,
      width,
      height,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path],
      maxRiverWidth: 2,
      vertical: false, // horizontal
    );

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE PATH MAP WITH HORIZONTAL RIVER
  static TileGrid generatePathMapWithVRiverAndChasmSquares(
      int height, int width) {
    final random = Random();
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);

    MapGenerator.addRiver(
      types,
      width,
      height,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path],
      maxRiverWidth: 2,
      vertical: true, // horizontal
    );

    MapGenerator.addTypeSquares(types, width, height, random);

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE SQUARES, CHASMS, AND RIVER
  static TileGrid generateSquaresChasmsAndRiver(int height, int width) {
    final random = Random();
    final types =
        MapGeneratorHelpers.createBaseTypes(width, height, fill: TileType.path);

    // First: put some chasm chunks over paths
    MapGenerator.addTypeChunks(
      types,
      width,
      height,
      random,
      chunkType: TileType.chasm,
      baseType: TileType.path,
    );

    // Then: square walls over remaining paths
    MapGenerator.addTypeSquares(
      types,
      width,
      height,
      random,
      tileType: TileType.wall,
      baseType: TileType.path,
    );

    // Finally: river goes through path *and* chasm, but not walls
    MapGenerator.addRiver(
      types,
      width,
      height,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path, TileType.chasm],
      maxRiverWidth: 3,
      vertical: true, // top -> bottom
    );

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }

  // GENERATE CHASM WITH BIG REGION PATH CHUNKS
  static TileGrid generateChasmWithBigPathChunks(int height, int width) {
    final random = Random();
    final types = MapGeneratorHelpers.createBaseTypes(width, height,
        fill: TileType.chasm);

    MapGenerator.addTypeRegionChunks(
      types,
      width,
      height,
      random,
      chunkType: TileType.path,
      baseType: TileType.chasm,
      minChunkSize: 4,
      maxChunkSize: 8,
      attempts: 30,
    );

    return MapGeneratorHelpers.buildGrid(width, height, types);
  }
}
