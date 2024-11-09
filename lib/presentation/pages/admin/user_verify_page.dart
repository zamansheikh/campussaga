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
        centerTitle: true,
        forceMaterialTransparency: true,
        title: const Text('User Verifications'),
      ),
      body: BlocConsumer<VerifyUserBloc, VerifyUserState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is VerifyUserLoaded) {
            return ListView.builder(
              itemCount: state.verifications.length,
              itemBuilder: (context, index) {
                final verification = state.verifications[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Information Section
                        Text(
                          'User Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text('UUID: ${verification.userUuid}'),
                        Text('Email: ${verification.universityEmail}'),
                        Text('Phone: ${verification.phoneNumber}'),
                        Text('DOB: ${verification.dateOfBirth}'),
                        Text('Department: ${verification.department}'),
                        Text('Gender: ${verification.gender}'),
                        const Divider(),

                        // Images Section with full-screen preview on tap
                        Text(
                          'Photos',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ImageCard(
                                imageUrl: verification.universityIdCardPhotoUrl,
                                label: 'ID Card',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ImageCard(
                                imageUrl: verification.profilePhotoUrl,
                                label: 'Profile Photo',
                              ),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Status Section
                        Text(
                          'Verification Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          verification.status.toString().split('.').last,
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ActionButton(
                              label: 'Accept',
                              color: Colors.green,
                              onPressed: () {
                                final veri = verification.copyWith(
                                    status: VerificationStatus.verified);
                                sl<VerifyUserBloc>().add(
                                  VerifyUserAcceptedEvent(verification: veri),
                                );
                              },
                            ),
                            ActionButton(
                              label: 'Reject',
                              color: Colors.red,
                              onPressed: () {
                                final veri = verification.copyWith(
                                    status: VerificationStatus.rejected);
                                sl<VerifyUserBloc>().add(
                                  VerifyUserRejectedEvent(verification: veri),
                                );
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
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class ImageCard extends StatelessWidget {
  final String imageUrl;
  final String label;
  const ImageCard({required this.imageUrl, required this.label, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, imageUrl);
      },
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.90,
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}
