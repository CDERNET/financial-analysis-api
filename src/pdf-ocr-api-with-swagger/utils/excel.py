from openpyxl import Workbook
from openpyxl.utils import get_column_letter
import tempfile

def chunks_to_excel(chunks, headers):
    chunks = sorted(chunks, key=lambda c: (-c.y, c.x))
    rows = []
    row = {}
    last_y = None
    x_thresholds = []

    for i, h in enumerate(headers):
        x_thresholds.append(None)

    for chunk in chunks:
        if last_y is None or abs(chunk.y - last_y) > 20:
            if row:
                rows.append(row)
            row = {}
            last_y = chunk.y

        for i, x in enumerate(x_thresholds):
            if x is None or abs(chunk.x - x) < 50:
                x_thresholds[i] = chunk.x
                if headers[i] in row:
                    row[headers[i]] += " " + chunk.text
                else:
                    row[headers[i]] = chunk.text
                break

    if row:
        rows.append(row)

    wb = Workbook()
    ws = wb.active
    ws.append(headers)

    for r in rows:
        ws.append([r.get(h, "") for h in headers])

    tmp_excel = tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx")
    wb.save(tmp_excel.name)
    return tmp_excel.name