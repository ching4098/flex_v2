import 'package:flex_v2/data.dart' as prefix1;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter/widgets.dart';
import 'package:flex_v2/data.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flex_v2/Models/todo.dart';
import 'package:flex_v2/Auth/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as prefix0;
import 'package:flex_v2/Pages/profilePage.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _MyHomePageState();
}

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;

class _MyHomePageState extends State<MyHomePage> {
  var currentPage = images.length - 1.0;

  List<Todo> _todoList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;

  prefix0.Query _todoQuery;

  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();

    _checkEmailVerification();

    _todoList = new List();
    _todoQuery = _database
        .reference()
        .child("todo")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
    _onTodoChangedSubscription =
        _todoQuery.onChildChanged.listen(_onEntryChanged);
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail() {
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: new Text("Verify your account"),
          content: new Text("Please verify account in the link sent to email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Resent link"),
              onPressed: () {
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new OutlineButton(
              child: new Text("Dismiss"),
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: new Text("Verify your account"),
          content:
              new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new OutlineButton(
              child: new Text("Dismiss"),
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = _todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _todoList[_todoList.indexOf(oldEntry)] =
          Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  _addNewTodo(String todoItem) {
    if (todoItem.length > 0) {
      Todo todo = new Todo(todoItem.toString(), widget.userId, false);
      _database.reference().child("todo").push().set(todo.toJson());
    }
  }

  _updateTodo(Todo todo) {
    //Toggle completed
    todo.completed = !todo.completed;
    if (todo != null) {
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  _deleteTodo(String todoId, int index) {
    _database.reference().child("todo").child(todoId).remove().then((_) {
      print("Delete $todoId successful");
      setState(() {
        _todoList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(
                    child: new TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add new todo',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    _addNewTodo(_textEditingController.text.toString());
                    Navigator.pop(context);
                  })
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(
      initialPage: images.length - 1,
    );
    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
    });

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 270,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                image: DecorationImage(
                  image: AssetImage("assets/images/gradientcolour.jpg"),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.only(
                  left: 12.0, right: 12.0, top: 30.0, bottom: 8.0),
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          FlatButton.icon(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProfilePage()));
                              },
                              icon: Icon(Icons.account_circle),
                              label: Text('Profile'))
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            child: Text(
                              'LOGOUT',
                              style: new TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Futura',
                                  fontSize: 20.0),
                            ),
                            onPressed: () {
                              _signOut();
                            },
                          ),
                        ],
                      ),
                    ]
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 50,
                                ),
                                Text(
                                  "Welcome to flex",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900),
                                ),
