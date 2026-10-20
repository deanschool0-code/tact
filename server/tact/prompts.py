"""Prompts. Reply quality is the product: the #1 complaint about this category is generic,
cringe, preset-sounding lines that get people blocked. Every rule below fights that."""
import json

TONES = {
    "chill": "relaxed, low-effort in a good way, easygoing",
    "funny": "playful and genuinely funny, light teasing at most, never mean",
    "flirty": "warm and flirty but tasteful, confident not thirsty, nothing sexual",
    "bold": "direct and confident, says what they want without games",
    "sweet": "kind, sincere, attentive",
    "witty": "clever wordplay or a sharp callback to something they said",
}

GOALS = {
    "keep_going": "keep the conversation going naturally; end with something easy to answer",
    "ask_out": "move toward a specific, low-pressure plan to meet (a concrete idea, not 'we should hang sometime')",
    "recover": "smooth over an awkward or dry moment without over-apologising",
    "change_topic": "pivot to a fresher, more interesting topic using something from the chat",
    "get_number": "suggest moving to texting/another app in a casual, no-pressure way",
}

STYLES = {
    "funny": "the user is naturally funny",
    "chill": "the user is laid-back",
    "bold": "the user is confident and direct",
    "sweet": "the user is warm and caring",
}

BASE_RULES = """You are Tact, a texting coach that writes messages the user will send as themselves.

Hard rules:
- Sound like a real person texting, not a pickup-line generator. No clichés, no cheesy puns
  unless the user asked for pickup lines, no "hey beautiful", no corporate words.
- Be specific: every reply must use a concrete detail from what the other person actually said
  or shared. A reply that could be sent to anyone is a failed reply.
- Keep it short like real texts: usually 3-20 words. One message, no multi-paragraph speeches.
- Never pressure, guilt-trip, neg, manipulate, or push after someone said no, asked for space,
  or is clearly losing interest. Respect boundaries. In that case set "boundary": true and write
  graceful, respectful replies (accept it, wish them well, or give space) instead.
- Nothing sexually explicit. Flirty means charming, not graphic.
- If anything suggests either person is under 18, do not write romantic or flirty content:
  set "boundary": true and keep replies friendly and platonic.
- Never invent facts about the user (job, plans, places) — if a reply needs one, keep it generic
  or phrase it as a question.
- Answer ONLY with JSON matching the schema. No markdown, no commentary."""


def voice_block(voice: list, style: str) -> str:
    parts = []
    if style in STYLES:
        parts.append(STYLES[style] + ".")
    samples = [s.strip() for s in (voice or []) if s and s.strip()][:8]
    if samples:
        parts.append(
            "Match the user's real texting voice from these messages they wrote: copy their typical "
            "length, capitalisation (lowercase if they write lowercase), punctuation, emoji use (none if "
            "they use none), and slang. Do not copy the content.\nUser's own texts:\n"
            + "\n".join(f"- {s[:200]}" for s in samples)
        )
    return "\n".join(parts) if parts else "No voice samples: write in a natural, casual texting voice."


def transcript_block(transcript: list) -> str:
    lines = []
    for m in transcript or []:
        who = "ME" if m.get("from") == "me" else "THEM"
        text = str(m.get("text", "")).strip()
        if text:
            lines.append(f"{who}: {text}")
    return "\n".join(lines)


REPLY_ITEM = '{"text": "the message", "why": "max 10 words on why it works"}'


