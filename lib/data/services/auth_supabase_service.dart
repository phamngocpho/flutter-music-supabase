import 'package:dartz/dartz.dart';
import 'package:spotify/core/constants/app_urls.dart';
import 'package:spotify/data/models/create_user_req.dart';
import 'package:spotify/data/models/signin_user_req.dart';
import 'package:spotify/data/models/user_model.dart';
import 'package:spotify/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthSupabaseService {
  Future<Either> signup(CreateUserReq createUserReq);
  Future<Either> signin(SigninUserReq signinUserReq);
  Future<Either> getUser();
}

class AuthSupabaseServiceImpl extends AuthSupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Either> signin(SigninUserReq signinUserReq) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: signinUserReq.email,
        password: signinUserReq.password
      );
      return const Right('Signin was Successful');
    } on AuthException catch(e) {
      String message = '';
      if(e.message.contains('Invalid login credentials')) {
        message = 'Invalid email or password';
      } else if (e.message.contains('Email not confirmed')) {
        message = 'Please verify your email address';
      } else {
        message = e.message;
      }
      return Left(message);
    } catch (e) {
      return Left('An error occurred: ${e.toString()}');
    }
  }

  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    try {
      var response = await _supabase.auth.signUp(
        email: createUserReq.email,
        password: createUserReq.password
      );

      if (response.user != null) {
        await _supabase.from('Users').insert({
          'id': response.user!.id,
          'name': createUserReq.fullName,
          'email': response.user!.email,
        });
      }
      return const Right('Signup was Successful');
    } on AuthException catch(e) {
      String message = '';
      if(e.message.contains('Password should be at least')) {
        message = 'The password provided is too weak';
      } else if (e.message.contains('User already registered')) {
        message = 'An account already exists with that email.';
      } else {
        message = e.message;
      }
      return Left(message);
    } catch (e) {
      return Left('An error occurred: ${e.toString()}');
    }
  }

  @override
  Future<Either> getUser() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return const Left('No user logged in');
      }

      var userData = await _supabase
        .from('Users')
        .select()
        .eq('id', user.id)
        .single();

      UserModel userModel = UserModel.fromJson(userData);
      userModel.imageURL = user.userMetadata?['avatar_url'] ?? AppURLs.defaultImage;
      UserEntity userEntity = userModel.toEntity();
      return Right(userEntity);
    } catch (e) {
      return Left('An error occurred: ${e.toString()}');
    }
  }
}

