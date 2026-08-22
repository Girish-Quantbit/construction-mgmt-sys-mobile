import 'package:flutter_test/flutter_test.dart';
import 'package:cms/core/error/failures.dart';

void main() {
  test('Should clean erpnext exception from JSON format', () {
    const rawException = '{"exception":"erpnext.controllers.buying_controller.QtyMismatchError: Row #1: Received Qty must be equal to Accepted + Rejected Qty for Item <strong>ITEM-001</strong>.","exc_type":"QtyMismatchError","_exc_source":"erpnext (app)","exc":"[\\"Traceback...\\"]"}';

    final failure = ServerFailure(rawException);
    expect(
      failure.message,
      'Row #1: Received Qty must be equal to Accepted + Rejected Qty for Item ITEM-001.',
    );
  });

  test('Should clean erpnext exception from raw string format', () {
    const rawException = 'Exception: erpnext.controllers.buying_controller.QtyMismatchError: Row #1: Received Qty must be equal to Accepted + Rejected Qty for Item <strong>ITEM-001</strong>.';

    final failure = ServerFailure(rawException);
    expect(
      failure.message,
      'Row #1: Received Qty must be equal to Accepted + Rejected Qty for Item ITEM-001.',
    );
  });
}
