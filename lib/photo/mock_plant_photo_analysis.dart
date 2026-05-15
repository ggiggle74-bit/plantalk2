import 'supported_species.dart';

class MockPlantPhotoAnalysis {
  final List<SupportedSpecies> speciesSuggestions;
  final String note;

  const MockPlantPhotoAnalysis({
    required this.speciesSuggestions,
    required this.note,
  });
}

MockPlantPhotoAnalysis mockAnalyzePlantPhoto(String photoPath) {
  final pool = supportedSpecies
      .where(
        (species) =>
            species.key == 'monstera' ||
            species.key == 'monstera_deliciosa' ||
            species.key == 'pothos',
      )
      .toList();
  final startIndex = photoPath.hashCode.abs() % pool.length;
  final candidates = [
    pool[startIndex],
    pool[(startIndex + 1) % pool.length],
  ];

  return MockPlantPhotoAnalysis(
    speciesSuggestions: candidates,
    note: '사진만으로 확정하지 않고, 등록 전 확인용 후보로만 사용합니다.',
  );
}
