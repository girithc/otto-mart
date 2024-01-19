from pdf2image import convert_from_path
import pytesseract
import cv2
import tempfile
import os
import re
import pandas as pd

# Convert PDF to list of images
def pdf_to_img(pdf_path):
    images = convert_from_path(pdf_path)
    return images

# Perform OCR on the images
def ocr_images(images):
    text = ""
    for img in images:
        width, height = img.size
        scale_factor = 3
        img = img.resize((width * scale_factor, height * scale_factor))

        # Save the PIL image as a temporary file
        temp_image = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
        img.save(temp_image, format="PNG")
        temp_image.close()

        # Read the temporary image file using cv2
        img_cv2 = cv2.imread(temp_image.name)
        
        # Convert to grayscale
        img_cv2 = cv2.cvtColor(img_cv2, cv2.COLOR_BGR2GRAY)
        
        # Binarize with threshold and invert image
        _, img_bin = cv2.threshold(img_cv2, 60, 255, cv2.THRESH_BINARY_INV)

        # Perform OCR on the processed image
        text += pytesseract.image_to_string(img_bin)
        
        # Clean up the temporary image file
        os.remove(temp_image.name)

    return text

# Parse the OCR text to extract structured data
def parse_data(ocr_text):
    # Define a regex pattern for the data lines
    pattern = r'(\d+)\.(\d+)\s+(.*?)\s+(\d+x\d+gm|\d+ MI)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)'
    matches = re.findall(pattern, ocr_text)

    print(matches)
    # Convert matches to a structured format
    data = []

    
    return data

# Use the functions
pdf_path = '/Users/girithc/work/py/vendor.pdf'
images = pdf_to_img(pdf_path)
ocr_text = ocr_images(images)
parsed_data = parse_data(ocr_text)

# Convert the data to a DataFrame for better visualization and further processing
df = pd.DataFrame(parsed_data)
print(df)
