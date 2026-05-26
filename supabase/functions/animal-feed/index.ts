import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GIPHY_KEY = 'dc6zaTOxFJmzC'

// ─── Reddit 設定 ───────────────────────────────────────────
const subredditMap: Record<string, { subs: string[]; tags: string[] }> = {
  cat:         { subs: ['cats', 'IllegallySmolCats', 'catpictures'], tags: ['猫', 'もふもふ'] },
  dog:         { subs: ['dogs', 'dogpictures', 'aww'], tags: ['犬', 'ふわふわ'] },
  otter:       { subs: ['Otters', 'otterchaos'], tags: ['カワウソ', 'かわいい'] },
  capybara:    { subs: ['capybara', 'Capybara'], tags: ['カピバラ', 'のんびり'] },
  rabbit:      { subs: ['Rabbits', 'rabbits'], tags: ['うさぎ', 'まん丸'] },
  bird:        { subs: ['parrots', 'birding', 'budgies'], tags: ['鳥', 'カラフル'] },
  smallAnimal: { subs: ['hamsters', 'guineapigs', 'chinchilla'], tags: ['小動物', 'まん丸'] },
  mixed:       { subs: ['AnimalsBeingBros', 'AnimalsBeingDerpy', 'aww'], tags: ['癒し', 'ほっこり'] },
  baby:        { subs: ['aww'], tags: ['赤ちゃん', 'ちいさい'] },
}

// ─── Tumblr タグ設定 ────────────────────────────────────────
const tumblrTagMap: Record<string, { tags: string[]; mofuTags: string[] }> = {
  cat:         { tags: ['cats of tumblr', 'cute cat', 'kitty cat'], mofuTags: ['猫', 'もふもふ', 'かわいい'] },
  dog:         { tags: ['dogs of tumblr', 'cute dog', 'puppy'], mofuTags: ['犬', 'ふわふわ', 'かわいい'] },
  otter:       { tags: ['otter', 'cute otter', 'otterly adorable'], mofuTags: ['カワウソ', 'かわいい'] },
  capybara:    { tags: ['capybara', 'capybaras'], mofuTags: ['カピバラ', 'のんびり'] },
  rabbit:      { tags: ['bunnies of tumblr', 'cute rabbit', 'bunny'], mofuTags: ['うさぎ', 'もふもふ'] },
  bird:        { tags: ['birds of tumblr', 'cute bird', 'birb'], mofuTags: ['鳥', 'かわいい'] },
  smallAnimal: { tags: ['hamster', 'guinea pig', 'hedgehog'], mofuTags: ['小動物', 'まん丸'] },
  mixed:       { tags: ['animals of tumblr', 'cute animals', 'fluffy'], mofuTags: ['癒し', 'どうぶつ'] },
  baby:        { tags: ['baby animals', 'baby animal'], mofuTags: ['赤ちゃん', 'ちいさい'] },
}

// ─── Giphy 検索設定 ─────────────────────────────────────────
const giphyQueryMap: Record<string, { query: string; tags: string[] }> = {
  cat:         { query: 'cute cat sleeping', tags: ['猫', 'GIF', 'ねむい'] },
  dog:         { query: 'cute dog fluffy', tags: ['犬', 'GIF', 'ふわふわ'] },
  otter:       { query: 'otter cute', tags: ['カワウソ', 'GIF', 'かわいい'] },
  capybara:    { query: 'capybara relax', tags: ['カピバラ', 'GIF', 'まったり'] },
  rabbit:      { query: 'bunny cute fluffy', tags: ['うさぎ', 'GIF', 'もふもふ'] },
  bird:        { query: 'cute bird', tags: ['鳥', 'GIF', 'かわいい'] },
  smallAnimal: { query: 'hamster cute', tags: ['小動物', 'GIF', 'まん丸'] },
  mixed:       { query: 'animals cute', tags: ['動物', 'GIF', '癒し'] },
  baby:        { query: 'baby animal cute', tags: ['赤ちゃん動物', 'GIF', 'ちいさい'] },
}

// ─── ユーティリティ ──────────────────────────────────────────
function isImage(url: string): boolean {
  const lower = url.toLowerCase()
  return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
    lower.endsWith('.png') || lower.endsWith('.gif') ||
    lower.endsWith('.webp') || lower.includes('i.redd.it') ||
    lower.includes('i.imgur.com')
}

// 低解像度URLを弾く
function isHighQuality(url: string): boolean {
  const lower = url.toLowerCase()
  const bad = ['_t.jpg', '_t.jpeg', '/thumb/', '/thumbnail/', '/small/',
    '50x50', '75x75', '100x', '120x', 'mqdefault', 'sq75', 'sq100']
  return !bad.some(p => lower.includes(p))
}

