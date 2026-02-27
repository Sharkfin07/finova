// GENERATED-like code — manual Hive TypeAdapter for TransactionModel
part of 'transaction_model.dart';

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as String,
      category: fields[4] as String,
      title: fields[5] as String,
      walletId: fields[6] as String,
      date: fields[7] as DateTime,
      notes: fields[8] as String?,
      tags: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(10) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.walletId)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.tags);
  }
}
