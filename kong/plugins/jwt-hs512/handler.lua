-- jwt-hs512: ตรวจลายเซ็น HS512 ของ JWT ที่ขอบ ด้วย secret เดียวกับ auth-service
-- ปรัชญา: ไม่มี token = ปล่อยผ่าน (ปล่อย endpoint สาธารณะ + ให้ service ตัดสินสิทธิ์เอง)
--          มี token แต่เสีย/หมดอายุ = เด้ง 401 ที่ Kong ไม่ให้วิ่งไปถึง service
local openssl_hmac = require "resty.openssl.hmac"
local cjson = require "cjson.safe"

local JwtHs512 = { PRIORITY = 1000, VERSION = "1.0.0" }

local function b64url_decode(input)
  local rem = #input % 4
  if rem > 0 then input = input .. string.rep("=", 4 - rem) end
  input = input:gsub("-", "+"):gsub("_", "/")
  return ngx.decode_base64(input)
end

local function b64url_encode(bytes)
  return (ngx.encode_base64(bytes):gsub("+", "-"):gsub("/", "_"):gsub("=", ""))
end

local function unauthorized(detail)
  return kong.response.exit(401,
    { title = "Unauthorized", status = 401, detail = detail },
    { ["Content-Type"] = "application/problem+json" })
end

-- เทียบสตริงแบบเวลาเท่ากันทุกครั้ง — กัน timing attack ตอนเดาลายเซ็น
local function constant_eq(a, b)
  if #a ~= #b then return false end
  local diff = 0
  for i = 1, #a do
    diff = bit.bor(diff, bit.bxor(a:byte(i), b:byte(i)))
  end
  return diff == 0
end

function JwtHs512:access(conf)
  local auth = kong.request.get_header("Authorization")
  if not auth then
    return -- ไม่มี token: endpoint สาธารณะเข้าได้ ส่วน endpoint ปิด service จะ 401 เอง
  end

  local token = auth:match("^Bearer%s+(.+)$")
  if not token then return unauthorized("malformed authorization header") end

  local h, p, s = token:match("^([^.]+)%.([^.]+)%.([^.]+)$")
  if not h then return unauthorized("malformed token") end

  local hmac = openssl_hmac.new(conf.secret, "sha512")
  local expected = b64url_encode(hmac:final(h .. "." .. p))
  if not constant_eq(expected, s) then return unauthorized("invalid signature") end

  local payload = cjson.decode(b64url_decode(p))
  if not payload then return unauthorized("invalid payload") end
  if payload.exp and payload.exp < ngx.time() then return unauthorized("token expired") end

  -- identity ที่ยืนยันแล้ว ส่งต่อให้ service (service ยัง verify ซ้ำได้ = defense in depth)
  kong.service.request.set_header("X-Auth-User", payload.sub or "")
  kong.service.request.set_header("X-Auth-Role", payload.role or "")
end

return JwtHs512
