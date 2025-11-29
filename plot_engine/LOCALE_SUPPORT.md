# AI Endpoints Locale Support

All AI endpoints now support multi-language responses via the `locale` parameter.

## Supported Locales

| Code | Language |
|------|----------|
| `en` | English (default) |
| `cn` | Chinese (Simplified) |
| `zh` | Chinese (Simplified) |
| `zh-CN` | Chinese (Simplified) |
| `zh-TW` | Chinese (Traditional) |
| `tw` | Chinese (Traditional) |
| `ja` | Japanese |
| `ko` | Korean |
| `es` | Spanish |
| `fr` | French |
| `de` | German |
| `pt` | Portuguese |
| `ru` | Russian |
| `ar` | Arabic |
| `it` | Italian |

## Usage

Add `locale` parameter to any AI endpoint request:

```json
{
  "projectId": "uuid",
  "question": "What are the plot holes?",
  "locale": "cn"
}
```

If `locale` is omitted or set to `"en"`, responses default to English.

## Affected Endpoints

| Endpoint | Locale Support |
|----------|----------------|
| `POST /ai/ask` | ✅ |
| `POST /ai/write/continue` | ✅ |
| `POST /ai/write/modify` | ✅ |
| `POST /ai/validate/consistency` | ✅ |
| `POST /ai/validate/timeline` | ✅ |
| `POST /ai/suggest/foreshadow` | ✅ |
| `POST /ai/suggest/foreshadow/detect` | ✅ |

## Frontend Integration

### 1. Store User Preference

```typescript
// Save user's language preference
localStorage.setItem('ai_locale', 'cn');

// Retrieve
const locale = localStorage.getItem('ai_locale') || 'en';
```

### 2. Include in API Calls

```typescript
const response = await fetch('/ai/ask', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    projectId,
    question,
    locale: getUserLocale(), // 'cn', 'ja', etc.
  }),
});
```

### 3. Auto-detect from Browser

```typescript
function getDefaultLocale(): string {
  const supported = ['en', 'cn', 'zh', 'ja', 'ko', 'es', 'fr', 'de', 'pt', 'ru', 'ar', 'it'];
  const browserLang = navigator.language.split('-')[0];

  // Map 'zh' to 'cn' for simplified Chinese
  if (browserLang === 'zh') {
    return navigator.language.includes('TW') ? 'tw' : 'cn';
  }

  return supported.includes(browserLang) ? browserLang : 'en';
}
```

### 4. React Hook Example

```typescript
function useLocale() {
  const [locale, setLocale] = useState(() => {
    return localStorage.getItem('ai_locale') || getDefaultLocale();
  });

  const updateLocale = (newLocale: string) => {
    localStorage.setItem('ai_locale', newLocale);
    setLocale(newLocale);
  };

  return { locale, setLocale: updateLocale };
}

// Usage in API calls
const { locale } = useLocale();

await fetch('/ai/ask', {
  method: 'POST',
  body: JSON.stringify({ projectId, question, locale }),
});
```

## Example Responses

### English (default)
```json
{
  "answer": "Based on your story, I found several plot holes...",
  "provider": "anthropic",
  "model": "claude-3-haiku-20240307"
}
```

### Chinese (`locale: "cn"`)
```json
{
  "answer": "根据您的故事，我发现了几个情节漏洞...",
  "provider": "anthropic",
  "model": "claude-3-haiku-20240307"
}
```

### Japanese (`locale: "ja"`)
```json
{
  "answer": "あなたの物語に基づいて、いくつかのプロットホールを見つけました...",
  "provider": "anthropic",
  "model": "claude-3-haiku-20240307"
}
```
