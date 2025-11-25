import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../models/auth_user.dart';
import '../services/entity_store.dart';
import '../services/local_entity_recognizer.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/web_auth_service.dart';
import '../services/api_client.dart';
import '../services/backend_project_service.dart';

// Current project provider
class ProjectNotifier extends StateNotifier<Project?> {
  ProjectNotifier() : super(null);

  void setProject(Project project) {
    state = project;
  }

  void clearProject() {
    state = null;
  }

  void updateProject(Project project) {
    state = project;
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, Project?>((ref) {
  return ProjectNotifier();
});

// Chapters provider
class ChaptersNotifier extends StateNotifier<List<Chapter>> {
  ChaptersNotifier() : super([]);

  void setChapters(List<Chapter> chapters) {
    state = chapters;
  }

  void addChapter(Chapter chapter) {
    state = [...state, chapter];
  }

  void updateChapter(Chapter chapter) {
    state = [
      for (final c in state)
        if (c.id == chapter.id) chapter else c,
    ];
  }

  void deleteChapter(String chapterId) {
    state = state.where((c) => c.id != chapterId).toList();
  }

  void clearChapters() {
    state = [];
  }
}

final chaptersProvider = StateNotifierProvider<ChaptersNotifier, List<Chapter>>((ref) {
  return ChaptersNotifier();
});

// Current chapter provider
class CurrentChapterNotifier extends StateNotifier<Chapter?> {
  CurrentChapterNotifier() : super(null);

  void setCurrentChapter(Chapter? chapter) {
    state = chapter;
  }

  void updateContent(String content) {
    if (state != null) {
      state = state!.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
    }
  }

  void updateTitle(String title) {
    if (state != null) {
      state = state!.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
    }
  }
}

final currentChapterProvider = StateNotifierProvider<CurrentChapterNotifier, Chapter?>((ref) {
  return CurrentChapterNotifier();
});

// Knowledge base provider
class KnowledgeBaseNotifier extends StateNotifier<List<KnowledgeItem>> {
  KnowledgeBaseNotifier() : super([]);

  void setItems(List<KnowledgeItem> items) {
    state = items;
  }

  void addItem(KnowledgeItem item) {
    state = [...state, item];
  }

  void updateItem(KnowledgeItem item) {
    state = [
      for (final i in state)
        if (i.id == item.id) item else i,
    ];
  }

  void deleteItem(String itemId) {
    state = state.where((i) => i.id != itemId).toList();
  }

  List<KnowledgeItem> getItemsByType(String type) {
    return state.where((i) => i.type == type).toList();
  }

  void clearItems() {
    state = [];
  }
}

final knowledgeBaseProvider = StateNotifierProvider<KnowledgeBaseNotifier, List<KnowledgeItem>>((ref) {
  return KnowledgeBaseNotifier();
});

// Entity store provider (singleton)
final entityStoreProvider = Provider<EntityStore>((ref) {
  return EntityStore();
});

// Entity recognizer provider
final entityRecognizerProvider = Provider<LocalEntityRecognizer>((ref) {
  final store = ref.watch(entityStoreProvider);
  return LocalEntityRecognizer(store);
});

// Selected entity provider (for sidebar display)
class SelectedEntityNotifier extends StateNotifier<EntityMetadata?> {
  SelectedEntityNotifier() : super(null);

  void selectEntity(EntityMetadata? entity) {
    state = entity;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedEntityProvider = StateNotifierProvider<SelectedEntityNotifier, EntityMetadata?>((ref) {
  return SelectedEntityNotifier();
});

// Entity highlight toggle provider
class EntityHighlightNotifier extends StateNotifier<bool> {
  EntityHighlightNotifier() : super(true); // Default: highlights enabled

  void toggle() {
    state = !state;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

final entityHighlightProvider = StateNotifierProvider<EntityHighlightNotifier, bool>((ref) {
  return EntityHighlightNotifier();
});

// Entity hover state provider
class HoveredEntityNotifier extends StateNotifier<String?> {
  HoveredEntityNotifier() : super(null);

  void setHovered(String? entityName) {
    state = entityName;
  }

  void clearHover() {
    state = null;
  }
}

final hoveredEntityProvider = StateNotifierProvider<HoveredEntityNotifier, String?>((ref) {
  return HoveredEntityNotifier();
});

// Auth service provider (Web auth for web, Google Auth for native)
final authServiceProvider = Provider<AuthService>((ref) {
  if (kIsWeb) {
    return WebAuthService();
  }
  return GoogleAuthService();
});

// Auth user provider
class AuthUserNotifier extends StateNotifier<AuthUser?> {
  final AuthService _authService;

  AuthUserNotifier(this._authService) : super(_authService.currentUser) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      state = user;
    });
  }

  Future<AuthResult> signIn() async {
    final result = await _authService.signIn();
    if (result.success && result.user != null) {
      state = result.user;
    }
    return result;
  }

  Future<bool> signOut() async {
    final success = await _authService.signOut();
    if (success) {
      state = null;
    }
    return success;
  }

  Future<AuthResult> refreshToken() async {
    final result = await _authService.refreshToken();
    if (result.success && result.user != null) {
      state = result.user;
    }
    return result;
  }

  bool get isSignedIn => state != null;
}

final authUserProvider = StateNotifierProvider<AuthUserNotifier, AuthUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthUserNotifier(authService);
});

// API client provider (singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Backend project service provider
final backendProjectServiceProvider = Provider<BackendProjectService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BackendProjectService(apiClient: apiClient);
});
