# Publish reusable-dev to GitHub — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เผยแพร่ `reusable-dev` เป็น public repo บน GitHub ที่เป็น marketplace ในตัว (คนอื่นติดตั้งได้ด้วยสองคำสั่ง) และสำรอง marketplace ส่วนตัวขึ้น GitHub แบบ private โดยไม่กระทบ dev loop เดิม

**Architecture:** repo นี้ได้ `.claude-plugin/marketplace.json` ที่ชี้ `"source": "./"` ทำให้ตัวมันเองทั้งเป็น plugin และเป็น marketplace หนึ่งรายการ — เป็นรูปแบบเดียวกับ `scroll-world`/`swiftui-expert-skill` ที่ติดตั้งอยู่ในเครื่องแล้ว `ekayutdev-plugins` ยังคงชี้ `./plugins/reusable-dev` (symlink ที่ gitignore ไว้) จึงยังใช้ `/plugin update` อัปเดตจาก working tree ได้เหมือนเดิม การตรวจสอบยึด "validate จาก clone ใหม่" เป็นหลักฐาน ไม่ใช่ working tree

**Tech Stack:** git, `gh` CLI (ล็อกอินแล้วในชื่อ `ekayutdev`), `claude plugin validate`

**Spec:** `docs/superpowers/specs/2026-09-18-publish-reusable-dev-design.md`

## Global Constraints

- repo public ชื่อ `ekayutdev/reusable-dev`; repo private ชื่อ `ekayutdev/ekayutdev-plugins` — ห้ามเปลี่ยนชื่อหรือย้ายโฟลเดอร์ในเครื่อง (`~/Project/ai/claude-skill`, `~/Project/ekayutdev-plugins` คงเดิม)
- ชื่อ marketplace ใน manifest ใหม่ = `reusable-dev` (ห้ามใช้ `ekayutdev-plugins` ซึ่งลงทะเบียนในเครื่องแล้ว)
- `plugin.json` เป็นแหล่งความจริงเดียวของ version/author/license/keywords — marketplace entry ห้ามซ้ำฟิลด์เหล่านี้
- ทุกคำสั่ง validate ต้องระบุพาธไฟล์ manifest ตรง ๆ ห้ามใช้ `claude plugin validate .` เพราะไดเรกทอรีที่มีสอง manifest จะตรวจเฉพาะ marketplace
- ห้าม `/plugin marketplace add ekayutdev/reusable-dev` ในเครื่องนี้ (จะได้ `reusable-dev` สองตัวพร้อมกัน) — การทดสอบเส้นทางติดตั้งจริงเป็นงานของรอบ M1–M7
- ห้าม commit งานที่ผู้อื่นแก้ค้างไว้โดยไม่ถาม (งาน hermes-offload ใน Task 3)
- commit message ลงท้ายด้วย `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` และ `Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc`

## File Structure

| ไฟล์ | หน้าที่ | Task |
|---|---|---|
| `.claude-plugin/marketplace.json` (ใหม่) | ทำให้ repo ติดตั้งได้ด้วยตัวเอง — รายการ plugin หนึ่งรายการ ชี้ root ของ repo | 1 |
| `.claude-plugin/plugin.json` (แก้) | metadata ของ plugin — เพิ่มลิงก์กลับไปที่ repo | 1 |
| `README.md` บรรทัด 42–66 (เขียนใหม่) | บอกวิธีติดตั้งที่ใช้ได้จริงหลังขึ้น GitHub | 1 |
| `/Users/ekayut/Project/ekayutdev-plugins/.gitignore` (แก้) | กัน `__pycache__/` ไม่ให้ขึ้น repo | 3 |
| `/Users/ekayut/Project/ekayutdev-plugins/README.md` (ใหม่) | วิธีกู้ symlink เมื่อตั้งเครื่องใหม่ — repo นี้ยังไม่มี README เลย | 3 |

---

### Task 1: Self-marketplace manifest + install docs

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Modify: `.claude-plugin/plugin.json`
- Modify: `README.md:42-66`

**Interfaces:**
- Consumes: ไม่มี (task แรก)
- Produces: marketplace ชื่อ `reusable-dev` ที่มี plugin `reusable-dev` → Task 2 เอาไป validate จาก clone, README ที่อ้าง URL `https://github.com/ekayutdev/reusable-dev` ซึ่ง Task 2 เป็นคนทำให้มีอยู่จริง

- [ ] **Step 1: ยืนยันจุดเริ่มต้นสะอาด**

```bash
cd /Users/ekayut/Project/ai/claude-skill
git status --short
```

