import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/provider/profile_provider.dart';
import 'package:glow/features/profile/widgets/profile_avatar.dart';

class ProfileEditorDialog extends ConsumerStatefulWidget {
  const ProfileEditorDialog({super.key});

  @override
  ConsumerState<ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends ConsumerState<ProfileEditorDialog> {
  late TextEditingController nameInputController;
  Profile? newProfile;
  String? tempImagePath; // Temporary image path for preview
  bool isSaving = false;
  ProfileNotifier? _profileNotifier; // Cached notifier for cleanup

  @override
  void initState() {
    super.initState();
    final WalletMetadata? wallet = ref.read(activeWalletProvider).value;
    nameInputController = TextEditingController(text: wallet?.displayName ?? '');
    _profileNotifier = ref.read(profileNotifierProvider.notifier);
  }

  @override
  void dispose() {
    // Clean up temp image if user exits without saving
    if (tempImagePath != null && _profileNotifier != null) {
      _profileNotifier!.cleanupTempImage(tempImagePath!);
    }
    nameInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final WalletMetadata? wallet = ref.watch(activeWalletProvider).value;

    // Use temp image for preview if available, otherwise use profile's image
    Profile currentProfile = newProfile ?? wallet?.profile ?? Profile.anonymous();
    final bool isPreview = tempImagePath != null;
    if (isPreview) {
      currentProfile = currentProfile.copyWith(customImagePath: tempImagePath);
    }

    return PopScope(
      canPop: !isSaving,
      child: SimpleDialog(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        title: _DialogTitle(
          profile: currentProfile,
          isSaving: isSaving,
          isPreview: isPreview,
          onRandomPressed: generateRandomProfile,
          onGalleryPressed: pickGalleryImage,
        ),
        titlePadding: const EdgeInsets.all(0.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0), top: Radius.circular(13.0)),
        ),
        children: <Widget>[
          SingleChildScrollView(
            child: TextField(
              enabled: !isSaving,
              style: themeData.textTheme.bodyMedium,
              controller: nameInputController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: themeData.textTheme.bodyMedium?.copyWith(color: themeData.hintColor),
              ),
              onSubmitted: (String text) {},
            ),
          ),
          _DialogActions(
            isSaving: isSaving,
            onCancel: () => Navigator.of(context).pop(),
            onSave: saveProfileChanges,
          ),
        ],
      ),
    );
  }

  void generateRandomProfile() {
    // Clean up temp image if switching to random profile
    if (tempImagePath != null && _profileNotifier != null) {
      _profileNotifier!.cleanupTempImage(tempImagePath!);
    }

    final Profile randomProfile = generateProfile();
    setState(() {
      newProfile = randomProfile;
      tempImagePath = null; // Clear temp path
      nameInputController.text = randomProfile.displayName;
    });
    // Close keyboard
    FocusScope.of(context).unfocus();
  }

  Future<void> pickGalleryImage() async {
    try {
      // Pick and crop image (returns temp path)
      final String? imagePath = await ref.read(profileNotifierProvider.notifier).pickImageForPreview();

      if (imagePath == null) {
        // User cancelled
        return;
      }

      // Store temp path and update preview
      setState(() {
        tempImagePath = imagePath;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> saveProfileChanges() async {
    final WalletMetadata? wallet = ref.read(activeWalletProvider).value;
    if (wallet == null) {
      return;
    }

    try {
      setState(() => isSaving = true);

      // Start with current profile (or new one if changed)
      Profile profileToSave = newProfile ?? wallet.profile;

      // If there's a temp image, save it permanently and update the profile
      if (tempImagePath != null) {
        final String savedPath = await ref
            .read(profileNotifierProvider.notifier)
            .saveTempImage(tempImagePath!);
        profileToSave = profileToSave.copyWith(customImagePath: savedPath);
        // Note: Don't clear tempImagePath here - let it show during save
      }

      // Update profile with all changes (name/animal/color/image)
      await ref
          .read(profileNotifierProvider.notifier)
          .updateProfile(newProfile: profileToSave, inputName: nameInputController.text.trim());

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}

class _DialogTitle extends StatelessWidget {
  final Profile profile;
  final bool isSaving;
  final bool isPreview;
  final VoidCallback onRandomPressed;
  final VoidCallback? onGalleryPressed;

  const _DialogTitle({
    required this.profile,
    required this.isSaving,
    required this.onRandomPressed,
    required this.onGalleryPressed,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const _TitleBackground(),
        SizedBox(
          height: 100.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RandomButton(onPressed: isSaving ? null : onRandomPressed),
              _AvatarPreview(profile: profile, isUploading: isSaving, isPreview: isPreview),
              _GalleryButton(onPressed: isSaving ? null : onGalleryPressed),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleBackground extends StatelessWidget {
  const _TitleBackground();

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Container(
      height: 70.0,
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.0))),
        color: themeData.canvasColor,
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _DialogActions({required this.isSaving, required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: isSaving ? null : onCancel,
            child: Text('CANCEL', style: themeData.textTheme.labelLarge),
          ),
          TextButton(
            onPressed: isSaving ? null : onSave,
            child: Text('SAVE', style: themeData.textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

class _RandomButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _RandomButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.only(bottom: 20.0, top: 26.0)),
        onPressed: onPressed,
        child: Text(
          'RANDOM',
          style: themeData.textTheme.labelLarge?.copyWith(color: themeData.colorScheme.onPrimaryContainer),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final Profile profile;
  final bool isUploading;
  final bool isPreview;

  const _AvatarPreview({required this.profile, required this.isUploading, this.isPreview = false});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Stack(
      children: <Widget>[
        if (isUploading) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 26.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeData.colorScheme.onPrimaryContainer),
                backgroundColor: themeData.colorScheme.primaryContainer,
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 26.0),
          child: AspectRatio(
            aspectRatio: 1,
            child: ProfileAvatar(
              profile: profile,
              avatarSize: AvatarSize.large,
              backgroundColor: themeData.primaryColor,
              isPreview: isPreview,
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GalleryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.only(bottom: 20.0, top: 26.0)),
        onPressed: onPressed,
        child: Text(
          'GALLERY',
          style: themeData.textTheme.labelLarge?.copyWith(color: themeData.colorScheme.onPrimaryContainer),
          maxLines: 1,
        ),
      ),
    );
  }
}
