import "_imports.dart";

// ------------------------------------------------------------
//  BUILDERS: devuelven Grid ya con TileObject en sus capas
// ------------------------------------------------------------

extension GridPopulatorBuilders on GridPopulator {
  // GENERATE EMPTY
  static Grid generateEmptyGrid(int height, int width) {
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);
    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE RANDOM
  static Grid generateRandomGrid(int height, int width) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);

    GridPopulator.fillCompletelyRandom(types, width, height, random);

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE SQUARE WALLS
  static Grid generateSquareWallsGrid(int height, int width) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);

    GridPopulator.addTypeSquares(types, width, height, random);

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE SQUARE WALLS WITH CHASMS
  static Grid generateSquareWallsGridWithChasms(int height, int width) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);

    GridPopulator.addTypeChunks(
      types,
      width,
      height,
      random,
      chunkType: TileType.chasm,
    );

    GridPopulator.addTypeSquares(types, width, height, random);

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE CHASM FILLED WITH PATH CHUNKS
  static Grid generateChasmFilledWithPathChunksGrid(int height, int width) {
    final random = Random();
    final types = GridPopulatorHelpers.createBaseTypes(
      width,
      height,
      fill: TileType.chasm,
    );

    GridPopulator.addTypeChunks(
      types,
      width,
      height,
      random,
      chunkType: TileType.path,
      baseType: TileType.chasm,
    );

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE CHASM FILLED WITH PATH SQUARES
  static Grid generateChasmFilledWithPathSquaresGrid(int height, int width) {
    final random = Random();
    final types = GridPopulatorHelpers.createBaseTypes(
      width,
      height,
      fill: TileType.chasm,
    );

    GridPopulator.addTypeSquares(
      types,
      width,
      height,
      random,
      tileType: TileType.path,
      baseType: TileType.chasm,
    );

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE PATH MAP WITH HORIZONTAL RIVER
  static Grid generatePathGridWithHorizontalRiver(int height, int width) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);

    GridPopulator.addRiver(
      types,
      width,
      height,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path],
      maxRiverWidth: 2,
      vertical: false, // horizontal
    );

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE PATH MAP WITH VERTICAL RIVER + WALL SQUARES
  static Grid generatePathGridWithVRiverAndChasmSquares(
      int height, int width) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);

    GridPopulator.addRiver(
      types,
      width,
      height,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path],
      maxRiverWidth: 2,
      vertical: true, // vertical
    );

    GridPopulator.addTypeSquares(types, width, height, random);

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE SQUARES, CHASMS, AND RIVER
  static Grid generateSquaresChasmsAndRiverGrid(int height, int width) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(width, height, fill: TileType.path);

    // First: put some chasm chunks over paths
    GridPopulator.addTypeChunks(
      types,
      width,
      height,
      random,
      chunkType: TileType.chasm,
      baseType: TileType.path,
    );

    // Then: square walls over remaining paths
    GridPopulator.addTypeSquares(
      types,
      width,
      height,
      random,
      tileType: TileType.wall,
      baseType: TileType.path,
    );

    // Finally: river goes through path *and* chasm, but not walls
    GridPopulator.addRiver(
      types,
      width,
      height,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path, TileType.chasm],
      maxRiverWidth: 3,
      vertical: true, // top -> bottom
    );

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }

  // GENERATE CHASM WITH BIG REGION PATH CHUNKS
  static Grid generateChasmWithBigPathChunksGrid(int height, int width) {
    final random = Random();
    final types = GridPopulatorHelpers.createBaseTypes(
      width,
      height,
      fill: TileType.chasm,
    );

    GridPopulator.addTypeRegionChunks(
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

    return GridPopulatorHelpers.buildGridObjects(width, height, types);
  }
}
