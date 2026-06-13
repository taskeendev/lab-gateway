# lab-gateway

API gateway (Kong, DB-less/declarative) ของ **Feature Lab** — ประตูเดียวหน้า service ทั้งหมด

## ทำอะไร
- **Routing** รวม 4 service ไว้หลังพอร์ตเดียว (`:8000`)
- **JWT ที่ขอบ** — custom Lua plugin `jwt-hs512` verify ลายเซ็น HS512 ด้วย secret เดียวกับ
  auth-service: ไม่มี token = ปล่อยผ่าน (endpoint สาธารณะ), token เสีย/หมดอายุ = เด้ง 401 ที่ Kong
  ก่อนถึง service; token ดี = แนบ `X-Auth-User`/`X-Auth-Role` ต่อให้ service
- config ทั้งหมด render จาก `kong/kong.tmpl.yml` + env (ไม่ commit URL/secret จริง)

## รัน (dev)
```bash
cp .env.example .env      # ตั้ง JWT_SECRET ให้ตรงกับ auth-service
./run.sh                  # render config + docker compose up
```
Kong proxy = `localhost:8000`, admin = `localhost:8001`

## บันได
ดู [PROGRESS.md](./PROGRESS.md)
