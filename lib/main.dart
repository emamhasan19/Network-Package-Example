import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:network_example/post_model.dart';

const String baseUrl = 'https://jsonplaceholder.typicode.com';
const String posts = '/posts';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  /// [FlutterNetwork] is a utility class for handling network requests in
  /// Flutter applications.
  ///
  /// It provides a convenient way to perform HTTP requests by encapsulating
  /// common networking functionalities and allowing customization of the
  /// base URL.
  final FlutterNetwork flutterNetwork = FlutterNetwork(baseUrl: baseUrl);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Package Example',
      home: NetworkExample(flutterNetwork: flutterNetwork),
    );
  }
}

class NetworkExample extends StatelessWidget {
  const NetworkExample({
    Key? key,
    required this.flutterNetwork,
  }) : super(key: key);

  final FlutterNetwork flutterNetwork;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Package'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<PostModel>>(
        future: fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No data available'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        snapshot.data![index].title,
                      ),
                      subtitle: Text(
                        snapshot.data![index].body,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  /// Fetches a list of posts from the specified API endpoint.
  ///
  /// Parameters:
  /// - [flutterNetwork]: The instance of [FlutterNetwork] used to make the
  ///   HTTP GET request.
  /// - [endpoint]: Specifies the specific API endpoint.
  /// - [apiType]: The [APIType] enum defines the type of API (public or
  ///   protected) to be accessed.
  /// - [query]: Optional parameter for passing query parameters.
  ///
  /// Returns a response containing the data from the API, or throws an
  /// exception if the request fails.
  Future<List<PostModel>> fetchPosts() async {
    try {
      final response = await flutterNetwork.get(
        posts,
        apiType: APIType.public,
        query: {
          '_page': 1,
          '_limit': 10,
        },
      );
      List<dynamic> body = response.data;
      return body.map((dynamic item) => PostModel.fromJson(item)).toList();
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      throw Exception('Failed to load posts');
    }
  }
}
