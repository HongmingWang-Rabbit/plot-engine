# AI Writing Endpoints - Frontend Integration Guide

This guide covers the three AI-powered writing assistance endpoints for PlotEngine.

## Authentication

All endpoints require authentication via Bearer token:

```javascript
const headers = {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
};
```

## Error Handling

### Common Error Responses

| Status | Code | Description |
|--------|------|-------------|
| 401 | Unauthorized | Invalid or missing token |
| 402 | Payment Required | Insufficient credits |
| 403 | Forbidden | User doesn't own the project |
| 404 | Not Found | Project or chapter not found |
| 400 | Bad Request | Invalid request body |

### Insufficient Credits Response (402)

```json
{
  "error": "Insufficient credits",
  "details": {
    "code": "INSUFFICIENT_CREDITS",
    "balance": 0,
    "message": "Please purchase more credits to continue using AI services."
  }
}
```

**Frontend Handling:**
```javascript
if (response.status === 402) {
  // Show purchase credits modal or redirect to billing page
  showCreditsModal();
}
```

---

## 1. Ask AI - General Questions

Ask questions about your project, get suggestions, identify issues, or brainstorm ideas.

### Endpoint

```
POST /ai/ask
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | Yes | Project UUID |
| `question` | string | Yes | User's question (max 2000 chars) |
| `context` | string | No | Context scope: `"project"`, `"chapter"`, `"selection"` (default: `"project"`) |
| `chapterId` | string | No | Required if context is `"chapter"` |
| `selection` | string | No | Selected text if context is `"selection"` (max 10000 chars) |
| `provider` | string | No | `"anthropic"` or `"openai"` (default: `"anthropic"`) |

### Context Levels

| Context | What AI Sees | Use Case |
|---------|--------------|----------|
| `project` | All chapters (previews), all entities | "What are the plot holes in my story?" |
| `chapter` | Full chapter content + entities | "How can I improve this chapter's pacing?" |
| `selection` | Selected text only + entities | "Is this dialogue realistic?" |

### Example Request

```javascript
// Ask about the entire project
const response = await fetch('/ai/ask', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    question: 'What are some potential plot holes in my story?',
    context: 'project'
  })
});

// Ask about a specific chapter
const response = await fetch('/ai/ask', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    question: 'How can I make this chapter more engaging?',
    context: 'chapter',
    chapterId: 'chapter-uuid-here'
  })
});

// Ask about selected text
const response = await fetch('/ai/ask', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    question: 'Is this dialogue realistic for these characters?',
    context: 'selection',
    selection: 'The selected text from the editor...'
  })
});
```

### Response

```json
{
  "answer": "Based on your story, I've identified several potential issues...",
  "provider": "anthropic",
  "model": "claude-3-haiku-20240307",
  "usage": {
    "input_tokens": 1234,
    "output_tokens": 567
  }
}
```

### Frontend Integration Example

```javascript
async function askAI(projectId, question, options = {}) {
  try {
    const response = await fetch('/ai/ask', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${getToken()}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        projectId,
        question,
        context: options.context || 'project',
        chapterId: options.chapterId,
        selection: options.selection
      })
    });

    if (response.status === 402) {
      throw new Error('INSUFFICIENT_CREDITS');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to get AI response');
    }

    return await response.json();
  } catch (error) {
    if (error.message === 'INSUFFICIENT_CREDITS') {
      // Handle credits dialog
      showPurchaseCreditsModal();
    }
    throw error;
  }
}

// Usage
const result = await askAI(projectId, 'What themes should I explore?');
displayAIResponse(result.answer);
```

---

## 2. Continue Writing

AI continues writing from where the chapter left off, maintaining style and consistency.

### Endpoint

```
POST /ai/write/continue
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | Yes | Project UUID |
| `chapterId` | string | Yes | Chapter UUID to continue from |
| `prompt` | string | No | Direction for continuation (max 1000 chars) |
| `maxWords` | integer | No | Approximate words to generate: 100-2000 (default: 500) |
| `provider` | string | No | `"anthropic"` or `"openai"` (default: `"anthropic"`) |