Expected: ไม่มี output (working tree สะอาด) ถ้ามีไฟล์ค้าง ให้หยุดและถามเจ้าของก่อน

- [ ] **Step 2: ตรวจว่าตอนนี้ validate ยังเห็น plugin manifest**

```bash
claude plugin validate .claude-plugin/plugin.json --strict
```

Expected: `Validating plugin manifest: …/.claude-plugin/plugin.json` แล้ว `✔ Validation passed`

- [ ] **Step 3: เขียน `.claude-plugin/marketplace.json`**

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "reusable-dev",
  "owner": { "name": "ekayut" },
  "metadata": {
    "description": "Reuse-first development for full-stack apps, by ekayut."
  },
  "plugins": [
    {
      "name": "reusable-dev",
      "source": "./",
      "description": "Reuse-first development for full-stack apps: find existing components and functions before writing new ones, design them for reuse, keep a registry, and verify changes including call sites. 11 stacks; stack-agnostic with optional extension points for other skills.",
      "category": "development"
    }
  ]
}
```

- [ ] **Step 4: validate marketplace manifest**

```bash
claude plugin validate .claude-plugin/marketplace.json --strict
```

Expected: `Validating marketplace manifest: …` แล้ว `✔ Validation passed`

- [ ] **Step 5: แก้ `.claude-plugin/plugin.json` ให้เป็นเนื้อหานี้ทั้งไฟล์**

```json
{
  "name": "reusable-dev",
  "version": "0.1.0",
  "description": "Reuse-first development for full-stack apps: find existing components and functions before writing new ones, design them for reuse, keep a registry, and verify changes including call sites. Stack-agnostic with optional extension points for other skills.",
  "author": { "name": "ekayut" },
  "homepage": "https://github.com/ekayutdev/reusable-dev",
  "repository": "https://github.com/ekayutdev/reusable-dev",
  "license": "MIT",
  "keywords": ["reuse", "components", "design-system", "shadcn", "refactor", "testing"]
}
```

- [ ] **Step 6: validate ทั้งสอง manifest (ข้อนี้คือจุดที่ `validate .` จะหลอก)**

```bash
claude plugin validate .claude-plugin/plugin.json --strict
claude plugin validate .claude-plugin/marketplace.json --strict
```

Expected: `✔ Validation passed` สองครั้ง บรรทัดแรกของแต่ละครั้งต้องขึ้นคนละชนิด (`plugin manifest` / `marketplace manifest`) ถ้าเห็น `marketplace manifest` สองครั้งแปลว่าพาธผิด

- [ ] **Step 7: แทนที่ README บรรทัด 42–66 ด้วยหัวข้อติดตั้งใหม่**

ของเดิมคือหัวข้อ `## ติดตั้ง / Install` ตั้งแต่บรรทัด 42 จนถึงบรรทัด 66 (บรรทัดว่างก่อน `## Config และ permission / Config & permissions`) แทนด้วย:

````markdown
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
````

- [ ] **Step 8: ตรวจว่า README ไม่เหลือวิธีติดตั้งแบบเก่า**

```bash
grep -n "plugins/reusable-dev\|<repo-url>\|<marketplace-name>" README.md
```

Expected: ไม่มี output ถ้ายังเจอ แปลว่าลบข้อความเก่าไม่หมด

- [ ] **Step 9: Commit**

```bash
git add .claude-plugin/marketplace.json .claude-plugin/plugin.json README.md
git commit -F - <<'EOF'
feat: make the repo its own marketplace

The plugin was installable only through a marketplace that pointed at a
local symlink, so nobody else could install it. A marketplace.json with
"source": "./" lets the repo be added and installed directly, and the
README now documents that path instead of hand-editing someone else's
marketplace manifest.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc
EOF
```

- [ ] **Step 10: ยืนยัน commit เข้าแล้ว**

```bash
git status --short && git log --oneline -1
```

Expected: `git status --short` ไม่มี output, log บรรทัดบนสุดคือ commit ที่เพิ่งทำ

---

### Task 2: Push public repo + tag + verify from a fresh clone

**Files:**
- ไม่แก้ไฟล์ใน repo — สร้าง remote และ tag

**Interfaces:**
- Consumes: commit จาก Task 1 (manifest ทั้งสองไฟล์ต้องอยู่ใน HEAD แล้ว)
- Produces: `https://github.com/ekayutdev/reusable-dev` (public, มี `main` และ tag `v0.1.0`) → Task 3 อ้างถึงใน README ของ marketplace repo

- [ ] **Step 1: ยืนยัน gh auth และว่ายังไม่มี remote**

```bash
cd /Users/ekayut/Project/ai/claude-skill
gh auth status
git remote -v
```

