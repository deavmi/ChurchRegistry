/**
 * FIXME: I don't want BUSL-licensed stuff in here
 */
module printer;

import types;
import printed.canvas;
import printed.canvas.pdfrender : PDFDocument;
import std.stdio;

import printed.flow;

import logging;

// private StyleOptions STYLE;

// static this()
// {
//     STYLE.fontFace = "Liberation Sans";
// }

public byte[] generate(BaseEntry entry)
{
    PDFDocument pdf = new PDFDocument(210, 297);

    StyleOptions s;
    s.fontFace = "Arial";
    IFlowDocument flow = new FlowDocument(pdf, s);

    renderTo(entry, flow);

    byte[] pdfBytes = cast(byte[])pdf.bytes();
    DEBUG("Created PDF of", pdfBytes.length, "bytes");

    return pdfBytes;
}

private void renderTo(BaseEntry b, IFlowDocument doc)
{
    doc.text("this is a test Hello");
}