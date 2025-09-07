/**
 * Utility class for handling OpenAI Streaming Events
 */

import type {
  StreamingEvent,
  ResponseCreatedEvent,
  ResponseCompletedEvent,
  ResponseOutputTextDeltaEvent,
  ErrorEvent,
  isResponseCreatedEvent,
  isResponseCompletedEvent,
  isResponseOutputTextDeltaEvent,
  isErrorEvent
} from '../types/StreamingEventsAPI';

export interface StreamingEventHandlers {
  onResponseCreated?: (event: ResponseCreatedEvent) => void;
  onResponseCompleted?: (event: ResponseCompletedEvent) => void;
  onTextDelta?: (event: ResponseOutputTextDeltaEvent) => void;
  onError?: (event: ErrorEvent) => void;
  onAnyEvent?: (event: StreamingEvent) => void;
}

export class StreamingEventHandler {
  private handlers: StreamingEventHandlers;
  private textBuffer: string = '';
  
  constructor(handlers: StreamingEventHandlers) {
    this.handlers = handlers;
  }
  
  /**
   * Process a streaming event
   */
  handleEvent(event: StreamingEvent): void {
    // Call generic handler if provided
    this.handlers.onAnyEvent?.(event);
    
    // Handle specific event types
    if (isResponseCreatedEvent(event)) {
      this.handlers.onResponseCreated?.(event);
    } else if (isResponseCompletedEvent(event)) {
      this.handlers.onResponseCompleted?.(event);
    } else if (isResponseOutputTextDeltaEvent(event)) {
      this.textBuffer += event.delta;
      this.handlers.onTextDelta?.(event);
    } else if (isErrorEvent(event)) {
      this.handlers.onError?.(event);
    }
  }
  
  /**
   * Get the accumulated text buffer
   */
  getTextBuffer(): string {
    return this.textBuffer;
  }
  
  /**
   * Clear the text buffer
   */
  clearBuffer(): void {
    this.textBuffer = '';
  }
  
  /**
   * Parse a server-sent event line
   */
  parseSSELine(line: string): StreamingEvent | null {
    if (!line.startsWith('data: ')) {
      return null;
    }
    
    const jsonStr = line.slice(6); // Remove 'data: ' prefix
    
    if (jsonStr === '[DONE]') {
      return null;
    }
    
    try {
      return JSON.parse(jsonStr) as StreamingEvent;
    } catch (error) {
      console.error('Failed to parse SSE line:', error);
      return null;
    }
  }
  
  /**
   * Process a stream of server-sent events
   */
  async processSSEStream(stream: ReadableStream<Uint8Array>): Promise<void> {
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    
    try {
      while (true) {
        const { done, value } = await reader.read();
        
        if (done) break;
        
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        
        // Keep the last incomplete line in the buffer
        buffer = lines.pop() || '';
        
        for (const line of lines) {
          const trimmedLine = line.trim();
          if (trimmedLine) {
            const event = this.parseSSELine(trimmedLine);
            if (event) {
              this.handleEvent(event);
            }
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}

// Example usage function
export function createStreamingHandler(
  onText?: (text: string) => void,
  onComplete?: (fullText: string) => void,
  onError?: (error: ErrorEvent) => void
): StreamingEventHandler {
  return new StreamingEventHandler({
    onTextDelta: (event) => {
      onText?.(event.delta);
    },
    onResponseCompleted: (event) => {
      const handler = event as unknown as StreamingEventHandler;
      onComplete?.(handler.getTextBuffer());
    },
    onError: (event) => {
      onError?.(event);
    }
  });
}