Expected: `Logged in to github.com account ekayutdev`, และ `git remote -v` ไม่มี output ถ้ามี remote อยู่แล้วให้หยุดและถามเจ้าของ

- [ ] **Step 2: สร้าง public repo แล้ว push**

```bash
gh repo create ekayutdev/reusable-dev \
  --public \
  --source=. \
  --remote=origin \
  --description "Reuse-first development plugin for Claude Code — 11 stacks, stack-agnostic." \
  --push
```

Expected: พิมพ์ URL ของ repo แล้ว push สำเร็จ

- [ ] **Step 3: ยืนยันว่า remote มี main ที่ commit เดียวกับ HEAD**

```bash
git rev-parse HEAD
git ls-remote origin refs/heads/main
```

Expected: sha สองอันตรงกัน

- [ ] **Step 4: ตั้ง tag v0.1.0 แล้ว push**

```bash
git tag -a v0.1.0 -m "reusable-dev 0.1.0 — 11 stacks, first public release"
git push origin v0.1.0
```

- [ ] **Step 5: ยืนยัน tag ขึ้นไปแล้ว**

```bash
git ls-remote --tags origin
```

Expected: มีบรรทัดที่ลงท้ายด้วย `refs/tags/v0.1.0`

- [ ] **Step 6: clone ใหม่จาก GitHub ไป scratch dir**

```bash
SCRATCH=/private/tmp/claude-501/-Users-ekayut-Project-ai-claude-skill/d3d4d9d5-7388-4834-91e5-a193c91db3a2/scratchpad
rm -rf "$SCRATCH/verify-clone"
git clone https://github.com/ekayutdev/reusable-dev "$SCRATCH/verify-clone"
```

- [ ] **Step 7: validate manifest ทั้งสองในโคลนนั้น — นี่คือหลักฐานว่าคนอื่นได้ของครบ**

```bash
SCRATCH=/private/tmp/claude-501/-Users-ekayut-Project-ai-claude-skill/d3d4d9d5-7388-4834-91e5-a193c91db3a2/scratchpad
claude plugin validate "$SCRATCH/verify-clone/.claude-plugin/plugin.json" --strict
claude plugin validate "$SCRATCH/verify-clone/.claude-plugin/marketplace.json" --strict
```

Expected: `✔ Validation passed` ทั้งสองครั้ง ถ้าไม่ผ่าน ให้รายงาน output จริงและหยุด อย่าแก้ในโคลนแล้วบอกว่าผ่าน

- [ ] **Step 8: ตรวจว่าโคลนมีของครบและไม่มีไฟล์ที่ไม่ควรมี**

```bash
SCRATCH=/private/tmp/claude-501/-Users-ekayut-Project-ai-claude-skill/d3d4d9d5-7388-4834-91e5-a193c91db3a2/scratchpad
ls "$SCRATCH/verify-clone/skills/reusable-dev/references/stacks/" | wc -l
ls -a "$SCRATCH/verify-clone" | grep -E "^\.(remember|superpowers)$" || echo "OK: no local-only dirs"
```

Expected: จำนวนไฟล์ stack reference ตรงกับใน working tree (`ls skills/reusable-dev/references/stacks/ | wc -l`) และพิมพ์ `OK: no local-only dirs`

- [ ] **Step 9: ลบ scratch clone**

```bash
SCRATCH=/private/tmp/claude-501/-Users-ekayut-Project-ai-claude-skill/d3d4d9d5-7388-4834-91e5-a193c91db3a2/scratchpad
rm -rf "$SCRATCH/verify-clone"
```

---

### Task 3: Back up the private marketplace repo

**Files:**
- Modify: `/Users/ekayut/Project/ekayutdev-plugins/.gitignore`
- Create: `/Users/ekayut/Project/ekayutdev-plugins/README.md`

**Interfaces:**
- Consumes: URL `https://github.com/ekayutdev/reusable-dev` จาก Task 2 (README อ้างถึงเพื่อกู้ symlink)
- Produces: `https://github.com/ekayutdev/ekayutdev-plugins` (private) — งานนี้จบ plan

- [ ] **Step 1: ดูสถานะและงานที่ค้าง**

```bash
cd /Users/ekayut/Project/ekayutdev-plugins
git status --short
git diff --stat
```

Expected: เห็น `plugins/hermes-offload/scripts/hz` และ `skills/hermes-offload/SKILL.md` แก้ค้าง (~429 บรรทัด) กับ `scripts/__pycache__/` ที่ยัง untracked

- [ ] **Step 2: หยุดถามเจ้าของเรื่องงาน hermes ที่ค้าง**

