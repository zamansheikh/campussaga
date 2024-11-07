import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_event.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateProfilePage extends StatefulWidget {
  final User user;

  const UpdateProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController guardianPhoneController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController interestsController = TextEditingController();
  final TextEditingController cgpaController = TextEditingController();
  final TextEditingController batchController = TextEditingController();

  Department? selectedDepartment;
  String? selectedBloodGroup;
  String? selectedGender;
  DateTime? selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user.name;
    emailController.text = widget.user.email;
    phoneNumberController.text = widget.user.phoneNumber ?? '';
    addressController.text = widget.user.address ?? '';
    guardianPhoneController.text = widget.user.guardianPhone ?? '';
    skillsController.text = widget.user.skills?.join(', ') ?? '';
    interestsController.text = widget.user.interests?.join(', ') ?? '';
    cgpaController.text = widget.user.cgpa?.toString() ?? '';
    batchController.text = widget.user.batch?.toString() ?? '';
    selectedDepartment = widget.user.department;
    selectedBloodGroup = widget.user.bloodGroup;
    selectedGender = widget.user.gender;
    selectedDateOfBirth = widget.user.dateOfBirth;
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDateOfBirth) {
      setState(() {
        selectedDateOfBirth = picked;
      });
    }
  }

  void _updateProfile(BuildContext context) {
    context.read<AuthBloc>().add(
          AuthUpdateRequested(
            widget.user.copyWith(
              name: nameController.text,
              email: emailController.text,
              phoneNumber: phoneNumberController.text,
              address: addressController.text,
              guardianPhone: guardianPhoneController.text,
              skills: skillsController.text.split(', '),
              interests: interestsController.text.split(', '),
              cgpa: double.tryParse(cgpaController.text),
              batch: int.tryParse(batchController.text),
              dateOfBirth: selectedDateOfBirth,
              department: selectedDepartment,
              bloodGroup: selectedBloodGroup,
              gender: selectedGender,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Department>(
              value: selectedDepartment,
              onChanged: (newValue) {
                setState(() {
                  selectedDepartment = newValue;
                });
              },
              items: Department.values.map((dept) {
                return DropdownMenuItem(
                  value: dept,
                  child: Text(dept.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cgpaController,
              decoration: const InputDecoration(
                labelText: 'CGPA',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: batchController,
              decoration: const InputDecoration(
                labelText: 'Batch',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: guardianPhoneController,
              decoration: const InputDecoration(
                labelText: 'Guardian Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              onChanged: (newValue) {
                setState(() {
                  selectedBloodGroup = newValue;
                });
              },
              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map((bloodType) {
                return DropdownMenuItem(
                  value: bloodType,
                  child: Text(bloodType),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickDateOfBirth(context),
              child: Text(
                selectedDateOfBirth == null
                    ? 'Select Date of Birth'
                    : 'Date of Birth: ${selectedDateOfBirth!.toLocal()}'
                        .split(' ')[0],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGender,
              onChanged: (newValue) {
                setState(() {
                  selectedGender = newValue;
                });
              },
              items: ['Male', 'Female', 'Other'].map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is AuthAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: ElevatedButton(
                    onPressed: () => _updateProfile(context),
                    child: const Text('Update Profile'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
