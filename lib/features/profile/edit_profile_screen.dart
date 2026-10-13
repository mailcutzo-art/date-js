import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/shell/root_shell.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/interest.dart';
import '../../domain/models/profile.dart';
import '../../shared/widgets/interest_chips.dart';
import '../../shared/widgets/photos_grid.dart';
import '../onboarding/steps/about_step.dart' show kMinInterests;
import '../onboarding/steps/photo_source_sheet.dart';
import '../onboarding/steps/photos_step.dart' show kMinPhotos;

/// Edit photos, bio, job and interests. Save is disabled until the rules of setup hold again
/// (2+ photos, 3+ interests) and something changed.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final Profile _me = ref.read(sessionProvider).me!;
  late List<int> _seeds = [for (final p in _me.photos) p.seed];
  late Set<String> _interests = {..._me.interests};
  late final _bio = TextEditingController(text: _me.bio);
  late final _job = TextEditingController(text: _me.job ?? '');

  @override
  void initState() {
    super.initState();
    _bio.addListener(() => setState(() {}));
    _job.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bio.dispose();
    _job.dispose();
    super.dispose();
  }

  bool get _valid =>
      _seeds.length >= kMinPhotos && _interests.length >= kMinInterests;

  bool get _changed =>
      _bio.text.trim() != _me.bio ||
      _job.text.trim() != (_me.job ?? '') ||
      _seeds.length != _me.photos.length ||
      !_sameSeeds() ||
      _interests.length != _me.interests.length ||
      !_interests.containsAll(_me.interests);

  bool _sameSeeds() {
    for (var i = 0; i < _seeds.length && i < _me.photos.length; i++) {
      if (_seeds[i] != _me.photos[i].seed) return false;
    }
    return true;
  }

  void _save() {
    final job = _job.text.trim();
    ref
        .read(sessionProvider.notifier)
        .updateMe(
          Profile(
            id: _me.id,
            name: _me.name,
            age: _me.age,
            gender: _me.gender,
            photos: [
              for (var i = 0; i < _seeds.length; i++)
                ProfilePhoto(id: 'me-$i', seed: _seeds[i]),
            ],
            bio: _bio.text.trim(),
            city: _me.city,
            interests: _interests.toList(),
            verified: _me.verified,
            job: job.isEmpty ? null : job,
          ),
        );
    ref
        .read(toastControllerProvider)
        .show('Profile saved', variant: ToastVariant.success);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SubpageHeader(
              title: 'Edit profile',
              onBack: context.pop,
              trailing: SynkButton(
                label: 'Save',
                size: SynkButtonSize.sm,
                onPressed: _valid && _changed ? _save : null,
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  const SectionLabel('Photos'),
                  const SizedBox(height: 10),
                  PhotosGrid(
                    seeds: _seeds,
                    onAdd: () async {
                      final seed = await showPhotoSourceSheet(
                        context,
                        _seeds.length,
                      );
                      if (seed != null) {
                        setState(() => _seeds = [..._seeds, seed]);
                      }
                    },
                    onRemove: (i) =>
                        setState(() => _seeds = [..._seeds]..removeAt(i)),
                  ),
                  if (_seeds.length < kMinPhotos)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SynkText(
                        'Keep at least $kMinPhotos photos.',
                        variant: SynkTextVariant.small,
                        color: context.colors.destructive,
                      ),
                    ),
                  const SizedBox(height: 24),
                  const SectionLabel('About me'),
                  const SizedBox(height: 8),
                  SynkTextField(
                    controller: _bio,
                    hint: 'Write something about you',
                    maxLength: 300,
                    maxLines: 5,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('Job title'),
                  const SizedBox(height: 8),
                  SynkTextField(
                    controller: _job,
                    hint: 'What do you do?',
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: SectionLabel('Interests')),
                      SynkText(
                        '${_interests.length}/$kMaxInterests',
                        variant: SynkTextVariant.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InterestChips(
                    interests: kAllInterests,
                    selected: _interests,
                    onToggle: (i) => setState(() {
                      final next = {..._interests};
                      if (!next.remove(i) && next.length < kMaxInterests) {
                        next.add(i);
                      }
                      _interests = next;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
