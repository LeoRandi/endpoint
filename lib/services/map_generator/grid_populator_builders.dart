import "_imports.dart";

// ------------------------------------------------------------
//  BUILDERS: devuelven Grid ya con TileObject en sus capas
// ------------------------------------------------------------

extension GridPopulatorBuilders on GridPopulator {
  // GENERATE EMPTY
  static Grid generateEmptyGrid(int gridSize) {
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);
    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE RANDOM
  static Grid generateRandomGrid(int gridSize) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);

    GridPopulator.fillCompletelyRandom(types, gridSize, random);

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE SQUARE WALLS
  static Grid generateSquareWallsGrid(int gridSize) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);

    GridPopulator.addTypeSquares(types, gridSize, random);

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE SQUARE WALLS WITH CHASMS
  static Grid generateSquareWallsGridWithChasms(int gridSize) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);

    GridPopulator.addTypeChunks(
      types,
      gridSize,
      random,
      chunkType: TileType.chasm,
    );

    GridPopulator.addTypeSquares(types, gridSize, random);

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE CHASM FILLED WITH PATH CHUNKS
  static Grid generateChasmFilledWithPathChunksGrid(int gridSize) {
    final random = Random();
    final types = GridPopulatorHelpers.createBaseTypes(
      gridSize,
      fill: TileType.chasm,
    );

    GridPopulator.addTypeChunks(
      types,
      gridSize,
      random,
      chunkType: TileType.path,
      baseType: TileType.chasm,
    );

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE CHASM FILLED WITH PATH SQUARES
  static Grid generateChasmFilledWithPathSquaresGrid(int gridSize) {
    final random = Random();
    final types = GridPopulatorHelpers.createBaseTypes(
      gridSize,
      fill: TileType.chasm,
    );

    GridPopulator.addTypeSquares(
      types,
      gridSize,
      random,
      tileType: TileType.path,
      baseType: TileType.chasm,
    );

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE PATH MAP WITH HORIZONTAL RIVER
  static Grid generatePathGridWithHorizontalRiver(int gridSize) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);

    GridPopulator.addRiver(
      types,
      gridSize,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path],
      maxRiverWidth: 2,
      vertical: false, // horizontal
    );

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE PATH MAP WITH VERTICAL RIVER + WALL SQUARES
  static Grid generatePathGridWithVRiverAndChasmSquares(
      int gridSize) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);

    GridPopulator.addRiver(
      types,
      gridSize,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path],
      maxRiverWidth: 2,
      vertical: true, // vertical
    );

    GridPopulator.addTypeSquares(types, gridSize, random);

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE SQUARES, CHASMS, AND RIVER
  static Grid generateSquaresChasmsAndRiverGrid(int gridSize) {
    final random = Random();
    final types =
        GridPopulatorHelpers.createBaseTypes(gridSize, fill: TileType.path);

    // First: put some chasm chunks over paths
    GridPopulator.addTypeChunks(
      types,
      gridSize,
      random,
      chunkType: TileType.chasm,
      baseType: TileType.path,
    );

    // Then: square walls over remaining paths
    GridPopulator.addTypeSquares(
      types,
      gridSize,
      random,
      tileType: TileType.wall,
      baseType: TileType.path,
    );

    // Finally: river goes through path *and* chasm, but not walls
    GridPopulator.addRiver(
      types,
      gridSize,
      random,
      riverType: TileType.river,
      erodedTypes: [TileType.path, TileType.chasm],
      maxRiverWidth: 3,
      vertical: true, // top -> bottom
    );

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }

  // GENERATE CHASM WITH BIG REGION PATH CHUNKS
  static Grid generateChasmWithBigPathChunksGrid(int gridSize) {
    final random = Random();
    final types = GridPopulatorHelpers.createBaseTypes(
      gridSize,
      fill: TileType.chasm,
    );

    GridPopulator.addTypeRegionChunks(
      types,
      gridSize,
      random,
      chunkType: TileType.path,
      baseType: TileType.chasm,
      minChunkSize: 4,
      maxChunkSize: 8,
      attempts: 30,
    );

    return GridPopulatorHelpers.buildGridObjects(gridSize, types);
  }
}
