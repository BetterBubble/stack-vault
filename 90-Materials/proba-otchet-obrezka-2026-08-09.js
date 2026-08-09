// Проба: данные утреннего отчёта не теряют порядок мержа при переполнении.
// Сценарий четырнадцатого круга: пять задач с обычными PR-описаниями → срез на 9000 символов
// приходился на середину массива задач, и mergeOrder в отчёт не попадал вовсе.
const fs = require('fs')
const src = fs.readFileSync(process.env.HOME + '/.claude/workflows/autonomous-feature.js', 'utf8')

// Вытаскиваем функцию reportJson из живого файла — проверяем то, что работает, а не копию.
const m = src.match(/function reportJson[\s\S]*?\n}\n/)
if (!m) { console.log('ПРОВАЛ: reportJson не найдена в файле'); process.exit(1) }
eval(m[0])

const prBody = 'Что сделано: ' + 'x'.repeat(1400) + '\nЧто тестировалось: числа.\n'
const mk = i => ({
  feature: 'feat-' + i, status: 'ready', branch: 'auto/feat-' + i,
  delivery: { branch: 'auto/feat-' + i, pushed: true, prUrl: 'https://x/' + i, prBodyBytes: prBody.length },
  acceptance: { passed: true }, attempts: 1,
})
const data = {
  status: 'ok', nightShift: true,
  mergeOrder: ['auto/feat-1', 'auto/feat-2', 'auto/feat-3', 'auto/feat-4', 'auto/feat-5'],
  needsHumanFirst: ['auto/feat-3 — конфликт с main'],
  deployAuthorized: false, failures: [], scopeReport: { declared: 5, touched: 5 },
  tasks: [1, 2, 3, 4, 5].map(mk),
}
// Раздуваем задачи так, чтобы гарантированно перелезть лимит.
data.tasks.forEach(t => { t.filler = 'y'.repeat(1800) })

const cap = 9000
const out = reportJson(data, cap)
let bad = 0
console.log('  длина результата:', out.length, '(лимит ' + cap + ')')

try { JSON.parse(out); console.log('  ok     JSON валиден') }
catch (e) { console.log('  ПРОВАЛ JSON невалиден:', e.message); bad++ }

const parsed = (() => { try { return JSON.parse(out) } catch { return {} } })()
if (parsed.mergeOrder && parsed.mergeOrder.length === 5) console.log('  ok     порядок мержа доехал целиком')
else { console.log('  ПРОВАЛ порядок мержа потерян:', JSON.stringify(parsed.mergeOrder)); bad++ }

if (parsed.needsHumanFirst && parsed.needsHumanFirst.length === 1) console.log('  ok     «требует человека» доехало')
else { console.log('  ПРОВАЛ «требует человека» потеряно'); bad++ }

if (parsed.tasksTruncated) console.log('  ok     потеря задач помечена явно:', parsed.tasksTruncated.slice(0, 60))
else if ((parsed.tasks || []).length === 5) console.log('  ok     все задачи влезли, обрезки не потребовалось')
else { console.log('  ПРОВАЛ задачи отброшены молча'); bad++ }

// Контроль: маленький отчёт не трогается вовсе
const small = { status: 'ok', mergeOrder: ['a'], tasks: [{ feature: 'f' }] }
const outSmall = reportJson(small, cap)
if (outSmall === JSON.stringify(small)) console.log('  ok     короткий отчёт не изменён')
else { console.log('  ПРОВАЛ короткий отчёт зачем-то переписан'); bad++ }

console.log(bad === 0 ? 'провалов нет' : 'ПРОВАЛОВ ' + bad)
process.exit(bad === 0 ? 0 : 1)
