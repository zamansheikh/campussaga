import 'dart:io';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/bloc/varify/varification_bloc.dart';
import 'package:campus_saga/presentation/pages/profile/update_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class VerificationPage extends StatefulWidget {
  final User user;
  const VerificationPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  XFile? selfieImage;
  XFile? idCardImage;
  final ImagePicker _picker = ImagePicker();
  File? selfieFile;
  File? idCardFile;

  Future<void> _takeSelfie() async {
    final image = await _picker.pickImage(
        preferredCameraDevice: CameraDevice.front,
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400);
    if (image != null) {
      setState(() {
        selfieImage = image;
        selfieFile = File(image.path);
      });
    }
  }

  Future<void> _takeIdCardPhoto() async {
    final image = await _picker.pickImage(
      preferredCameraDevice: CameraDevice.rear,
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        idCardImage = image;
        idCardFile = File(image.path);
      });
    }
  }

  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        title: Text(
          'Verification Page',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            user = state.user;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Upload Live Selfie',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _takeSelfie,
                      child: Container(
                        height: 155,
                        width: MediaQuery.of(context).size.width * .45,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: selfieImage == null
                            ? Center(
                                child: Icon(Icons.camera_alt,
                                    size: 50, color: Colors.grey[700]),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(selfieImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Upload University ID Card',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _takeIdCardPhoto,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: idCardImage == null
                            ? Center(
                                child: Icon(Icons.camera_alt,
                                    size: 50, color: Colors.grey[700]),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(idCardImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      'Personal Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Phone Number: ${user.phoneNumber}'),
                    Text('Date of Birth: ${user.dateOfBirth}'),
                    Text('Department: ${user.department}'),
                    Text('Gender: ${user.gender}'),
                    Text('User UUID: ${user.id}'),
                    Text('University Email: ${user.email}'),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<VarificationBloc, VarificationState>(
          listener: (context, state) {
            if (state is VarificationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification request submitted successfully'),
                ),
              );
              Navigator.pop(context);
            } else if (state is VarificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit verification request'),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is VarificationInProgress) {
              return ElevatedButton(
                onPressed: null,
                child: CircularProgressIndicator(),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              );
            }

            return ElevatedButton(
              onPressed: () {
                // Check if required user information fields are null
                final missingFields = <String>[];
                if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
                  missingFields.add("Phone Number");
                }
                if (user.dateOfBirth == null) {
                  missingFields.add("Date of Birth");
                }
                if (user.department == null) {
                  missingFields.add("Department");
                }
                if (user.gender == null || user.gender!.isEmpty) {
                  missingFields.add("Gender");
                }
                if (missingFields.isNotEmpty) {
                  final missingFieldsText = missingFields.join(", ");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'The following fields are missing: $missingFieldsText. '
                        'Please update them from the profile edit page.',
                      ),
                    ),
                  );
                  //show alert dialog - Are you want to update the profile yes or not
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Update Profile'),
                        content: Text(
                          'The following fields are missing: $missingFieldsText. '
                          '\nDo you want to update them now?'
                          'After Update, go back to profile and Refresh the page',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          UpdateProfilePage(user: user)));
                            },
                            child: Text('Yes'),
                          ),
                        ],
                      );
                    },
                  );
                }
                if (selfieFile == null || idCardFile == null) {
                  if (missingFields.isNotEmpty) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please upload both images'),
                    ),
                  );
                  return;
                }
                final verificationEntity = Verification(
                  userUuid: user.id,
                  universityEmail: user.email,
                  universityIdCardPhotoUrl: "",
                  profilePhotoUrl: user.profilePictureUrl,
                  status: VerificationStatus.pending,
                  phoneNumber: '',
                  dateOfBirth: user.dateOfBirth ?? DateTime.now(),
                  department: user.department?.toString() ?? '',
                  gender: user.gender ?? '',
                  timestamp: DateTime.now(),
                );
                context.read<VarificationBloc>().add(SubmitVerification(
                    verification: verificationEntity,
                    files: [selfieFile!, idCardFile!]));
              },
              child: Text('Submit Verification'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
            );
          },
        ),
      ),
    );
  }
  //Write function to compress image file
}
