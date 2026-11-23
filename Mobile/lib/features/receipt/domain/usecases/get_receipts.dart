import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';

class GetReceipts implements UseCase<ReceiptsPage, GetReceiptsParams> {
  const GetReceipts(this._repository);
  final ReceiptRepository _repository;

  @override
  Future<Result<ReceiptsPage>> call(GetReceiptsParams params) =>
      _repository.getReceipts(offset: params.offset, limit: params.limit);
}

class GetReceiptsParams extends Equatable {
  const GetReceiptsParams({required this.offset, required this.limit});
  final int offset;
  final int limit;

  @override
  List<Object?> get props => [offset, limit];
}