### Example Requests

```javascript
// Continue naturally without specific direction
const response = await fetch('/ai/write/continue', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    chapterId: 'chapter-uuid-here',
    maxWords: 500
  })
});

// Continue with specific direction
const response = await fetch('/ai/write/continue', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    chapterId: 'chapter-uuid-here',
    prompt: 'Have the protagonist discover a hidden room behind the bookshelf',
    maxWords: 800
  })
});
```

### Response

```json
{
  "content": "She ran her fingers along the dusty spines, pausing at a leather-bound tome that seemed oddly out of place...",
  "provider": "anthropic",
  "model": "claude-3-haiku-20240307",
  "usage": {
    "input_tokens": 2345,
    "output_tokens": 890
  }
}
```

### Frontend Integration Example

```javascript
async function continueWriting(projectId, chapterId, options = {}) {
  const response = await fetch('/ai/write/continue', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${getToken()}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      projectId,
      chapterId,
      prompt: options.prompt,
      maxWords: options.maxWords || 500
    })
  });

  if (response.status === 402) {
    showPurchaseCreditsModal();
    throw new Error('INSUFFICIENT_CREDITS');
  }

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error);
  }

  return await response.json();
}

// Usage in editor
async function handleContinueWriting() {
  setLoading(true);
  try {
    const result = await continueWriting(projectId, currentChapterId, {
      prompt: userPrompt,  // Optional user direction
      maxWords: 500
    });

    // Append to editor content
    appendToEditor(result.content);

    // Show token usage if desired
    showUsageNotification(result.usage);
  } catch (error) {
    showError(error.message);
  } finally {
    setLoading(false);
  }
}
```

---

## 3. Modify Chapter

AI modifies chapter content based on instructions. Can modify entire chapter or just a selection.

### Endpoint

```
POST /ai/write/modify
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | Yes | Project UUID |
| `chapterId` | string | Yes | Chapter UUID to modify |
| `prompt` | string | Yes | Modification instructions (max 1000 chars) |
| `selection` | string | No | Specific text to modify (max 10000 chars) |
| `provider` | string | No | `"anthropic"` or `"openai"` (default: `"anthropic"`) |

### Modification Modes

| Mode | When | Behavior |
|------|------|----------|
| Selection | `selection` provided | Only modifies the selected text |
| Full Chapter | `selection` not provided | Modifies entire chapter |

### Example Requests

```javascript
// Modify selected text
const response = await fetch('/ai/write/modify', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    chapterId: 'chapter-uuid-here',
    prompt: 'Make this dialogue more tense and confrontational',
    selection: '"Hello," she said. "How are you?" He smiled. "I\'m fine."'
  })
});

// Modify entire chapter
const response = await fetch('/ai/write/modify', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    projectId: 'uuid-here',
    chapterId: 'chapter-uuid-here',
    prompt: 'Add more sensory details and atmosphere throughout'
  })
});
```

### Response

```json
{
  "content": "\"What do you want?\" she snapped, her voice cutting through the silence...",
  "isFullChapter": false,
  "provider": "anthropic",
  "model": "claude-3-haiku-20240307",
  "usage": {
    "input_tokens": 1567,
    "output_tokens": 234
  }
}
```

### Frontend Integration Example

```javascript
async function modifyContent(projectId, chapterId, prompt, selection = null) {
  const response = await fetch('/ai/write/modify', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${getToken()}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      projectId,
      chapterId,
      prompt,
      selection
    })
  });

  if (response.status === 402) {
    showPurchaseCreditsModal();
    throw new Error('INSUFFICIENT_CREDITS');
  }

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error);
  }

  return await response.json();
}

// Usage: Modify selection
async function handleModifySelection() {
  const selectedText = editor.getSelection();
  if (!selectedText) {
    showError('Please select text to modify');
    return;
  }

  setLoading(true);
  try {
    const result = await modifyContent(
      projectId,
      currentChapterId,
      modificationPrompt,
      selectedText
    );

    // Replace selection with modified content
    editor.replaceSelection(result.content);
  } catch (error) {
    showError(error.message);
  } finally {
    setLoading(false);
  }
}

