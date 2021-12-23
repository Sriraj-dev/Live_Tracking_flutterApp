import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maps_sample/Screens/MapPage.dart';
import 'package:maps_sample/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController number = new TextEditingController();
  TextEditingController code = new TextEditingController();
  bool sendingCode = false;
  bool codeSent = false;
  bool verifyingOtp = false;
  String receivedCode = '';

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: kSecondaryColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(),
            Text(
              'Welcome to Maps',
              style: GoogleFonts.arvo(fontSize: 20, color: kPrimaryColor),
            ),
            SizedBox(
              height: 15,
            ),
            Material(
              borderRadius: BorderRadius.circular(20),
              elevation: 5,
              child: Container(
                height: size.height * 0.3,
                width: size.width * 0.8,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Please enter your mobile number',
                      style: GoogleFonts.lato(fontSize: 17, color: bgColor),
                    ),
                    SizedBox(
                      height: 35,
                    ),
                    (codeSent)?Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 40,
                          width: size.width * 0.4,
                          decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(5)),
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              controller: code,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter OTP',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        :Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(5)),
                            height: 40,
                            width: 45,
                            child: Center(
                              child: Text(
                                '+91',
                                style: GoogleFonts.lato(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Container(
                            height: 40,
                            width: size.width * 0.5,
                            decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                controller: number,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Enter mobile number',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    //Here is the elevated button.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: kSecondaryColor, elevation: 2),
                          onPressed: () {
                            if(!sendingCode){
                              setState(() {
                                sendingCode = true;
                              });
                              loginUser();
                            }
                            if(codeSent){
                              if(verifyingOtp){

                              }else{
                                verifyOtp();
                              }
                            }
                          },
                          child: Center(
                            child: (sendingCode)?
                            (codeSent)?(verifyingOtp)?
                            Transform.scale(
                              scale: 0.5,
                              child: CircularProgressIndicator(
                                color: kPrimaryColor,
                                strokeWidth: 3,
                              ),
                            )
                                :Text(
                              'Verify',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ):Transform.scale(
                              scale: 0.5,
                              child: CircularProgressIndicator(
                                color: kPrimaryColor,
                                strokeWidth: 3,
                              ),
                            )
                                :Text(
                              'Send OTP',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          )),
                    )
                  ],
                ),
              ),
            )
          ],
        ));
  }

  void loginUser() async {
    FirebaseAuth _auth = FirebaseAuth.instance;

    _auth.verifyPhoneNumber(
        phoneNumber: "+91${number.text}",
        timeout: Duration(seconds: 90),
        verificationCompleted: (AuthCredential credentials) async {
          UserCredential result = await _auth.signInWithCredential(credentials);
          User? user = result.user;
          if (user != null) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context)=>MapScreen(user))
            );
          }else{
            showSnackBar('An error Occurred!',Colors.red);
          }
        },
        verificationFailed: (FirebaseAuthException exception){
          setState(() {
            sendingCode = false;
            codeSent = false;
            verifyingOtp = false;
          });
          print(exception);
          showSnackBar('$exception', Colors.red);
        },
        codeSent: (String verificationId,[int? forceResendingToken])async{
          print('code sent is - $verificationId');
          setState(() {
            codeSent = true;
          });
          receivedCode = verificationId;

        }, codeAutoRetrievalTimeout: (String verificationId) {  },
        //codeAutoRetrievalTimeout: null
    );
  }

  void verifyOtp()async{
    setState(() {
      verifyingOtp = true;
    });
    print(receivedCode);
    try{
      AuthCredential credential = PhoneAuthProvider.credential(verificationId: receivedCode, smsCode: code.text);
      FirebaseAuth _auth = FirebaseAuth.instance;
      UserCredential result = await _auth.signInWithCredential(credential);

      User? user = result.user;
      if(user!=null){
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context)=>MapScreen(user))
        );
      }else{
        setState(() {
          sendingCode =false;
          codeSent = false;
        });
        showSnackBar('An error Occurred!', Colors.red);
      }
    }catch(e){
      setState(() {
        verifyingOtp = false;
      });
      showSnackBar('Invalid Code!', Colors.red);
    }
  }
  void showSnackBar(String text,Color color) {
    final snackBar = new SnackBar(
      duration: Duration(seconds: 2),
      elevation: 4,
      content: Text(text),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
