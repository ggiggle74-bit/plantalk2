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
  aliases: ['unknown', 'unknown plant', '알 수 없음', '모름', '기타'],
);

const List<SupportedSpecies> supportedSpecies = [
  SupportedSpecies(
    key: 'monstera',
    displayName: '몬스테라',
    aliases: ['몬스테라', '몬스', 'monstera'],
  ),
  SupportedSpecies(
    key: 'monstera_deliciosa',
    displayName: '몬스테라 델리시오사',
    aliases: ['몬스테라', '델리시오사', 'monstera deliciosa'],
  ),
  SupportedSpecies(
    key: 'stucky',
    displayName: '스투키',
    aliases: [
      '스투키',
      'stucky',
      'stuckyi',
      'sansevieria cylindrica',
      'dracaena angolensis',
    ],
  ),
  SupportedSpecies(
    key: 'sansevieria',
    displayName: '산세베리아',
    aliases: [
      '산세베리아',
      'snake plant',
      'sansevieria',
      'sansevieria trifasciata',
      'dracaena trifasciata',
    ],
  ),
  SupportedSpecies(
    key: 'pothos',
    displayName: '스킨답서스',
    aliases: [
      '스킨',
      '스킨답서스',
      '포토스',
      'pothos',
      'epipremnum aureum',
      'devil\'s ivy',
      'devils ivy',
    ],
  ),
  SupportedSpecies(
    key: 'philodendron',
    displayName: '필로덴드론',
    aliases: ['필로', '필로덴드론', 'philodendron'],
  ),
  SupportedSpecies(
    key: 'rubber_tree',
    displayName: '고무나무',
    aliases: ['고무나무', '인도고무나무', 'rubber tree', 'ficus', 'ficus elastica'],
  ),
  SupportedSpecies(
    key: 'dracaena_fragrans',
    displayName: '행운목',
    aliases: ['행운목', 'dracaena', 'corn plant', 'dracaena fragrans'],
  ),
  SupportedSpecies(
    key: 'pachira',
    displayName: '파키라',
    aliases: ['파키라', 'money tree', 'pachira', 'pachira aquatica'],
  ),
  SupportedSpecies(
    key: 'ivy',
    displayName: '아이비',
    aliases: ['아이비', 'ivy', 'hedera helix'],
  ),
  SupportedSpecies(
    key: 'alocasia',
    displayName: '알로카시아',
    aliases: ['알로', '알로카시아', 'alocasia'],
  ),
  SupportedSpecies(
    key: 'schefflera',
    displayName: '홍콩야자',
    aliases: ['홍콩야자', 'schefflera', 'schefflera arboricola', 'umbrella tree'],
  ),
  SupportedSpecies(
    key: 'areca_palm',
    displayName: '아레카야자',
    aliases: ['아레카야자', '아레카', '야자', 'areca', 'areca palm', 'dypsis lutescens'],
  ),
  SupportedSpecies(
    key: 'calathea',
    displayName: '칼라테아',
    aliases: ['칼라', '칼라테아', 'calathea', 'goeppertia'],
  ),
  SupportedSpecies(
    key: 'peperomia',
    displayName: '페페로미아',
    aliases: ['페페', '페페로미아', 'peperomia'],
  ),
  SupportedSpecies(
    key: 'succulent',
    displayName: '다육이',
    aliases: ['다육', '다육이', 'succulent', 'succulent plant', 'echeveria'],
  ),
  SupportedSpecies(
    key: 'cactus',
    displayName: '선인장',
    aliases: ['선인장', 'cactus', 'cacti'],
  ),
  unknownSpecies,
];

List<SupportedSpecies> searchSupportedSpecies(String keyword) {
  final query = keyword.trim().toLowerCase();
  if (query.isEmpty) {
    return supportedSpecies
        .where((species) => species.key != 'unknown')
        .toList();
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