//                                SizedBox(
//                                  height: 16,
//                                ),
                                Text(
                                  "A new way to flex up your life",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
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
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Goals",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 46.0,
                        fontFamily: "HelveticaNeue",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                  SizedBox(
                    height: 80,
                  ),
                ],
              ),
            ),
            Container(
              height: 350.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 250.0,
                        margin: new EdgeInsets.symmetric(horizontal: 15.0),
                        child: Image.asset(
                          "assets/images/eat.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 80.0, top: 238.0),
                        child: RaisedButton(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text("Learn More",
                              style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => eat()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 250.0,
                        margin: new EdgeInsets.symmetric(horizontal: 15.0),
                        child: Image.asset(
                          "assets/images/study.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 80.0, top: 238.0),
                        child: RaisedButton(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text("Learn More",
                              style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => study()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 250.0,
                        margin: new EdgeInsets.symmetric(horizontal: 15.0),
                        child: Image.asset(
                          "assets/images/workout.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 80.0, top: 238.0),
                        child: RaisedButton(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text("Learn More",
                              style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => workout()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 250.0,
                        margin: new EdgeInsets.symmetric(horizontal: 15.0),
                        child: Image.asset(
                          "assets/images/rehydrated.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 80.0, top: 238.0),
                        child: RaisedButton(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text("Learn More",
                              style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => rehydrated()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 250.0,
                        margin: new EdgeInsets.symmetric(horizontal: 15.0),
                        child: Image.asset(
                          "assets/images/sleep.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 80.0, top: 238.0),
                        child: RaisedButton(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text("Learn More",
                              style: TextStyle(color: Colors.black)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => sleep()),
                            );
                          },
                        ),
                      ),
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
}

class AnimatedButton extends StatefulWidget {
  final String initialText, finalText;
  final ButtonStyle buttonStyle;
  final IconData iconData;
  final double iconSize;
  final Duration animationDuration;
  final Function onTap;

  AnimatedButton(
      {this.initialText,
      this.finalText,
      this.iconData,
      this.iconSize,
      this.animationDuration,
      this.buttonStyle,
      this.onTap});

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  AnimationController _controller;
  ButtonState _currentState;
  Duration _smallDuration;
  Animation<double> _scaleFinalTextAnimation;

  @override
  void initState() {
    super.initState();
    _currentState = ButtonState.SHOW_ONLY_TEXT;
    _smallDuration = Duration(
        milliseconds: (widget.animationDuration.inMilliseconds * 0.2).round());
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _controller.addListener(() {
      double _controllerValue = _controller.value;
      if (_controllerValue < 0.2) {
        setState(() {
          _currentState = ButtonState.SHOW_ONLY_ICON;
        });
      } else if (_controllerValue > 0.8) {
        setState(() {
          _currentState = ButtonState.SHOW_TEXT_ICON;
        });
      }
    });

    _controller.addStatusListener((currentStatus) {
      if (currentStatus == AnimationStatus.completed) {
        return widget.onTap();
      }
    });

    _scaleFinalTextAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: widget.buttonStyle.elevation,
      borderRadius:
          BorderRadius.all(Radius.circular(widget.buttonStyle.borderRadius)),
      child: InkWell(
        onTap: () {
          _controller.forward();
        },
        child: AnimatedContainer(
          duration: _smallDuration,
          height: widget.iconSize + 16,
          decoration: BoxDecoration(
            color: (_currentState == ButtonState.SHOW_ONLY_ICON ||
                    _currentState == ButtonState.SHOW_TEXT_ICON)
                ? widget.buttonStyle.secondaryColor
                : widget.buttonStyle.primaryColor,
            border: Border.all(
                color: (_currentState == ButtonState.SHOW_ONLY_ICON ||
                        _currentState == ButtonState.SHOW_TEXT_ICON)
                    ? widget.buttonStyle.primaryColor
                    : Colors.transparent),
            borderRadius: BorderRadius.all(
                Radius.circular(widget.buttonStyle.borderRadius)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal:
                (_currentState == ButtonState.SHOW_ONLY_ICON) ? 16.0 : 48.0,
            vertical: 8.0,
          ),
          child: AnimatedSize(
            vsync: this,
            curve: Curves.easeIn,
            duration: _smallDuration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                (_currentState == ButtonState.SHOW_ONLY_ICON ||
                        _currentState == ButtonState.SHOW_TEXT_ICON)
                    ? Icon(
                        widget.iconData,
                        size: widget.iconSize,
                        color: widget.buttonStyle.primaryColor,
                      )
                    : Container(),
                SizedBox(
                  width:
                      _currentState == ButtonState.SHOW_TEXT_ICON ? 30.0 : 0.0,
                ),
                getTextWidget()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getTextWidget() {
    if (_currentState == ButtonState.SHOW_ONLY_TEXT) {
      return Text(
        widget.initialText,
        style: widget.buttonStyle.initialTextStyle,
      );
    } else if (_currentState == ButtonState.SHOW_ONLY_ICON) {
      return Container();
    } else {
      return ScaleTransition(
        scale: _scaleFinalTextAnimation,
        child: Text(
          widget.finalText,
          style: widget.buttonStyle.finalTextStyle,
        ),
      );
    }
  }
}

class ButtonStyle {
  final TextStyle initialTextStyle, finalTextStyle;
  final Color primaryColor, secondaryColor;
  final double elevation, borderRadius;

  ButtonStyle(
      {this.primaryColor,
      this.secondaryColor,
      this.initialTextStyle,
      this.finalTextStyle,
      this.elevation,
      this.borderRadius});
}

enum ButtonState { SHOW_ONLY_TEXT, SHOW_ONLY_ICON, SHOW_TEXT_ICON }

class eat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    double c_width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 260.0, top: 40.0),
                child: IconButton(
                  icon: new Icon(Icons.close),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60.0, top: 40.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text("Breakfast",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 46.0,
                        fontFamily: "HelveticaNeue",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: c_width,
                child: Padding(
                  padding: const EdgeInsets.only(left: 80.0, top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            "Breakfast – The Most Important Meal of The Day. A day starts best with a filled tummy! Experience comparably different mornings with good breakfast meals with FLEX buddies, friends, and families. Suggested breakfast foods range from a simple sunny side up to glorious chicken & waffles. What are you waiting for? Have your breakfast now and complete your daily FLEX task!",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                              fontFamily: "HelveticaNeue",
                              letterSpacing: 1.0,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 90.0, top: 200.0),
                child: RaisedButton(
                  color: Colors.teal[200],
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: Text("Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      )),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => congrats()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class study extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    double c_width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 260.0, top: 40.0),
                child: IconButton(
                  icon: new Icon(Icons.close),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60.0, top: 40.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text("Book Binging",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 46.0,
                        fontFamily: "HelveticaNeue",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: c_width,
                child: Padding(
                  padding: const EdgeInsets.only(left: 80.0, top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            "Book Binging – Its Like Netflix But Better A few pages of a book per day is enough to account for a week’s worth of learning! Have a good read with some light on your bed or even on the good ol’ coffee table. Binging books rather than Netflix because a novel is only as fun as your wild and magical imagination, get your mind stimulated with just a few minutes of seamless reading and complete your FLEX task now!",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                              fontFamily: "HelveticaNeue",
                              letterSpacing: 1.0,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 90.0, top: 200.0),
                child: RaisedButton(
                  color: Colors.teal[200],
                  padding:
                  EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: Text("Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      )),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => congrats()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class workout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    double c_width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 260.0, top: 40.0),
                child: IconButton(
                  icon: new Icon(Icons.close),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60.0, top: 40.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text("Jog On",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 46.0,
                        fontFamily: "HelveticaNeue",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: c_width,
                child: Padding(
                  padding: const EdgeInsets.only(left: 80.0, top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            "Have a great morning’s jog with FLEX! A morning is the best filled with energy, friends, and the morning sunrise view. Experience extraordinarily wonderful mornings with FLEX buddies, friends, and families. Get your jog on today! But do remember to get yourself a comfortable pair of trainers for maximum enjoyment and for your own safety. Hit the start button and start your daily JOG ON routine now!",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                              fontFamily: "HelveticaNeue",
                              letterSpacing: 1.0,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 90.0, top: 200.0),
                child: RaisedButton(
                  color: Colors.teal[200],
                  padding:
                  EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: Text("Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      )),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => congrats()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class rehydrated extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    double c_width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 260.0, top: 40.0),
                child: IconButton(
                  icon: new Icon(Icons.close),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60.0, top: 40.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text("Rehydrated",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 46.0,
                        fontFamily: "HelveticaNeue",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: c_width,
                child: Padding(
                  padding: const EdgeInsets.only(left: 80.0, top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            "Rehydrate – The Bread and Butter of Maintaining Good Health A cup of water is important for maintaining your body temperature, keeping your skin hydrated and also your mind fresh for your activities and challenges throughout the day. FLEX is here to remind you to get your daily serving of 8 cups of water per day so you won’t dry out like the Sahara Desert. Have a cup of water and complete your daily FLEX task now! ",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                              fontFamily: "HelveticaNeue",
                              letterSpacing: 1.0,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 90.0, top: 200.0),
                child: RaisedButton(
                  color: Colors.teal[200],
                  padding:
                  EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: Text("Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      )),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => congrats()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class sleep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    double c_width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 260.0, top: 40.0),
                child: IconButton(
                  icon: new Icon(Icons.close),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60.0, top: 40.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text("Sleep In",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 46.0,
                        fontFamily: "HelveticaNeue",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: c_width,
                child: Padding(
                  padding: const EdgeInsets.only(left: 80.0, top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            "Sleeping In – A Pure Enjoyment of Life Chill yourself out, calm yourself down, rest your soul and let your comfy bed do the rest. Recommended once a week, on a weekend especially to serve as a reward for your hard work done during the busy weekdays. Have some background music on and sleep till your body realises it has enough rest and wakes you up. Snuggle up in your warm blanket and complete your FLEX task now!",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                              fontFamily: "HelveticaNeue",
                              letterSpacing: 1.0,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 90.0, top: 200.0),
                child: RaisedButton(
                  color: Colors.teal[200],
                  padding:
                  EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: Text("Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      )),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => congrats()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class congrats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body:Stack(
        children: <Widget>[
          Container(
            child: Image.asset(
              "assets/images/congratulation.png",
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 160.0, top: 650.0),
            child: RaisedButton(
              color: Colors.teal[200],
              padding: EdgeInsets.symmetric(
                  horizontal: 32.0, vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: Text("Continue",
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}