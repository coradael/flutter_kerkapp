import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _picker = ImagePicker();
  
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  XFile? _selectedImage;
  PlatformFile? _selectedFile;

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

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _selectedFile = null;
      });
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _selectedImage = null;
      });
    }
  }

  void _clearAttachment() {
    setState(() {
      _selectedImage = null;
      _selectedFile = null;
    });
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
    if (user == null || (_commentController.text.trim().isEmpty && _selectedImage == null && _selectedFile == null)) {
      return;
    }

    final success = await _postService.addComment(
      widget.post.id,
      user.id,
      _commentController.text.trim(),
      image: _selectedImage,
      file: _selectedFile,
    );

    if (success) {
      _commentController.clear();
      _clearAttachment();
      _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Comment geplaatst')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId, String? attachmentUrl) async {
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
      await _postService.deleteComment(commentId, attachmentUrl);
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
    return Scaffold(
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
                  // Show post image if exists
                  if (widget.post.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 200),
                        child: GestureDetector(
                          onTap: () => _showFullscreenImage(widget.post.imageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.post.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading image: $error');
                                debugPrint('Image URL: ${widget.post.imageUrl}');
                                return Container(
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.broken_image, size: 50),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Kan afbeelding niet laden',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                          final attachmentUrl = comment['attachment_url'] as String?;
                          final attachmentType = comment['attachment_type'] as String?;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: comment['user_avatar'] != null
                                            ? NetworkImage(_storageService.getAvatarUrl(comment['user_avatar']!)!)
                                            : null,
                                        child: comment['user_avatar'] == null
                                            ? Text((comment['user_name'] ?? 'U')[0].toUpperCase())
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['user_name'] ?? 'Onbekend',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              _formatTime(DateTime.parse(comment['created_at'])),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isOwnComment)
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                          onPressed: () => _deleteComment(comment['id'], attachmentUrl),
                                        ),
                                    ],
                                  ),
                                  if (comment['comment_text'] != null && comment['comment_text'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(comment['comment_text']),
                                  ],
                                  // Show attachment if exists
                                  if (attachmentUrl != null) ...[
                                    const SizedBox(height: 8),
                                    Center(
                                      child: attachmentType == 'image'
                                          ? ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 150),
                                              child: GestureDetector(
                                                onTap: () => _showFullscreenImage(attachmentUrl),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    attachmentUrl,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 150,
                                                        color: Colors.grey.shade200,
                                                        child: const Center(
                                                          child: Icon(Icons.broken_image, size: 40),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.attach_file, color: Colors.blue),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Document bijgevoegd',
                                                    style: TextStyle(color: Colors.grey.shade700),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.download, size: 20),
                                                    onPressed: () {
                                                      launchUrl(Uri.parse(attachmentUrl));
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ],
                              ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show selected attachment preview
                  if (_selectedImage != null || _selectedFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedImage != null ? Icons.image : Icons.attach_file,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedImage != null
                                  ? 'Foto geselecteerd'
                                  : _selectedFile!.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _clearAttachment,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      // Image picker button
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.blue),
                        onPressed: _pickImage,
                      ),
                      // File picker button
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.blue),
                        onPressed: _pickFile,
                      ),
                      const SizedBox(width: 8),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
