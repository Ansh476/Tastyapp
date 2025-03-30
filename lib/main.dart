import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_option.dart';
import 'widgets/recipe_detail_screen.dart';
import 'models/recipe.dart';
import 'dart:async';
import 'signup_screen.dart';
import 'explore_screen.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'cart_provider.dart'; // Import CartProvider
import 'cart_page.dart';
import 'community_page.dart';
import '../services/cloudinary_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  CloudinaryService.init();
  runApp(
    MultiProvider( // Wrap MyApp with MultiProvider
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()), // Provide CartProvider
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasty',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: AuthWrapper(),
      routes: { // Add the routes here
        '/login': (context) => SignupScreen(), // Define the /login route
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return SignupScreen();
          } else {
            return MyHomePage();
          }
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Recipe> _recipes = [];
  String _searchTerm = '';
  Recipe? _randomRecipe;
  Timer? _timer;
  double _opacity = 1.0;
  Map<String, List<Recipe>> _areaRecipes = {};
  List<String> areas = [
    'Indian',
    'Canadian',
    'Italian',
    'Chinese',
    'Mexican',
    'Thai'
  ];
  bool _isLoadingAreaRecipes = true;
  int _selectedIndex = 0;

  // Add page controller
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    if (_selectedIndex == 0) {
      fetchRandomRecipe();
      fetchAreaRecipes();
      startRandomRecipeTimer();
    }
  }

  void startRandomRecipeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_selectedIndex == 0 && mounted) { // Added mounted check here
        setState(() {
          _opacity = 0.0;
        });
        Future.delayed(Duration(milliseconds: 500), () {
          fetchRandomRecipe();
          if(mounted){ // Added mounted check here
            setState(() {
              _opacity = 1.0;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchRandomRecipe() async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        setState(() {
          _randomRecipe = Recipe.fromJson(data['meals'][0]);
        });
      }
    }
  }

  Future<void> fetchAreaRecipes() async {
    setState(() {
      _isLoadingAreaRecipes = true;
    });
    Map<String, List<Recipe>> tempAreaRecipes = {};
    for (String area in areas) {
      final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?a=$area'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Recipe> recipes = (data['meals'] as List).map((json) => Recipe.fromJson(json)).toList();
          tempAreaRecipes[area] = recipes;
        }
      }
    }
    if (mounted) {
      setState(() {
        _areaRecipes = tempAreaRecipes;
        _isLoadingAreaRecipes = false;
      });
    }
  }

  Future<void> fetchRecipes() async {
    if (_searchTerm.isEmpty) {
      setState(() {
        _recipes = [];
      });
      return;
    }

    final response = await http.get(Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=$_searchTerm'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        setState(() {
          _recipes = (data['meals'] as List)
              .map((json) => Recipe.fromJson(json))
              .toList();
        });
      } else {
        setState(() {
          _recipes = [];
        });
      }
    }
  }

  List<Recipe> get filteredRecipes {
    return _recipes.where((recipe) =>
    recipe.strMeal.toLowerCase().contains(_searchTerm.toLowerCase()) ||
        recipe.ingredients.any((ingredient) =>
            ingredient.name.toLowerCase().contains(_searchTerm.toLowerCase()))).toList();
  }

  Future<Recipe?> fetchRecipeDetails(String recipeName) async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$recipeName'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return Recipe.fromJson(data['meals'][0]);
      }
    }
    return null;
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              fillColor: Colors.grey[800],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white),
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
                fetchRecipes();
              });
            },
          ),
        ),
        Expanded(
          child: _searchTerm.isEmpty
              ? SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: Duration(milliseconds: 500),
                  child: SizedBox(
                    height: 300,
                    child: _randomRecipe != null
                        ? InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(recipe: _randomRecipe!),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.grey[800],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(
                                _randomRecipe!.strMealThumb,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(Icons.error_outline),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _randomRecipe!.strMeal,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        : Center(child: CircularProgressIndicator()),
                  ),
                ),
                SizedBox(height: 20),
                if (!_isLoadingAreaRecipes)
                  ...areas.map((area) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            area,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _areaRecipes[area]?.length ?? 0,
                            itemBuilder: (context, index) {
                              final recipe = _areaRecipes[area]![index];
                              return InkWell(
                                onTap: () async {
                                  Recipe? detailedRecipe = await fetchRecipeDetails(recipe.strMeal);
                                  if (detailedRecipe != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RecipeDetailScreen(recipe: detailedRecipe),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 200,
                                  margin: EdgeInsets.only(right: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            recipe.strMealThumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Center(
                                                  child: Icon(Icons.error_outline),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          recipe.strMeal,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList()
                else
                  Center(child: CircularProgressIndicator()),
              ],
            ),
          )
              : ListView.builder(
            itemCount: filteredRecipes.length,
            itemBuilder: (context, index) {
              final recipe = filteredRecipes[index];
              return Card(
                color: Colors.grey[800],
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Image.network(
                          recipe.strMealThumb,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.error_outline),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        Text(
                          recipe.strMeal,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
        title: Row(
        children: [
        Padding(
        padding: const EdgeInsets.only(right: 8.0),
    child: Image.asset(
    'assets/tasty_logo.png',
    width: 30,
    height: 30,
    ),
    ),
    Text('Tasty'),
    ],
    ),
    centerTitle: false,
    ),
    body: PageView(
    controller: _pageController,
    onPageChanged: (index) {
    setState(() {
    _selectedIndex = index;
    if (index == 0) {
    startRandomRecipeTimer();
    } else {
    _timer?.cancel();
    }
    });
    },
    children: [
    _buildSearchPage(),
    ExploreScreen(),
      CommunityPage(),
    CartPage(),
      ProfilePage(),
    ],
    ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.grey[850],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

            if (index == 0) {
              startRandomRecipeTimer();
            } else {
              _timer?.cancel();
            }
          });
        },
      ),
    );
  }
}