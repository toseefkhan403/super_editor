import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/src/test/ime.dart';
import 'package:super_editor/src/test/super_editor_test/supereditor_inspector.dart';
import 'package:super_editor/src/test/super_editor_test/supereditor_robot.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import 'supereditor_test_tools.dart';
import 'test_documents.dart';

void main() {
  group("SuperEditor", () {
    group("applies attributions", () {
      group("when selecting by tapping", () {
        testWidgetsOnAllPlatforms("and typing at the end of the attributed text", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("A **bold** text")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at "bold|".
          await tester.placeCaretInParagraph(doc.nodes.first.id, 6);

          // Type at an offset that should expand the bold attribution.
          await tester.typeImeText("er");

          // Place the caret at "text|".
          await tester.placeCaretInParagraph(doc.nodes.first.id, 13);

          // Type at an offset that shouldn't expand any attributions.
          await tester.typeImeText(".");

          // Ensure the bold attribution was applied to the inserted text.
          expect(doc, equalsMarkdown("A **bolder** text."));
        });

        testWidgetsOnAllPlatforms("and typing at the middle of the attributed text", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("A **bld** text")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at b|ld.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 3);

          // Type at an offset that should expand the bold attribution.
          await tester.typeImeText("o");

          // Place the caret at A|.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 1);

          // Type at an offset that shouldn't expand any attributions.
          await tester.typeImeText("nother");

          // Ensure the bold attribution was applied to the inserted text.
          expect(doc, equalsMarkdown("Another **bold** text"));
        });

        testWidgetsOnAllPlatforms("and typing at the middle of a link", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("[This is a link](https://google.com) to google")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at This is a|.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 9);

          // Type at an offset that should expand the link attribution.
          await tester.typeImeText("nother");

          // Place the caret at google|.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 30);

          // Type at an offset that shouldn't expand any attributions.
          await tester.typeImeText(".");

          // Ensure the link attribution was applied to the inserted text.
          expect(doc, equalsMarkdown("[This is another link](https://google.com) to google."));
        });
      });

      group("when selecting by the keyboard", () {
        testWidgetsOnAllPlatforms("and typing at the end of the attributed text", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("A **bold** text")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at |text.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 7);

          // Press left arrow to place the caret at bold|.
          await tester.pressLeftArrow();

          // Type at an offset that should expand the bold attribution.
          await tester.typeImeText("er");

          // Press right arrow to place the caret at |text.
          await tester.pressRightArrow();

          // Type at an offset that shouldn't expand any attributions.
          await tester.typeImeText("new ");

          // Ensure the bold attribution was applied to the inserted text.
          expect(doc, equalsMarkdown("A **bolder** new text"));
        });

        testWidgetsOnAllPlatforms("and typing at the middle of the attributed text", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("A **bld** text")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at A|.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 1);

          // Press right arrow twice to place the caret at b|ld.
          await tester.pressRightArrow();
          await tester.pressRightArrow();

          // Type at an offset that should expand the bold attribution.
          await tester.typeImeText("o");

          // Pres right arrow three times to place the caret at bold |text.
          await tester.pressRightArrow();
          await tester.pressRightArrow();
          await tester.pressRightArrow();

          // Type at an offset that shouldn't expand any attributions.
          await tester.typeImeText("new ");

          // Ensure the bold attribution was applied to the inserted text.
          expect(doc, equalsMarkdown("A **bold** new text"));
        });

        testWidgetsOnAllPlatforms("and typing at the middle of a link", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("[This is a link](https://google.com) to google")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at |to google.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 15);

          // Press left arrow twice to place caret at lin|k.
          await tester.pressLeftArrow();
          await tester.pressLeftArrow();

          // Typing at this offset should expand the link attribution.
          await tester.typeImeText("n");

          // Press right arrow twice to place caret at |to google.
          await tester.pressRightArrow();
          await tester.pressRightArrow();

          // Typing at this offset shouldn't expand any attributions.
          await tester.typeImeText("pointing ");

          // Ensure the link attribution was applied to the inserted text.
          expect(doc, equalsMarkdown("[This is a linnk](https://google.com) pointing to google"));
        });
      });

      group("when a single node is selected", () {
        testWidgetsOnAllPlatforms("toggles attribution throughout a node", (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphDocShortText(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;

          // Ensure markers are empty.
          expect(
            firstNode.text.spans.markers,
            isEmpty,
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, firstNode.text.length),
            {boldAttribution},
          );

          // Ensure attribution was applied throughout the selection.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, firstNode.text.length),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from the selection.
          expect(
            firstNode.text.spans.markers,
            isEmpty,
          );
        });

        testWidgetsOnAllPlatforms("toggles attribution on a partial node selection", (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphDocShortText(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;

          // Ensure markers are empty.
          expect(
            firstNode.text.spans.markers,
            isEmpty,
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, 17),
            {boldAttribution},
          );

          // Ensure attribution was applied to the selection.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first** node in a document.",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, 17),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from the selection.
          expect(
            firstNode.text.spans.markers,
            isEmpty,
          );
        });

        testWidgetsOnAllPlatforms("toggles an attribution within a sub-range of an existing same attribution",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphDocAllBold(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is present.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, 17),
            {boldAttribution},
          );

          // Ensure bold attribution is removed from the selection.
          expect(
            doc,
            equalsMarkdown(
              "This is the first** node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, 17),
            {boldAttribution},
          );

          // Ensure bold attribution is applied throughout the node.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first**** node in a document.**",
            ),
          );
        });

        testWidgetsOnAllPlatforms("toggles a different attribution within a sub-range of another existing attribution",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphDocAllBold(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is present.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, 17),
            {italicsAttribution},
          );

          // Ensure italic attribution is applied to the selection.
          expect(
            doc,
            equalsMarkdown(
              "***This is the first* node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, 17),
            {italicsAttribution},
          );

          // Ensure bold attribution is applied throughout the node.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**",
            ),
          );
        });

        testWidgetsOnAllPlatforms("toggles multiple attributions throughout a node", (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphDocShortText(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;

          // Ensure markers are empty.
          expect(
            firstNode.text.spans.markers,
            isEmpty,
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, firstNode.text.length),
            {italicsAttribution, boldAttribution},
          );

          // Ensure both bold and italic attributions were applied throughout the node.
          expect(
            doc,
            equalsMarkdown(
              "***This is the first node in a document.***",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            firstNode.selectionBetween(0, firstNode.text.length),
            {boldAttribution, italicsAttribution},
          );

          // Ensure both bold and italic attributions are removed from the node.
          expect(
            firstNode.text.spans.markers,
            isEmpty,
          );
        });
      });

      group("when multiple nodes are selected", () {
        testWidgetsOnAllPlatforms("toggles attribution throughout multiple nodes", (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                twoParagraphDoc(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          // Ensure markers are empty for both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution is applied throughout both nodes.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles an attribution across nodes with the attribution applied throughout first node", (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                _paragraphFullBoldThenParagraph(),
              )
              .pump();

          final Editor editor = context.editor;

          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is applied throughout the first node.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\nThis is the second node in a document.",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          editor.execute([
            ToggleTextAttributionsRequest(
              documentRange: DocumentSelection(
                base: firstNode.beginningDocumentPosition,
                extent: secondNode.endDocumentPosition,
              ),
              attributions: {boldAttribution},
            )
          ]);

          // Ensure bold attribution is applied throughout both nodes.
          //
          // The toggled attribution already existed across the selection. In
          // such cases, the attribution is applied throughout the selection without removing it from
          // any of the node selections that already have it.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles an attribution across nodes with the attribution applied partially within first node",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                _paragraphPartiallyBoldThenParagraph(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is applied partially to the first node.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first** node in a document.\n\nThis is the second node in a document.",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution is applied throughout the both nodes.
          //
          // The toggled attribution already existed across the selection.In
          // such cases, the attribution is applied throughout the selection without removing it from
          // any of the node selections that already have it.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles an attribution across nodes with the attribution applied throughout and partially within first and second node respectively",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                _paragraphFullyBoldThenParagraphPartiallyBold(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is applied partially to first node and
          // throughout the second node.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first** node in a document.\n\n**This is the second node in a document.**",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution is applied throughout the both nodes.
          //
          // The toggled attribution already existed across the selection. In
          // such cases, the attribution is applied throughout the selection without removing it from
          // any of the node selections that already have it.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles an attribution across nodes with the attribution applied partially within all nodes",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                _paragraphPartiallyBoldThenParagraphPartiallyBold(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is applied partially across both nodes.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first** node in a document.\n\n**This is the second** node in a document.",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution is applied throughout the both nodes.
          //
          // The toggled attribution already existed across the selection. In
          // such cases, the attribution is applied throughout the selection without removing it from
          // any of the node selections that already have it.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution},
          );

          // Ensure bold attribution was removed from both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles a different attribution across nodes with an existing attribution applied throughout them",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                twoParagraphDocAllBold(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is applied throughout both nodes.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          final firstNode = doc.getNodeById("1")!;
          final secondNode = doc.getNodeById("2")!;

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {italicsAttribution},
          );

          // Ensure both bold and italic attributions were applied throughout the selection.
          expect(
            doc,
            equalsMarkdown(
              "***This is the first node in a document.***\n\n***This is the second node in a document.***",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {italicsAttribution},
          );

          // Ensure italic attribution was removed from both nodes.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles a different attribution partially across nodes with an existing attribution applied throughout them",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                twoParagraphDocAllBold(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          // Ensure bold attribution is applied throughout the selection.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.positionAt(18),
            ),
            {italicsAttribution},
          );

          // Ensure both bold and italic attributions were applied throughout
          // the selection.
          expect(
            doc,
            equalsMarkdown(
              "***This is the first node in a document.***\n\n***This is the second* node in a document.**",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.positionAt(18),
            ),
            {italicsAttribution},
          );

          // Ensure italic attribution was removed from the selection while keeping the bold
          // attribution.
          expect(
            doc,
            equalsMarkdown(
              "**This is the first node in a document.**\n\n**This is the second node in a document.**",
            ),
          );
        });

        testWidgetsOnAllPlatforms("toggles multiple attributions throughout multiple nodes", (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                twoParagraphDoc(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          // Ensure markers are empty for both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {
              italicsAttribution,
              boldAttribution,
            },
          );

          // Ensure both bold and italic attributions were applied throughout the selection.
          expect(
            doc,
            equalsMarkdown(
              "***This is the first node in a document.***\n\n***This is the second node in a document.***",
            ),
          );

          // Toggle bold attribution for both nodes.
          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.beginningDocumentPosition,
              extent: secondNode.endDocumentPosition,
            ),
            {boldAttribution, italicsAttribution},
          );

          // Ensure markers are empty for both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles attribution for a selection going halfway from first node and halfway within second node",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                twoParagraphDoc(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;
          final secondNode = doc.getNodeById("2")! as TextNode;

          // Ensure markers are empty for both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.positionAt(18),
              extent: secondNode.positionAt(18),
            ),
            {boldAttribution},
          );

          // Ensure bold attribution was applied.
          expect(
            doc,
            equalsMarkdown(
              "This is the first **node in a document.**\n\n**This is the second** node in a document.",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.positionAt(18),
              extent: secondNode.positionAt(18),
            ),
            {boldAttribution},
          );

          // Ensure markers are empty for both nodes.
          expect(
            firstNode.text.spans.markers.isEmpty && secondNode.text.spans.markers.isEmpty,
            true,
          );
        });

        testWidgetsOnAllPlatforms(
            "toggles attribution for a selection going halfway in first node till the halfway into the third node",
            (tester) async {
          final TestDocumentContext context = await tester //
              .createDocument()
              .withCustomContent(
                threeParagraphDoc(),
              )
              .pump();

          final Editor editor = context.editor;
          final doc = SuperEditorInspector.findDocument()!;

          final firstNode = doc.getNodeById("1")! as TextNode;
          final thirdNode = doc.getNodeById("3")! as TextNode;

          // Ensure no attributions are present.
          expect(
            doc,
            equalsMarkdown(
              "This is the first node in a document.\n\nThis is the second node in a document.\n\nThis is the third node in a document.",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.positionAt(18),
              extent: thirdNode.positionAt(18),
            ),
            {boldAttribution},
          );

          // Ensure bold attributions were applied.
          expect(
            doc,
            equalsMarkdown(
              "This is the first **node in a document.**\n\n**This is the second node in a document.**\n\n**This is the third **node in a document.",
            ),
          );

          editor.toggleAttributionsForDocumentSelection(
            DocumentSelection(
              base: firstNode.positionAt(18),
              extent: thirdNode.positionAt(18),
            ),
            {boldAttribution},
          );

          // Ensure no attributions are present.
          expect(
            doc,
            equalsMarkdown(
              "This is the first node in a document.\n\nThis is the second node in a document.\n\nThis is the third node in a document.",
            ),
          );
        });
      });

      group("applies color attributions", () {
        testWidgetsOnAllPlatforms("to full text", (tester) async {
          await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphFullColor(),
              )
              .pump();

          // Ensure the text is colored orange.
          expect(
            SuperEditorInspector.findRichTextInParagraph("1").style?.color,
            Colors.orange,
          );
        });

        testWidgetsOnAllPlatforms("to partial text", (tester) async {
          await tester //
              .createDocument()
              .withCustomContent(
                singleParagraphWithPartialColor(),
              )
              .pump();

          // Ensure the first span is colored black.
          expect(
            SuperEditorInspector.findRichTextInParagraph("1")
                .getSpanForPosition(const TextPosition(offset: 0))!
                .style!
                .color,
            Colors.black,
          );

          // Ensure the second span is colored orange.
          expect(
            SuperEditorInspector.findRichTextInParagraph("1")
                .getSpanForPosition(const TextPosition(offset: 5))!
                .style!
                .color,
            Colors.orange,
          );
        });
      });

      group("doesn't apply attributions", () {
        testWidgetsOnAllPlatforms("when typing before the start of the attributed text", (tester) async {
          await tester //
              .createDocument()
              .fromMarkdown("A **bold** text")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = SuperEditorInspector.findDocument()!;

          // Place the caret at |bold.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 2);

          // Type some letters.
          await tester.typeImeText("very ");

          // Ensure the bold attribution wasn't applied to the inserted text.
          expect(doc, equalsMarkdown("A very **bold** text"));
        });
      });

      group("doesn't clear attributions", () {
        testWidgetsOnAllPlatforms("when changing the selection affinity", (tester) async {
          final context = await tester //
              .createDocument()
              .fromMarkdown("This text should be")
              .withInputSource(TextInputSource.ime)
              .pump();

          final doc = context.findEditContext().document;
          final composer = context.findEditContext().composer;

          // Place the caret at the end of the paragraph.
          await tester.placeCaretInParagraph(doc.nodes.first.id, 19);

          // Toggle the bold attribution.
          composer.preferences.toggleStyle(boldAttribution);
          await tester.pump();

          // Ensure we have an upstream selection.
          expect((composer.selection!.extent.nodePosition as TextNodePosition).affinity, TextAffinity.upstream);

          // Simulate the IME sending us a selection at the same offset
          // but with a different affinity.
          await tester.ime.sendDeltas(
            [
              const TextEditingDeltaNonTextUpdate(
                oldText: ". This text should be",
                selection: TextSelection.collapsed(offset: 21, affinity: TextAffinity.downstream),
                composing: TextRange.empty,
              ),
            ],
            getter: imeClientGetter,
          );

          // Type text at the end of the paragraph.
          await tester.typeImeText(" bold");

          // Ensure the bold attribution is applied.
          expect(doc, equalsMarkdown("This text should be** bold**"));
        });
      });
    });

    testWidgetsOnArbitraryDesktop('does not merge different colors', (tester) async {
      final context = await tester //
          .createDocument()
          .withSingleParagraph()
          .pump();

      final editor = context.editor;

      // Apply a yellow color to the word "Lorem".
      editor.execute([
        AddTextAttributionsRequest(
          documentRange: const DocumentRange(
            start: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 0)),
            end: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 5)),
          ),
          attributions: {const ColorAttribution(Colors.yellow)},
        ),
      ]);

      // Try to apply a red color to the range "L|ore|m". This should fail
      // because we can't apply two different colors to the same range.
      expect(
        () => editor.execute([
          AddTextAttributionsRequest(
            documentRange: const DocumentRange(
              start: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 1)),
              end: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 3)),
            ),
            attributions: {const ColorAttribution(Colors.red)},
          ),
        ]),
        throwsException,
      );
    });

    testWidgetsOnArbitraryDesktop('does not merge different background colors', (tester) async {
      final context = await tester //
          .createDocument()
          .withSingleParagraph()
          .pump();

      final editor = context.editor;

      // Apply a yellow background to the word "Lorem".
      editor.execute([
        AddTextAttributionsRequest(
          documentRange: const DocumentRange(
            start: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 0)),
            end: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 5)),
          ),
          attributions: {const BackgroundColorAttribution(Colors.yellow)},
        ),
      ]);

      // Try to apply a red background to the range "L|ore|m". This should fail
      // because we can't apply two different background colors to the same range.
      expect(
        () => editor.execute([
          AddTextAttributionsRequest(
            documentRange: const DocumentRange(
              start: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 1)),
              end: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 3)),
            ),
            attributions: {const BackgroundColorAttribution(Colors.red)},
          ),
        ]),
        throwsException,
      );
    });

    testWidgetsOnArbitraryDesktop('does not merge different font sizes', (tester) async {
      final context = await tester //
          .createDocument()
          .withSingleParagraph()
          .pump();

      final editor = context.editor;

      // Apply a font size of 14 to the word "Lorem".
      editor.execute([
        AddTextAttributionsRequest(
          documentRange: const DocumentRange(
            start: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 0)),
            end: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 5)),
          ),
          attributions: {const FontSizeAttribution(14)},
        ),
      ]);

      // Try to apply a font size of 16 to the range "L|ore|m". This should fail
      // because we can't apply two different font sizes to the same range.
      expect(
        () => editor.execute([
          AddTextAttributionsRequest(
            documentRange: const DocumentRange(
              start: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 1)),
              end: DocumentPosition(nodeId: '1', nodePosition: TextNodePosition(offset: 3)),
            ),
            attributions: {const FontSizeAttribution(16)},
          ),
        ]),
        throwsException,
      );
    });
  });
}

