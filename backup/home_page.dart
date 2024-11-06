import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Saga'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo, Colors.purple],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications page
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings page
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Academic'),
            Tab(text: 'Facility'),
            Tab(text: 'Safety'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(),
          _buildPostList(category: 'Academic'),
          _buildPostList(category: 'Facility'),
          _buildPostList(category: 'Safety'),
        ],
      ),
    );
  }

  Widget _buildPostList({String? category}) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return PostCard(
          title: 'Sample Post Title',
          content: 'This is a sample post content. It can be quite long and will be truncated if it exceeds the available space.',
          imageUrl: 'https://picsum.photos/seed/${index + 1}/400/200',
          onTap: () {
            // TODO: Navigate to post detail page
          },
        );
      },
    );
  }
}

class PostCard extends StatelessWidget {
  final String title;
  final String content;
  final String imageUrl;
  final VoidCallback onTap;

  const PostCard({
    Key? key,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(context, Icons.thumb_up, 'Agree', Colors.green),
                      _buildActionButton(context, Icons.thumb_down, 'Disagree', Colors.red),
                      _buildActionButton(context, Icons.comment, 'Comment', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color) {
    return TextButton.icon(
      onPressed: () {
        // TODO: Implement action
      },
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }
}