export const meta = {
  name: 'dispatch-engine',
  description:
    'DAG-parallel GitHub-issue executor: schedules each task the moment its dependencies finish, runs it in an isolated git worktree at a triaged model/effort, and files a PR that closes the issue.',
  phases: [
    { title: 'Dispatch', detail: 'one worktree-isolated subagent per issue, scheduled by the dependency DAG' },
  ],
}

// args — supplied by the /dispatch orchestrator AFTER it has scouted the issues
// with `gh` and built the dependency DAG:
// {
//   baseBranch: 'master',          // trunk the independent tasks branch from
//   draft: true,                   // open PRs as drafts (default true)
//   tasks: [
//     {
//       id:       'A',             // stable key, referenced by other tasks' deps
//       issue:    123,             // GitHub issue number (or null for a synthetic sub-task)
//       title:    'short title',
//       brief:    'self-contained implementation brief: acceptance criteria, files, constraints',
//       model:    'haiku' | 'sonnet' | 'opus',
//       effort:   'low' | 'medium' | 'high' | 'max',
//       executor: 'claude' | 'antigravity',   // antigravity delegates the typing to agy (Gemini 3)
//       branch:   'dispatch/123-slug',
//       deps:     ['B', 'C'],      // ids that must finish first — MUST be acyclic
//     },
//   ],
// }
//
// Returns { baseBranch, count, results: [PR_RESULT...] }.

phase('Dispatch')

// The harness may deliver `args` as a JSON string rather than a parsed object
// (large inline tool-call payloads in particular). Coerce defensively.
let A = args
if (typeof A === 'string') {
  try {
    A = JSON.parse(A)
  } catch (e) {
    return { error: 'args was a string but not valid JSON: ' + e.message }
  }
}

const tasks = (A && A.tasks) || []
if (!tasks.length) return { error: 'args.tasks is empty — nothing to dispatch' }

const baseBranch = (A && A.baseBranch) || 'master'
const draft = !(A && A.draft === false)
const byId = {}
for (const t of tasks) byId[t.id] = t

const PR_RESULT = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'status'],
  properties: {
    id: { type: 'string' },
    issue: { type: ['number', 'null'] },
    status: { type: 'string', enum: ['pr_opened', 'pushed_no_pr', 'blocked', 'failed'] },
    branch: { type: 'string' },
    prUrl: { type: 'string' },
    summary: { type: 'string' },
    notes: { type: 'string' },
  },
}

function briefFor(t, base, depTasks, depResults) {
  const depLines = depTasks
    .map((dt, i) => {
      const r = depResults[i] || {}
      return `- #${dt.issue} "${dt.title}" → branch \`${dt.branch}\`${r.prUrl ? ` (${r.prUrl})` : ''}`
    })
    .join('\n')
  const closes = t.issue ? `Closes #${t.issue}` : '(no linked issue)'
  const useAgy =
    t.executor === 'antigravity'
      ? '\nThis is mechanical/well-specified work: do the typing by shelling out to `agy -p "<precise instructions>"` (Gemini 3), then review, test, commit, and open the PR yourself. Keep the agy task narrow and self-contained.'
      : ''
  return [
    `You are implementing ${t.issue ? `GitHub issue #${t.issue}` : 'a sub-task'}: ${t.title}.`,
    '',
    '## Task',
    t.brief,
    useAgy,
    '',
    '## Worktree + Git protocol (you have your own isolated git worktree)',
    `1. Base off \`${base}\`: \`git fetch origin ${base} && git checkout -B ${t.branch} origin/${base}\`.`,
    '2. Implement ONLY this task. Keep the diff tightly scoped.',
    '3. Run the repo build / tests / linter and iterate until green. Report what you ran.',
    `4. Commit with a clear message whose body contains \`${closes}\`.`,
    `5. Push: \`git push -u origin ${t.branch}\`.`,
    `6. Open a PR: \`gh pr create ${draft ? '--draft ' : ''}--base ${base} --head ${t.branch} --title "<title>" --body "<body>"\`.`,
    `   Body = ## Summary + ## Test plan + \`${closes}\`.`,
    depLines
      ? `   This work is STACKED on the PR(s) below (its base is \`${base}\`, not trunk). List them under a "## Depends on" section:\n${depLines}`
      : '',
    '7. Return the structured result: status, branch, prUrl, a one-line summary, and notes.',
    '',
    "If you can't get tests green or you're blocked, push what you have, skip/mark the PR as WIP, and return status=blocked with the reason in notes. Do not merge anything.",
  ]
    .filter(Boolean)
    .join('\n')
}

// Each task runs as soon as ALL of its dependencies have resolved — not when a
// whole "wave" finishes. This is the maximally-parallel realization of the DAG.
const started = {}
function run(t) {
  if (started[t.id]) return started[t.id]
  started[t.id] = (async () => {
    const depTasks = (t.deps || []).map((d) => byId[d]).filter(Boolean)
    const depResults = await Promise.all(depTasks.map(run))
    // Stack on the single dependency's branch; with 0 or >1 deps, branch from trunk
    // and let the dependent's PR note the cross-links (merge order is the reviewer's call).
    const base = depTasks.length === 1 ? depTasks[0].branch : baseBranch
    log(
      `▶ #${t.issue ?? '—'} ${t.title}  [${t.model}/${t.effort}${
        t.executor === 'antigravity' ? ' · agy' : ''
      }]  base=${base}`,
    )
    const opts = {
      label: `#${t.issue ?? '—'} ${t.title}`.slice(0, 60),
      phase: 'Dispatch',
      model: t.model,
      effort: t.effort,
      isolation: 'worktree',
      schema: PR_RESULT,
    }
    if (t.executor === 'antigravity') opts.agentType = 'antigravity'
    const res = await agent(briefFor(t, base, depTasks, depResults), opts)
    return res || { id: t.id, issue: t.issue ?? null, status: 'failed', notes: 'subagent returned null' }
  })()
  return started[t.id]
}

const results = await Promise.all(tasks.map(run))
return { baseBranch, count: results.length, results }
