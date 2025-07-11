import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gnet_app/models/activity_model.dart';
import 'package:gnet_app/services/activity_service.dart';
import 'package:gnet_app/services/api_service.dart';
import 'package:gnet_app/services/storage_service.dart';
import 'package:gnet_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:gnet_app/screens/full_screen_image_screen.dart';

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
  DateTime? _selectedDate;
  bool _isDateFilterApplied = false;

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
      _selectedDate = null;
      _isDateFilterApplied = false;
    });
    await _loadActivities();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
              primary: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isDateFilterApplied = true;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _isDateFilterApplied = false;
    });
  }

  List<Activity> get _filteredActivities {
    if (_selectedDate == null) return _activities;

    return _activities.where((activity) {
      return activity.createdAt.year == _selectedDate!.year &&
          activity.createdAt.month == _selectedDate!.month &&
          activity.createdAt.day == _selectedDate!.day;
    }).toList();
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: _isDateFilterApplied
                  ? AppTheme.lightTheme.colorScheme.secondary
                  : AppTheme.lightTheme.colorScheme.onPrimary,
            ),
            onPressed: () => _selectDate(context),
          ),
          if (_isDateFilterApplied)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
              onPressed: _clearDateFilter,
            ),
        ],
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

    final filteredActivities = _filteredActivities;

    if (filteredActivities.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 64,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _isDateFilterApplied
                  ? 'No activities for selected date'
                  : 'No activities found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_isDateFilterApplied)
              TextButton(
                onPressed: _clearDateFilter,
                child: const Text('Clear filter'),
              )
            else
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
      child: Column(
        children: [
          if (_isDateFilterApplied)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Showing activities for: ${DateFormat.yMMMMd().format(_selectedDate!)}',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _clearDateFilter,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredActivities.length + 1,
              itemBuilder: (context, index) {
                if (index < filteredActivities.length) {
                  final activity = filteredActivities[index];
                  final imageUrl = ApiService.getFullImageUrl(activity.imageUrl);
                  return _buildActivityCard(activity, imageUrl, context);
                }
                return _buildLoader();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return _hasMore && !_isDateFilterApplied
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
          // Wrap the image with InkWell to make it clickable
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageScreen(
                    imageUrl: imageUrl,
                    authToken: _authToken,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 200,
                color: AppTheme.lightTheme.colorScheme.background,
                child: _buildImageWidget(activity.imageUrl, imageUrl),
              ),
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
                          '${activity.createdAt.day.toString().padLeft(2, '0')}/${activity.createdAt.month.toString().padLeft(2, '0')}/${activity.createdAt.year} ${activity.createdAt.hour.toString().padLeft(2, '0')}:${activity.createdAt.minute.toString().padLeft(2, '0')}',
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

  void _openFullScreenImage(String imageUrl, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageScreen(
          imageUrl: imageUrl,
          authToken: _authToken,
        ),
      ),
    );
  }
}