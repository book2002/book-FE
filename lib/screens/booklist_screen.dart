import 'package:flutter/material.dart';
import 'package:flutter_app/testdata/book_dummy.dart';
import 'package:flutter_app/widget/BookListWidget.dart';

class BooklistScreen extends StatefulWidget {

  const BooklistScreen ({
    Key? key,
  }) : super(key: key);

  @override
  State<BooklistScreen> createState() => _BooklistScreenState();
}

class _BooklistScreenState extends State<BooklistScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
        child: Column(
          children: [
            //상단 탭바
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: "읽는 중"),
                Tab(text: "읽기 전"),
                Tab(text: "다 읽은"),
              ]
            ),
            //하단
            Expanded(
              child: TabBarView(
                children: [
                  BookListWidget(books: dummyBooks, tabType: 'reading'),
                  BookListWidget(books: dummyBooks, tabType: 'before'),
                  BookListWidget(books: dummyBooks, tabType: 'done'),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}