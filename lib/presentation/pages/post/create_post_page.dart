import 'package:campussaga/core/constants/dummypost.dart';
import 'package:campussaga/core/theme/app_theme.dart';
import 'package:campussaga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campussaga/presentation/bloc/auth/auth_state.dart';
import 'package:campussaga/presentation/bloc/post/post_bloc.dart';
import 'package:campussaga/presentation/bloc/post/post_event.dart';
import 'package:campussaga/presentation/bloc/post/post_state.dart';
import 'package:campussaga/presentation/bloc/promotion/promotion_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPromo = postType == 'Promotional';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.edit_2, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Create Post',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Post type chips ──────────────────────────────────────
            _SectionLabel(icon: Iconsax.category, text: 'Post Type'),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Problem',
                  icon: Iconsax.shield_cross,
                  selected: postType == 'Problem',
                  color: AppColors.primary,
                  onTap: () => setState(() => postType = 'Problem'),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: 'Promotional',
                  icon: Iconsax.award,
                  selected: postType == 'Promotional',
                  color: const Color(0xFF7C4DFF),
                  onTap: () => setState(() => postType = 'Promotional'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────
            _SectionLabel(icon: Iconsax.text, text: 'Title'),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter a clear, concise title…',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Iconsax.text, size: 18),
              ),
            ),

            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────
            _SectionLabel(icon: Iconsax.document_text, text: 'Description'),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe the issue or event in detail…',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                alignLabelWithHint: true,
              ),
            ),

            // ── Promo-only fields ─────────────────────────────────────
            if (isPromo) ...[
              const SizedBox(height: 16),
              _SectionLabel(icon: Iconsax.people, text: 'Club Name'),
              const SizedBox(height: 8),
              TextField(
                controller: clubNameController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Robotics Club',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(Iconsax.people, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              _SectionLabel(icon: Iconsax.link_21, text: 'Event Link'),
              const SizedBox(height: 8),
              TextField(
                controller: eventLinkController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'https://…',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(Iconsax.link_21, size: 18),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Attachments ──────────────────────────────────────────
            Row(
              children: [
                _SectionLabel(icon: Iconsax.gallery, text: 'Attachments'),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: pickImages,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Iconsax.add_square, size: 16),
                  label: Text(
                    'Add',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (selectedImages.isNotEmpty)
              SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withAlpha(60),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => removeImage(index),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(60),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 13,
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
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2140)
                      : const Color(0xFFF5F6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(40),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.gallery_add,
                        size: 18,
                        color: AppColors.primary.withAlpha(160),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap "Add" to attach images',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // ── Submit button ─────────────────────────────────────────
            BlocBuilder<AuthBloc, AuthState>(
              builder: (authCtx, authState) {
                if (authState is AuthAuthenticated) {
                  final user = authState.user;
                  return MultiBlocListener(
                    listeners: [
                      BlocListener<PostBloc, PostState>(
                        listener: (ctx, postState) {
                          if (postState is PostingSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Post created successfully'),
                              ),
                            );
                            handlePostCreation(0);
                          } else if (postState is PostingFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: ${postState.message}'),
                              ),
                            );
                          }
                        },
                      ),
                      BlocListener<PromotionBloc, PromotionState>(
                        listener: (ctx, promoState) {
                          if (promoState is PromotionPostingSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Promotion created successfully'),
                              ),
                            );
                            handlePostCreation(1);
                          } else if (promoState is PromotionPostingFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: ${promoState.message}'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    child: Column(
                      children: [
                        BlocBuilder<PostBloc, PostState>(
                          builder: (_, postState) {
                            if (postState is PostingLoading) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Publishing post…',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        BlocBuilder<PromotionBloc, PromotionState>(
                          builder: (_, promoState) {
                            if (promoState is PromotionPostingLoading) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF7C4DFF),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Publishing promotion…',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (postType == 'Problem') {
                                final post = postGenerate(
                                  user,
                                  titleController.text,
                                  descriptionController.text,
                                );
                                BlocProvider.of<PostBloc>(
                                  context,
                                ).add(PostCreated(post, selectedImages));
                              } else if (postType == 'Promotional') {
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
                                        'Please select at least one image',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                BlocProvider.of<PromotionBloc>(context).add(
                                  PromotionPostCreated(
                                    promotion,
                                    selectedImages,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a post type first',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isPromo
                                  ? const Color(0xFF7C4DFF)
                                  : AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Iconsax.send_2, size: 18),
                            label: Text(
                              isPromo ? 'Publish Promotion' : 'Create Post',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Text(
                    'You are not authenticated',
                    style: GoogleFonts.poppins(fontSize: 14),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Post type chip ────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.outline.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
