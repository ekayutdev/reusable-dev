# Publish reusable-dev ขึ้น GitHub — Design Spec

- **วันที่:** 2026-09-18
- **สถานะ:** Approved (ยังไม่ implement)
- **ต่อจาก:** `docs/superpowers/specs/2026-09-15-reusable-dev-phase2c-design.md` (implemented, merged)

## 1. เป้าหมาย

1. โค้ดมีสำเนานอกเครื่องนี้ — ตอนนี้ repo มี 76 commits และไม่มี remote เลย เครื่องหาย = งานหาย
2. คนอื่นติดตั้ง `reusable-dev` ได้จริง — ตอนนี้ marketplace ผูกกับ symlink ในเครื่อง (`/Users/ekayut/Project/ekayutdev-plugins/plugins/reusable-dev → /Users/ekayut/Project/ai/claude-skill`) ซึ่งใช้ได้เฉพาะเครื่องนี้

### Non-goals

- ไม่เปลี่ยนชื่อ/ย้ายโฟลเดอร์ในเครื่อง (`~/Project/ai/claude-skill` คงเดิม)
- ไม่เปลี่ยน dev loop ของเจ้าของ — ยังติดตั้งผ่าน marketplace ส่วนตัวแบบ directory เหมือนเดิม
- ไม่ทำ CI, release automation, changelog, หรือ semantic-release ในรอบนี้
- ไม่แก้ปัญหา minor ที่ค้างจาก review (SwiftUI แถว 8, Rust แถว 7, research comment, แถว F#) — คนละรอบ
- ไม่รัน manual checks M1–M7 ในรอบนี้

### สถานะที่ตรวจแล้ว (2026-09-18)

- `gh auth status`: ล็อกอิน `github.com` บัญชี `ekayutdev`, scopes `gist, read:org, repo` — พอสำหรับสร้าง repo และ push
- repo นี้: branch `main`, HEAD `1ec56c6`, working tree สะอาด, ไม่มี remote
- `ekayutdev-plugins`: ไม่มี remote, มีงาน hermes-offload ค้าง uncommitted (`scripts/hz`, `skills/hermes-offload/SKILL.md`) และ `scripts/__pycache__/` ที่ยังไม่ถูก ignore
- `ekayutdev-plugins/.gitignore` มี `/plugins/reusable-dev` แล้ว → symlink **ไม่ถูก track** ใน git
- สแกน 2 repo ด้วย regex หา `sk-` / `ghp_` / `gho_` / api key: ไม่พบ → เปิด public ได้โดยไม่ต้องล้างประวัติ
- ตัวที่ติดตั้งใช้งานอยู่คือสำเนาใน `~/.claude/plugins/cache/ekayutdev-plugins/reusable-dev/0.1.0` (snapshot 16 Sep, `gitCommitSha` = `1ec56c6`) และมี `.remember/`, `.superpowers/` ที่ gitignore ติดไปด้วย → การแก้ working tree ไม่ถึงโปรเจกต์อื่นจนกว่าจะ `/plugin update`
- รูปแบบ "repo เดียวเป็น marketplace ของตัวเอง" ยืนยันจาก marketplace ที่ติดตั้งจริงในเครื่อง (`scroll-world`, `swiftui-expert-skill`): มี `.claude-plugin/marketplace.json` คู่กับ `.claude-plugin/plugin.json` และ entry ใช้ `"source": "./"`

## 2. โครงสร้างปลายทาง

```
github.com/ekayutdev/reusable-dev          (public)
  .claude-plugin/plugin.json               แก้: เพิ่ม homepage
  .claude-plugin/marketplace.json          ใหม่: marketplace ในตัว
  skills/ commands/ agents/ evals/ docs/ README.md LICENSE

github.com/ekayutdev/ekayutdev-plugins     (private, backup + ใช้เอง)
  .claude-plugin/marketplace.json          คงเดิม (entry ./plugins/reusable-dev)
  plugins/hermes-offload/                  ไฟล์จริง
  plugins/reusable-dev                     symlink (gitignore อยู่แล้ว ไม่ขึ้น GitHub)
```

- คนอื่น: `/plugin marketplace add ekayutdev/reusable-dev` → `/plugin install reusable-dev@reusable-dev`
- เจ้าของ: ยังใช้จาก `ekayutdev-plugins` แบบ directory เหมือนเดิม แก้โค้ด → `/plugin update`

## 3. ไฟล์ที่เปลี่ยนใน repo นี้

### 3.1 `.claude-plugin/marketplace.json` (ใหม่)

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "reusable-dev",
  "owner": { "name": "ekayut" },
  "metadata": {
    "description": "Reuse-first development for full-stack apps.",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "reusable-dev",
      "source": "./",
      "description": "Reuse-first development for full-stack apps: find existing components and functions before writing new ones, design them for reuse, keep a registry, and verify changes including call sites. 11 stacks; stack-agnostic with optional extension points for other skills.",
      "version": "0.1.0",
      "author": { "name": "ekayut" },
      "license": "MIT",
      "category": "development",
      "keywords": ["reuse", "components", "design-system", "shadcn", "refactor", "testing"]
    }
  ]
}
```

ชื่อ marketplace = `reusable-dev` ไม่ชนกับ `ekayutdev-plugins` ที่ลงทะเบียนไว้แล้วในเครื่อง

### 3.2 `.claude-plugin/plugin.json` (แก้)

เพิ่มคีย์เดียว: `"homepage": "https://github.com/ekayutdev/reusable-dev"` (name, version, description, author, license, keywords มีครบแล้ว)

### 3.3 `README.md` หัวข้อ "ติดตั้ง / Install" (บรรทัด 42–66, เขียนใหม่)

ของเดิมบอกให้ clone แล้วชี้ `--plugin-dir` และให้ผู้ใช้แปะ entry เข้า `marketplace.json` ของ marketplace ตัวเองด้วยมือ — ใช้ไม่ได้แล้วเมื่อ repo เป็น marketplace ในตัว แทนด้วย:

- ทางหลัก (2 บรรทัด): `/plugin marketplace add ekayutdev/reusable-dev` แล้ว `/plugin install reusable-dev@reusable-dev`
- ทางรอง สำหรับ dev/ทดสอบ: `git clone … && claude --plugin-dir <clone-path>` (M1–M7 ใช้ทางนี้)
- คงข้อความเดิมที่ว่า `evals/` และ `docs/` อยู่ใน repo แต่ Claude Code ไม่โหลด

## 4. ลำดับการทำ

| # | ทำ | เสร็จเมื่อ |
|---|---|---|
| 1 | เพิ่ม `marketplace.json`, แก้ `plugin.json`, เขียน README หัวข้อติดตั้งใหม่ | `claude plugin validate . --strict` ผ่าน |
| 2 | commit การเปลี่ยนแปลงข้อ 1 | working tree สะอาด |
| 3 | `gh repo create ekayutdev/reusable-dev --public --source=. --remote=origin --push` | `git ls-remote origin` เห็น `main` ที่ commit เดียวกับ HEAD |
| 4 | tag `v0.1.0` ที่ HEAD แล้ว `git push origin v0.1.0` | `git ls-remote --tags origin` เห็น `v0.1.0` |
| 5 | clone ใหม่จาก GitHub ไป scratch dir แล้ว `claude plugin validate <clone> --strict` | ผ่าน (ดูข้อ 5) |
| 6 | `ekayutdev-plugins`: เพิ่ม `__pycache__/` ใน `.gitignore`; แสดง diff ของงาน hermes ที่ค้างให้เจ้าของตัดสินใจว่าจะ commit หรือไม่ | เจ้าของตัดสินใจแล้ว |
| 7 | `gh repo create ekayutdev/ekayutdev-plugins --private --source=. --remote=origin --push` | `git ls-remote origin` เห็น `main` |
| 8 | README ของ `ekayutdev-plugins` หนึ่งบรรทัด: ถ้าตั้งเครื่องใหม่ ให้ clone `reusable-dev` แล้วสร้าง symlink `plugins/reusable-dev` ใหม่ | บรรทัดนั้นอยู่ใน repo |

ขั้น 6 ไม่ commit งานของคนอื่นแทนเจ้าของ — แสดง diff แล้วถามก่อน

## 5. การตรวจสอบ

1. ก่อน push: `claude plugin validate . --strict`
2. หลัง push: `git clone https://github.com/ekayutdev/reusable-dev <scratch>` แล้ว `claude plugin validate <scratch> --strict` — ข้อนี้ตรวจ *สิ่งที่คนอื่นได้จริง* ไม่ใช่ working tree ที่มี `.remember/`, `.superpowers/` ปนอยู่ จับกรณี "ลืม commit ไฟล์" และ "พึ่งไฟล์ที่ gitignore"
3. รายงานผลตาม output จริง ถ้า validate ไม่ผ่านให้แจ้งพร้อม output ห้ามสรุปว่าเสร็จ

