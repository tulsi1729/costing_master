import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod/riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
    firestore: ref.read(firestoreProvider),
    auth: ref.read(firebaseAuthProvider),
    googleSignIn: ref.read(googleSignInProvider)));
    

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository(
      {required FirebaseFirestore firestore,
      required FirebaseAuth auth,
      required GoogleSignIn googleSignIn})
      : _firestore = firestore,
        _auth = auth,
        _googleSignIn = googleSignIn;

  User? get currentUser => _auth.currentUser;
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  Stream<User?> get authStateChange => _auth.authStateChanges();

  Future<UserModel?> signInWithGoogle(bool isFromLogin) async {
    // try {
  final GoogleSignInAccount? googleUser =
    await _googleSignIn.signIn();

if (googleUser == null) return null;

final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

final credential = GoogleAuthProvider.credential(
  idToken: googleAuth.idToken,
  accessToken: googleAuth.accessToken,
);


    UserCredential userCredential;

    if (isFromLogin) {
      userCredential = await _auth.signInWithCredential(credential);
    } else {
      userCredential = await _auth.currentUser!.linkWithCredential(credential);
    }

    UserModel userModel;

    if (userCredential.additionalUserInfo!.isNewUser) {
      userModel = UserModel(
        name: userCredential.user!.displayName ?? "No Name ",
        uid: userCredential.user!.uid,
      );
      await _users.doc(userCredential.user!.uid).set(userModel.toMap());
    } else {
      userModel = await getUserData(userCredential.user!.uid).first;
    }
    return userModel;
    // }
    //  on FirebaseException catch (e) {
    //   throw e.message!;
    // } catch (e) {
    //   return left(Failure(e.toString()));
    // }
  }

  Stream<UserModel> getUserData(String uid) {
    return _users.doc(uid).snapshots().map(
        (event) => UserModel.fromMap(event.data() as Map<String, dynamic>));
  }

  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
