import 'package:flutter/material.dart';

class Mynetwork{

  final String username;
  final String? id;
  final String? role;
  final String Designnation;
  final String photoUrl;
  final String? organization;
  final IconData? reject;
  final IconData? accept;
  final String? aboutme;
  final String? email;
  final String? mobile;
  final String? businessLocation;
  final String? companywebsite;
  final String? contry;
  final String? city;
  final String? countrycode;
   final String? industry;
   final String? otherinfo;
   final String? purposeOfAttending;
   final String? brandname;
  final List<String>? socialLinks;
  final String? compayname;
  final String? category;

  Mynetwork({

    required this.username,
    required this.Designnation,
    required this.photoUrl,
    this.id,
    this.role,
     this.reject,
    this.brandname,
    this.otherinfo,
    this.accept,
    this.category,
    this.aboutme,
    this.organization,
    this.email,
    this.countrycode,
    this.mobile,
    this.purposeOfAttending,
    this.industry,
    this.companywebsite,
    this.contry,
    this.city,
    this.compayname,
    this.businessLocation,
    this.socialLinks,

});

}