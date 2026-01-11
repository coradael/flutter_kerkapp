import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_service.dart';
import '../tenant/user_tenant_service.dart';
import 'event_model.dart';
import 'event_service.dart';
import 'event_storage_service.dart';
import 'event_comment_model.dart';
import 'event_comment_service.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _authService = AuthService();
  final _userTenantService = UserTenantService();
  final _eventService = EventService();
  final _storageService = EventStorageService();
  final _commentService = EventCommentService();
  final _commentController = TextEditingController();
  
  bool _isAdmin = false;
  bool _isCreator = false;
  bool _loading = true;
  bool _isLiked = false;
  int _likeCount = 0;
  List<EventComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadLikes();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final isAdmin = await _userTenantService.isUserAdmin(
      user.id,
      widget.event.tenantId,
    );

    setState(() {
      _isAdmin = isAdmin;
      _isCreator = user.id == widget.event.createdBy;
      _loading = false;
    });
  }

  Future<void> _loadLikes() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final likes = await _commentService.getEventLikes(widget.event.id);
    final isLiked = await _commentService.hasUserLiked(widget.event.id, user.id);

    setState(() {
      _likeCount = likes.length;
      _isLiked = isLiked;
    });
  }

  Future<void> _loadComments() async {
    final comments = await _commentService.getEventComments(widget.event.id);
    setState(() => _comments = comments);
  }

  Future<void> _toggleLike() async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (_isLiked) {
      await _commentService.unlikeEvent(widget.event.id, user.id);
    } else {
      await _commentService.likeEvent(widget.event.id, user.id);
    }

    await _loadLikes();
  }

  Future<void> _addComment() async {
    final user = _authService.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final comment = EventComment(
      id: '',
      eventId: widget.event.id,
      userId: user.id,
      commentText: _commentController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await _commentService.addComment(comment);
    if (success) {
      _commentController.clear();
      await _loadComments();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment verwijderen?'),
        content: const Text('Weet je zeker dat je dit comment wilt verwijderen?'),
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

    if (confirm == true) {
      await _commentService.deleteComment(commentId);
      await _loadComments();
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event verwijderen?'),
        content: const Text('Weet je zeker dat je dit event wilt verwijderen?'),
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

    if (confirm != true) return;

    try {
      // Delete files from storage
      if (widget.event.files != null) {
        for (final file in widget.event.files!) {
          await _storageService.deleteFile(file.filePath);
        }
      }

      // Delete event (will cascade delete event_files records)
      await _eventService.deleteEvent(widget.event.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Event verwijderd')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fout: $e')),
        );
      }
    }
  }

  Future<void> _openFile(EventFile file) async {
    final url = _storageService.getFileUrl(file.filePath);
    if (url == null) return;
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Kan bestand niet openen')),
        );
      }
    }
  }

  void _showFullscreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _comments.length),
        ),
        actions: [
            if (!_loading && (_isAdmin || _isCreator)) ...[
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteEvent,
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (widget.event.description != null) ...[
              Text(
                'Beschrijving:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(widget.event.description!),
              const SizedBox(height: 16),
            ],
            if (widget.event.eventDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.event.eventDate!.day}/${widget.event.eventDate!.month}/${widget.event.eventDate!.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (widget.event.location != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.event.location!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (widget.event.files != null && widget.event.files!.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Foto\'s en Bestanden (${widget.event.files!.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Toon foto's als grid
              ...widget.event.files!
                  .where((file) => file.fileType == 'image')
                  .map((file) {
                final url = _storageService.getFileUrl(file.filePath);
                return url != null
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _showFullscreenImage(url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                height: 300,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 50),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
              // Toon andere bestanden als lijst
              ...widget.event.files!
                  .where((file) => file.fileType != 'image')
                  .map((file) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(_getFileIcon(file.fileType)),
                          title: Text(file.fileName),
                          subtitle: Text(file.fileType.toUpperCase()),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _openFile(file),
                        ),
                      )),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Like button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleLike,
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                  Text(
                    '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_comments.length} ${_comments.length == 1 ? 'comment' : 'comments'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Comments section
            if (_comments.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final isOwnComment = comment.userId == _authService.currentUser?.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (comment.userName ?? 'U').substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(
                          comment.userName ?? 'Gebruiker',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.commentText),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(comment.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: (isOwnComment || _isAdmin)
                            ? IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deleteComment(comment.id),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
            // Comment input
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Schrijf een comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addComment,
                    icon: const Icon(Icons.send, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Zojuist';
    if (diff.inHours < 1) return '${diff.inMinutes}m geleden';
    if (diff.inDays < 1) return '${diff.inHours}u geleden';
    if (diff.inDays < 7) return '${diff.inDays}d geleden';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.insert_drive_file;
      default:
        return Icons.attach_file;
    }
  }
}