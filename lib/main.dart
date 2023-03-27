// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:interview_task/constants.dart';
import 'package:interview_task/state_management/local_db_processing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory root = await getTemporaryDirectory(); // this is using path_provider
  String directoryPath = root.path + '/user/data';
  await Hive.initFlutter(directoryPath);
  Hive.registerAdapter(MovieAdapter());
  Box<Movie> box = await Hive.openBox('userMovies');
  runApp(MyApp(box: box));
}

class MyApp extends StatelessWidget {
  Box<Movie> box;
  MyApp({Key? key, required this.box}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocalDB(box: box),
      child: MaterialApp(
        title: 'User Movie List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool addNew = false;
  late AnimationController animationController;
  late TextEditingController movieNameController;
  late TextEditingController directorNameController;

  @override
  void initState() {
    super.initState();
    context.read<LocalDB>().loadData();
    movieNameController = TextEditingController();
    directorNameController = TextEditingController();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    super.dispose();
    movieNameController.dispose();
    directorNameController.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: backgroundColor,
            title: Text('MoviesListPro',
                style: TextStyle(
                  color: appbarTextColor,
                )),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                addNew = !addNew;
              });
            },
            child: !addNew ? Icon(Icons.add) : Icon(Icons.clear)
          ),
          body: Consumer<LocalDB>(
            builder: (context, myType, child) {
              return Stack(
                children: [
                  myType.movies.isNotEmpty
                      ? BackdropFilter(
                          filter: addNew
                              ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
                              : ImageFilter.blur(),
                          child: GestureDetector(
                            onTap: () => setState(() {
                  addNew = false;
                }),
                            child: ListView.builder(
                              itemCount: myType.movies.length,
                              itemBuilder: (context, index) => ListTile(
                                trailing:
                                    IconButton(onPressed: () {
                                      context.read<LocalDB>().deleteMovie(
                                        myType.movies.elementAt(index));
                                    }, icon: Icon(Icons.delete)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                tileColor: listTileColor,
                                title: Text(myType.movies.elementAt(index).name,
                                    style: TextStyle(color: textColor)),
                                subtitle: Text(
                                    myType.movies.elementAt(index).directorName,
                                    style: TextStyle(color: textColor)),
                                leading: CircleAvatar(
                                  radius: 40,
                                    backgroundImage: MemoryImage(myType.movies
                                        .elementAt(index)
                                        .posterImage)),
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                              "You haven't added any movies :(\nPlease add a movie to see the list",
                              style: TextStyle())),
                  addNew
                      ? BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Center(
                            child: Container(
                                padding: const EdgeInsets.all(20),
                                width: size.width - 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: movieNameController,
                                      decoration: InputDecoration(
                                        label: const Text('Movie Name'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                    TextField(
                                      controller: directorNameController,
                                      decoration: InputDecoration(
                                        label: const Text('Director Name'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.read<LocalDB>().receiveImage();
                                      },
                                      style: TextButton.styleFrom(
                                        fixedSize: const Size(200, 30),
                                        backgroundColor: Colors.grey,
                                      ),
                                      child: Text(
                                        context
                                                .watch<LocalDB>()
                                                .imageDetails
                                                ?.name ??
                                            "Upload Movie Poster",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Movie newMovie = Movie(
                                            name: movieNameController.text,
                                            directorName:
                                                directorNameController.text,
                                            posterImage: await context
                                                    .read<LocalDB>()
                                                    .imageDetails
                                                    ?.readAsBytes() ??
                                                Uint8List(10));
              
                                        // try {
                                        movieNameController.text.isNotEmpty &&
                                                directorNameController
                                                    .text.isNotEmpty &&
                                                context
                                                        .read<LocalDB>()
                                                        .imageDetails !=
                                                    null
                                            ? {
                                                context
                                                    .read<LocalDB>()
                                                    .setMovie(
                                                        movie: newMovie,
                                                        onSuccess: () {
                                                          setState(() {
                                                            addNew = !addNew;
                                                            movieNameController
                                                                .text = "";
                                                            directorNameController
                                                                .text = "";
                                                            context
                                                                .read<LocalDB>()
                                                                .imageDetails = null;
                                                          });
                                                        },
                                                        onFail: () {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  const SnackBar(
                                                            content: Text(
                                                                "Movie Already Exists"),
                                                          ));
                                                        })
                                              }
                                            : null;
                                        // }  catch (e) {
              
                                        // }
                                      },
                                      style: TextButton.styleFrom(
                                        fixedSize: const Size(100, 30),
                                      ),
                                      child: const Text(
                                        "Add Movie",
                                        style: TextStyle(),
                                      ),
                                    )
                                  ],
                                )),
                          ),
                        )
                      : const IgnorePointer(child: SizedBox()),
                ],
              );
            },
          )),
    );
  }
}
