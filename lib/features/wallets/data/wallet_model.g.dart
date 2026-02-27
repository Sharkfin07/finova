// GENERATED-like code — manual Hive TypeAdapter for WalletModel
import 'package:hive/hive.dart';
import 'wallet_model.dart';

class WalletModelAdapter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 1;

  @override
  WalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      balance: fields[3] as double,
      icon: fields[4] as String? ?? 'account_balance',
      color: fields[5] as String? ?? '0xFF2ECC71',
      accountNumber: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(7) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.accountNumber);
  }
}
