import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/storage_service.dart';
import 'post_model.dart';
import 'post_service.dart';
import 'comments_page.dart';
import '../events/create_event_page.dart';
import '../events/event_service.dart';
import '../events/event_model.dart';
import '../events/event_detail_page.dart';
import '../events/event_storage_service.dart';
import '../events/event_comment_service.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _postService = PostService();
  final _eventService = EventService();
  final _authService = AuthService();
  final _localStorage = LocalStorageService();
  final _storageService = StorageService();
  final _eventStorageService = EventStorageService();
  final _eventCommentService = EventCommentService();
  
  List<dynamic> _feedItems = [];
  bool _loading = true;
  String? _tenantId;
  final Set<String> _likedPosts = {};
  final Set<String> _likedEvents = {};
  final Map<String, int> _eventLikeCounts = {};
  final Map<String, int> _eventCommentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    
    _tenantId = await _localStorage.getSelectedTenantId();
    if (_tenantId == null) {
      setState(() => _loading = false);
      return;
    }

    // Load both posts and events
    final posts = await _postService.getTenantPosts(_tenantId!);
    final events = await _eventService.getTenantEvents(_tenantId!);
    
    // Check which posts the user has liked
    final user = _authService.currentUser;
    if (user != null) {
      for (final post in posts) {
        final liked = await _postService.hasUserLiked(post.id, user.id);
        if (liked) {
          _likedPosts.add(post.id);
        }
      }
      
      // Check which events the user has liked and get counts
      for (final event in events) {
        final liked = await _eventCommentService.hasUserLiked(event.id, user.id);
        if (liked) {
          _likedEvents.add(event.id);
        }
        
        final likes = await _eventCommentService.getEventLikes(event.id);
        _eventLikeCounts[event.id] = likes.length;
        
        final comments = await _eventCommentService.getEventComments(event.id);
        _eventCommentCounts[event.id] = comments.length;
      }
    }
    
    // Combine and sort by date
    final List<dynamic> combined = [...posts, ...events];
    combined.sort((a, b) {
      final dateA = a is Post ? a.createdAt : (a as Event).createdAt;
      final dateB = b is Post ? b.createdAt : (b as Event).createdAt;
      return dateB.compareTo(dateA); // Most recent first
    });
    
    setState(() {
      _feedItems = combined;
      _loading = false;
    });
  }

  Future<void> _createPost() async {
    final user = _authService.currentUser;
    if (user == null || _tenantId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(
          tenantId: _tenantId!,
          userId: user.id,
        ),
      ),
    );
    
    _loadFeed();
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bericht verwijderen?'),
        content: const Text('Weet je zeker dat je dit bericht wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _postService.deletePost(post.id, post.imageUrl);
      _loadFeed();
    }
  }

  Future<void> _toggleLike(Post post) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final isLiked = _likedPosts.contains(post.id);
    
    if (isLiked) {
      await _postService.unlikePost(post.id, user.id);
      setState(() => _likedPosts.remove(post.id));
    } else {
      await _postService.likePost(post.id, user.id);
      setState(() => _likedPosts.add(post.id));
    }
    
    // Reload feed to update counts
    _loadFeed();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeed,
              child: _feedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Nog geen berichten of evenementen',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _createPost,
                            icon: const Icon(Icons.add),
                            label: const Text('Eerste bericht plaatsen'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _feedItems.length,
                      itemBuilder: (context, index) {
                        final item = _feedItems[index];
                        
                        if (item is Event) {
                          return _buildEventCard(item);
                        } else {
                          return _buildPostCard(item as Post);
                        }
                      },
                    ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'post',
            onPressed: _createPost,
            icon: const Icon(Icons.add),
            label: const Text('Nieuw Bericht'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'event',
            onPressed: () async {
              if (_tenantId != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventPage(tenantId: _tenantId!),
                  ),
                );
                if (result == true) {
                  _loadFeed();
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Nieuw Event'),
            backgroundColor: Colors.deepPurple.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final firstImage = event.files?.firstWhere(
      (file) => file.fileType == 'image',
      orElse: () => EventFile(
        id: '',
        eventId: '',
        filePath: '',
        fileType: '',
        fileName: '',
        createdAt: DateTime.now(),
      ),
    );
    final hasImage = firstImage?.filePath.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator info header
            ListTile(
              leading: CircleAvatar(
                backgroundImage: event.creatorAvatar != null
                    ? NetworkImage(_storageService.getAvatarUrl(event.creatorAvatar!)!)
                    : null,
                child: event.creatorAvatar == null
                    ? Text((event.creatorName ?? 'U')[0].toUpperCase())
                    : null,
              ),
              title: Row(
                children: [
                  Text(
                    event.creatorName ?? 'Onbekend',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, color: Colors.deepPurple.shade700, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Evenement',
                          style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(_formatTime(event.createdAt)),
            ),
            // Event image
            if (hasImage)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _eventStorageService.getFileUrl(firstImage!.filePath)!,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Event info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (event.eventDate != null) ...[
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                      if (event.location != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Like and comment buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _likedEvents.contains(event.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _likedEvents.contains(event.id)
                          ? Colors.red
                          : null,
                    ),
                    onPressed: () => _toggleEventLike(event),
                  ),
                  Text('${_eventLikeCounts[event.id] ?? 0}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event),
                        ),
                      ).then((_) => _loadFeed());
                    },
                  ),
                  Text('${_eventCommentCounts[event.id] ?? 0}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEventLike(Event event) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final isLiked = _likedEvents.contains(event.id);
    
    if (isLiked) {
      await _eventCommentService.unlikeEvent(event.id, user.id);
      setState(() => _likedEvents.remove(event.id));
    } else {
      await _eventCommentService.likeEvent(event.id, user.id);
      setState(() => _likedEvents.add(event.id));
    }
    
    // Reload feed to update counts
    _loadFeed();
  }

  Widget _buildPostCard(Post post) {
    final isOwnPost = post.userId == _authService.currentUser?.id;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.userAvatar != null
                  ? NetworkImage(_storageService.getAvatarUrl(post.userAvatar!)!)
                  : null,
              child: post.userAvatar == null
                  ? Text((post.userName ?? 'U')[0].toUpperCase())
                  : null,
            ),
            title: Text(
              post.userName ?? 'Onbekend',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_formatTime(post.createdAt)),
            trailing: isOwnPost
                ? IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _deletePost(post),
                  )
                : null,
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          // Image if exists
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Like and comment buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _likedPosts.contains(post.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _likedPosts.contains(post.id)
                        ? Colors.red
                        : null,
                  ),
                  onPressed: () => _toggleLike(post),
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsPage(post: post),
                      ),
                    );
                    _loadFeed(); // Refresh to update comment count
                  },
                ),
                Text('${post.commentCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePostPage extends StatefulWidget {
  final String tenantId;
  final String userId;

  const CreatePostPage({
    super.key,
    required this.tenantId,
    required this.userId,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  final _postService = PostService();
  final _picker = ImagePicker();
  
  XFile? _selectedImage;
  bool _posting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() => _selectedImage = image);
  }

  Future<void> _post() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schrijf iets om te delen')),
      );
      return;
    }

    setState(() => _posting = true);

    final success = await _postService.createPost(
      tenantId: widget.tenantId,
      userId: widget.userId,
      content: _contentController.text.trim(),
      image: _selectedImage,
    );

    setState(() => _posting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bericht geplaatst')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Fout bij plaatsen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuw bericht'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Plaatsen', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Wat wil je delen?',
                border: InputBorder.none,
              ),
              maxLines: 10,
              autofocus: true,
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedImage!.path,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                const Text('Foto toevoegen'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
