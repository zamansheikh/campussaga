import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/domain/entities/university.dart';
import 'package:campus_saga/presentation/bloc/admin/admin_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddUniversityPage extends StatefulWidget {
  const AddUniversityPage({Key? key}) : super(key: key);

  @override
  _AddUniversityPageState createState() => _AddUniversityPageState();
}

class _AddUniversityPageState extends State<AddUniversityPage> {
  final TextEditingController uidController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController logoUrlController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController researchScoreController = TextEditingController();
  final TextEditingController qsRankingScoreController =
      TextEditingController();
  final TextEditingController totalPostsController = TextEditingController();
  final TextEditingController totalSolvedPostsController =
      TextEditingController();
  final TextEditingController agreesController = TextEditingController();
  final TextEditingController disagreesController = TextEditingController();
  final TextEditingController studentCountController = TextEditingController();
  final TextEditingController facultyCountController = TextEditingController();
  final TextEditingController programsOfferedController =
      TextEditingController();
  final TextEditingController establishmentYearController =
      TextEditingController();
  final TextEditingController academicScoreController = TextEditingController();
  bool isPublic = false;

  University _addUniversity() {
    final String id = uidController.text;
    final String name = nameController.text;
    final String description = descriptionController.text;
    final String logoUrl = logoUrlController.text;
    final String location = locationController.text;
    final double researchScore =
        double.tryParse(researchScoreController.text) ?? 0.0;
    final double qsRankingScore =
        double.tryParse(qsRankingScoreController.text) ?? 0.0;
    final int totalPosts = int.tryParse(totalPostsController.text) ?? 0;
    final int totalSolvedPosts =
        int.tryParse(totalSolvedPostsController.text) ?? 0;
    final int agrees = int.tryParse(agreesController.text) ?? 0;
    final int disagrees = int.tryParse(disagreesController.text) ?? 0;
    final int studentCount = int.tryParse(studentCountController.text) ?? 0;
    final int facultyCount = int.tryParse(facultyCountController.text) ?? 0;
    final int programsOffered =
        int.tryParse(programsOfferedController.text) ?? 0;
    final int establishmentYear =
        int.tryParse(establishmentYearController.text) ?? 0;
    final double academicScore =
        double.tryParse(academicScoreController.text) ?? 0.0;
    final university = University(
      id: id,
      name: name,
      description: description,
      logoUrl: logoUrl,
      location: location,
      isPublic: isPublic,
      researchScore: researchScore,
      qsRankingScore: qsRankingScore,
      totalPosts: totalPosts,
      totalSolvedPosts: totalSolvedPosts,
      agrees: agrees,
      disagrees: disagrees,
      studentCount: studentCount,
      facultyCount: facultyCount,
      programsOffered: programsOffered,
      establishmentYear: establishmentYear,
      academicScore: academicScore,
    );
    return university;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        title: const Text('Add University',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add University Details Below and Click on Add University',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: uidController,
              decoration: const InputDecoration(
                labelText: 'University ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'University Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: logoUrlController,
              decoration: const InputDecoration(
                labelText: 'Logo URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Public'),
              value: isPublic,
              onChanged: (value) {
                setState(() {
                  isPublic = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: researchScoreController,
              decoration: const InputDecoration(
                labelText: 'Research Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qsRankingScoreController,
              decoration: const InputDecoration(
                labelText: 'QS Ranking Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalPostsController,
              decoration: const InputDecoration(
                labelText: 'Total Posts',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalSolvedPostsController,
              decoration: const InputDecoration(
                labelText: 'Total Solved Posts',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: agreesController,
              decoration: const InputDecoration(
                labelText: 'Agrees',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: disagreesController,
              decoration: const InputDecoration(
                labelText: 'Disagrees',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentCountController,
              decoration: const InputDecoration(
                labelText: 'Student Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: facultyCountController,
              decoration: const InputDecoration(
                labelText: 'Faculty Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: programsOfferedController,
              decoration: const InputDecoration(
                labelText: 'Programs Offered',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: establishmentYearController,
              decoration: const InputDecoration(
                labelText: 'Establishment Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: academicScoreController,
              decoration: const InputDecoration(
                labelText: 'Academic Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            BlocConsumer(
              bloc: sl<AdminBloc>(),
              listener: (context, state) {
                if (state is AdminError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage),
                    ),
                  );
                } else if (state is AdminSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AdminLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final university = _addUniversity();
                      context.read<AdminBloc>().add(AddUniversity(university));
                    },
                    child: const Text('Add University'),
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
