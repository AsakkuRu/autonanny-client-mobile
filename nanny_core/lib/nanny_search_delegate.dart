import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/static_data.dart';
import 'package:nanny_core/nanny_core.dart';

class NannySearchDelegate<T, E> extends SearchDelegate<E?> {
  NannySearchDelegate({
    required this.onSearch,
    required this.onResponse,
    this.tileBuilder,
    this.searchLabel = "Поиск...",
    this.emptyLabel = "Начните вводить адрес...",
  });

  final Future<ApiResponse<T>> Function(String query) onSearch;
  final List<E>? Function(ApiResponse<T> response) onResponse;
  final Widget Function(E data, VoidCallback close)? tileBuilder;
  final String searchLabel;
  final String emptyLabel;

  /// Один Future на конкретную строку: иначе при каждом rebuild (клавиатура и т.д.)
  /// создаётся новый Future и debounce сбрасывается — запрос не доходит до API.
  String _memoQuery = '';
  Future<List<E>>? _memoFuture;

  @override
  String? get searchFieldLabel => searchLabel;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isNotEmpty) {
            query = "";
          } else {
            close(context, null);
          }
        },
        icon: const Icon(Icons.close),
        splashRadius: 25,
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_outlined),
      splashRadius: 25,
    );
  }

  @override
  Widget buildResults(BuildContext context) => searchForSuggestions();

  @override
  Widget buildSuggestions(BuildContext context) => searchForSuggestions();

  Widget searchForSuggestions() {
    final q = query.trim();
    return FutureLoader(
      key: ValueKey<String>('addr_search_$q'),
      future: loadRequest(),
      completeView: (context, data) {
        if (data.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(emptyLabel, textAlign: TextAlign.center),
            ),
          );
        }

        return ListView(
          children: data
              .map(
                (e) => tileBuilder != null
                    ? tileBuilder!(e, () => close(context, e))
                    : ListTile(
                        title: Text((e as StaticData).title),
                        onTap: () => close(context, e),
                      ),
              )
              .toList(),
        );
      },
      errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }

  /// Debounce + один Future на строку `query`, чтобы перестроения не сбрасывали таймер.
  Future<List<E>> loadRequest() {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      _memoQuery = '';
      _memoFuture = null;
      return Future<List<E>>.value([]);
    }

    if (_memoQuery == normalizedQuery && _memoFuture != null) {
      return _memoFuture!;
    }

    _memoQuery = normalizedQuery;
    _memoFuture = _loadRequestDebounced(normalizedQuery);
    return _memoFuture!;
  }

  Future<List<E>> _loadRequestDebounced(String normalizedQuery) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.trim() != normalizedQuery) {
      return [];
    }
    try {
      final response = await onSearch(normalizedQuery);
      if (!response.success) {
        throw Exception(response.errorMessage);
      }
      return onResponse(response) ?? [];
    } catch (e) {
      // Не прячем ошибки под "пусто", иначе дебаг невозможен и UX ломается.
      // FutureLoader покажет ErrorView с текстом ошибки.
      return Future<List<E>>.error(e);
    }
  }
}
