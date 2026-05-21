import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// 動物種別ごとのsubreddit設定
const subredditMap: Record<string, { subs: string[]; tags: string[] }> = {
  cat:         { subs: ['cats', 'IllegallySmolCats', 'catpictures'], tags: ['猫', 'もふもふ'] },
  dog:         { subs: ['dogs', 'dogpictures', 'aww'], tags: ['犬', 'ふわふわ'] },
  otter:       { subs: ['Otters', 'otterchaos'], tags: ['カワウソ', 'かわいい'] },
  capybara:    { subs: ['capybara', 'Capybara'], tags: ['カピバラ', 'のんびり'] },
  rabbit:      { subs: ['Rabbits', 'rabbits'], tags: ['うさぎ', 'まん丸'] },
  bird:        { subs: ['parrots', 'birding', 'budgies'], tags: ['鳥', 'カラフル'] },
  smallAnimal: { subs: ['hamsters', 'guineapigs', 'chinchilla'], tags: ['小動物', 'まん丸'] },
  mixed:       { subs: ['AnimalsBeingBros', 'AnimalsBeingDerpy', 'aww'], tags: ['癒し', 'ほっこり'] },
  baby:        { subs: ['babybigcatgifs', 'aww'], tags: ['赤ちゃん', 'ちいさい'] },
}

function isImage(url: string): boolean {
  const lower = url.toLowerCase()
  return lower.endsWith('.jpg') ||
    lower.endsWith('.jpeg') ||
    lower.endsWith('.png') ||
    lower.endsWith('.gif') ||
    lower.endsWith('.webp') ||
    lower.includes('i.redd.it') ||
    lower.includes('i.imgur.com')
}

function calcCalmScore(title: string, upvoteRatio: number): number {
  let score = upvoteRatio * 0.7 + 0.2
  const lower = title.toLowerCase()
  const sadWords = ['died', 'rip', 'sick', 'cancer', 'passed', 'lost', 'rescue', 'sad']
  if (sadWords.some(w => lower.includes(w))) score -= 0.25
  if (lower.includes('sleep') || lower.includes('cute') || lower.includes('fluffy')) score += 0.05
  return Math.max(0.3, Math.min(1.0, score))
}

async function fetchSubreddit(sub: string, limit = 8): Promise<any[]> {
  const res = await fetch(
    `https://www.reddit.com/r/${sub}/hot.json?limit=${limit}&raw_json=1`,
    { headers: { 'User-Agent': 'mofu-app/1.0 (github.com/catlisa332/mofu-app)' } }
  )
  if (!res.ok) return []
  const data = await res.json()
  return data?.data?.children ?? []
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const url = new URL(req.url)
  const animalType = url.searchParams.get('type') ?? 'mixed'
  const limit = parseInt(url.searchParams.get('limit') ?? '8')

  const config = subredditMap[animalType] ?? subredditMap['mixed']
  const posts: any[] = []

  for (const sub of config.subs) {
    try {
      const children = await fetchSubreddit(sub, limit)
      for (const child of children) {
        const post = child.data
        const imgUrl = post.url as string ?? ''
        if (!isImage(imgUrl)) continue
        if (post.over_18) continue
        if ((post.score ?? 0) < 50) continue

        const title = post.title ?? ''
        posts.push({
          id: `reddit_${post.id}`,
          sourceUrl: `https://reddit.com${post.permalink}`,
          thumbnailUrl: imgUrl,
          animalType,
          tags: [...config.tags, ...extractTags(title)].slice(0, 3),
          calmScore: calcCalmScore(title, post.upvote_ratio ?? 0.8),
          soundLevel: 0.1,
          mood: 'healing',
          hasSadContext: ['died','rip','sick','cancer','passed','lost'].some(w => title.toLowerCase().includes(w)),
          isAsmr: false,
        })
      }
    } catch (_) { continue }
  }

  // シャッフル
  posts.sort(() => Math.random() - 0.5)

  return new Response(JSON.stringify({ posts }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})

function extractTags(title: string): string[] {
  const lower = title.toLowerCase()
  const tags: string[] = []
  if (lower.includes('sleep') || lower.includes('nap')) tags.push('寝顔')
  if (lower.includes('kitten') || lower.includes('puppy') || lower.includes('baby')) tags.push('赤ちゃん')
  if (lower.includes('together') || lower.includes('friend') || lower.includes('bros')) tags.push('仲良し')
  if (lower.includes('fluffy') || lower.includes('fluff')) tags.push('ふわふわ')
  if (lower.includes('tiny') || lower.includes('small') || lower.includes('smol')) tags.push('ちいさい')
  return tags
}
