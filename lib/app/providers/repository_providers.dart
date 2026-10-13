import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_repositories.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/discovery_repository.dart';

/// The demo build wires in-memory repositories. Override these three providers with real
/// implementations (in `bootstrap`) when a backend exists; nothing else changes.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => MockDiscoveryRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => MockChatRepository(),
);
