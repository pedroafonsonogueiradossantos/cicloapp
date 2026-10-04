import '../../models/page_response.dart';

/// Generic contract every entity repository implements
abstract class CrudRepository<T> {
  Future<List<T>> list({bool Function(T item)? where});

  Future<PageResponse<T>> page({
    bool Function(T item)? where,
    int Function(T a, T b)? sort,
    int page = 0,
    int size = 20,
  });

  Future<T> getById(String id);

  Future<T> create(Map<String, dynamic> data);

  Future<T> update(String id, Map<String, dynamic> data);

  Future<void> delete(String id);
}
