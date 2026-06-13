# lab-gateway — Progress

ส่วนหนึ่งของ **Feature Lab** — API gateway (Kong, DB-less/declarative) คั่นหน้า service ทั้งหมด
หลักออกแบบ: ประตูเดียวหน้าระบบ · config เป็น declarative ที่ commit/รีวิวได้ · ไม่ฝัง URL (render
จาก template+env) · JWT ตรวจที่ขอบ + เขียน custom Lua plugin เองเพื่อโชว์ของจริง · ทำบนเครื่องก่อน
(deploy จริง+domain เป็นเฟสย่อยถัดไป)

สถานะ: ⬜ ยังไม่เริ่ม · 🔨 กำลังทำ · ✅ เสร็จ

## บันได 5 ขั้น

- [x] 1. โครง gateway: Kong DB-less + routing 4 service ผ่านจุดเดียว (config render จาก template+env) + CI ตรวจ config — 2026-06-13
- [x] 2. JWT ตรวจที่ขอบ: custom Lua plugin verify HS512 secret เดียวกับ auth (ปลอม/หมดอายุ → 401 ที่ Kong) — 2026-06-13
- [x] 3. Rate limiting + CORS + correlation-id (request-id ไหลทุกชั้น) — 2026-06-13
- [x] 4. WebSocket presence ผ่าน Kong + upstream health checks (circuit breaker) — 2026-06-13
- [ ] 5. lab-web ยิง Kong จุดเดียว (เลิก vite proxy แยกพอร์ต) + docker compose รวมทั้งระบบ (เกณฑ์เฟส)

## Log การทำงาน

- 2026-06-13 — ขั้น 4 เสร็จ: เปลี่ยน service จาก url ตรง เป็น upstream object (target host:port จาก env)
  + healthchecks (active probe /health ทุก 3s + passive); WS presence ทะลุ Kong: first-message auth
  (token ใน message ไม่ใช่ header → jwt plugin ปล่อยผ่าน) ได้ ready+snapshot จริง; circuit breaker:
  ตัด contact → active healthcheck mark UNHEALTHY → Kong ตอบ 503 เองใน ~40ms ไม่ค้างรอ service ที่ตาย,
  service กลับมา → healthy เอง; เจอบั๊ก: compose up รอบที่ env port ไม่ติดทำให้ map random port →
  ย้ำว่าต้อง source .env ก่อนเสมอ (run.sh จัดการให้แล้ว)

- 2026-06-13 — ขั้น 3 เสร็จ: correlation-id (header X-Request-Id ตรงกับ filter ของ service →
  id เดียวไหลทะลุ Kong→service→log, สร้างให้ถ้าไม่มี + echo กลับ client) / cors ที่เดียว
  (origins จาก env, credentials=true รองรับ refresh cookie ข้าม origin, origin แปลกปลอมไม่คืน ACAO)
  / rate-limiting สองชั้น (global 100/min + เส้น /api/auth เข้ม 20/min กัน brute force, policy local
  เหมาะ DB-less); แก้บั๊ก: docker compose --env-file แกะ inline array CORS ไม่ได้ → ให้ bash source
  เองแล้ว compose ใช้ค่า export (--env-file /dev/null); เทสต์ครบ: id propagate, CORS allow/deny,
  429 หลังครบเพดาน + header RateLimit

- 2026-06-13 — ขั้น 2 เสร็จ: custom Lua plugin jwt-hs512 (เขียนเอง โหลดผ่าน KONG_PLUGINS +
  LUA_PACKAGE_PATH) verify HS512 ด้วย openssl_hmac + secret เดียวกับ auth; ปล่อยถ้าไม่มี token
  (public), เด้ง 401 ที่ Kong ถ้าลายเซ็นเสีย/หมดอายุ/รูปแบบเพี้ยน, แนบ X-Auth-User/Role ต่อให้
  service; เทียบลายเซ็นแบบ constant-time; เทสต์ 8 เคส รวมเคสพิสูจน์ "block ก่อนถึง service"
  (token ปลอมยิง GET /api/posts สาธารณะ → 401 ที่ Kong แทนที่จะ 200 จาก service) + mint token
  เองด้วย secret เพื่อทดสอบ expired/fresh; CI โหลด plugin ตอน validate ด้วย

- 2026-06-13 — ขั้น 1 เสร็จ: Kong DB-less (kong:3.9) เป็นประตูเดียวที่ :8000; declarative config
  render จาก kong.tmpl.yml + env (render-config.py แทน ${VAR} — ไม่ฝัง URL ในไฟล์ที่ commit,
  kong.yml ที่ render แล้ว gitignore); routing 4 service: auth (/api/auth,/users,/admin),
  feed (/api/posts,/comments), contact (/api/contact), presence (/api/presence,/ws/presence)
  strip_path=false ส่ง path เต็ม; เข้า service บนเครื่องผ่าน host.docker.internal; CI ให้ Kong
  ตรวจ config จริง (kong config parse, KONG_DATABASE=off); เทสต์ 8 เส้นทะลุ Kong ครบ:
  login/me/สร้างโพสต์/like/ส่ง contact/กล่อง admin/presence ADMIN 200 + USER 403
