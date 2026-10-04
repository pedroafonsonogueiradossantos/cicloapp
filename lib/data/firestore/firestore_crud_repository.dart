import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/api_exception.dart';
import '../../domain/repositories/crud_repository.dart';
import '../../models/page_response.dart';

  FirestoreCrudRepository({
    required this.collectionPath,
    required this.fromDoc,
    required this.notFoundMessage,
  });

  final String collectionPath;
  final T Function(String id, Map<String, dynamic> data) fromDoc;
  final String Function(String id) notFoundMessage;

  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection(collectionPath);

  @override
  Future<List<T>> list({bool Function(T item)? where}) async {
    final snapshot = await collection.get();
    final items = snapshot.docs.map((d) => fromDoc(d.id, d.data())).toList();
    return where == null ? items : items.where(where).toList();
  }

  @override
  Future<PageResponse<T>> page({
    bool Function(T item)? where,
    int Function(T a, T b)? sort,
    int page = 0,
    int size = 20,
  }) async {
    final items = await list(where: where);
    if (sort != null) items.sort(sort);

    final totalElements = items.length;
    final totalPages = (totalElements / size).ceil();
    final start = page * size;
    final content = start >= items.length ? <T>[] : items.skip(start).take(size).toList();

    return PageResponse<T>(
      content: content,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages == 0 ? 1 : totalPages,
      last: page >= totalPages - 1,
    );
  }

  @override
  Future<T> getById(String id) async {
    final doc = await collection.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) throw ApiException(message: notFoundMessage(id), statusCode: 404);
    return fromDoc(doc.id, data);
  }

  @override
  Future<T> create(Map<String, dynamic> data) async {
    final ref = await collection.add(data);
    return getById(ref.id);
  }

  @override
  Future<T> update(String id, Map<String, dynamic> data) async {
    final ref = collection.doc(id);
    if (!(await ref.get()).exists) throw ApiException(message: notFoundMessage(id), statusCode: 404);
    await ref.update(data);
    return getById(id);
  }

  @override
  Future<void> delete(String id) async {
    final ref = collection.doc(id);
    if (!(await ref.get()).exists) throw ApiException(message: notFoundMessage(id), statusCode: 404);
    await ref.delete();
  }
}
