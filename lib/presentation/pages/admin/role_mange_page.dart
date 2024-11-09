import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/domain/entities/role_change.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/presentation/bloc/role_manage/role_change_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleMangePage extends StatefulWidget {
  final User user;
  const RoleMangePage({required this.user, super.key});

  @override
  State<RoleMangePage> createState() => _RoleMangePageState();
}

class _RoleMangePageState extends State<RoleMangePage> {
  List<RoleChange> roleChanges = [];
  @override
  void initState() {
    sl<RoleChangeBloc>().add(FetchRoleChangeEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Role Change Requests",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<RoleChangeBloc, RoleChangeState>(
        builder: (context, state) {
          if (state is RoleChangeLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is RoleChangeSuccess) {
            roleChanges = state.roleChangeList;
            return ListView.builder(
              itemCount: roleChanges.length,
              itemBuilder: (context, index) {
                final roleChange = roleChanges[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage(roleChange.profilePicture),
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roleChange.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                roleChange.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${roleChange.role}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.admin_panel_settings_sharp,
                                  color: Colors.green),
                              onPressed: () {
                                print("approved");
                                context
                                    .read<RoleChangeBloc>()
                                    .add(RoleChangeAccepted(roleChange.copyWith(
                                      status: "approved",
                                      role: "admin",
                                    )));
                              },
                            ),
                            IconButton(
                              iconSize: 20,
                              icon:
                                  const Icon(Icons.school, color: Colors.green),
                              onPressed: () {
                                print("approved");
                                context
                                    .read<RoleChangeBloc>()
                                    .add(RoleChangeAccepted(roleChange.copyWith(
                                      status: "approved",
                                      role: "university",
                                    )));
                              },
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                print("rejected");
                                context
                                    .read<RoleChangeBloc>()
                                    .add(RoleChangeAccepted(roleChange.copyWith(
                                      status: "rejected",
                                    )));
                              },
                            ),
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.fact_check_outlined,
                                  color: Colors.red),
                              onPressed: () {
                                print("Ambassador");
                                context
                                    .read<RoleChangeBloc>()
                                    .add(RoleChangeAccepted(roleChange.copyWith(
                                      role: "ambassador",
                                      status: "Ambassador",
                                    )));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is RoleChangeFailure) {
            return Center(
              child: Text(state.message),
            );
          }
          return Container();
        },
      ),
    );
  }
}
