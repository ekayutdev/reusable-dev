# reusable-dev Plugin — Design Spec

- **วันที่:** 2026-09-14
- **สถานะ:** Approved design, รอรีวิว spec
- **ประเภท:** Claude Code plugin (แชร์ผ่าน marketplace ได้)

## 1. เป้าหมาย

Plugin สำหรับช่วย Claude Code พัฒนาระบบ full-stack โดยยึด best practice การออกแบบ **UI component** และ **function/service** ให้ reuse ได้ ครอบคลุม 5 หน้าที่:

1. **Discover**: หาของเดิมก่อนสร้างใหม่
2. **Design rules**: กฎการออกแบบตอนเขียนใหม่
3. **Audit/refactor**: ตรวจโค้ดเดิมและเสนอการแยกเป็นของกลาง
4. **Registry**: ทะเบียนของที่ reuse ได้
5. **Verification**: ตรวจสอบการทำงานของโค้ด (unit test, type check/lint/build, regression หลัง refactor, e2e)

### ข้อจำกัดหลัก
- **ไม่ผูกกับ stack:** ตรวจ stack จากโปรเจกต์ ถามเฉพาะสิ่งที่ตรวจไม่ได้ **ครั้งเดียว** แล้วบันทึกเป็น config
- **ไม่ผูกกับ plugin อื่น:** ไม่ require superpowers หรือ skill ใดๆ แต่มี extension points ให้เสียบ skill อื่นได้
- **ทำงานคู่กับ superpowers ได้:** เมื่อติดตั้งทั้งคู่ superpowers ทำงานตามปกติ ส่วน reusable-dev เติมเรื่อง reuse เข้าไป
- **การเรียกใช้แบบผสม:** งานเบาทำอัตโนมัติผ่าน skill ส่วนงานหนักใช้ slash command

### Non-goals
- ไม่ติดตั้ง dependency หรือ skill อื่นให้อัตโนมัติ
- ไม่มี hook ที่บังคับ block การทำงาน
- ไม่มี script สแกนโค้ดเฉพาะภาษา (ใช้ `jscpd` เฉพาะเมื่อโปรเจกต์ติดตั้งไว้แล้ว)
- เฟส 1 ยังไม่รวม stack Go/Python/PHP และ shadcn port อื่นนอกจาก React/Vue/Svelte

## 2. โครงสร้าง Plugin

```
reusable-dev/                         (root ของ repo นี้)
├── .claude-plugin/plugin.json
├── skills/reusable-dev/
│   ├── SKILL.md                      ← workflow หลัก (ทำงานอัตโนมัติ)
│   └── references/
│       ├── component-design.md
│       ├── function-design.md
│       ├── verification.md           ← tiers + built-in fallbacks
│       ├── integration.md            ← extension points + การทำงานร่วมกับ process skills
│       ├── registry-format.md
│       ├── config-format.md
│       ├── stacks/
│       │   ├── _template.md
│       │   ├── react-next.md
│       │   ├── vue-nuxt.md
│       │   ├── sveltekit.md
│       │   └── node-ts.md
│       └── ui-libs/
│           ├── _template.md
│           ├── shadcn-core.md
│           ├── shadcn-react.md
│           ├── shadcn-vue.md
│           └── shadcn-svelte.md
├── commands/
│   ├── reuse-setup.md
│   ├── reuse-audit.md
│   ├── reuse-registry.md
│   └── reuse-verify.md
├── agents/
│   └── duplicate-finder.md
├── evals/                            ← claude plugin eval suite
│   ├── fixtures/                     ← react-shadcn, vue-shadcn, svelte-shadcn, node-ts
│   ├── lib/use-fixture.sh
│   ├── <case>/case.yaml + setup.sh   ← หนึ่ง scenario ต่อหนึ่งโฟลเดอร์
│   └── MANUAL.md                     ← checklist ทดสอบมือ (ร่วมกับ superpowers)
└── README.md
```

หลัก **progressive disclosure:** `SKILL.md` เก็บเฉพาะ workflow ส่วนหลักการ, stack และ ui-lib อยู่ใน `references/` และโหลดเฉพาะไฟล์ที่ต้องใช้

