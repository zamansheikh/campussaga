import 'package:campus_saga/core/constants/dummypost.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/bloc/post/post_bloc.dart';
import 'package:campus_saga/presentation/bloc/post/post_event.dart';
import 'package:campus_saga/presentation/bloc/post/post_state.dart';
import 'package:campus_saga/presentation/bloc/promotion/promotion_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  final void Function(int index)? onPostCreated;

  const CreatePostPage({Key? key, this.onPostCreated}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController eventLinkController = TextEditingController();
  final TextEditingController clubNameController = TextEditingController();
  final List<File> selectedImages = [];
  String? postType;

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

  void handlePostCreation(int index) {
    widget.onPostCreated?.call(index);
    titleController.clear();
    descriptionController.clear();
    eventLinkController.clear();
    clubNameController.clear();
    setState(() {
      selectedImages.clear();
      postType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Text(
          "Create Post",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications page
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create a New Post",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
              ),
              child: DropdownButtonFormField<String>(
                value: postType,
                items: ["Problem", "Promotional"].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(type),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    postType = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Post Type",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Post Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            if (postType == "Promotional") ...[
              const SizedBox(height: 16),
              TextField(
                controller: clubNameController,
                decoration: const InputDecoration(
                  labelText: "Club Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: eventLinkController,
                decoration: const InputDecoration(
                  labelText: "Event Link",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              "Attachment",
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
                  return MultiBlocListener(
                    listeners: [
                      BlocListener<PostBloc, PostState>(
                        listener: (postcontext, poststate) {
                          if (poststate is PostingSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Post created successfully"),
                              ),
                            );
                            handlePostCreation(0);
                          } else if (poststate is PostingFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Post creation failed: ${poststate.message}"),
                              ),
                            );
                          }
                        },
                      ),
                      BlocListener<PromotionBloc, PromotionState>(
                        listener: (promotioncontext, promotionstate) {
                          if (promotionstate is PromotionPostingSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Promotion created successfully"),
                              ),
                            );
                            handlePostCreation(1);
                          } else if (promotionstate
                              is PromotionPostingFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Promotion creation failed: ${promotionstate.message}"),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    child: Column(
                      children: [
                        BlocBuilder<PostBloc, PostState>(
                          builder: (postcontext, poststate) {
                            if (poststate is PostingLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                        BlocBuilder<PromotionBloc, PromotionState>(
                          builder: (promotioncontext, promotionstate) {
                            if (promotionstate is PromotionPostingLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (postType == "Problem") {
                                final post = postGenerate(
                                  user,
                                  titleController.text,
                                  descriptionController.text,
                                );
                                BlocProvider.of<PostBloc>(context)
                                    .add(PostCreated(post, selectedImages));
                              } else if (postType == "Promotional") {
                                final promotion = promotionGenerate(
                                  user,
                                  titleController.text,
                                  descriptionController.text,
                                  clubNameController.text,
                                  eventLinkController.text,
                                  DateTime.now().add(const Duration(days: 7)),
                                );
                                if (selectedImages.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Please select at least one image"),
                                    ),
                                  );
                                  return;
                                }
                                BlocProvider.of<PromotionBloc>(context).add(
                                    PromotionPostCreated(
                                        promotion, selectedImages));
                                print("Promotional post");
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 40.0),
                              child: Text("Create Post",
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ),
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
