import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/presentation/bloc/verify_user/verify_user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserVerifyPage extends StatefulWidget {
  const UserVerifyPage({super.key});

  @override
  State<UserVerifyPage> createState() => _UserVerifyPageState();
}

class _UserVerifyPageState extends State<UserVerifyPage> {
  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    sl<VerifyUserBloc>()
        .add(PendingVerificationLoadedEvent(universtiyId: "DIU"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Verifications'),
      ),
      body: BlocConsumer<VerifyUserBloc, VerifyUserState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          if (state is VerifyUserLoaded) {
            return ListView.builder(
              itemCount: state.verifications.length,
              itemBuilder: (context, index) {
                final verification = state.verifications[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User UUID: ${verification.userUuid}'),
                        Text(
                            'University Email: ${verification.universityEmail}'),
                        Text('Phone Number: ${verification.phoneNumber}'),
                        Text('Date of Birth: ${verification.dateOfBirth}'),
                        Text('Department: ${verification.department}'),
                        Text('Gender: ${verification.gender}'),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              verification.universityIdCardPhotoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              verification.profilePhotoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Status: ${verification.status.toString().split('.').last}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                final veri = verification.copyWith(
                                    status: VerificationStatus.verified);
                                sl<VerifyUserBloc>().add(
                                  VerifyUserAcceptedEvent(verification: veri),
                                );
                              },
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final veri = verification.copyWith(
                                    status: VerificationStatus.rejected);
                                sl<VerifyUserBloc>().add(
                                  VerifyUserRejectedEvent(verification: veri),
                                );
                              },
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