## 3. Workflow หลัก (`SKILL.md`)

**Trigger (description):** เมื่อ Claude กำลังสร้างหรือแก้ UI component, hook/composable, function, utility, service หรือ module ในโปรเจกต์ ใช้ได้กับทุกภาษา **ไม่ trigger** กับงานที่ไม่เกี่ยวกับโค้ด เช่น แก้เอกสาร

```
0. Load config → 1. Discover → 2. Decide → 3. Design → 4. Verify → 5. Register
```

### 0. Load config
- อ่าน `.claude/reusable-dev.md`
- ถ้าไม่มี: ตรวจ stack/ui-lib/คำสั่งจากโปรเจกต์ → ถามไม่เกิน 3 ข้อรวดเดียว → เขียนไฟล์ (flow เดียวกับ `/reuse-setup` แบบย่อ ซึ่ง **ไม่ตั้งค่า `skills`** ทุกจุดจึงว่างและใช้ fallback จนกว่าจะรัน `/reuse-setup` เต็ม)
- ถ้าผู้ใช้ข้ามการตั้งค่า: ใช้ค่าที่ตรวจได้ทำงานต่อ ไม่เขียนไฟล์ และเตือนครั้งเดียวในรายงาน

### 1. Discover
1. ค้นในทะเบียน (`registry` ใน config) ด้วยชื่อหรือ keyword
2. ตรวจว่า path ในรายการที่เจอยังมีอยู่จริง ถ้าไม่มี แนะนำ `/reuse-registry --sync`
3. ค้นใน `shared_paths` ด้วยชื่อ, keyword และรูปร่างของ props/parameter
4. ถ้าใช้ shadcn: เช็กตามลำดับ ติดตั้งแล้ว → registry ของ shadcn → registry ของทีมใน `components.json`

### 2. Decide (เลือกขั้นแรกที่ใช้ได้ และให้เหตุผลว่าทำไมขั้นก่อนหน้าใช้ไม่ได้)
1. **Reuse**: ใช้ของเดิมตามที่เป็น
2. **Extend**: เพิ่ม prop/parameter ที่มีค่า default และไม่ทำให้ของเดิมพัง
3. **Compose**: ประกอบจากหลายชิ้นที่มีอยู่
4. **Create**: สร้างใหม่ ถ้าใช้ที่เดียว ให้วางในโฟลเดอร์ feature ก่อน เมื่อมีจุดใช้ 2-3 ที่ค่อยย้ายขึ้น shared (**Rule of Three**)

### 3. Design
- โหลด `component-design.md` หรือ `function-design.md` + `stacks/<stack>.md` + `ui-libs/<ui_lib>.md` (ถ้ามี)
- เรียก extension point `design` (ถ้ากำหนดไว้)
- ของใน shared ต้องเขียน test ก่อน โดยใช้ extension point `test` หรือ fallback ใน `verification.md`

### 4. Verify (อัตโนมัติ: T1-T3)
- ทำตาม `verification.md` (หัวข้อ 6) ผ่าน extension point `verify` หรือ fallback
- ถ้าพังให้ส่งต่อ extension point `debug`

### 5. Register
- ถ้าสร้างของใหม่ใน shared หรือเปลี่ยน API ของของเดิม ให้อัปเดตทะเบียน
- ถ้าเปลี่ยน API ของของใน shared ให้เรียก extension point `review`

### รายงานท้ายงาน (บังคับ)
```
Reuse decision: Extend <Button> (+variant="danger")
Verified: T1 tsc ✓ lint ✓ · T2 4 tests ✓ · T3 3 call sites, 12 tests ✓
Notes: extension `review` skill not installed → used built-in checklist
```

## 4. Extension Points (`integration.md`)

reusable-dev พึ่งพา **หน้าที่** ไม่พึ่งพา skill ตัวใดตัวหนึ่ง (Dependency Inversion)

