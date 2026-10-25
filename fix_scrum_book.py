import os
import docx
from docx.shared import Pt, Inches
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx2pdf import convert
import shutil

SRC_PATH = r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK_15Weeks.docx"

OUT_PATHS = [
    r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK.docx",
    r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK_15Weeks.docx",
    r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK_Filled.docx",
    r"c:\project\Irfan\S3_MCA_SCRUM_BOOK.docx",
    r"c:\project\Irfan\S3_MCA_SCRUM_BOOK_15Weeks.docx",
    r"c:\project\Irfan\S3_MCA_SCRUM_BOOK_Filled.docx"
]

doc = docx.Document(SRC_PATH)

def set_font(run, name="Times New Roman", size_pt=14, bold=True, italic=False):
    run.font.name = name
    if size_pt:
        run.font.size = Pt(size_pt)
    run.bold = bold
    run.italic = italic

# ==========================================
# 1. UPDATE TABLE 0 (Academic Year & Guide Name)
# ==========================================
t0 = doc.tables[0]

# Row 3: Academic Year: 2026
c3 = t0.rows[3].cells[1]
c3.text = ""
p3 = c3.paragraphs[0]
r3 = p3.add_run("  2026")
set_font(r3, "Times New Roman", 14, bold=True)

# Row 6: Name and Designation of the Guide: ATHIRA PJ
c6 = t0.rows[6].cells[1]
c6.text = ""
p6 = c6.paragraphs[0]
r6 = p6.add_run("  ATHIRA PJ")
set_font(r6, "Times New Roman", 14, bold=True)

# ==========================================
# 2. FIX TABLE 6 (CO/PO Mapping - Uncrop Col 12 PO12)
# ==========================================
t6 = doc.tables[6]

# Column widths in dxa
col0_w = 1050  # CO/PO
coli_w = 560   # PO1 to PO12
col_widths = [col0_w] + [coli_w] * 12
total_tbl_w = sum(col_widths)

# 1. Update tblGrid
grid = t6._tbl.tblGrid
grid_cols = grid.findall(qn('w:gridCol'))
for ci, col_elem in enumerate(grid_cols):
    col_elem.set(qn('w:w'), str(col_widths[ci]))

# 2. Update each cell tcW, tcBorders, and paragraph alignment
for ri, r in enumerate(t6.rows):
    for ci, c in enumerate(r.cells):
        w_val = col_widths[ci]
        tcPr = c._tc.get_or_add_tcPr()
        
        # Set exact cell width
        tcW = tcPr.find(qn('w:tcW'))
        if tcW is None:
            tcW = OxmlElement('w:tcW')
            tcPr.append(tcW)
        tcW.set(qn('w:w'), str(w_val))
        tcW.set(qn('w:type'), 'dxa')
        
        # Ensure borders
        tcBorders = tcPr.find(qn('w:tcBorders'))
        if tcBorders is None:
            tcBorders = OxmlElement('w:tcBorders')
            tcPr.append(tcBorders)
        
        # Make sure top, left, bottom, right all exist
        for border_name in ['top', 'left', 'bottom', 'right']:
            b_elem = tcBorders.find(qn(f'w:{border_name}'))
            if b_elem is None:
                b_elem = OxmlElement(f'w:{border_name}')
                tcBorders.append(b_elem)
            b_elem.set(qn('w:val'), 'single')
            b_elem.set(qn('w:sz'), '8')
            b_elem.set(qn('w:space'), '0')
            b_elem.set(qn('w:color'), '000000')
            
        # Center align columns 1 to 12
        if ci > 0:
            for p in c.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        else:
            for p in c.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER

# 3. Update table properties to center
tblPr = t6._tbl.tblPr
tblW = tblPr.find(qn('w:tblW'))
if tblW is not None:
    tblW.set(qn('w:w'), str(total_tbl_w))
    tblW.set(qn('w:type'), 'dxa')

# Save to all target paths
for pth in OUT_PATHS:
    doc.save(pth)
    print("Saved DOCX to:", pth)

# Re-convert to PDF
pdf_dl = r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK_15Weeks.pdf"
pdf_proj = r"c:\project\Irfan\S3_MCA_SCRUM_BOOK_15Weeks.pdf"
pdf_std = r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK.pdf"

convert(r"C:\Users\Irfan\Downloads\S3_MCA_SCRUM_BOOK_15Weeks.docx", pdf_dl)
shutil.copyfile(pdf_dl, pdf_proj)
shutil.copyfile(pdf_dl, pdf_std)
print("PDF updated successfully at:")
print(" -", pdf_dl)
print(" -", pdf_proj)
print(" -", pdf_std)
