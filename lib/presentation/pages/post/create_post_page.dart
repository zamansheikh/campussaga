import 'package:campus_saga/core/constants/dummypost.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/bloc/post/post_bloc.dart';
import 'package:campus_saga/presentation/bloc/post/post_event.dart';
import 'package:campus_saga/presentation/bloc/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const CreatePostPage({Key? key, this.onPostCreated}) : super(key: key);
  // In your post creation success logic:
  void _handlePostCreated() {
    // Call the callback if provided
    onPostCreated?.call();
  }

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<File> selectedImages = [];

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        title: Text(
          "Campus Saga",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Post Title",
                hintText: "Enter the post title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Post Description",
                hintText: "Describe the issue or share information",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Selected Images:",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => removeImage(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              const Text("No images selected."),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Select Images"),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (authcontext, state) {
                if (state is AuthAuthenticated) {
                  final user = state.user;
                  return BlocConsumer<PostBloc, PostState>(
                    listener: (postcontext, poststate) {
                      if (poststate is PostingSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Post created successfully"),
                          ),
                        );
                        widget._handlePostCreated();
                        //Clear the all TextFields and selectedImages
                        titleController.clear();
                        descriptionController.clear();
                        setState(() {
                          selectedImages.clear();
                        });
                      } else if (poststate is PostingFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Post creation failed: ${poststate.message}"),
                          ),
                        );
                      }
                    },
                    builder: (postcontext, poststate) {
                      if (poststate is PostingLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        return Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final post = postGenerate(
                                  user,
                                  titleController.text,
                                  descriptionController.text);
                              BlocProvider.of<PostBloc>(context)
                                  .add(PostCreated(
                                post,
                                selectedImages,
                              ));
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 40.0),
                              child:
                                  Text("Post", style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        );
                      }
                    },
                  );
                } else {
                  return const Center(
                    child: Text("You are not authenticated"),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
