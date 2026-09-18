# reusable-dev

Claude Code plugin สำหรับพัฒนาระบบแบบ **reuse-first**: หา component/function เดิมก่อนสร้างใหม่ · ออกแบบให้ reuse ได้ · มีทะเบียน · ตรวจสอบรวมถึงจุดที่เรียกใช้

Reuse-first development for Claude Code. Stack-agnostic, works alone or alongside other skill plugins.

## ทำงานอย่างไร / How it works

เมื่อ Claude กำลังสร้างหรือแก้ component, hook/composable, function หรือ service แล้ว skill `reusable-dev` จะทำงานอัตโนมัติ:

```
0. Load config → 1. Discover → 2. Decide → 3. Design → 4. Verify → 5. Register
```

- **Decide:** Reuse → Extend → Compose → Create (Rule of Three ก่อนย้ายขึ้น shared)
- **Verify:** T1 typecheck/lint/build · T2 unit tests · T3 call-site tests · T4 e2e (สั่งเอง)
- จบงานด้วยรายงาน `Reuse decision:` / `Verified:` / `Notes:`

## Commands

| Command | ใช้ทำอะไร |
|---|---|
| `/reusable-dev:reuse-setup [--reset]` | ตรวจ stack/ui-lib/คำสั่ง + เลือก extension skills → เขียน `.claude/reusable-dev.md` |
| `/reusable-dev:reuse-audit [path]` | หาโค้ดซ้ำและจุดผิดกฎ เรียงตามผลกระทบ (ไม่แก้ไฟล์เอง) |
| `/reusable-dev:reuse-registry [--sync] [--shadcn-registry]` | แสดง diff กับโค้ดจริง · `--sync` เขียนทะเบียน · `--shadcn-registry` สร้าง registry ของ shadcn / show diff; `--sync` writes it; `--shadcn-registry` generates a shadcn registry source |
| `/reusable-dev:reuse-verify [path or 'all']` | ตรวจครบ T1–T4 |

## รองรับ / Supported

Stacks: React/Next.js · Vue/Nuxt · SvelteKit · Node/TypeScript · NestJS · FastAPI · Django · Laravel · Rust (axum) · SwiftUI · .NET (ASP.NET Core · Blazor)
UI libraries: shadcn/ui (`shadcn-react`) · shadcn-vue (`shadcn-vue`) · shadcn-svelte (`shadcn-svelte`)
Stack อื่นใช้หลักการทั่วไปได้ และ `/reusable-dev:reuse-setup` สร้างไฟล์ stack ใหม่จาก template ได้

## Extension points

ไม่บังคับ plugin อื่น แต่เสียบ skill ที่มีอยู่ได้ใน `.claude/reusable-dev.md`:
`design` · `test` · `verify` · `debug` · `review` · `plan` · `e2e`
เช่น `test: [superpowers:test-driven-development]` — ถ้าไม่ได้ติดตั้ง จะใช้ built-in fallback และแจ้งใน Notes

ใช้คู่กับ superpowers: superpowers คุมกระบวนการตามปกติ ส่วน reusable-dev เติมเรื่อง reuse (เช่น `Reuse decision:` ในทุก task ของ plan)

## ติดตั้ง / Install

```bash
claude plugin marketplace add ekayutdev/reusable-dev
claude plugin install reusable-dev@reusable-dev
```

หรือพิมพ์ `/plugin marketplace add ekayutdev/reusable-dev` แล้ว `/plugin install reusable-dev@reusable-dev` ใน session — repo นี้เป็น marketplace ในตัว ชื่อ marketplace กับชื่อ plugin จึงเหมือนกัน

สำหรับ dev หรือทดสอบ (โหลดจากโฟลเดอร์ ไม่ผ่าน marketplace):

```bash
git clone https://github.com/ekayutdev/reusable-dev
claude --plugin-dir reusable-dev
```

repo นี้ทั้งตัวคือ plugin — `evals/` และ `docs/` อยู่ใน repo แต่ Claude Code ไม่ได้โหลด

## Config และ permission / Config & permissions

Config อยู่ที่ `.claude/reusable-dev.md` (commit ลง git เพื่อให้ทีมใช้ convention เดียวกัน) — Claude Code จะขอ permission ก่อนเขียนไฟล์ใน `.claude/` ถ้าปฏิเสธ `/reusable-dev:reuse-setup` จะพิมพ์ config ให้ save เอง และตอน skill ทำงานอัตโนมัติจะดำเนินการต่อพร้อม note `config not saved — run /reusable-dev:reuse-setup`

## พัฒนา / Development

```bash
claude plugin validate . --strict
evals/lib/run-eval.sh [flags]
```

`evals/lib/run-eval.sh` wrap `claude plugin eval` และย้าย `~/.docker` ออกชั่วคราว เพราะ Bash sandbox ของ eval ปฏิเสธการรันเมื่อ `~/.docker` มี symlinks — Docker Desktop อาจสร้าง `~/.docker` ใหม่ระหว่างชุดยาว ให้รันชุดยาวตอนปิด Docker Desktop หรือรันแบบ case ย่อย ระหว่าง eval กำลังรัน คำสั่ง Docker CLI จะใช้ไม่ได้ Manual checks ร่วมกับ superpowers อยู่ที่ `evals/MANUAL.md`

## Token cost

ต่อ session โหลดตลอด ~761 tokens + references loaded as needed; skill ทำงาน ~1.8k tokens ตอน fire — measured with `claude plugin details` at 0.1.0; agent `duplicate-finder` ~890 tokens เมื่อ `/reusable-dev:reuse-audit` ส่งงานให้ (when `/reusable-dev:reuse-audit` dispatches it)

## License

MIT