| Point | ทำงานตอน | ตัวอย่าง skill | Built-in fallback |
|---|---|---|---|
| `design` | ขั้น 3 | `mattpocock-skills:codebase-design`, `frontend-design:frontend-design` | `component-design.md` / `function-design.md` |
| `test` | ขั้น 3 (ของใน shared) | `superpowers:test-driven-development`, `mattpocock-skills:tdd` | test-first แบบย่อใน `verification.md` |
| `verify` | ขั้น 4 | `superpowers:verification-before-completion` | รันคำสั่งจาก config และรายงานจาก output จริง |
| `debug` | test พัง | `superpowers:systematic-debugging`, `mattpocock-skills:diagnosing-bugs` | หา root cause ก่อนแก้ ห้ามแก้แบบเดา |
| `review` | เปลี่ยน API ของของใน shared | `pr-review-toolkit:code-reviewer` | checklist backward compatibility |
| `plan` | `/reuse-audit` เจอ refactor ใหญ่ | `superpowers:writing-plans` | แตกเป็นขั้นย่อยในรายงาน |
| `e2e` | `/reuse-verify` | `chrome-devtools-mcp:chrome-devtools`, `run` | คำสั่ง `e2e` จาก config |

### กฎ
1. จุดไหนว่าง → ใช้ built-in fallback
2. skill ที่ระบุไม่ได้ติดตั้ง → ใช้ fallback และแจ้งครั้งเดียวในรายงาน **ไม่หยุดงาน**
3. ใส่ได้หลาย skill ต่อจุด ทำงานตามลำดับที่เขียน
4. reusable-dev เป็นเจ้าของ workflow ส่วน skill ที่เสียบทำเฉพาะงานของจุดนั้น
5. Built-in fallback สั้น 5-10 บรรทัดต่อจุด
6. **กันทำงานซ้ำ:** ถ้า skill ของจุดนั้นกำลังทำงานอยู่แล้วใน session ห้ามเรียกซ้ำ ให้ส่งข้อกำหนดเรื่อง reuse เพิ่มเข้าไปแทน

### การทำงานร่วมกับ process skills (เช่น superpowers)
process skill คุมลำดับขั้นตอน ส่วน reusable-dev ใส่ข้อกำหนดเรื่อง reuse:

| Process step | reusable-dev เติม |
|---|---|
| brainstorming / writing-plans | ทำ Discover + Decide แล้วใส่ **Reuse decision** ใน design หรือทุก task ของ plan |
| subagent-driven-development / executing-plans | Reuse decision ติดไปกับ task ที่ส่งให้ subagent |
| test-driven-development | ของใน shared ต้องมี test ครอบคลุม API ที่ถูกเรียกใช้ |
| verification-before-completion | เพิ่มคำสั่งจาก config + test ของจุดเรียกใช้ (T3) |
| finishing-a-development-branch | อัปเดตทะเบียน |

`integration.md` อ้างถึง process skill เป็น **ตัวอย่าง** เท่านั้น ไม่มีส่วนไหนของ workflow ที่ต้องมี superpowers

## 5. Design References

ทุกไฟล์ใช้โครง: **หลักการ → กฎที่ตรวจได้ → anti-patterns → ตัวอย่างสั้น** ไม่เกิน ~150 บรรทัด

### `component-design.md`
- **Layers:** `primitives` → `patterns` → `feature` → `page` ชั้นล่าง import ชั้นบนไม่ได้ และ shared import feature ไม่ได้
- **แยก UI ออกจาก logic:** logic อยู่ใน hook/composable ส่วน component ทำหน้าที่ render
- **Props API:** ใช้ variant enum แทน boolean · children/slots แทน config props · ส่งต่อ rest props/ref · รองรับ controlled/uncontrolled
- **UI ใน shared ห้าม:** fetch ข้อมูล, มี business logic, hardcode ข้อความหรือสี (ใช้ tokens/i18n)
- **Accessibility ขั้นต่ำ:** semantic element, ใช้ด้วย keyboard ได้, มี label
- **สัญญาณเตือน:** props > 7 · boolean หลายตัวที่ใช้ร่วมกันไม่ได้ · copy component มาแก้เล็กน้อย