แสดง `git diff --stat` ให้เจ้าของ แล้วถามว่า (ก) commit งาน hermes ก่อน backup หรือ (ข) push เฉพาะสิ่งที่ commit แล้ว ปล่อยงานค้างไว้ก่อน — **ห้ามตัดสินใจเอง** ทำตามคำตอบ ถ้าเลือก (ก) ให้ commit แยกจาก commit ของ plan นี้ โดยเจ้าของเป็นคนให้ข้อความ commit

- [ ] **Step 3: เพิ่ม `__pycache__/` ใน `.gitignore`**

ไฟล์เดิมมีสองบรรทัด ต่อท้ายให้เป็น:

```gitignore
# local-only symlink to the reusable-dev repo (see marketplace.json)
/plugins/reusable-dev

# python bytecode from scripts/hz
__pycache__/
```

- [ ] **Step 4: ยืนยันว่า `__pycache__` หายจาก untracked แล้ว**

```bash
git status --short
```

Expected: ไม่มีบรรทัด `?? plugins/hermes-offload/scripts/__pycache__/` เหลืออยู่

- [ ] **Step 5: เขียน `README.md` ของ marketplace repo**

```markdown
# ekayutdev-plugins

Marketplace ส่วนตัวของ ekayut สำหรับ Claude Code — private repo ตัวนี้เป็นสำเนาสำรอง ไม่ใช่ช่องทางแจกจ่าย

| Plugin | ที่อยู่ | สาธารณะ |
|---|---|---|
| `hermes-offload` | `plugins/hermes-offload/` (ไฟล์จริงใน repo นี้) | ไม่ |
| `reusable-dev` | `plugins/reusable-dev` → symlink ไป `~/Project/ai/claude-skill` | ใช่ — https://github.com/ekayutdev/reusable-dev |

## ตั้งเครื่องใหม่

symlink ไม่ได้อยู่ใน git (ดู `.gitignore`) หลัง clone repo นี้ต้องสร้างใหม่เอง:

```bash
git clone https://github.com/ekayutdev/reusable-dev ~/Project/ai/claude-skill
ln -s ~/Project/ai/claude-skill ~/Project/ekayutdev-plugins/plugins/reusable-dev
claude plugin marketplace add ~/Project/ekayutdev-plugins
claude plugin install reusable-dev@ekayutdev-plugins
```

ติดตั้งแบบนี้จะได้สำเนาที่คัดลอกจากโฟลเดอร์ (ไม่ใช่ live) — แก้โค้ดใน `~/Project/ai/claude-skill` แล้วต้อง `/plugin update` ถึงจะเห็นผล

คนอื่นที่ต้องการแค่ `reusable-dev` ไม่ต้องใช้ repo นี้ — ติดตั้งจาก `ekayutdev/reusable-dev` ได้โดยตรง
```

- [ ] **Step 6: commit .gitignore + README**

```bash
git add .gitignore README.md
git commit -F - <<'EOF'
docs: README with rebuild steps, ignore __pycache__

The reusable-dev entry is a gitignored symlink, so a fresh clone of this
marketplace has a dangling plugin path with nothing explaining it. The
README now records where the real repo lives and how to relink it.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01E4b9iKXRA1bxNgBfpyhnFc
EOF
```

- [ ] **Step 7: สร้าง private repo แล้ว push**

```bash
gh repo create ekayutdev/ekayutdev-plugins \
  --private \
  --source=. \
  --remote=origin \
  --description "Personal Claude Code marketplace (backup)." \
  --push
```

- [ ] **Step 8: ยืนยันว่า push ขึ้นจริงและเป็น private**

```bash
git rev-parse HEAD
git ls-remote origin refs/heads/main
gh repo view ekayutdev/ekayutdev-plugins --json isPrivate,url
```

Expected: sha ตรงกัน และ `"isPrivate": true`

- [ ] **Step 9: ยืนยันว่า symlink ไม่ได้ขึ้นไปบน GitHub**

```bash
git ls-files plugins/ | grep -q "^plugins/reusable-dev$" && echo "FAIL: symlink is tracked" || echo "OK: symlink not tracked"
```

Expected: `OK: symlink not tracked`

- [ ] **Step 10: รายงานผลรวมให้เจ้าของ**

รายงานตามจริง: URL ทั้งสอง repo, tag `v0.1.0`, ผล validate จาก clone (Task 2 Step 7) และสิ่งที่ยังไม่ได้ทำตาม spec — การทดสอบ `/plugin marketplace add` จริง ซึ่งอยู่ในรอบ M1–M7
