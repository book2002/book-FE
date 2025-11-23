import 'dart:io';

import 'package:flutter/material.dart';

// final String baseUrl = Platform.isAndroid ? "http://10.0.2.2:8080" : "http://localhost:8080";
final String baseUrl = "http://localhost:8080";
const String signupApiUrl = "http://localhost:8080/api/v1/member/signup";
const String loginApiUrl = "http://localhost:8080/api/v1/member/login";
const String googleApiUrl = "http://localhost:8080/oauth2/authorization/google";
const String profileSetupApiUrl = "http://localhost:8080/api/v1/profile/create";
const String profileEditApiUrl = "http://localhost:8080/api/v1/profile/update";
const String profileApiUrl = "http://localhost:8080/api/v1/profile/";

const Color primaryColor = Color(0xFF00AA00);
const Color errorColor = Color(0xFFCC0000);
const Color borderColor = Color(0xFFE1E1E1);