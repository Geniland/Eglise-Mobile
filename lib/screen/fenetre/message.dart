import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafintech/core/theme/app_color.dart';

Widget Message() {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.couleur1,
      leading: IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back)),
      actions: [
        IconButton(onPressed: () {}, icon: Icon(Icons.call)),
        IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
        IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
      ],
      title: Text('Nom'),
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 10, top: 5),
            child: Container(
              padding: EdgeInsets.all(12),
              color: AppColors.couleur21,
              child: Column(
                children: [
                  Text(
                    'ici message',
                    style: GoogleFonts.abel(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    '11:00',
                    style: GoogleFonts.abel(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 10, top: 5),
            child: Container(
              padding: EdgeInsets.all(12),
              color: AppColors.couleur21,
              child: Column(
                children: [
                  Text(
                    'ici message',
                    style: GoogleFonts.abel(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    '11:00',
                    style: GoogleFonts.abel(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(left: 10, top: 2),
            child: Container(
              padding: EdgeInsets.all(12),
              color: AppColors.couleur21,
              child: Column(
                children: [
                  Text(
                    'ici message',
                    style: GoogleFonts.abel(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    '11:00',
                    style: GoogleFonts.abel(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
