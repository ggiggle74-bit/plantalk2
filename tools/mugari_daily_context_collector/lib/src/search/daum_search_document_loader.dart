import '../models/search_document.dart';
import '../planning/daily_search_query.dart';
import '../runner/daily_context_collector_runner.dart';
import 'daum_search_client.dart';

enum DaumSearchEndpoint { web, blog }

final class DaumSearchDocumentLoader implements SearchDocumentLoader {
  const DaumSearchDocumentLoader({
    required DaumSearchClient client,
    this.resultSize = 10,
  }) : _client = client;

  final DaumSearchClient _client;
  final int resultSize;

  @override
  Future<List<SearchDocument>> load(DailySearchQuery query) async {
    if (resultSize < 1 || resultSize > 50) {
      throw ArgumentError.value(
        resultSize,
        'resultSize',
        'must be between 1 and 50',
      );
    }

    final endpoint = endpointFor(query);
    final sort = sortFor(query);
    final result = switch (endpoint) {
      DaumSearchEndpoint.web => await _client.searchWeb(
        query,
        size: resultSize,
        sort: sort,
      ),
      DaumSearchEndpoint.blog => await _client.searchBlog(
        query,
        size: resultSize,
        sort: sort,
      ),
    };
    return result.documents;
  }

  static DaumSearchEndpoint endpointFor(DailySearchQuery query) {
    return switch (query.intent) {
      DailyQueryIntents.park ||
      DailyQueryIntents.culture ||
      DailyQueryIntents.region ||
      DailyQueryIntents.audience => DaumSearchEndpoint.blog,
      _ => DaumSearchEndpoint.web,
    };
  }

  static String sortFor(DailySearchQuery query) {
    return switch (query.intent) {
      DailyQueryIntents.weather || DailyQueryIntents.region => 'recency',
      _ => 'accuracy',
    };
  }
}