**ไม่ทำในรอบนี้:** `/plugin marketplace add ekayutdev/reusable-dev` ในเครื่องนี้ เพราะจะมี `reusable-dev` สองตัวจากสอง marketplace พร้อมกัน เสี่ยงชนกับตัวที่ใช้งานอยู่ — ทดสอบเส้นทางติดตั้งจริงในรอบ M1–M7 ซึ่งรันในสภาพแวดล้อมแยกอยู่แล้ว

## 6. ความเสี่ยงที่รับไว้

| ความเสี่ยง | ผลถ้าเกิด | ที่กันไว้ |
|---|---|---|
| สิ่งที่เจ้าของใช้ (สำเนา directory มีไฟล์ gitignore) ≠ สิ่งที่คนอื่นได้ (git clone) | โค้ดที่เผลอพึ่ง `.remember/` หรือ `.superpowers/` จะพังเฉพาะคนอื่น | ขั้นตรวจสอบข้อ 5.2 validate จาก clone ใหม่ (จับได้ระดับหนึ่ง ไม่ 100%) |
| marketplace ส่วนตัวเป็น private + symlink มีแค่ในเครื่อง | ตั้งเครื่องใหม่แล้ว marketplace ชี้ path ที่ไม่มีอยู่ | ขั้นที่ 8 เขียนวิธีกู้ไว้ใน README ของ marketplace repo |
| เปิด public แล้วมีข้อมูลส่วนตัวในประวัติ 76 commits | ลบยาก ต้อง rewrite history | สแกน token/key แล้วไม่พบ (ดูข้อ 1) |
