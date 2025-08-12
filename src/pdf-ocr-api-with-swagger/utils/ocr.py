from pdf2image import convert_from_path
import pytesseract

class TextChunk:
    def __init__(self, text, x, y):
        self.text = text
        self.x = x
        self.y = y

def extract_text_chunks(pdf_path):
    images = convert_from_path(pdf_path, dpi=300)
    chunks = []
    for image in images:
        data = pytesseract.image_to_data(image, lang='tur', output_type=pytesseract.Output.DICT)
        for i in range(len(data['text'])):
            text = data['text'][i].strip()
            if text:
                x = data['left'][i]
                y = data['top'][i]
                chunks.append(TextChunk(text, x, y))
    return chunks