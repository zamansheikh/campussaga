import 'package:campus_saga/app/data/providers/add_post_provider.dart';
import 'package:campus_saga/app/data/widgets/app_bar.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/add_post_controller.dart';

class AddPostView extends GetView<AddPostController> {
  final controller = Get.put(AddPostController());
  final postProvider = Get.put(PostProvider());
  AddPostView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true,
      backgroundColor: Color(0xFF207BFF),
      appBar: CustomAppBar(
          actionIcon: Icons.dark_mode,
          onPressedAction: () {
            Get.changeTheme(
              Get.isDarkMode ? ThemeData.light() : ThemeData.dark(),
            );
          },
          leadingIcon: Icons.info,
          onPressedLeading: () {
            _showAlertDialog("Campus Saga by deCodersFamily",
                "Our mission is to provide a platform for students to share their thoughts and ideas.");
          },
          title: "Posting"),
      body: Container(
        height: Get.height,
        width: Get.width,
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(bottom: 60),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  DropdownButtonFormField(
                    items: controller.postTypeList.map((e) {
                      return DropdownMenuItem(
                        child: Text(e),
                        value: e,
                      );
                    }).toList(),
                    onChanged: (val) {
                      controller.selectedPostType.value = val.toString();
                    },
                    value: controller.selectedPostType.value,
                    dropdownColor: Colors.white.withOpacity(1),
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        // border when the field is focused
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          width: 3,
                          color: Colors.black38,
                        ),
                      ),
                      enabled: true,
                      labelStyle: TextStyle(
                        color: Colors.black38,
                      ),
                      enabledBorder: OutlineInputBorder(
                        // border when the field is enabled
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          width: 3,
                          color: Colors.black38,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(.5),
                      labelText: "Post Type",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Form(
                    key: controller.formKey,
                    child: Column(children: [
                      SizedBox(height: 10),
                      TextField(
                        controller: controller.postHeadingController,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(
                              color: Colors.black38,
                            ),
                            focusedBorder: OutlineInputBorder(
                              // border when the field is focused
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                width: 3,
                                color: Colors.black38,
                              ),
                            ),

                            // enabled: true,
                            enabledBorder: OutlineInputBorder(
                              // border when the field is enabled
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                width: 3,
                                color: Colors.black38,
                              ),
                            ),
                            fillColor: Colors.white.withOpacity(.5),
                            filled: true,
                            labelText: "Title",
                            border: OutlineInputBorder(),
                            hintText: "Type a Title"),
                        keyboardType: TextInputType.multiline,
                        maxLines: 2,
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: controller.postDescriptionController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(.5),
                          labelText: "Type a Description !",
                          labelStyle: TextStyle(
                            color: Colors.black38,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              width: 10,
                              color: Colors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // border when the field is focused
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              width: 3,
                              color: Colors.black38,
                            ),
                          ),

                          // enabled: true,
                          enabledBorder: OutlineInputBorder(
                            // border when the field is enabled
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              width: 3,
                              color: Colors.black38,
                            ),
                          ),
                          hintText:
                              "Type a Description ! Describe your post in detail",
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: 8,
                      ),
                      SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          postProvider.picImage();
                        },
                        child: GetBuilder<PostProvider>(
                          builder: (controller) {
                            return Container(
                                width: Get.width,
                                height: 250,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 3, color: Colors.black38),
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white.withOpacity(.5)),
                                child: Obx(
                                  () => Center(
                                    child: Stack(
                                      children: [
                                        (postProvider.pickedImage.value == null)
                                            ? Icon(Icons.add_a_photo_rounded)
                                            : Image.file(
                                                postProvider.pickedImage.value!,
                                                fit: BoxFit.cover,
                                              ),
                                        Visibility(
                                          visible:
                                              postProvider.pickedImage.value !=
                                                  null,
                                          child: Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: IconButton(
                                                onPressed: () {
                                                  postProvider
                                                      .pickedImage.value = null;
                                                },
                                                icon: Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Colors.red,
                                                ),
                                              )),
                                        )
                                      ],
                                    ),
                                  ),
                                ));
                          },
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Obx(
                        () => SizedBox(
                            width: Get.width * .5,
                            height: 40,
                            child: controller.isPosting.value
                                ? Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: () {
                                      controller.addPost();
                                    },
                                    child: Text("Post Now"))),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      // SizedBox(
                      //   height: 40,
                      //   width: Get.width * .5,
                      //   child: ElevatedButton(
                      //       onPressed: () {
                      //         controller.addUniversity();
                      //       },
                      //       child: Text("Add University")),
                      // ),
                    ]),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertDialog(String title, String content) {
    Get.defaultDialog(
      title: title,
      middleText: content,
      textConfirm: "OK",
      onConfirm: () {
        Get.back(); // Close the dialog
      },
    );
  }
}
