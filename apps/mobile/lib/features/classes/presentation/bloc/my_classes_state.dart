part of 'my_classes_cubit.dart';

/// The signed-in student's class groups and routine.
class MyClassesState extends Equatable {
  const MyClassesState({
    this.userId,
    this.groups = const [],
    this.personal = const [],
    this.loaded = false,
    this.refreshing = false,
    this.failure,
  });

  final String? userId;
  final List<ClassGroup> groups;

  /// The student's own classes (only they see them).
  final List<ClassSlot> personal;

  /// Everything for Today, Routine and reminders: the groups plus the
  /// personal classes as a pseudo-group.
  List<ClassGroup> get routine => [
    ...groups,
    if (personal.isNotEmpty) ClassGroup.personal(personal),
  ];

  /// True once groups came from the phone or the server.
  final bool loaded;
  final bool refreshing;

  /// The last refresh failed (offline): the saved routine is still shown.
  final Failure? failure;

  bool get hasGroups => groups.isNotEmpty;

  ClassGroup? group(String id) {
    if (id == personalGroupId) return ClassGroup.personal(personal);
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  MyClassesState copyWith({
    List<ClassGroup>? groups,
    List<ClassSlot>? personal,
    bool? loaded,
    bool? refreshing,
    Failure? Function()? failure,
  }) => MyClassesState(
    userId: userId,
    groups: groups ?? this.groups,
    personal: personal ?? this.personal,
    loaded: loaded ?? this.loaded,
    refreshing: refreshing ?? this.refreshing,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    userId,
    groups,
    personal,
    loaded,
    refreshing,
    failure,
  ];
}
