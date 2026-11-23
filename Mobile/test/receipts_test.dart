import 'package:bbmobile/core/error/failures.dart';
import 'package:bbmobile/core/result.dart';
import 'package:bbmobile/features/receipt/data/models/receipt_model.dart';
import 'package:bbmobile/features/receipt/domain/entities/receipt.dart';
import 'package:bbmobile/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:bbmobile/features/receipt/domain/usecases/get_receipts.dart';
import 'package:bbmobile/features/receipt/presentation/bloc/receipts_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ReceiptRepository {}

Receipt _receipt(String hash) => Receipt(
      hash: hash,
      fromAddress: '0xa',
      toAddress: '0xb',
      type: ReceiptType.tokenTransfer,
      success: true,
    );

void main() {
  group('ReceiptModel', () {
    test('parses a page, including a pending entry without block data', () {
      final page = ReceiptModel.pageFromJson({
        'offset': 0,
        'limit': 20,
        'total': 2,
        'result': [
          {
            'hash': '0x1',
            'fromAddress': 'BB_Internal_Account',
            'toAddress': '0xabc',
            'blockNumber': 7,
            'gasUsed': 21000,
            'effectiveGasPrice': 2,
            'transactionType': 'FUNDING',
            'success': true,
          },
          {'hash': '0x2', 'fromAddress': '0xa', 'toAddress': '0xb', 'transactionType': 'TOKEN_TRANSFER'},
        ],
      });
      expect(page.total, 2);
      expect(page.receipts[0].type, ReceiptType.funding);
      expect(page.receipts[0].status, ReceiptStatus.confirmed);
      expect(page.receipts[0].feeWei, BigInt.from(42000));
      expect(page.receipts[1].status, ReceiptStatus.pending);
      expect(page.receipts[1].blockNumber, isNull);
    });
  });

  group('ReceiptsBloc', () {
    late _MockRepo repo;
    late ReceiptsBloc bloc;

    setUp(() {
      repo = _MockRepo();
      bloc = ReceiptsBloc(getReceipts: GetReceipts(repo));
    });

    tearDown(() => bloc.close());

    test('loads the first page then appends the next one without duplicates', () async {
      when(() => repo.getReceipts(offset: 0, limit: ReceiptsBloc.pageSize)).thenAnswer(
        (_) async => Success(ReceiptsPage(offset: 0, total: 3, receipts: [_receipt('a'), _receipt('b')])),
      );
      when(() => repo.getReceipts(offset: 2, limit: ReceiptsBloc.pageSize)).thenAnswer(
        (_) async => Success(ReceiptsPage(offset: 2, total: 3, receipts: [_receipt('b'), _receipt('c')])),
      );

      bloc.add(const ReceiptsRequested());
      await bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.loaded);
      expect(bloc.state.hasMore, isTrue);

      bloc.add(const ReceiptsMoreRequested());
      await bloc.stream.firstWhere((s) => !s.isLoadingMore && s.receipts.length > 2);
      expect(bloc.state.receipts.map((r) => r.hash), ['a', 'b', 'c']);
      expect(bloc.state.hasMore, isFalse);
    });

    test('shows a failure when the first load fails', () async {
      when(() => repo.getReceipts(offset: 0, limit: ReceiptsBloc.pageSize))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      bloc.add(const ReceiptsRequested());
      final state = await bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.failure);
      expect(state.receipts, isEmpty);
      expect(state.errorMessage, isNotNull);
    });
  });
}