// Usage: Modify entire chapter
async function handleModifyChapter() {
  setLoading(true);
  try {
    const result = await modifyContent(
      projectId,
      currentChapterId,
      modificationPrompt
      // No selection = modify entire chapter
    );

    // Replace entire chapter content
    editor.setContent(result.content);
  } catch (error) {
    showError(error.message);
  } finally {
    setLoading(false);
  }
}
```

---

## UI/UX Recommendations

### 1. Loading States

All AI endpoints may take 5-15 seconds. Show appropriate loading indicators:

```javascript
// Example loading component
function AILoadingIndicator({ action }) {
  const messages = {
    ask: 'Thinking...',
    continue: 'Writing...',
    modify: 'Revising...'
  };

  return (
    <div className="ai-loading">
      <Spinner />
      <span>{messages[action]}</span>
    </div>
  );
}
```

### 2. Preview Before Apply

For `write/continue` and `write/modify`, consider showing a preview before applying:

```javascript
async function handleContinueWithPreview() {
  const result = await continueWriting(projectId, chapterId);

  // Show in preview modal
  showPreviewModal({
    content: result.content,
    onAccept: () => appendToEditor(result.content),
    onReject: () => closeModal(),
    onRegenerate: () => handleContinueWithPreview()
  });
}
```

### 3. Undo Support

Always save state before AI modifications:

```javascript
function handleModifyWithUndo() {
  const previousContent = editor.getContent();

  modifyContent(projectId, chapterId, prompt, selection)
    .then(result => {
      editor.replaceContent(result.content);

      // Enable undo
      setUndoState({
        available: true,
        previousContent
      });
    });
}
```

### 4. Credit Balance Display

Show remaining credits before AI operations:

```javascript
// Fetch balance before showing AI options
const balance = await fetch('/billing/credits', { headers });
const { creditsBalance } = await balance.json();

if (creditsBalance < 0.01) {
  showLowCreditsWarning();
}
```

---

## TypeScript Interfaces

```typescript
// Request types
interface AskRequest {
  projectId: string;
  question: string;
  context?: 'project' | 'chapter' | 'selection';
  chapterId?: string;
  selection?: string;
  provider?: 'anthropic' | 'openai';
}

interface ContinueWritingRequest {
  projectId: string;
  chapterId: string;
  prompt?: string;
  maxWords?: number;
  provider?: 'anthropic' | 'openai';
}

interface ModifyRequest {
  projectId: string;
  chapterId: string;
  prompt: string;
  selection?: string;
  provider?: 'anthropic' | 'openai';
}

// Response types
interface AIUsage {
  input_tokens: number;
  output_tokens: number;
}

interface AskResponse {
  answer: string;
  provider: string;
  model: string;
  usage: AIUsage;
}

interface WriteResponse {
  content: string;
  provider: string;
  model: string;
  usage: AIUsage;
}

interface ModifyResponse extends WriteResponse {
  isFullChapter: boolean;
}

// Error response
interface ErrorResponse {
  error: string;
  details?: {
    code: string;
    balance?: number;
    message?: string;
  };
}
```

---

## Rate Limiting

These endpoints are rate-limited. If you receive a 429 response, implement exponential backoff:

```javascript
async function fetchWithRetry(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = await fetch(url, options);

    if (response.status === 429) {
      const delay = Math.pow(2, i) * 1000; // 1s, 2s, 4s
      await new Promise(resolve => setTimeout(resolve, delay));
      continue;
    }

    return response;
  }

  throw new Error('Rate limit exceeded');
}
```

---

## Cost Estimation

Approximate costs per request (using Claude Haiku):

| Endpoint | Typical Input | Typical Output | Est. Cost |
|----------|--------------|----------------|-----------|
| `/ai/ask` | 2-5K tokens | 500-1K tokens | $0.002-0.005 |
| `/ai/write/continue` | 3-6K tokens | 500-1.5K tokens | $0.003-0.007 |
| `/ai/write/modify` | 2-8K tokens | 500-2K tokens | $0.003-0.010 |

Costs vary based on project size and response length.