MutableDocument _paragraphFullBoldThenParagraph() => MutableDocument(
      nodes: [
        ParagraphNode(
          id: "1",
          text: AttributedText(
            "This is the first node in a document.",
            _createAttributedSpansForAttribution(
              attribution: boldAttribution,
              startOffset: 0,
              endOffset: 36,
            ),
          ),
        ),
        ParagraphNode(
          id: "2",
          text: AttributedText(
            "This is the second node in a document.",
          ),
        ),
      ],
    );

MutableDocument _paragraphPartiallyBoldThenParagraph() => MutableDocument(
      nodes: [
        ParagraphNode(
          id: "1",
          text: AttributedText(
            "This is the first node in a document.",
            _createAttributedSpansForAttribution(
              attribution: boldAttribution,
              startOffset: 0,
              endOffset: 16,
            ),
          ),
        ),
        ParagraphNode(
          id: "2",
          text: AttributedText(
            "This is the second node in a document.",
          ),
        ),
      ],
    );

MutableDocument _paragraphFullyBoldThenParagraphPartiallyBold() => MutableDocument(
      nodes: [
        ParagraphNode(
          id: "1",
          text: AttributedText(
            "This is the first node in a document.",
            _createAttributedSpansForAttribution(
              attribution: boldAttribution,
              startOffset: 0,
              endOffset: 16,
            ),
          ),
        ),
        ParagraphNode(
          id: "2",
          text: AttributedText(
            "This is the second node in a document.",
            _createAttributedSpansForAttribution(
              attribution: boldAttribution,
              startOffset: 0,
              endOffset: 37,
            ),
          ),
        ),
      ],
    );

