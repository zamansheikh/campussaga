import 'dart:io';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/domain/entities/varification_status.dart';
import 'package:campus_saga/presentation/bloc/varify/varification_bloc.dart';
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
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        selfieImage = image;
        selfieFile = File(image.path);
      });
    }
  }

  Future<void> _takeIdCardPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        idCardImage = image;
        idCardFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Live Selfie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _takeSelfie,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: selfieImage == null
                      ? Icon(Icons.camera_alt, size: 50)
                      : Image.file(
                          File(selfieImage!.path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Upload University ID Card',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _takeIdCardPhoto,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: idCardImage == null
                      ? Icon(Icons.camera_alt, size: 50)
                      : Image.file(
                          File(idCardImage!.path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Phone Number: ${widget.user.phoneNumber}'),
              Text('Date of Birth: ${widget.user.dateOfBirth}'),
              Text('Department: ${widget.user.department}'),
              Text('Gender: ${widget.user.gender}'),
              Text('User UUID: ${widget.user.id}'),
              Text('University Email: ${widget.user.email}'),
              SizedBox(height: 20),
            ],
          ),
        ),
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
                if (selfieFile == null || idCardFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please upload both images'),
                    ),
                  );
                  return;
                }
                // Check if required user information fields are null
                final missingFields = <String>[];
                if (widget.user.phoneNumber == null ||
                    widget.user.phoneNumber!.isEmpty) {
                  missingFields.add("Phone Number");
                }
                if (widget.user.dateOfBirth == null) {
                  missingFields.add("Date of Birth");
                }
                if (widget.user.department == null) {
                  missingFields.add("Department");
                }
                if (widget.user.gender == null || widget.user.gender!.isEmpty) {
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
                  return;
                }
                final verificationEntity = Verification(
                  userUuid: widget.user.id,
                  universityEmail: widget.user.email,
                  universityIdCardPhotoUrl: "",
                  profilePhotoUrl: '',
                  status: VerificationStatus.pending,
                  phoneNumber: '',
                  dateOfBirth: widget.user.dateOfBirth ?? DateTime.now(),
                  department: widget.user.department?.toString() ?? '',
                  gender: widget.user.gender ?? '',
                  timestamp: DateTime.now(),
                );
                context.read<VarificationBloc>().add(SubmitVerification(
                    verification: verificationEntity,
                    files: [selfieFile!, idCardFile!]));
              },
              child: Text('Submit Verification'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            );
          },
        ),
      ),
    );
  }
}
