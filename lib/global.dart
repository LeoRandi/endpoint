import "_imports.dart";

class GlobalState {
  final _viewSelectedBattlerController = StreamController<Battler?>.broadcast();
  final ManagerList<BattlerObject> battlerObjectManager = ManagerList<BattlerObject>([]);
  final ManagerList<Grid> gridManager = ManagerList<Grid>([]);

  Stream<Battler?> get viewSelectedBattlerStream =>
      _viewSelectedBattlerController.stream;

  void setViewSelectedBattler(Battler? battler) {
    _viewSelectedBattlerController.add(battler);
  }
  final ValueNotifier<Battler?> playingBattlerNotifier = ValueNotifier<Battler?>(null);

  void setPlayingBattler(Battler? battler) {
    playingBattlerNotifier.value = battler;
  }

  int gridSize = 12;
}

final global = GlobalState();

typedef Grid = List<GridObject?>;

// ============ DUEL STATION UI CONSTANTS ============

// Pentagon Party dimensions
const double PARTY_CONTAINER_WIDTH = 136;
const double PARTY_CONTAINER_HEIGHT = 90;
const double PENTAGON_CENTER_X = 68;
const double PENTAGON_CENTER_Y = 45;
const double PENTAGON_RADIUS = 36;

// Battler slot dimensions
const double BATTLER_SLOT_WIDTH = 48;
const double BATTLER_SLOT_HEIGHT = 64;
const double BATTLER_SLOT_OFFSET_X = 24; // Width / 2
const double BATTLER_SLOT_OFFSET_Y = 32; // Height / 2
const double BATTLER_SLOT_BORDER_WIDTH = 1;

// Battler slot text sizes
const double BATTLER_NAME_FONT_SIZE = 7;
const double BATTLER_HP_FONT_SIZE = 6;
const double BATTLER_EMPTY_SLOT_FONT_SIZE = 12;

// Battle card dimensions
const double BATTLE_CARD_WIDTH = 55;
const double BATTLE_CARD_TITLE_FONT_SIZE = 10;
const double BATTLE_CARD_ATTACK_FONT_SIZE = 8;
const double BATTLE_CARD_DESCRIPTION_FONT_SIZE = 7;
const double BATTLE_CARD_BACK_FONT_SIZE = 8;
const double BATTLE_CARD_SPACING = 4;

// Hand dimensions
const double HAND_HEIGHT = 80;
const double HAND_CARD_OPACITY_DRAGGING = 0.5;

// Drop slot dimensions
const double DROP_SLOT_WIDTH = 70;
const double DROP_SLOT_HEIGHT = 104;
const double DROP_SLOT_BORDER_WIDTH = 2;
const double DROP_SLOT_ICON_SIZE = 26;
const double DROP_SLOT_ICON_SPACING = 8;
const double DROP_SLOT_TEXT_FONT_SIZE = 12;

// Field layout spacing
const double FIELD_PADDING = 16;
const double FIELD_HORIZONTAL_SPACING = 16;
const double FIELD_VERTICAL_SPACING = 32;

// Active battler styling
const double ACTIVE_BATTLER_SCALE = 1.3; // Size multiplier (30% larger)
const double ACTIVE_BATTLER_BORDER_WIDTH = 3;
const int ACTIVE_BATTLER_Z_INDEX = 10; // Higher z-index for active battler

// Duel station appbar dimensions
const double APPBAR_BATTLER_IMAGE_WIDTH = 32;
const double APPBAR_BATTLER_IMAGE_HEIGHT = 32;
const double APPBAR_DIVIDER_WIDTH = 2;
const double APPBAR_DIVIDER_HEIGHT = 60;
const double APPBAR_BACKGROUND_OPACITY = 0.2;
const double APPBAR_BORDER_RADIUS = 8;
const double APPBAR_HORIZONTAL_PADDING = 2.0;
const double APPBAR_VERTICAL_PADDING = 4.0;
const double APPBAR_IMAGE_SPACING = 6;
const int APPBAR_BACKGROUND_ALPHA = 200; // For Color.fromARGB

// Duel station battler stats widget
const double STATS_WIDGET_CLASS_ICON_WIDTH = 16;
const double STATS_WIDGET_CLASS_ICON_HEIGHT = 16;
const double STATS_WIDGET_NAME_SPACING = 4;
const double STATS_WIDGET_ROW_SPACING = 2;
const double APPBAR_STATS_ICON_WIDTH = 16;
const double APPBAR_STATS_ICON_HEIGHT = 16;

// Battle card widget
const double BATTLE_CARD_STAT_ICON_WIDTH = 16;
const double BATTLE_CARD_STAT_ICON_HEIGHT = 16;

// BattlerStatsWidget (full stats display)
const double BATTLER_STATS_DIVIDER_HEIGHT = 1;

// Duel Station Middle Zone dimensions
const double MIDDLE_ZONE_HEIGHT = 60;
const double MIDDLE_ZONE_HORIZONTAL_PADDING = 8;
const double MIDDLE_ZONE_VERTICAL_PADDING = 6;
const double MIDDLE_ZONE_TURN_WIDTH = 30;
const double MIDDLE_ZONE_TURN_HEIGHT = 40;
const double MIDDLE_ZONE_TURN_FONT_SIZE = 16;
const double MIDDLE_ZONE_STEP_WIDTH = 40;
const double MIDDLE_ZONE_STEP_HEIGHT = 40;
const double MIDDLE_ZONE_STEP_FONT_SIZE = 10;
const double MIDDLE_ZONE_BUTTON_HORIZONTAL_PADDING = 6;
const double MIDDLE_ZONE_BUTTON_VERTICAL_PADDING = 4;
const double MIDDLE_ZONE_BUTTON_TEXT_FONT_SIZE = 12;

const int TIME_BETWEEN_TURN_STEPS = 1000; // in milliseconds

// Turn Announcement dimensions
const double TURN_ANNOUNCEMENT_FONT_SIZE = 48;
const double TURN_ANNOUNCEMENT_HORIZONTAL_PADDING = 48;
const double TURN_ANNOUNCEMENT_VERTICAL_PADDING = 24;
const double TURN_ANNOUNCEMENT_BORDER_RADIUS = 12;
const double TURN_ANNOUNCEMENT_SHADOW_BLUR = 8;
