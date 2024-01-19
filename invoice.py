from PIL import Image
import pytesseract
import cv2


# Make sure to set the path to the tesseract executable if it's not in your PATH
# pytesseract.pytesseract.tesseract_cmd = r'<full_path_to_your_tesseract_executable>'

from pdf2image import convert_from_path

def pdf_to_img(pdf_path):
    # Convert PDF to list of images
    images = convert_from_path(pdf_path)
    return images


def ocr_images(images):
    text = ""
    for img in images:
        text += pytesseract.image_to_string(img)
    return text

# Use the functions
images = pdf_to_img('/Users/girithc/work/py/vendor.pdf')

# read image
img = cv2.imread(images[0])
# convert to grayscale
img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# binarize with threshold and invert image
_, img_bin = cv2.threshold(img, 60, 255, cv2.THRESH_BINARY_INV)


# ocr_text = ocr_images(images)
ocr_text = ocr_images(images)
print(ocr_text)



'''
import sys
import fitz  # PyMuPDF
import pandas as pd

def extract_text_from_pdf(file_path):
    text = ''
    with fitz.open(file_path) as doc:
        for page in doc:
            text += page.get_text()
    return text

def parse_invoice_data_v3(text):
    lines = text.split('\n')
    start_index = -1
    end_index = -1
    for i, line in enumerate(lines):
        if 'Description' in line and 'Rate' in line and 'Net Amt' in line:
            start_index = i + 1
        if start_index != -1 and 'Page' in line:
            end_index = i
            break

    # For troubleshooting: Print start, end, and some lines around these indices
    print("Start Index:", start_index, "End Index:", end_index)
    print("Lines around start and end:")
    for i in range(max(0, start_index - 3), min(len(lines), end_index + 3)):
        print(i, lines[i])
    print(lines)

    if start_index == -1 or end_index == -1:
        return pd.DataFrame()

    items = []
    for line in lines[start_index:end_index]:
        parts = line.split()
        if len(parts) < 8:
            continue

        description = " ".join(parts[7:])
        rate = parts[1]
        qty = int(parts[2]) * int(parts[3])
        gst_percent = parts[5]
        gst_amount = parts[6]
        items.append([description, qty, rate, gst_percent, gst_amount])

    df = pd.DataFrame(items, columns=['Description', 'Quantity', 'Rate', 'GST%', 'GST Amount'])
    return df

def main(pdf_path):
    text = extract_text_from_pdf(pdf_path)
    invoice_df = parse_invoice_data_v3(text)
    print(invoice_df.head())

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python parse_invoice.py <path_to_pdf>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    main(pdf_path)

'''