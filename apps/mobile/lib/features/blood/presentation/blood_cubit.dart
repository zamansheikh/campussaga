import 'package:campus_core/campus_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class BloodState extends Equatable {
  const BloodState({
    this.loading = true,
    this.donor,
    this.open = const [],
    this.mine = const [],
    this.myGroupOnly = false,
    this.failure,
  });

  final bool loading;

  /// The student's donor profile (null: not a donor).
  final Donor? donor;
  final List<BloodRequest> open;
  final List<BloodRequest> mine;

  /// Only requests for the donor's own group.
  final bool myGroupOnly;
  final Failure? failure;

  /// Open requests as shown (the "My group" filter applied).
  List<BloodRequest> get shown {
    final g = donor?.bloodGroup;
    if (!myGroupOnly || g == null) return open;
    return [
      for (final r in open)
        if (r.bloodGroup == g) r,
    ];
  }

  BloodState copyWith({
    bool? loading,
    Donor? Function()? donor,
    List<BloodRequest>? open,
    List<BloodRequest>? mine,
    bool? myGroupOnly,
    Failure? Function()? failure,
  }) => BloodState(
    loading: loading ?? this.loading,
    donor: donor != null ? donor() : this.donor,
    open: open ?? this.open,
    mine: mine ?? this.mine,
    myGroupOnly: myGroupOnly ?? this.myGroupOnly,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [loading, donor, open, mine, myGroupOnly, failure];
}

/// The blood donation page: the student's donor profile, open requests at
/// the university and their own requests. Actions return the failure to
/// show (null = done).
class BloodCubit extends Cubit<BloodState> {
  BloodCubit(this._repo) : super(const BloodState());

  final BloodRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: () => null));
    try {
      final results = await Future.wait<Object?>([
        _repo.me(),
        _repo.requests(),
        _repo.requests(mine: true),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          donor: () => results[0] as Donor?,
          open: (results[1]! as BloodRequestList).items,
          mine: (results[2]! as BloodRequestList).items,
        ),
      );
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(loading: false, failure: () => f));
    }
  }

  void setMyGroupOnly(bool on) => emit(state.copyWith(myGroupOnly: on));

  Future<Failure?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  Future<Failure?> saveDonor(DonorInput input) => _run(() async {
    final d = await _repo.saveDonor(input);
    if (!isClosed) emit(state.copyWith(donor: () => d));
  });

  Future<Failure?> setAvailable(bool on) async {
    final d = state.donor;
    if (d == null) return null;
    return saveDonor(
      DonorInput(
        bloodGroup: d.bloodGroup,
        available: on,
        phone: d.phone,
        lastDonated: d.lastDonated,
      ),
    );
  }

  Future<Failure?> leaveDonors() => _run(() async {
    await _repo.leaveDonors();
    if (!isClosed) emit(state.copyWith(donor: () => null, myGroupOnly: false));
  });

  Future<Failure?> donatedToday() => _run(() async {
    final d = await _repo.donated();
    if (!isClosed) emit(state.copyWith(donor: () => d));
  });

  /// A request changed on its own page (responded, closed).
  void updated(BloodRequest r) {
    List<BloodRequest> swap(List<BloodRequest> list) => [
      for (final x in list) x.id == r.id ? r : x,
    ];
    emit(
      state.copyWith(
        open: r.isOpen
            ? swap(state.open)
            : [
                for (final x in state.open)
                  if (x.id != r.id) x,
              ],
        mine: swap(state.mine),
      ),
    );
  }
}

final class BloodRequestState extends Equatable {
  const BloodRequestState({
    this.request,
    this.donor,
    this.loading = true,
    this.busy = false,
    this.failure,
  });

  final BloodRequest? request;

  /// The student's donor profile (for "I can donate").
  final Donor? donor;
  final bool loading;
  final bool busy;
  final Failure? failure;

  BloodRequestState copyWith({
    BloodRequest? request,
    Donor? Function()? donor,
    bool? loading,
    bool? busy,
    Failure? Function()? failure,
  }) => BloodRequestState(
    request: request ?? this.request,
    donor: donor != null ? donor() : this.donor,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [request, donor, loading, busy, failure];
}

/// One request: respond, withdraw, or (the requester) close it.
class BloodRequestCubit extends Cubit<BloodRequestState> {
  BloodRequestCubit(this._repo, this.id) : super(const BloodRequestState());

  final BloodRepository _repo;
  final String id;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: () => null));
    try {
      final results = await Future.wait<Object?>([
        _repo.request(id),
        _repo.me(),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          request: results[0]! as BloodRequest,
          donor: () => results[1] as Donor?,
        ),
      );
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(loading: false, failure: () => f));
    }
  }

  Future<Failure?> _act(Future<BloodRequest> Function() action) async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true));
    try {
      final r = await action();
      if (!isClosed) emit(state.copyWith(request: r, busy: false));
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return f;
    }
  }

  Future<Failure?> respond(String phone) =>
      _act(() => _repo.respond(id, phone));

  Future<Failure?> withdraw() => _act(() => _repo.withdraw(id));

  Future<Failure?> finish({required bool fulfilled}) =>
      _act(() => _repo.close(id, fulfilled: fulfilled));

  /// Became a donor from this page (to respond).
  void donorSaved(Donor d) => emit(state.copyWith(donor: () => d));
}
