class PlantKoreanNameEntry {
  const PlantKoreanNameEntry({
    required this.key,
    required this.koreanName,
    required this.scientificNames,
    this.aliases = const [],
    this.supportedSpeciesKey,
  });

  final String key;
  final String koreanName;
  final List<String> scientificNames;
  final List<String> aliases;
  final String? supportedSpeciesKey;
}

const List<PlantKoreanNameEntry> plantKoreanNameCatalog = [
  PlantKoreanNameEntry(
    key: "monstera_deliciosa",
    koreanName: "몬스테라 델리시오사",
    scientificNames: ["Monstera deliciosa"],
    aliases: ["monstera deliciosa", "swiss cheese plant", "몬스테라 델리시오사"],
    supportedSpeciesKey: "monstera_deliciosa",
  ),
  PlantKoreanNameEntry(
    key: "monstera",
    koreanName: "몬스테라",
    scientificNames: ["Monstera adansonii", "Monstera borsigiana"],
    aliases: ["monstera", "몬스테라", "몬스"],
    supportedSpeciesKey: "monstera",
  ),
  PlantKoreanNameEntry(
    key: "pothos",
    koreanName: "스킨답서스",
    scientificNames: ["Epipremnum aureum"],
    aliases: ["pothos", "devils ivy", "스킨답서스", "포토스"],
    supportedSpeciesKey: "pothos",
  ),
  PlantKoreanNameEntry(
    key: "sansevieria",
    koreanName: "산세베리아",
    scientificNames: ["Dracaena trifasciata", "Sansevieria trifasciata"],
    aliases: ["snake plant", "sansevieria", "산세베리아"],
    supportedSpeciesKey: "sansevieria",
  ),
  PlantKoreanNameEntry(
    key: "stucky",
    koreanName: "스투키",
    scientificNames: ["Dracaena angolensis", "Sansevieria cylindrica"],
    aliases: ["stucky", "stuckyi", "스투키"],
    supportedSpeciesKey: "stucky",
  ),
  PlantKoreanNameEntry(
    key: "philodendron",
    koreanName: "필로덴드론",
    scientificNames: ["Philodendron hederaceum", "Philodendron erubescens"],
    aliases: ["philodendron", "heartleaf philodendron", "필로덴드론"],
    supportedSpeciesKey: "philodendron",
  ),
  PlantKoreanNameEntry(
    key: "rubber_tree",
    koreanName: "고무나무",
    scientificNames: ["Ficus elastica"],
    aliases: [
      "rubber tree",
      "rubber plant",
      "ficus elastica",
      "고무나무",
      "인도고무나무",
    ],
    supportedSpeciesKey: "rubber_tree",
  ),
  PlantKoreanNameEntry(
    key: "fiddle_leaf_fig",
    koreanName: "떡갈고무나무",
    scientificNames: ["Ficus lyrata"],
    aliases: ["fiddle leaf fig", "fiddle-leaf fig", "떡갈고무나무"],
    supportedSpeciesKey: "rubber_tree",
  ),
  PlantKoreanNameEntry(
    key: "pachira",
    koreanName: "파키라",
    scientificNames: ["Pachira aquatica"],
    aliases: ["money tree", "pachira", "파키라"],
    supportedSpeciesKey: "pachira",
  ),
  PlantKoreanNameEntry(
    key: "zz_plant",
    koreanName: "금전수",
    scientificNames: ["Zamioculcas zamiifolia"],
    aliases: ["zz plant", "zanzibar gem", "금전수"],
  ),
  PlantKoreanNameEntry(
    key: "dracaena_fragrans",
    koreanName: "행운목",
    scientificNames: ["Dracaena fragrans"],
    aliases: ["corn plant", "dracaena", "행운목"],
    supportedSpeciesKey: "dracaena_fragrans",
  ),
  PlantKoreanNameEntry(
    key: "ivy",
    koreanName: "아이비",
    scientificNames: ["Hedera helix"],
    aliases: ["ivy", "english ivy", "아이비"],
    supportedSpeciesKey: "ivy",
  ),
  PlantKoreanNameEntry(
    key: "alocasia",
    koreanName: "알로카시아",
    scientificNames: ["Alocasia macrorrhizos", "Alocasia amazonica"],
    aliases: ["alocasia", "elephant ear", "알로카시아"],
    supportedSpeciesKey: "alocasia",
  ),
  PlantKoreanNameEntry(
    key: "schefflera",
    koreanName: "홍콩야자",
    scientificNames: ["Schefflera arboricola", "Heptapleurum arboricola"],
    aliases: ["schefflera", "umbrella tree", "홍콩야자"],
    supportedSpeciesKey: "schefflera",
  ),
  PlantKoreanNameEntry(
    key: "areca_palm",
    koreanName: "아레카야자",
    scientificNames: ["Dypsis lutescens", "Chrysalidocarpus lutescens"],
    aliases: ["areca palm", "butterfly palm", "아레카야자", "아레카"],
    supportedSpeciesKey: "areca_palm",
  ),
  PlantKoreanNameEntry(
    key: "parlor_palm",
    koreanName: "테이블야자",
    scientificNames: ["Chamaedorea elegans"],
    aliases: ["parlor palm", "parlour palm", "table palm", "테이블야자"],
  ),
  PlantKoreanNameEntry(
    key: "lady_palm",
    koreanName: "관음죽",
    scientificNames: ["Rhapis excelsa"],
    aliases: ["lady palm", "관음죽"],
  ),
  PlantKoreanNameEntry(
    key: "calathea",
    koreanName: "칼라테아",
    scientificNames: ["Calathea orbifolia", "Goeppertia orbifolia"],
    aliases: ["calathea", "goeppertia", "칼라테아"],
    supportedSpeciesKey: "calathea",
  ),
  PlantKoreanNameEntry(
    key: "peperomia",
    koreanName: "페페로미아",
    scientificNames: ["Peperomia obtusifolia", "Peperomia caperata"],
    aliases: ["peperomia", "baby rubber plant", "페페로미아"],
    supportedSpeciesKey: "peperomia",
  ),
  PlantKoreanNameEntry(
    key: "spathiphyllum",
    koreanName: "스파티필름",
    scientificNames: ["Spathiphyllum wallisii"],
    aliases: ["peace lily", "spathiphyllum", "스파티필름", "스파티필럼"],
  ),
  PlantKoreanNameEntry(
    key: "dieffenbachia",
    koreanName: "디펜바키아",
    scientificNames: ["Dieffenbachia seguine"],
    aliases: ["dieffenbachia", "dumb cane", "디펜바키아"],
  ),
  PlantKoreanNameEntry(
    key: "aglaonema",
    koreanName: "아글라오네마",
    scientificNames: ["Aglaonema commutatum", "Aglaonema modestum"],
    aliases: ["aglaonema", "chinese evergreen", "아글라오네마"],
  ),
  PlantKoreanNameEntry(
    key: "anthurium",
    koreanName: "안스리움",
    scientificNames: ["Anthurium andraeanum"],
    aliases: ["anthurium", "flamingo flower", "안스리움"],
  ),
  PlantKoreanNameEntry(
    key: "hoya",
    koreanName: "호야",
    scientificNames: ["Hoya carnosa"],
    aliases: ["hoya", "wax plant", "honey plant", "호야"],
  ),
  PlantKoreanNameEntry(
    key: "olive_tree",
    koreanName: "올리브나무",
    scientificNames: ["Olea europaea"],
    aliases: ["olive", "olive tree", "올리브", "올리브나무"],
  ),
  PlantKoreanNameEntry(
    key: "rosemary",
    koreanName: "로즈마리",
    scientificNames: ["Salvia rosmarinus", "Rosmarinus officinalis"],
    aliases: ["rosemary", "로즈마리"],
  ),
  PlantKoreanNameEntry(
    key: "lavender",
    koreanName: "라벤더",
    scientificNames: ["Lavandula angustifolia"],
    aliases: ["lavender", "라벤더"],
  ),
  PlantKoreanNameEntry(
    key: "basil",
    koreanName: "바질",
    scientificNames: ["Ocimum basilicum"],
    aliases: ["basil", "sweet basil", "바질"],
  ),
  PlantKoreanNameEntry(
    key: "lucky_bamboo",
    koreanName: "개운죽",
    scientificNames: ["Dracaena sanderiana"],
    aliases: ["lucky bamboo", "개운죽"],
  ),
  PlantKoreanNameEntry(
    key: "bird_of_paradise",
    koreanName: "극락조",
    scientificNames: ["Strelitzia reginae"],
    aliases: ["bird of paradise", "극락조"],
  ),
  PlantKoreanNameEntry(
    key: "travellers_palm",
    koreanName: "여인초",
    scientificNames: ["Ravenala madagascariensis", "Strelitzia nicolai"],
    aliases: [
      "travellers palm",
      "traveler palm",
      "white bird of paradise",
      "여인초",
    ],
  ),
  PlantKoreanNameEntry(
    key: "succulent",
    koreanName: "다육이",
    scientificNames: [
      "Echeveria elegans",
      "Crassula ovata",
      "Sedum morganianum",
    ],
    aliases: [
      "succulent",
      "succulent plant",
      "echeveria",
      "jade plant",
      "다육이",
      "다육",
    ],
    supportedSpeciesKey: "succulent",
  ),
  PlantKoreanNameEntry(
    key: "cactus",
    koreanName: "선인장",
    scientificNames: ["Mammillaria elongata", "Opuntia microdasys"],
    aliases: ["cactus", "cacti", "선인장"],
    supportedSpeciesKey: "cactus",
  ),
  PlantKoreanNameEntry(
    key: "aloe_vera",
    koreanName: "알로에",
    scientificNames: ["Aloe vera"],
    aliases: ["aloe", "aloe vera", "알로에"],
    supportedSpeciesKey: "succulent",
  ),
  PlantKoreanNameEntry(
    key: "spider_plant",
    koreanName: "접란",
    scientificNames: ["Chlorophytum comosum"],
    aliases: ["spider plant", "chlorophytum", "접란"],
  ),
  PlantKoreanNameEntry(
    key: "syngonium",
    koreanName: "싱고니움",
    scientificNames: ["Syngonium podophyllum"],
    aliases: ["syngonium", "arrowhead plant", "싱고니움"],
  ),
  PlantKoreanNameEntry(
    key: "fittonia",
    koreanName: "피토니아",
    scientificNames: ["Fittonia albivenis"],
    aliases: ["fittonia", "nerve plant", "피토니아"],
  ),
];

