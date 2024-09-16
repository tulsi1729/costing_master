import 'package:costing_master/common/extension/error_text.dart';
import 'package:costing_master/common/extension/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension WhenAsyncValue<T> on AsyncValue<T> {
  Widget whenWidget(Widget Function(T) data) => when(
        data: data,
        error: (error, stackTrace) => ErrorText(
            error: error.toString(), stackTrace: stackTrace.toString()),
        loading: Loader.new,
      );
}
