import os
import time

db_files = ["omechat.db", "sql_app.db"]

for db_file in db_files:
    if os.path.exists(db_file):
        try:
            os.remove(db_file)
            print(f"Successfully deleted {db_file}")
        except PermissionError:
            print(f"Permission denied: {db_file}. Is it open?")
        except Exception as e:
            print(f"Error deleting {db_file}: {e}")
    else:
        print(f"{db_file} does not exist.")
