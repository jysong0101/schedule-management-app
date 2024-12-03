import sqlite3
from datetime import datetime, timedelta

def add_december_data(database_path):
    # 데이터베이스 연결
    conn = sqlite3.connect(database_path)
    cursor = conn.cursor()

    # 사용자 데이터 확인
    cursor.execute("SELECT id FROM users")
    users = [row[0] for row in cursor.fetchall()]

    if not users:
        print("No users found in the database.")
        conn.close()
        return

    # 12월 데이터 추가
    start_date = datetime(2024, 12, 1)
    end_date = datetime(2024, 12, 31)

    for date in (start_date + timedelta(days=i) for i in range((end_date - start_date).days + 1)):
        formatted_date = f"{date.month:02}-{date.day:02}"
        date_string = date.strftime("%Y-%m-%d")
        for i in range(1, 3):  # example1, example2 생성
            name = f"{formatted_date} example{i}"
            details = f"{name} for test"

            for user_id in users:  # 각 사용자별 일정 추가
                cursor.execute('''
                    INSERT INTO schedules (user_id, name, start_date, end_date, details, completed)
                    VALUES (?, ?, ?, ?, ?, 0)
                ''', (user_id, name, date_string, date_string, details))
    
    # 변경 사항 커밋 및 데이터베이스 연결 종료
    conn.commit()
    conn.close()
    print("December data added successfully.")

if __name__ == "__main__":
    database_path = "example.db"  # SQLite 데이터베이스 경로 설정
    add_december_data(database_path)