// ─── イラスト・アート除外 ─────────────────────────────────────
// イラスト系タグ（Tumblr タグと照合）
const ART_TAGS = new Set([
  'art', 'illustration', 'illustrations', 'drawing', 'drawings',
  'artwork', 'artworks', 'digital art', 'digitalart', 'fanart', 'fan art',
  'sketch', 'sketches', 'watercolor', 'watercolour', 'my art', 'myart',
  'original art', 'artist', 'illustrator', 'painted', 'painting', 'paintings',
  'pixel art', 'pixelart', 'comic', 'comics', 'cartoon', 'cartoons',
  'vector', 'concept art', 'character design', 'anime art', 'manga',
  'furry art', 'furry', 'anthro', 'oc', 'original character',
  'animation', 'gif art', 'art blog',
])

// イラスト系ドメイン
const ART_DOMAINS = [
  'deviantart.com', 'artstation.com', 'pixiv.net', 'furaffinity.net',
  'weasyl.com', 'newgrounds.com', 'e621.net',
]

// タグ・キャプション・URLでイラストかどうか判定
function isIllustration(
  tags: string[],
  caption: string,
  url: string
): boolean {
  // ① タグチェック
  if (tags.some(t => ART_TAGS.has(t.toLowerCase().trim()))) return true

  // ② キャプション内のアートキーワード
  const lower = caption.toLowerCase()
  const artPhrases = [
    'illustration', 'digital art', 'my art', 'painted by', 'drawn by',
    'art by', 'commission', 'deviantart', 'artstation',
  ]
  if (artPhrases.some(k => lower.includes(k))) return true

  // ③ イラスト系ドメイン
  if (ART_DOMAINS.some(d => url.includes(d))) return true

  return false
}

function calcCalmScore(title: string, upvoteRatio: number): number {
  let score = upvoteRatio * 0.7 + 0.2
  const lower = title.toLowerCase()
  const sadWords = ['died', 'rip', 'sick', 'cancer', 'passed', 'lost']
  if (sadWords.some(w => lower.includes(w))) score -= 0.25
  if (lower.includes('sleep') || lower.includes('cute') || lower.includes('fluffy')) score += 0.05
  return Math.max(0.3, Math.min(1.0, score))
}

function extractTags(title: string): string[] {
  const lower = title.toLowerCase()
  const tags: string[] = []
  if (lower.includes('sleep') || lower.includes('nap')) tags.push('寝顔')
  if (lower.includes('kitten') || lower.includes('puppy') || lower.includes('baby')) tags.push('赤ちゃん')
  if (lower.includes('together') || lower.includes('friend')) tags.push('仲良し')
  if (lower.includes('fluffy') || lower.includes('fluff')) tags.push('ふわふわ')
  return tags
}

// ─── Reddit 取得 ─────────────────────────────────────────────
async function fetchReddit(sub: string, limit = 6): Promise<any[]> {
  const res = await fetch(
    `https://www.reddit.com/r/${sub}/hot.json?limit=${limit}&raw_json=1`,
    { headers: { 'User-Agent': 'mofu-app/1.0' } }
  )
  if (!res.ok) return []
  const data = await res.json()
  return data?.data?.children ?? []
}

// ─── Tumblr 取得（高画質写真のみ）────────────────────────────
async function fetchTumblr(
  tag: string,
  limit = 6
): Promise<{ url: string; postUrl: string }[]> {
  const apiKey = Deno.env.get('TUMBLR_API_KEY') ?? ''
  if (!apiKey) return []
  try {
    const res = await fetch(
      `https://api.tumblr.com/v2/tagged?tag=${encodeURIComponent(tag)}&api_key=${apiKey}&limit=20&filter=text`,
      { headers: { 'User-Agent': 'mofu-app/1.0' } }
    )
    if (!res.ok) return []
    const data = await res.json()
    const posts: any[] = data.response ?? []
    const results: { url: string; postUrl: string }[] = []

    for (const post of posts) {
      if (post.type !== 'photo') continue

      // イラスト・アートを除外
      const postTags: string[] = post.tags ?? []
      const caption: string = post.caption ?? post.summary ?? ''
      const postUrl: string = post.post_url ?? 'https://tumblr.com'
      if (isIllustration(postTags, caption, postUrl)) continue

      const photos: any[] = post.photos ?? []
      for (const photo of photos) {
        const orig = photo.original_size
        if (!orig) continue
        // 最低 500px 幅以上の高画質のみ
        if ((orig.width ?? 0) < 500) continue
        if (!isHighQuality(orig.url ?? '')) continue
        // 画像URLでもアートドメインチェック
        if (isIllustration([], '', orig.url ?? '')) continue
        results.push({
          url: orig.url,
          postUrl,
        })
        if (results.length >= limit) return results
      }
    }
    return results
  } catch (_) {
    return []
  }
}

