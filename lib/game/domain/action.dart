enum ActionType { attack, defend, skill }

class BattleAction {
  final ActionType type;
  final String? skillId;
  const BattleAction.attack() : type = ActionType.attack, skillId = null;
  const BattleAction.defend() : type = ActionType.defend, skillId = null;
  const BattleAction.skill(this.skillId) : type = ActionType.skill;
}
