from django.db import connections
from django.db.utils import OperationalError

# ...existing code...
def check_db_connection() -> bool:
    """
    Kiểm tra kết nối tới DB sử dụng Django connections.
    Trả về True nếu thành công, False nếu thất bại.
    """
    try:
        from django.db import connections
        from django.db.utils import OperationalError

        conn = connections['default']
        # ensure_connection() sẽ raise OperationalError nếu không kết nối được
        conn.ensure_connection()
        print("Kết nối DB thành công")
        return True
    except OperationalError as e:
        print("Kết nối DB thất bại:", e)
        return False
    except Exception as e:
        print("Kết nối DB thất bại (khác):", e)
        return False
# ...existing code...