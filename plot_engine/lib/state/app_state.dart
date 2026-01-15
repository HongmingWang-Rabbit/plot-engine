import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/platform_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../models/auth_user.dart';
import '../models/billing_models.dart';
import '../models/entity_update_suggestion.dart';
import '../services/entity_store.dart';
import '../services/ai_entity_recognizer.dart';
import '../services/ai_service.dart';
import '../services/entity_recognizer.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/desktop_auth_service_stub.dart'
    if (dart.library.io) '../services/desktop_auth_service.dart';
import '../services/web_auth_service_stub.dart'
    if (dart.library.html) '../services/web_auth_service.dart';
import '../services/api_client.dart';
import '../services/backend_project_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/project_service_stub.dart'
    if (dart.library.io) '../services/project_service.dart';
import '../services/web_project_service.dart';
import '../services/base_project_service.dart';
import '../services/billing_service.dart';
import '../services/sync_service_stub.dart'
    if (dart.library.io) '../services/sync_service.dart';
export '../services/sync_service_stub.dart'
    if (dart.library.io) '../services/sync_service.dart'
    show syncServiceProvider, syncStatusProvider, SyncStatusNotifier;
export '../models/sync_metadata.dart' show SyncStatus;

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

// Project loading state provider
class ProjectLoadingNotifier extends StateNotifier<bool> {
  ProjectLoadingNotifier() : super(false);

  void setLoading(bool loading) {
    state = loading;
  }
}

final projectLoadingProvider = StateNotifierProvider<ProjectLoadingNotifier, bool>((ref) {
  return ProjectLoadingNotifier();
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

  void replaceChapter(String oldId, Chapter newChapter) {
    state = [
      for (final c in state)
        if (c.id == oldId) newChapter else c,
    ];
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

// Entity store version provider - increment this to force UI rebuild when entities change
class EntityStoreVersionNotifier extends StateNotifier<int> {
  EntityStoreVersionNotifier() : super(0);

  void increment() {
    state++;
  }
}

final entityStoreVersionProvider = StateNotifierProvider<EntityStoreVersionNotifier, int>((ref) {
  return EntityStoreVersionNotifier();
});

// AI entity recognizer provider (with debounced API calls)
final aiEntityRecognizerProvider = Provider<AIEntityRecognizer>((ref) {
  final store = ref.watch(entityStoreProvider);
  final aiService = ref.watch(aiServiceProvider);
  return AIEntityRecognizer(store, aiService);
});

// Entity recognizer provider - always uses AI for better accuracy
final entityRecognizerProvider = Provider<EntityRecognizer>((ref) {
  return ref.watch(aiEntityRecognizerProvider);
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

// Auth service provider (Web auth for web, Desktop auth for Windows/Linux, Google Auth for macOS)
final authServiceProvider = Provider<AuthService>((ref) {
  if (kIsWeb) {
    return WebAuthService();
  }
  // Use browser-based OAuth for Windows/Linux (google_sign_in not supported)
  // macOS can use GoogleAuthService directly
  if (PlatformUtil.isWindows || PlatformUtil.isLinux) {
    return DesktopAuthService();
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

// Cloud storage service provider
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CloudStorageService(apiClient: apiClient);
});

// Local project service provider (desktop only)
final localProjectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(ref);
});

// Cloud project service provider (works on both web and desktop when logged in)
final cloudProjectServiceProvider = Provider<WebProjectService>((ref) {
  return WebProjectService(ref);
});

// Platform-aware project service provider
// Uses WebProjectService (cloud) for web, ProjectService (local files) for desktop
// On desktop, this returns the local service by default; use cloudProjectServiceProvider
// when user explicitly chooses cloud storage
final projectServiceProvider = Provider<BaseProjectService>((ref) {
  if (kIsWeb) {
    return WebProjectService(ref);
  }
  return ProjectService(ref);
});

// ===== Billing Providers =====

// Billing service provider
final billingServiceProvider = Provider<BillingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BillingService(apiClient: apiClient);
});

// Credits balance provider (async)
final creditsBalanceProvider = FutureProvider<double>((ref) async {
  final billingService = ref.watch(billingServiceProvider);
  return await billingService.getCreditsBalance();
});

// Billing status provider (async)
final billingStatusProvider = FutureProvider<BillingStatus>((ref) async {
  final billingService = ref.watch(billingServiceProvider);
  return await billingService.getBillingStatus();
});

// Billing summary provider (async)
final billingSummaryProvider = FutureProvider<BillingSummary>((ref) async {
  final billingService = ref.watch(billingServiceProvider);
  return await billingService.getBillingSummary();
});

// Usage summary provider (async)
final usageSummaryProvider = FutureProvider<UsageSummary>((ref) async {
  final billingService = ref.watch(billingServiceProvider);
  return await billingService.getUsageSummary(days: 30);
});

// Credits balance notifier for manual refresh
class CreditsBalanceNotifier extends StateNotifier<double?> {
  final BillingService _billingService;

  CreditsBalanceNotifier(this._billingService) : super(null) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _billingService.getCreditsBalance();
  }

  void setBalance(double balance) {
    state = balance;
  }
}

final creditsBalanceNotifierProvider =
    StateNotifierProvider<CreditsBalanceNotifier, double?>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  return CreditsBalanceNotifier(billingService);
});

// ===== Entity Update Suggestion Providers =====

/// State for entity update suggestions
class EntityUpdateState {
  final List<EntityUpdateSuggestion> suggestions;
  final Set<String> dismissedIds;
  final bool isLoading;
  final String? error;

  const EntityUpdateState({
    this.suggestions = const [],
    this.dismissedIds = const {},
    this.isLoading = false,
    this.error,
  });

  EntityUpdateState copyWith({
    List<EntityUpdateSuggestion>? suggestions,
    Set<String>? dismissedIds,
    bool? isLoading,
    String? error,
  }) {
    return EntityUpdateState(
      suggestions: suggestions ?? this.suggestions,
      dismissedIds: dismissedIds ?? this.dismissedIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get suggestions that haven't been dismissed
  List<EntityUpdateSuggestion> get visibleSuggestions {
    return suggestions.where((s) => !dismissedIds.contains(s.entityId)).toList();
  }

  /// Check if there are any visible suggestions
  bool get hasSuggestions => visibleSuggestions.isNotEmpty;
}

/// Notifier for managing entity update suggestions
class EntityUpdateNotifier extends StateNotifier<EntityUpdateState> {
  EntityUpdateNotifier() : super(const EntityUpdateState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, error: null);
  }

  void setSuggestions(List<EntityUpdateSuggestion> suggestions) {
    state = state.copyWith(
      suggestions: suggestions,
      isLoading: false,
      error: null,
    );
  }

  void setError(String error) {
    state = state.copyWith(isLoading: false, error: error);
  }

  void dismissSuggestion(String entityId) {
    state = state.copyWith(
      dismissedIds: {...state.dismissedIds, entityId},
    );
  }

  void removeSuggestion(String entityId) {
    state = state.copyWith(
      suggestions: state.suggestions.where((s) => s.entityId != entityId).toList(),
    );
  }

  void clearSuggestions() {
    state = const EntityUpdateState();
  }

  void clearDismissed() {
    state = state.copyWith(dismissedIds: {});
  }
}

final entityUpdateProvider =
    StateNotifierProvider<EntityUpdateNotifier, EntityUpdateState>((ref) {
  return EntityUpdateNotifier();
});
