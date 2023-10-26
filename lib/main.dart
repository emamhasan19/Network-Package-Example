import 'package:flutter/material.dart';
import 'package:network/network.dart';

const String baseUrl = 'https://jsonplaceholder.typicode.com/posts';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Package Example',
      home: NetworkDemo(
        restClient: RestClient(
          baseUrl: baseUrl,
          tokenCallBack: () => Future.value(null),
        ),
      ),
    );
  }
}

class NetworkDemo extends StatefulWidget {
  const NetworkDemo({
    super.key,
    required this.restClient,
  });

  final RestClient restClient;

  @override
  State<NetworkDemo> createState() => _NetworkDemoState();
}

class _NetworkDemoState extends State<NetworkDemo> {
  late List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Package'),
        centerTitle: true,
      ),
      body: posts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        posts[index].title,
                      ),
                      subtitle: Text(
                        posts[index].body,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              updatePost(
                                posts[index].id,
                                'Updated Title',
                                'Updated Body',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deletePost(posts[index].id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createPost(
            'New Title',
            'New Body',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> fetchPosts() async {
    final response = await widget.restClient.get(
      APIType.public,
      baseUrl,
      query: {
        '_page': 1,
        '_limit': 10,
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> body = response.data;
      setState(() {
        posts = body.map((dynamic item) => Post.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> createPost(String title, String body) async {
    final response = await widget.restClient.post(
      APIType.public,
      baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      {
        'title': title,
        'body': body,
        'userId': 1,
        'id': posts.length + 1,
      },
    );
    if (response.statusCode == 201) {
      final newPost = Post.fromJson(response.data);
      setState(() {
        posts.insert(0, newPost);
      });
    } else {
      throw Exception('Failed to create post');
    }
  }

  Future<void> updatePost(int id, String title, String body) async {
    final response = await widget.restClient.put(
      APIType.public,
      '$baseUrl/$id',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      {
        'title': title,
        'body': body,
        'userId': 1,
        'id': id,
      },
    );
    if (response.statusCode == 200) {
      final updatedPost = Post.fromJson(response.data);
      setState(() {
        final index = posts.indexWhere((post) => post.id == id);
        if (index != -1) {
          posts[index] = updatedPost;
        }
      });
    } else {
      throw Exception('Failed to update post');
    }
  }

  Future<void> deletePost(int id) async {
    final response = await widget.restClient.delete(
      APIType.public,
      '$baseUrl/$id',
    );
    if (response.statusCode == 200) {
      setState(() {
        posts.removeWhere((post) => post.id == id);
      });
    } else {
      throw Exception('Failed to delete post');
    }
  }
}

class Post {
  late final int id;
  late final int userId;
  late final String title;
  late final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
    );
  }
}
