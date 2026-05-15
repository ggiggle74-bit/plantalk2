class SupportedSpecies {
  final String key;
  final String displayName;
  final List<String> aliases;

  const SupportedSpecies({
    required this.key,
    required this.displayName,
    this.aliases = const [],
  });
}

const SupportedSpecies unknownSpecies = SupportedSpecies(
  key: 'unknown',
  displayName: '알 수 없음',
  aliases: ['unknown', 'unknown plant', '알 수 없음', '모름'],
);

const List<SupportedSpecies> supportedSpecies = [
  SupportedSpecies(
    key: 'monstera',
    displayName: '몬스테라',
    aliases: ['몬스', 'monstera'],
  ),
  SupportedSpecies(
    key: 'monstera_deliciosa',
    displayName: '몬스테라 델리시오사',
    aliases: ['몬스', '델리시오사', 'monstera deliciosa'],
  ),
  SupportedSpecies(
    key: 'stucky',
    displayName: '스투키',
    aliases: ['stucky', '스투키'],
  ),
  SupportedSpecies(
    key: 'sansevieria',
    displayName: '산세베리아',
    aliases: ['snake plant', 'sansevieria', '산세베리아'],
  ),
  SupportedSpecies(
    key: 'pothos',
    displayName: '스킨답서스',
    aliases: ['pothos', '스킨', '스킨답서스'],
  ),
  SupportedSpecies(
    key: 'philodendron',
    displayName: '필로덴드론',
    aliases: ['philodendron', '필로'],
  ),
  SupportedSpecies(
    key: 'rubber_tree',
    displayName: '고무나무',
    aliases: ['rubber tree', 'ficus', '고무나무'],
  ),
  SupportedSpecies(
    key: 'dracaena_fragrans',
    displayName: '행운목',
    aliases: ['dracaena', 'corn plant', '행운목'],
  ),
  SupportedSpecies(
    key: 'pachira',
    displayName: '파키라',
    aliases: ['money tree', 'pachira', '파키라'],
  ),
  SupportedSpecies(
    key: 'ivy',
    displayName: '아이비',
    aliases: ['ivy', '아이비'],
  ),
  SupportedSpecies(
    key: 'alocasia',
    displayName: '알로카시아',
    aliases: ['alocasia', '알로'],
  ),
  SupportedSpecies(
    key: 'schefflera',
    displayName: '홍콩야자',
    aliases: ['schefflera', '홍콩야자'],
  ),
  SupportedSpecies(
    key: 'areca_palm',
    displayName: '아레카야자',
    aliases: ['areca', 'areca palm', '야자'],
  ),
  SupportedSpecies(
    key: 'calathea',
    displayName: '칼라데아',
    aliases: ['calathea', '칼라'],
  ),
  SupportedSpecies(
    key: 'peperomia',
    displayName: '페페로미아',
    aliases: ['peperomia', '페페'],
  ),
  SupportedSpecies(
    key: 'succulent',
    displayName: '다육이',
    aliases: ['succulent', '다육'],
  ),
  SupportedSpecies(
    key: 'cactus',
    displayName: '선인장',
    aliases: ['cactus', 'cacti', '선인장'],
  ),
  unknownSpecies,
];

List<SupportedSpecies> searchSupportedSpecies(String keyword) {
  final query = keyword.trim().toLowerCase();
  if (query.isEmpty) {
    return supportedSpecies.where((species) => species.key != 'unknown').toList();
  }

  final matches = supportedSpecies.where((species) {
    if (species.key == 'unknown') return false;

    final displayName = species.displayName.toLowerCase();
    final key = species.key.toLowerCase();
    final aliases = species.aliases.map((alias) => alias.toLowerCase());

    return displayName.contains(query) ||
        key.contains(query) ||
        aliases.any((alias) => alias.contains(query));
  }).toList();

  return matches;
}
