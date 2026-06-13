-- config มี secret อย่างเดียว — มาจาก env ตอน render kong.yml (ไม่ commit ค่าจริง)
return {
  name = "jwt-hs512",
  fields = {
    { config = {
        type = "record",
        fields = {
          { secret = { type = "string", required = true } },
        },
    } },
  },
}