// ─── 人間のみ投稿を除外 ──────────────────────────────────────
function isHumanOnly(title: string): boolean {
  const lower = title.toLowerCase()
  const humanSignals = [
    'selfie', 'portrait of', 'photo of me', 'me and my', 'my son', 'my daughter',
    'my wife', 'my husband', 'my girlfriend', 'my boyfriend', 'my kids',
    'my child', 'my family', 'gave birth', 'ultrasound', 'pregnant',
    'halloween costume', 'cosplay as', 'dress up as',
  ]
  if (!humanSignals.some(p => lower.includes(p))) return false
  const animalWords = ['cat', 'dog', 'pet', 'animal', 'kitten', 'puppy',
    'bird', 'rabbit', 'hamster', 'otter', 'guinea', 'ferret']
  return !animalWords.some(w => lower.includes(w))
}

// ─── Giphy 取得（ID付き・高画質）────────────────────────────
async function fetchGiphy(query: string, limit = 4): Promise<{url: string, id: string}[]> {
  try {
    const url = `https://api.giphy.com/v1/gifs/search?api_key=${GIPHY_KEY}&q=${encodeURIComponent(query)}&limit=${limit}&rating=g`
    const res = await fetch(url)
    if (!res.ok) return []
    const data = await res.json()
    return (data.data ?? [])
      .map((g: any) => ({
        url: g?.images?.fixed_width?.url ?? g?.images?.original_still?.url ?? '',
        id: g?.id ?? '',
      }))
      .filter((item: {url: string, id: string}) => item.url.length > 0)
  } catch (_) {
    return []
  }
}

// ─── メインハンドラー ─────────────────────────────────────────
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const url = new URL(req.url)
  const animalType = url.searchParams.get('type') ?? 'mixed'
  const limit = parseInt(url.searchParams.get('limit') ?? '6')

  const posts: any[] = []

  // ① Reddit 投稿
  const redditConfig = subredditMap[animalType] ?? subredditMap['mixed']
  for (const sub of redditConfig.subs) {
    try {
      const children = await fetchReddit(sub, limit)
      for (const child of children) {
        const post = child.data
        const imgUrl = post.url as string ?? ''
        if (!isImage(imgUrl)) continue
        if (!isHighQuality(imgUrl)) continue
        if (post.over_18) continue
        if ((post.score ?? 0) < 50) continue
        const title = post.title ?? ''
        // イラスト・アート投稿を除外（タイトル・URLで判定）
        if (isIllustration([], title, imgUrl)) continue
        if (isHumanOnly(title)) continue
        posts.push({
          id: `reddit_${post.id}`,
          sourceUrl: `https://reddit.com${post.permalink}`,
          thumbnailUrl: imgUrl,
          animalType,
          tags: [...redditConfig.tags, ...extractTags(title)].slice(0, 3),
          calmScore: calcCalmScore(title, post.upvote_ratio ?? 0.8),
          soundLevel: 0.1,
          mood: 'healing',
          hasSadContext: ['died','rip','sick','cancer','passed','lost'].some(w => title.toLowerCase().includes(w)),
          isAsmr: false,
          isGif: false,
        })
      }
    } catch (_) { continue }
  }

  // ② Tumblr 写真（高画質）
  const tumblrConfig = tumblrTagMap[animalType] ?? tumblrTagMap['mixed']
  for (const tag of tumblrConfig.tags) {
    try {
      const photos = await fetchTumblr(tag, 4)
      for (let i = 0; i < photos.length; i++) {
        posts.push({
          id: `tumblr_${photos[i].url.split('/').pop()?.split('?')[0].replace(/\W/g, '_').slice(-40) ?? i}`,
          sourceUrl: photos[i].postUrl,
          thumbnailUrl: photos[i].url,
          animalType,
          tags: tumblrConfig.mofuTags,
          calmScore: 0.88,
          soundLevel: 0.05,
          mood: 'healing',
          hasSadContext: false,
          isAsmr: false,
          isGif: photos[i].url.toLowerCase().endsWith('.gif'),
        })
      }
    } catch (_) { continue }
  }

  // ③ Giphy GIF
  const giphyConfig = giphyQueryMap[animalType] ?? giphyQueryMap['mixed']
  try {
    const gifItems = await fetchGiphy(giphyConfig.query, 4)
    for (let i = 0; i < gifItems.length; i++) {
      posts.push({
        id: `giphy_${gifItems[i].id || `${animalType}_${i}`}`,
        sourceUrl: 'https://giphy.com',
        thumbnailUrl: gifItems[i].url,
        animalType,
        tags: giphyConfig.tags,
        calmScore: 0.85,
        soundLevel: 0.05,
        mood: 'healing',
        hasSadContext: false,
        isAsmr: false,
        isGif: true,
      })
    }
  } catch (_) {}

  posts.sort(() => Math.random() - 0.5)

  return new Response(JSON.stringify({ posts }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