PlantKoreanNameEntry? findPlantKoreanNameEntry({
  String? scientificName,
  String? displayName,
  Iterable<String> commonNames = const [],
}) {
  final names = <String>[?scientificName, ?displayName, ...commonNames];

  for (final name in names) {
    final entry = findPlantKoreanNameEntryByName(name);
    if (entry != null) return entry;
  }

  return null;
}

PlantKoreanNameEntry? findPlantKoreanNameEntryByName(String? value) {
  final normalizedValue = normalizePlantCatalogName(value);
  if (normalizedValue.isEmpty) return null;

  for (final entry in plantKoreanNameCatalog) {
    if (_entryMatches(entry, normalizedValue)) {
      return entry;
    }
  }

  return null;
}

String normalizePlantCatalogName(String? value) {
  if (value == null) return "";

  return value
      .trim()
      .toLowerCase()
      .replaceAll("’", "'")
      .replaceAll("‘", "'")
      .replaceAll("`", "'")
      .replaceAll(RegExp(r"\s+"), " ")
      .replaceAll(RegExp(r"\.$"), "");
}

bool _entryMatches(PlantKoreanNameEntry entry, String normalizedValue) {
  if (_matchesCatalogName(entry.koreanName, normalizedValue)) {
    return true;
  }

  for (final scientificName in entry.scientificNames) {
    if (_matchesCatalogName(scientificName, normalizedValue)) {
      return true;
    }
  }

  for (final alias in entry.aliases) {
    if (_matchesCatalogName(alias, normalizedValue)) {
      return true;
    }
  }

  return false;
}

bool _matchesCatalogName(String catalogName, String normalizedValue) {
  final normalizedCatalogName = normalizePlantCatalogName(catalogName);
  if (normalizedCatalogName.isEmpty) return false;

  return normalizedValue == normalizedCatalogName ||
      normalizedValue.startsWith("$normalizedCatalogName ");
}
