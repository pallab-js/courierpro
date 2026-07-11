import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct InvoiceExporter {
    static func exportToPDF(invoice: Invoice) -> Data? {
        let view = createInvoiceView(invoice: invoice)
        let width: CGFloat = 612
        let height: CGFloat = 792

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else { return nil }

        var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)
        let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)

        guard let pdfContext = pdfContext else { return nil }

        pdfContext.beginPDFPage(nil)

        pdfContext.saveGState()
        pdfContext.translateBy(x: 0, y: height)
        pdfContext.scaleBy(x: 1, y: -1)

        view.wantsLayer = true
        view.layer?.render(in: pdfContext)

        pdfContext.restoreGState()
        pdfContext.endPDFPage()
        pdfContext.closePDF()

        return data as Data
    }

      private static func createInvoiceView(invoice: Invoice) -> NSView {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 540, height: 720))
        let currencySymbol = AppSettings.load().currencySymbol

        var yOffset: CGFloat = 680

        func addText(_ text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat, bold: Bool = false, color: NSColor = .black) {
            let label = NSTextField(labelWithString: text)
            label.frame = NSRect(x: x, y: y, width: 400, height: fontSize * 1.5)
            label.font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
            label.textColor = color
            containerView.addSubview(label)
        }

        func addLine(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, width: CGFloat = 1) {
            let lineView = LineView(
                frame: NSRect(
                    x: min(x1, x2),
                    y: min(y1, y2),
                    width: max(width, abs(x2 - x1)),
                    height: max(width, abs(y2 - y1))
                ),
                width: width
            )
            containerView.addSubview(lineView)
        }

        addText("INVOICE", x: 36, y: yOffset, fontSize: 28, bold: true)
        yOffset -= 30

        addText(invoice.invoiceNumber, x: 36, y: yOffset, fontSize: 14, color: .gray)
        yOffset -= 25

        addText("Date: \(invoice.createdAt.formatted(date: .long, time: .omitted))", x: 36, y: yOffset, fontSize: 12)
        addText("Due: \(invoice.dueDate.formatted(date: .long, time: .omitted))", x: 300, y: yOffset, fontSize: 12)
        yOffset -= 20

        addText("Status: \(invoice.status.displayName)", x: 36, y: yOffset, fontSize: 12, color: .systemOrange)
        yOffset -= 35

        addText("BILL TO:", x: 36, y: yOffset, fontSize: 10, bold: true, color: .gray)
        yOffset -= 18
        addText(invoice.customer?.name ?? "Unknown", x: 36, y: yOffset, fontSize: 14, bold: true)
        yOffset -= 18
        if let email = invoice.customer?.email, !email.isEmpty {
            addText(email, x: 36, y: yOffset, fontSize: 12, color: .gray)
            yOffset -= 18
        }
        if let phone = invoice.customer?.phone, !phone.isEmpty {
            addText(phone, x: 36, y: yOffset, fontSize: 12, color: .gray)
            yOffset -= 18
        }
        yOffset -= 20

        addText("DESCRIPTION", x: 36, y: yOffset, fontSize: 10, bold: true, color: .gray)
        addText("QTY", x: 300, y: yOffset, fontSize: 10, bold: true, color: .gray)
        addText("PRICE", x: 370, y: yOffset, fontSize: 10, bold: true, color: .gray)
        addText("TOTAL", x: 460, y: yOffset, fontSize: 10, bold: true, color: .gray)
        yOffset -= 15

        addLine(x1: 36, y1: yOffset, x2: 540, y2: yOffset)
        yOffset -= 20

        if let items = invoice.items {
            for item in items {
                addText(item.itemDescription, x: 36, y: yOffset, fontSize: 11)
                addText("\(item.quantity)", x: 300, y: yOffset, fontSize: 11)
                addText(String(format: "\(currencySymbol)%.2f", item.unitPrice), x: 370, y: yOffset, fontSize: 11)
                addText(String(format: "\(currencySymbol)%.2f", item.totalPrice), x: 460, y: yOffset, fontSize: 11, bold: true)
                yOffset -= 20
            }
        }

        yOffset -= 10
        addLine(x1: 300, y1: yOffset, x2: 540, y2: yOffset)
        yOffset -= 25

        addText("Subtotal:", x: 350, y: yOffset, fontSize: 12, color: .gray)
        addText(String(format: "\(currencySymbol)%.2f", invoice.subtotal), x: 460, y: yOffset, fontSize: 12)
        yOffset -= 20

        addText("Tax (\(String(format: "%.1f", invoice.taxRate))%):", x: 350, y: yOffset, fontSize: 12, color: .gray)
        addText(String(format: "\(currencySymbol)%.2f", invoice.taxAmount), x: 460, y: yOffset, fontSize: 12)
        yOffset -= 25

        addLine(x1: 350, y1: yOffset, x2: 540, y2: yOffset, width: 2)
        yOffset -= 25

        addText("TOTAL:", x: 350, y: yOffset, fontSize: 16, bold: true)
        addText(String(format: "\(currencySymbol)%.2f", invoice.totalAmount), x: 440, y: yOffset, fontSize: 16, bold: true)
        yOffset -= 30

        if invoice.totalPaid > 0 {
            addText("Paid:", x: 350, y: yOffset, fontSize: 12, color: .systemGreen)
            addText(String(format: "\(currencySymbol)%.2f", invoice.totalPaid), x: 460, y: yOffset, fontSize: 12, color: .systemGreen)
            yOffset -= 20
        }

        if invoice.balanceDue > 0 {
            addText("Balance Due:", x: 350, y: yOffset, fontSize: 12, bold: true, color: .systemOrange)
            addText(String(format: "\(currencySymbol)%.2f", invoice.balanceDue), x: 460, y: yOffset, fontSize: 12, bold: true, color: .systemOrange)
            yOffset -= 30
        }

        if let notes = invoice.notes, !notes.isEmpty {
            yOffset -= 20
            addText("NOTES:", x: 36, y: yOffset, fontSize: 10, bold: true, color: .gray)
            yOffset -= 18
            addText(notes, x: 36, y: yOffset, fontSize: 11, color: .gray)
        }

        return containerView
    }
}

struct ExportButton: View {
    let invoice: Invoice

    var body: some View {
        Button(action: exportInvoice) {
            Label("Export PDF", systemImage: "square.and.arrow.up")
        }
    }

    private func exportInvoice() {
        guard let data = InvoiceExporter.exportToPDF(invoice: invoice) else { return }

        let sanitizedNumber = invoice.invoiceNumber
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "..", with: "")
            .replacingOccurrences(of: "\0", with: "")

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(sanitizedNumber).pdf"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                } catch {
                    // Silent failure handled by NSSavePanel
                }
            }
        }
    }
}

class LineView: NSView {
    var lineWidth: CGFloat

    init(frame frameRect: NSRect, width: CGFloat = 1) {
        self.lineWidth = width
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        self.lineWidth = 1
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath()
        if bounds.width >= bounds.height {
            // Horizontal line
            path.move(to: NSPoint(x: 0, y: bounds.height / 2))
            path.line(to: NSPoint(x: bounds.width, y: bounds.height / 2))
        } else {
            // Vertical line
            path.move(to: NSPoint(x: bounds.width / 2, y: 0))
            path.line(to: NSPoint(x: bounds.width / 2, y: bounds.height))
        }
        path.lineWidth = lineWidth
        NSColor.separatorColor.set()
        path.stroke()
    }
}
