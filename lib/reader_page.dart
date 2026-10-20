import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'glass.dart';
import 'store.dart';
import 'theme.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.book});
  final Book book;
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final controller = PdfViewerController();
  int page = 1;
  int total = 0;

  @override
  void initState() {
    super.initState();
    page = widget.book.lastPage;
    widget.book.openedAt = DateTime.now().millisecondsSinceEpoch;
    Store.update(widget.book);
  }

  PdfViewerParams get _params => PdfViewerParams(
    backgroundColor: HC.deep,
    onViewerReady: (document, c) {
      setState(() => total = document.pages.length);
      widget.book.total = total;
      if (widget.book.lastPage > 1)
        c.goToPage(pageNumber: widget.book.lastPage);
    },
    onPageChanged: (n) {
      if (n == null) return;
      setState(() => page = n);
      widget.book.lastPage = n;
      Store.update(widget.book);
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HC.deep,
    body: Stack(
      children: [
        if (kIsWeb)
          PdfViewer.data(
            widget.book.bytes!,
            sourceName: widget.book.id,
            controller: controller,
            params: _params,
          )
        else
          PdfViewer.file(
            widget.book.path,
            controller: controller,
            params: _params,
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$page من ${total == 0 ? '—' : total}',
                      style: TextStyle(color: HC.cream.withValues(alpha: .85)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
