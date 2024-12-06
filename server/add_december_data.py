import sqlite3
from datetime import datetime, timedelta
import hashlib

def hash_password(password):
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

def add_december_data(database_path):
    conn = sqlite3.connect(database_path)
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM users")
    user_count = cursor.fetchone()[0]

    if user_count == 0:
        print("No users found. Adding initial users...")
        initial_users = [
            {"id": "user1", "name": "Alice", "password": "fortest", "email": "alice@example.com"},
            {"id": "user2", "name": "Bob", "password": "fortest", "email": "bob@example.com"}
        ]
        for user in initial_users:
            hashed_password = hash_password(user["password"])
            cursor.execute('''
                INSERT INTO users (id, name, password, backup_email)
                VALUES (?, ?, ?, ?)
            ''', (user["id"], user["name"], hashed_password, user["email"]))
        print("Initial users added.")

    print("Adding December schedules...")
    cursor.execute("SELECT id FROM users")
    users = [row[0] for row in cursor.fetchall()]

    start_date = datetime(2024, 12, 1)
    end_date = datetime(2024, 12, 31)

    for date in (start_date + timedelta(days=i) for i in range((end_date - start_date).days + 1)):
        formatted_date = f"{date.month:02}-{date.day:02}"
        date_string = date.strftime("%Y-%m-%d")
        for i in range(1, 3): 
            name = f"{formatted_date} example{i}"
            details = f"{name} for test"

            for user_id in users:
                cursor.execute('''
                    INSERT INTO schedules (user_id, name, start_date, end_date, details, completed)
                    VALUES (?, ?, ?, ?, ?, 0)
                ''', (user_id, name, date_string, date_string, details))
    
    conn.commit()
    conn.close()
    print("December data added successfully.")

if __name__ == "__main__":
    database_path = "example.db"
    add_december_data(database_path)