MutableDocument _paragraphPartiallyBoldThenParagraphPartiallyBold() => MutableDocument(
      nodes: [
        ParagraphNode(
          id: "1",
          text: AttributedText(
            "This is the first node in a document.",
            _createAttributedSpansForAttribution(
              attribution: boldAttribution,
              startOffset: 0,
              endOffset: 16,
            ),
          ),
        ),
        ParagraphNode(
          id: "2",
          text: AttributedText(
            "This is the second node in a document.",
            _createAttributedSpansForAttribution(
              attribution: boldAttribution,
              startOffset: 0,
              endOffset: 17,
            ),
          ),
        ),
      ],
    );

extension _GetDocumentPosition on DocumentNode {
  DocumentPosition get beginningDocumentPosition {
    return DocumentPosition(
      nodeId: id,
      nodePosition: beginningPosition,
    );
  }

  DocumentPosition get endDocumentPosition {
    return DocumentPosition(
      nodeId: id,
      nodePosition: endPosition,
    );
  }
}

extension _ToggleAttributions on Editor {
  /// Toggles given [attributions] for the [documentSelection].
  void toggleAttributionsForDocumentSelection(
    DocumentSelection documentSelection,
    Set<Attribution> attributions,
  ) {
    return execute([
      ToggleTextAttributionsRequest(
        documentRange: documentSelection,
        attributions: attributions,
      )
    ]);
  }
}

/// Creates an [AttributedSpans] for the [attribution] starting at [startOffset]
/// and ending at [endOffset].
AttributedSpans _createAttributedSpansForAttribution({
  required NamedAttribution attribution,
  required int startOffset,
  required int endOffset,
}) {
  return AttributedSpans(
    attributions: [
      SpanMarker(
        attribution: attribution,
        offset: startOffset,
        markerType: SpanMarkerType.start,
      ),
      SpanMarker(
        attribution: attribution,
        offset: endOffset,
        markerType: SpanMarkerType.end,
      ),
    ],
  );
}
