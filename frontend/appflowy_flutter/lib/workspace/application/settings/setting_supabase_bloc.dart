import 'package:appflowy/plugins/database_view/application/defines.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

import 'cloud_setting_listener.dart';

part 'setting_supabase_bloc.freezed.dart';

class SupabaseCloudSettingBloc
    extends Bloc<SupabaseCloudSettingEvent, SupabaseCloudSettingState> {
  final UserCloudConfigListener _listener;

  SupabaseCloudSettingBloc({
    required String userId,
    required CloudSettingPB config,
  })  : _listener = UserCloudConfigListener(userId: userId),
        super(SupabaseCloudSettingState.initial(config)) {
    on<SupabaseCloudSettingEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _listener.start(
            onSettingChanged: (result) {
              if (isClosed) {
                return;
              }

              result.fold(
                (config) =>
                    add(SupabaseCloudSettingEvent.didReceiveConfig(config)),
                (error) => Log.error(error),
              );
            },
          );
        },
        enableSync: (bool enable) async {
          final update = UpdateCloudConfigPB.create()..enableSync = enable;
          updateCloudConfig(update);
        },
        didReceiveConfig: (CloudSettingPB config) {
          emit(
            state.copyWith(
              config: config,
              loadingState: LoadingState.finish(left(unit)),
            ),
          );
        },
        enableEncrypt: (bool enable) {
          final update = UpdateCloudConfigPB.create()..enableEncrypt = enable;
          updateCloudConfig(update);
          emit(state.copyWith(loadingState: const LoadingState.loading()));
        },
      );
    });
  }

  Future<void> updateCloudConfig(UpdateCloudConfigPB config) async {
    await UserEventSetCloudConfig(config).send();
  }
}

@freezed
class SupabaseCloudSettingEvent with _$SupabaseCloudSettingEvent {
  const factory SupabaseCloudSettingEvent.initial() = _Initial;
  const factory SupabaseCloudSettingEvent.didReceiveConfig(
    CloudSettingPB config,
  ) = _DidSyncSupabaseConfig;
  const factory SupabaseCloudSettingEvent.enableSync(bool enable) = _EnableSync;
  const factory SupabaseCloudSettingEvent.enableEncrypt(bool enable) =
      _EnableEncrypt;
}

@freezed
class SupabaseCloudSettingState with _$SupabaseCloudSettingState {
  const factory SupabaseCloudSettingState({
    required CloudSettingPB config,
    required Either<Unit, String> successOrFailure,
    required LoadingState loadingState,
  }) = _SupabaseCloudSettingState;

  factory SupabaseCloudSettingState.initial(CloudSettingPB config) =>
      SupabaseCloudSettingState(
        config: config,
        successOrFailure: left(unit),
        loadingState: LoadingState.finish(left(unit)),
      );
}
