import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../services/storage_service.dart';
import 'post_model.dart';
import 'post_service.dart';

class CommentsPage extends StatefulWidget {
  final Post post;

  const CommentsPage({
    super.key,
    required this.post,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _postService = PostService();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _commentController = TextEditingController();
  
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    final comments = await _postService.getPostComments(widget.post.id);
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _addComment() async {
    final user = _authService.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final success = await _postService.addComment(
      widget.post.id,
      user.id,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Comment geplaatst')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true) {
      await _postService.deleteComment(commentId);
      _loadComments();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Zojuist';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m geleden';
    if (difference.inHours < 24) return '${difference.inHours}u geleden';
    if (difference.inDays < 7) return '${difference.inDays}d geleden';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Return the current comment count
          Navigator.of(context).pop(_comments.length);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comments'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _comments.length),
          ),
        ),
        body: Column(
        children: [
          // Original post
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.post.userAvatar != null
                            ? NetworkImage(_storageService.getAvatarUrl(widget.post.userAvatar!)!)
                            : null,
                        child: widget.post.userAvatar == null
                            ? Text((widget.post.userName ?? 'U')[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.userName ?? 'Onbekend',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatTime(widget.post.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.post.content),
                ],
              ),
            ),
          ),
          const Divider(),
          // Comments list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.comment_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Nog geen comments',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isOwnComment = comment['user_id'] == _authService.currentUser?.id;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: comment['user_avatar'] != null
                                    ? NetworkImage(_storageService.getAvatarUrl(comment['user_avatar']!)!)
                                    : null,
                                child: comment['user_avatar'] == null
                                    ? Text((comment['user_name'] ?? 'U')[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(
                                comment['user_name'] ?? 'Onbekend',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(comment['comment_text']),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(DateTime.parse(comment['created_at'])),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isOwnComment
                                  ? IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteComment(comment['id']),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
          // Comment input
          Container(
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
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Schrijf een comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
