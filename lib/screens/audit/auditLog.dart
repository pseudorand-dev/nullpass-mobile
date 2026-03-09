/*
 * Created by Ilan Rasekh on 2020/4/21
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:nullpass/models/auditRecord.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/widgets.dart';
// TODO: Re-enable after timeline_list is updated for Dart 3.x compatibility
// import 'package:timeline_list/timeline.dart';
// import 'package:timeline_list/timeline_model.dart';

class AuditLog extends StatefulWidget {
  const AuditLog({super.key});

  @override
  _AuditLogState createState() => _AuditLogState();
}

class _AuditLogState extends State<AuditLog> {
  late List<AuditRecord> _auditRecords;
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
        appBar: AppBar(title: const Text('Audit Log')),
        body: Container(child: const CenterLoader()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: (_auditRecords.isEmpty)
          ? const CenterText("No Audit Records")
          : ListView.builder(
              itemCount: _auditRecords.length,
              itemBuilder: (context, index) {
                final AuditRecord ar = _auditRecords[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    title: Text(
                      ar.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      ar.date.toString().split(".")[0],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