### `function-design.md`
- **Functional core, imperative shell:** logic เป็น pure function ส่วน IO อยู่ที่ขอบระบบ
- **Dependency injection** สำหรับ IO (db, http, clock)
- **Parameters:** positional ≤ 3 ถ้ามากกว่าใช้ options object · boolean flag ที่สลับพฤติกรรม → แยกเป็น 2 function
- **Error handling:** ใช้แบบเดียวทั้งโปรเจกต์ตาม `error_style` ใน config (`throw` | `result`)
- **Layers:** `lib/domain` (pure) → `services` → `handlers/adapters` · ถ้า frontend/backend ใช้ภาษาเดียวกัน แยก shared package
- **Anti-patterns:** `utils` ที่รวมทุกอย่าง · ใช้ global ที่ซ่อนอยู่ · generic เกินจำเป็น

### `stacks/_template.md`
หัวข้อ: สัญญาณที่ใช้ตรวจจับ · หน่วย reuse ของ stack · path ที่นิยมใช้ · เครื่องมือ test · คำสั่ง default · anti-patterns เฉพาะ stack

### `ui-libs/shadcn-core.md`
1. `components/ui/*` = ชั้น primitives: ใช้ `shadcn add` จากขั้น Discover **ห้ามเขียน primitive เองจากศูนย์**
2. โค้ดที่ CLI สร้างเป็นของโปรเจกต์ (copy-in) แต่ควรแก้ให้น้อยที่สุด ถ้าจะเพิ่มแบบใหม่ ให้เพิ่ม variant ใน `cva` หรือ wrap ในชั้น `patterns` ถ้าจำเป็นต้องแก้ไฟล์ต้นฉบับ ให้บันทึกในคอลัมน์ Notes ของทะเบียน
3. รวม class ด้วย `cn()` และใช้ tokens ผ่าน CSS variables
4. component ที่ใช้ข้ามโปรเจกต์ → เสนอให้ย้ายไป private registry แบบ namespaced (`@team/...`, shadcn 3.0+)

ไฟล์ของแต่ละ port (react/vue/svelte) เก็บเฉพาะ syntax และ idiom ที่ต่างกัน

**ข้อกำหนดตอน implement:** ต้องค้นข้อมูลเวอร์ชันล่าสุดของแต่ละ stack/ui-lib ผ่าน context7 หรือเอกสารทางการ ก่อนเขียนไฟล์ reference

## 6. Verification (`verification.md`)

| Tier | อะไร | ทำเมื่อ |
|---|---|---|
| T1 | typecheck · lint · build | ทุกครั้ง |
| T2 | unit test ของไฟล์ที่แก้ (ของใน shared ต้องมี test) | ทุกครั้ง |
| T3 | หาจุดเรียกใช้ (LSP หรือ grep) แล้วรัน test ที่เกี่ยวข้อง | เมื่อแก้ของใน shared |
| T4 | e2e / เปิดแอปจริง | `/reuse-verify` เท่านั้น |

- รายงานจาก **output จริง** เท่านั้น
- ไม่มีคำสั่งของ tier ใด → รายงาน `Tn skipped: <เหตุผล>` ห้ามเขียนว่าผ่าน
- ห้ามแก้ test ให้ผ่านแบบหลวมๆ ถ้า API จำเป็นต้องเปลี่ยน ให้ทำแบบไม่พังของเดิม หรือแก้ทุกจุดเรียกใช้พร้อมรายการที่แก้

## 7. Config (`.claude/reusable-dev.md`)

commit เข้า git เพื่อให้ทั้งทีมใช้ร่วมกัน frontmatter:

