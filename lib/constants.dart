import 'dart:io';

import 'package:flutter/material.dart';

final String baseUrl = "http://43.200.103.186:8080";
const String signupApiUrl = "http://43.200.103.186:8080/api/v1/member/signup";
const String loginApiUrl = "http://43.200.103.186:8080/api/v1/member/login";
const String googleApiUrl = "http://43.200.103.186:8080/oauth2/authorization/google";
const String profileSetupApiUrl = "http://43.200.103.186:8080/api/v1/profile/create";
const String profileEditApiUrl = "http://43.200.103.186:8080/api/v1/profile/update";
const String profileApiUrl = "http://43.200.103.186:8080/api/v1/profile/";

const Color primaryColor = Color(0xFF00AA00);
const Color errorColor = Color(0xFFCC0000);
const Color borderColor = Color(0xFFE1E1E1);