class AggregationEntity {
  final int createdBy;
  final int itemsCount;
  final String id;
  final Lox da;
  final String? comment;
  final List<String> codes;
  final List<Lox?> net;
  final List<Lox>? newt;
  final List<Lox?>? nwewt;

  AggregationEntity({
    required this.createdBy,
    required this.itemsCount,
    required this.id,
    required this.da,
    this.comment,
    required this.codes,
    required this.net,
    this.newt,
    this.nwewt,
  });

  copyWith({
    int? createdBy,
    int? itemsCount,
    String? comment,
    String? id,
    Lox? da,
    List<String>? codes,
    List<Lox?>? net,
    List<Lox>? newt,
    List<Lox?>? nwewt,
  }) {
    return AggregationEntity(
      createdBy: createdBy ?? this.createdBy,
      itemsCount: itemsCount ?? this.itemsCount,
      id: id ?? this.id,
      codes: codes ?? this.codes,
      comment: comment ?? this.comment,
      da: da ?? this.da,
      net: net ?? this.net,
      newt: newt ?? this.newt,
      nwewt: nwewt ?? this.nwewt,
    );
  }
}

class Lox {
  final String da;

  Lox({required this.da});
}

class AggregationEntityGOOD {
  final int createdBy;
  final int itemsCount;
  final double price;
  final String id;
  final Lox da;
  final String? comment;
  final List<String> codes;
  final List<Lox?> net;
  final List<Lox>? newt;
  final List<Lox?>? nwewt;

  AggregationEntityGOOD({
    required this.createdBy,
    required this.itemsCount,
    required this.price,
    required this.id,
    required this.da,
    this.comment,
    required this.codes,
    required this.net,
    this.newt,
    this.nwewt,
  });
}