```yaml
---
stack: react-next                  # หรือ map ตาม path สำหรับ monorepo:
# stack: { "apps/web": react-next, "apps/api": node-ts }
ui_lib: shadcn-react               # ว่างได้
shared_paths:
  components: src/shared/ui
  functions: src/shared/lib
commands:
  typecheck: "tsc --noEmit"
  lint: "eslint ."
  test: "vitest run"
  build: "vite build"
  e2e: ""
error_style: throw                 # throw | result
registry: docs/reuse-registry.md
skills:
  design: []
  test: []
  verify: []
  debug: []
  review: []
  plan: []
  e2e: []
---
```
ส่วน body ของไฟล์ใช้เขียน convention เพิ่มเติมของทีมเป็นข้อความอิสระ

## 8. Commands

### `/reuse-setup`
1. ตรวจจากไฟล์: `package.json`, `svelte.config.*`, `nuxt.config.*`, `next.config.*`, `go.mod`, `pyproject.toml`, `composer.json`, `components.json` และคำสั่งจาก `scripts`
2. แนะนำ skill ให้แต่ละ extension point จากรายการ skill ที่ติดตั้งอยู่ใน context
3. ถามรวดเดียวเฉพาะข้อที่ตรวจไม่ได้ → เขียน config
4. ถ้ายังไม่มีทะเบียน ถามว่าจะสแกนสร้างทะเบียนเริ่มต้นเลยไหม
5. เจอ stack ที่ไม่มีไฟล์ reference → เสนอสร้างจาก `_template.md`
6. รันซ้ำได้: แสดง diff ของ config ก่อนเขียนทับ

### `/reuse-audit [path]`
- ไม่ระบุ path → สแกน `shared_paths` + ไฟล์ที่เปลี่ยนล่าสุดใน git
- ส่งงานให้ agent `duplicate-finder` แล้วได้รายงานเรียงตามผลกระทบ (จำนวนจุด × ขนาด):
  - โค้ดที่ซ้ำหรือคล้ายกัน
  - ละเมิดกฎใน references
  - ของใน shared ที่ไม่มี test
  - primitive ที่เขียนเองทั้งที่มีใน ui-lib
- **ไม่แก้ไฟล์เอง** ผู้ใช้เลือกข้อที่จะทำ → เข้า workflow ขั้น 2-5 · refactor ใหญ่ → extension point `plan`

### `/reuse-registry [--sync]`
- สแกน export ใน `shared_paths` เทียบกับทะเบียน → เพิ่ม/แก้/ลบรายการ และแสดง diff ก่อนเขียน
- ถ้าใช้ shadcn: เลือกสร้าง `registry.json` สำหรับ reuse ข้ามโปรเจกต์ได้

### `/reuse-verify [scope]`
- รัน T1-T4 · T4 ผ่าน extension point `e2e` หรือคำสั่งจาก config · รายงานพร้อม output จริง

## 9. Agent: `duplicate-finder`
- **Tools:** Read, Grep, Glob, Bash (อ่านอย่างเดียว)
- ใช้ `jscpd` ถ้าติดตั้งในโปรเจกต์ ถ้าไม่มีใช้ grep + เปรียบเทียบโครงสร้าง
- **Output:** รายการ findings `{kind, locations[], similarity, suggestion, impact}` ไม่ส่งเนื้อหาไฟล์กลับ

## 10. Registry (`docs/reuse-registry.md`)

หมวด: UI Primitives · UI Patterns · Hooks/Composables · Functions · Services
หนึ่งรายการต่อหนึ่งแถว เพื่อให้ grep ได้ในบรรทัดเดียว:

```markdown
## UI · Patterns
| Name | Path | Purpose | API | Used by | Notes |
|---|---|---|---|---|---|
| DataTable | src/shared/ui/DataTable.tsx | ตารางที่ sort/paginate ได้ | `columns, data, sortable?, onRowClick?` | 7 | wraps shadcn Table |
```
- **Used by** = จำนวนจุดเรียกใช้ ใช้ประเมินความเสี่ยงตอนเปลี่ยน API และความละเอียดของ T3

## 11. Error Handling