def build(kind: str, p: dict) -> tuple[str, str]:
    """Return (system, user) prompts for a generation request."""
    tone = TONES.get(p.get("tone") or "chill", TONES["chill"])
    goal = GOALS.get(p.get("goal") or "keep_going", GOALS["keep_going"])
    voice = voice_block(p.get("voice") or [], p.get("style") or "")
    extra = (p.get("extra") or "").strip()
    extra_line = f"\nExtra context from the user: {extra}" if extra else ""
    text = (p.get("text") or "").strip()

    if kind == "reply":
        chat = transcript_block(p.get("transcript")) or text
        user = f"""Conversation (oldest first). ME is the user, THEM is the other person:
{chat}
{extra_line}
Tone: {tone}
Goal: {goal}
{voice}

Write 4 different reply options for ME to send next (different angles, not rewordings).
Schema: {{"read": "one honest sentence on where the chat stands", "boundary": false, "replies": [{REPLY_ITEM}, ...4]}}"""
    elif kind == "opener":
        user = f"""The other person's dating profile / bio / prompts:
{text}
{extra_line}
Tone: {tone}
{voice}

Write 4 first messages that reference something specific from the profile, end in something easy to answer, and avoid "hey" openers.
Schema: {{"read": "one sentence on the best hook in their profile", "boundary": false, "replies": [{REPLY_ITEM}, ...4]}}"""
    elif kind == "lines":
        about = text or "no name or topic given"
        user = f"""Pickup lines about: {about}
{extra_line}
Tone: {tone}

Write 6 pickup lines. They may be playful and a bit cheesy (that's the point here) but must be clever,
original, never crude or creepy, and never insult anyone. Use the name or topic if given.
Schema: {{"replies": [{REPLY_ITEM}, ...6]}}"""
    elif kind == "vibe":
        chat = transcript_block(p.get("transcript")) or text
        user = f"""Conversation (oldest first). ME is the user, THEM is the other person:
{chat}
{extra_line}

Honestly assess THEM's interest in ME from the text alone (reply length, questions asked back,
enthusiasm, who initiates, plans proposed). Be kind but truthful; don't flatter.
Schema: {{"interest": 0-100, "summary": "2 sentences", "green_flags": ["short", ...], "red_flags": ["short", ...],
"next_move": "one concrete suggestion", "boundary": false}}"""
    elif kind == "bio":
        user = f"""The user's own dating bio:
{text}
{extra_line}
{voice}

Score it 0-100 for how likely it is to start good conversations. Then write 3 improved versions in the
user's voice that keep their real facts (never invent hobbies or jobs) and add a hook someone can reply to.
Schema: {{"score": 0-100, "summary": "one sentence", "strengths": ["short", ...], "fixes": ["short", ...],
"rewrites": [{REPLY_ITEM}, ...3]}}"""
    elif kind == "tweak":
        how = {
            "shorter": "make it shorter and punchier",
            "funnier": "make it funnier",
            "bolder": "make it more confident and direct",
            "softer": "make it softer and warmer",
        }.get(p.get("tweak") or "", "improve it")
        chat = transcript_block(p.get("transcript"))
        ctx = f"Conversation so far:\n{chat}\n\n" if chat else ""
        user = f"""{ctx}Draft reply: {p.get("base", "")}
{voice}

{how.capitalize()}. Give 2 options.
Schema: {{"replies": [{REPLY_ITEM}, {REPLY_ITEM}]}}"""
    else:
        raise ValueError(f"unknown kind {kind}")
    return BASE_RULES, user


COACH_SYSTEM = """You are Tact's dating and texting coach. Give practical, specific, kind advice in a casual
voice, like a socially smart friend. Keep answers under 120 words unless asked for more; use short
paragraphs or a few bullets. Encourage honesty, respect and consent; never advise manipulation,
pressure, negging, or ignoring someone's "no". Nothing sexually explicit. If the user seems to be
under 18 or asks about someone under 18 romantically, keep advice age-appropriate and non-sexual.
If they're dealing with something serious (harassment, safety, feeling very low), be supportive and
suggest talking to someone they trust. Plain text only, no JSON."""


def coach_messages(messages: list, context: list | None) -> list:
    out = []
    if context:
        out.append({"role": "user", "content": "For context, here's my chat:\n" + transcript_block(context)})
        out.append({"role": "assistant", "content": "Got it, I've read the chat. What do you want to know?"})
    for m in messages[-20:]:
        role = "assistant" if m.get("role") == "assistant" else "user"
        text = str(m.get("text", "")).strip()[:2000]
        if text:
            out.append({"role": role, "content": text})
    # APIs need alternating roles starting with user; merge repeats.
    merged = []
    for m in out:
        if merged and merged[-1]["role"] == m["role"]:
            merged[-1]["content"] += "\n" + m["content"]
        else:
            merged.append(dict(m))
    while merged and merged[0]["role"] != "user":
        merged.pop(0)
    return merged


def parse_json(raw: str) -> dict:
    """Pull the first JSON object out of a model response."""
    raw = raw.strip()
    if raw.startswith("```"):
        raw = raw.strip("`")
        raw = raw[raw.find("{"):]
    start = raw.find("{")
    if start < 0:
        raise ValueError("no JSON object in model output")
    depth, in_str, esc = 0, False, False
    for i in range(start, len(raw)):
        c = raw[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return json.loads(raw[start:i + 1])
    raise ValueError("unterminated JSON in model output")
