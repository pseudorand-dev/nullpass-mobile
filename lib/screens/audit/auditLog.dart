/*
 * Created by Ilan Rasekh on 2020/4/21
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/widgets.dart';
import 'package:timeline_list/timeline.dart';
import 'package:timeline_list/timeline_model.dart';

class AuditLog extends StatefulWidget {
  @override
  _AuditLogState createState() => _AuditLogState();
}

class _AuditLogState extends State<AuditLog> {
  List<AuditRecord> _auditRecords;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _auditRecords = <AuditRecord>[];
    NullPassDB.instance.getAllAuditRecords().then((ars) {
      setState(() {
        _auditRecords = ars ?? <AuditRecord>[];
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Audit Log')),
        body: new Container(child: CenterLoader()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Audit Log')),
      body: new Container(
        child: (_auditRecords.length < 1)
            ? CenterText("No Audit Records")
            : Timeline.builder(
                position: TimelinePosition.Center,
                itemCount: _auditRecords.length,
                itemBuilder: (context, index) {
                  final AuditRecord ar = _auditRecords[index];
                  return TimelineModel(
                      Card(
                        child: Text(ar.message),
                      ),
                      position: index % 2 == 0
                          ? TimelineItemPosition.right
                          : TimelineItemPosition.left,
                      isFirst: index == 0,
                      isLast: index == _auditRecords.length);
                },
              ),
      ),
    );
  }
}