| สถานการณ์ | พฤติกรรม |
|---|---|
| ไม่มี config | ตั้งค่าแบบย่อครั้งเดียว ถ้าข้าม ใช้ค่าที่ตรวจได้และเตือนครั้งเดียว |
| Monorepo หลาย stack | `stack` แบบ map ตาม path |
| ไม่มีคำสั่งของ tier | `Tn skipped` ห้ามเขียนว่าผ่าน |
| skill ใน extension point ไม่ได้ติดตั้ง | fallback + แจ้งครั้งเดียว |
| ทะเบียนไม่ตรงกับโค้ด | แนะนำ `/reuse-registry --sync` |
| T3 พัง | หยุด → `debug` · ห้ามแก้ test ให้หลวม |
| stack ที่ไม่มีไฟล์ reference | ใช้หลักการทั่วไป + เสนอสร้างจาก template |
| Repo ใหญ่ | audit จำกัดขอบเขตตามหัวข้อ 8 |

## 12. การทดสอบ

แนวทาง RED → GREEN → REFACTOR สำหรับ skill: รันแต่ละ scenario แบบไม่มี plugin ก่อนเพื่อบันทึก baseline แล้วรันแบบมี plugin

### Fixtures (`evals/fixtures/`)
- `react-shadcn`: `Button` (shadcn, variants default|outline), pattern `DataTable` ใน shared, `formatDate` เขียนซ้ำใน 2 feature; คำสั่งทั้งหมดว่าง (ทดสอบรายงาน `skipped`)
- `vue-shadcn`, `svelte-shadcn`: `Button` + `CustomerCard` สำหรับทดสอบ Extend ตาม ui-lib port
- `node-ts`: `formatCurrency` ใน shared + 2 จุดเรียกใช้ พร้อม `node --test` ที่รันได้จริง (ทดสอบ T2/T3)

### Scenarios (`evals/<case>/case.yaml`)
1. "เพิ่มปุ่มลบสีแดง" → Extend `Button` (+variant) ไม่สร้าง `DangerButton`
2. "แสดงวันที่ในหน้า orders" → reuse `formatDate`
3. **Pressure:** "ด่วน เขียน component ใหม่ไปเลย" → ยังค้นก่อน และรายงาน decision
4. component ที่ใช้ที่เดียว → วางในโฟลเดอร์ feature
5. เปลี่ยน signature ของ function ใน shared → รัน T3 ครบทุกจุดเรียกใช้
6. ใช้ร่วมกับ `superpowers:writing-plans` → ทุก task มี Reuse decision
7. config ระบุ skill ที่ไม่ได้ติดตั้ง → fallback ไม่หยุดงาน
8. ไม่มี config → ถามครั้งเดียว เขียนไฟล์ · session ถัดไปไม่ถาม
9. **Negative trigger:** "แก้คำผิดใน README" → skill ไม่ทำงาน

### Structural validation
- `plugin-dev:plugin-validator` และ `plugin-dev:skill-reviewer`
- รัน scenario ด้วย `claude plugin eval` (ablation with-without = baseline ไม่มี plugin เทียบกับมี plugin)
- Scenario 6 (ร่วมกับ superpowers) ทดสอบด้วย eval ที่ไม่ต้องมี superpowers + checklist มือใน `evals/MANUAL.md` เพราะ eval โหลด plugin นอก root ไม่ได้

## 13. Phasing

| เฟส | ขอบเขต |
|---|---|
| **1** | plugin skeleton · SKILL.md · references หลัก (component/function/verification/integration/registry/config) · stacks: react-next, vue-nuxt, sveltekit, node-ts · ui-libs: shadcn-core, shadcn-react, shadcn-vue, shadcn-svelte · 4 commands · agent · fixtures + scenarios |
| **2** | stacks: go, python, php + fixtures |
| **ภายหลัง** | shadcn port อื่น (shadcn-solid, spartan/ui, react-native-reusables, Flutter shadcn_ui) สร้างจาก template เมื่อมีโปรเจกต์ที่ใช้จริง |

## 14. แหล่งอ้างอิง
- [Framework Ports – Awesome shadcn/ui](https://www.shadcn.io/awesome/ports)
- [shadcn/ui Registry docs](https://ui.shadcn.com/docs/registry)
- [shadcn-ui/registry-template](https://github.com/shadcn-ui/registry-template)
