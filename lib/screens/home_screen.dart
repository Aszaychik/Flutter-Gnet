import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gnet_app/models/activity_model.dart';
import 'package:gnet_app/services/activity_service.dart';
import 'package:gnet_app/services/api_service.dart';
import 'package:gnet_app/services/storage_service.dart';
import 'package:gnet_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ActivityService _activityService = ActivityService();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final List<Activity> _activities = [];
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _authToken;
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadToken();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadToken() async {
    final token = await StorageService.getToken();
    setState(() => _authToken = token);
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (_isLoading || _authToken == null) return;
    setState(() => _isLoading = true);

    try {
      final activities = await _activityService.getActivities(page: _currentPage);

      // Pre-cache images
      for (final activity in activities) {
        if (!_imageCache.containsKey(activity.imageUrl)) {
          _cacheImage(activity.imageUrl);
        }
      }

      setState(() {
        _activities.addAll(activities);
        _hasMore = activities.isNotEmpty;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activities: $e'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cacheImage(String imagePath) async {
    try {
      final bytes = await ApiService().getImageBytes(imagePath);
      setState(() {
        _imageCache[imagePath] = bytes;
      });
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      setState(() => _currentPage++);
      _loadActivities();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _activities.clear();
      _imageCache.clear();
      _isRefreshing = true;
    });
    await _loadActivities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activities'),
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_authToken == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }

    if (_isRefreshing && _activities.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }

    if (_activities.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: AppTheme.lightTheme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No activities found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            TextButton(
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _activities.length + 1,
        itemBuilder: (context, index) {
          if (index < _activities.length) {
            final activity = _activities[index];
            final imageUrl = ApiService.getFullImageUrl(activity.imageUrl);
            return _buildActivityCard(activity, imageUrl, context);
          }
          return _buildLoader();
        },
      ),
    );
  }

  Widget _buildLoader() {
    return _hasMore
        ? Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
    )
        : const SizedBox();
  }

  Widget _buildActivityCard(Activity activity, String imageUrl, BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      color: AppTheme.lightTheme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 200,
              color: AppTheme.lightTheme.colorScheme.background,
              child: _buildImageWidget(activity.imageUrl, imageUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      child: Text(
                        activity.user['name'][0],
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.user['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${activity.createdAt.day}/${activity.createdAt.month}/${activity.createdAt.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imagePath, String fullImageUrl) {
    if (_imageCache.containsKey(imagePath)) {
      return Image.memory(
        _imageCache[imagePath]!,
        height: 200,
        fit: BoxFit.cover,
      );
    }

    return CachedNetworkImage(
      imageUrl: fullImageUrl,
      height: 200,
      fit: BoxFit.cover,
      httpHeaders: _authToken != null
          ? {'Authorization': 'Bearer $_authToken'}
          : {},
      placeholder: (context, url) => Container(
        color: AppTheme.lightTheme.colorScheme.background,
        height: 200,
        child: Icon(
          Icons.image,
          size: 50,
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.lightTheme.colorScheme.background,
        height: 200,
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: AppTheme.lightTheme.colorScheme.error,
        ),
      ),
    );
  }
}