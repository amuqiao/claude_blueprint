from sqlalchemy import text


def create_user(request, db):
    # 故意违规示例：
    # 1. 在入口层直接访问数据库
    # 2. 在入口层直接 commit
    email = request.json["email"]
    db.execute(text("insert into users(email) values (:email)"), {"email": email})
    db.commit()
    return {"ok": True}

