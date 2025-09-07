/**
 * OpenAI Streaming Events API Type Definitions
 * Generated from official API documentation
 */

// Base Event Types
export interface BaseEvent {
  type: string;
  sequence_number: integer;
}

// Response Events
export interface ResponseCreatedEvent extends BaseEvent {
  type: 'response.created';
  response: Response;
  sequence_number: number;
}

export interface ResponseInProgressEvent extends BaseEvent {
  type: 'response.in_progress';
  response: Response;
  sequence_number: number;
}

export interface ResponseCompletedEvent extends BaseEvent {
  type: 'response.completed';
  response: Response;
  sequence_number: number;
}

export interface ResponseFailedEvent extends BaseEvent {
  type: 'response.failed';
  response: Response;
  sequence_number: number;
}

export interface ResponseIncompleteEvent extends BaseEvent {
  type: 'response.incomplete';
  response: Response;
  sequence_number: number;
}

// Output Item Events
export interface ResponseOutputItemAddedEvent extends BaseEvent {
  type: 'response.output_item.added';
  output_index: number;
  item: OutputItem;
  sequence_number: number;
}

export interface ResponseOutputItemDoneEvent extends BaseEvent {
  type: 'response.output_item.done';
  output_index: number;
  item: OutputItem;
  sequence_number: number;
}

// Content Part Events
export interface ResponseContentPartAddedEvent extends BaseEvent {
  type: 'response.content_part.added';
  item_id: string;
  output_index: number;
  content_index: number;
  part: ContentPart;
  sequence_number: number;
}

export interface ResponseContentPartDoneEvent extends BaseEvent {
  type: 'response.content_part.done';
  item_id: string;
  output_index: number;
  content_index: number;
  part: ContentPart;
  sequence_number: number;
}

// Text Delta Events
export interface ResponseOutputTextDeltaEvent extends BaseEvent {
  type: 'response.output_text.delta';
  item_id: string;
  output_index: number;
  content_index: number;
  delta: string;
  logprobs?: LogProb[];
  sequence_number: number;
}

export interface ResponseOutputTextDoneEvent extends BaseEvent {
  type: 'response.output_text.done';
  item_id: string;
  output_index: number;
  content_index: number;
  text: string;
  logprobs?: LogProb[];
  sequence_number: number;
}

// Tool Call Events
export interface ResponseFunctionCallArgumentsDeltaEvent extends BaseEvent {
  type: 'response.function_call_arguments.delta';
  item_id: string;
  output_index: number;
  delta: string;
  sequence_number: number;
}

export interface ResponseFunctionCallArgumentsDoneEvent extends BaseEvent {
  type: 'response.function_call_arguments.done';
  item_id: string;
  output_index: number;
  arguments: string;
  sequence_number: number;
}

// Error Event
export interface ErrorEvent extends BaseEvent {
  type: 'error';
  code: string | null;
  message: string;
  param: string | null;
  sequence_number: number;
}

// Core Response Types
export interface Response {
  id: string;
  object: 'response';
  created_at: number;
  status: 'completed' | 'failed' | 'in_progress' | 'cancelled' | 'queued' | 'incomplete';
  error?: ErrorObject | null;
  incomplete_details?: IncompleteDetails | null;
  instructions?: string | InputItemList;
  model: string;
  output: OutputItem[];
  metadata?: Record<string, string>;
  usage?: Usage | null;
  // ...additional properties based on documentation
}

export interface ErrorObject {
  code: string;
  message: string;
}

export interface IncompleteDetails {
  reason: string;
}

export interface Usage {
  input_tokens: number;
  output_tokens: number;
  output_tokens_details?: {
    reasoning_tokens: number;
  };
  total_tokens: number;
  input_tokens_details?: {
    cached_tokens: number;
  };
}

// Output Types
export type OutputItem = 
  | OutputMessage
  | FileSearchToolCall
  | FunctionToolCall
  | WebSearchToolCall
  | ComputerToolCall
  | ReasoningOutput
  | ImageGenerationCall
  | CodeInterpreterToolCall
  | LocalShellCall
  | MCPToolCall
  | CustomToolCall;

export interface OutputMessage {
  id: string;
  type: 'message';
  role: 'assistant';
  status?: 'in_progress' | 'completed' | 'incomplete';
  content: ContentPart[];
}

export type ContentPart = 
  | OutputText
  | Refusal;

export interface OutputText {
  type: 'output_text';
  text: string;
  annotations?: Annotation[];
  logprobs?: LogProb[];
}

export interface Refusal {
  type: 'refusal';
  refusal: string;
}

export interface LogProb {
  token: string;
  logprob: number;
  bytes?: number[];
  top_logprobs?: TopLogProb[];
}

export interface TopLogProb {
  token: string;
  logprob: number;
  bytes?: number[];
}

// Annotation Types
export type Annotation = 
  | FileCitation
  | URLCitation
  | ContainerFileCitation
  | FilePath;

export interface FileCitation {
  type: 'file_citation';
  file_id: string;
  filename: string;
  index: number;
}

export interface URLCitation {
  type: 'url_citation';
  url: string;
  title: string;
  start_index: number;
  end_index: number;
}

export interface ContainerFileCitation {
  type: 'container_file_citation';
  container_id: string;
  file_id: string;
  filename: string;
  start_index: number;
  end_index: number;
}

export interface FilePath {
  type: 'file_path';
  file_id: string;
  index: number;
}

// Tool Call Types
export interface FunctionToolCall {
  id: string;
  type: 'function_call';
  call_id: string;
  name: string;
  arguments: string;
  status?: 'in_progress' | 'completed' | 'incomplete';
}

export interface FileSearchToolCall {
  id: string;
  type: 'file_search_call';
  queries: any[];
  status: 'in_progress' | 'searching' | 'incomplete' | 'failed';
  results?: FileSearchResult[] | null;
}

export interface FileSearchResult {
  file_id: string;
  filename: string;
  score: number;
  text: string;
  attributes?: Record<string, any>;
}

export interface WebSearchToolCall {
  id: string;
  type: 'web_search_call';
  status: string;
  action?: WebSearchAction;
}

export type WebSearchAction = 
  | SearchAction
  | OpenPageAction
  | FindAction;

export interface SearchAction {
  type: 'search';
  query: string;
  sources?: WebSource[];
}

export interface OpenPageAction {
  type: 'open_page';
  url: string;
}

export interface FindAction {
  type: 'find';
  pattern: string;
  url: string;
}

export interface WebSource {
  type: 'url';
  url: string;
}

// Reasoning Types
export interface ReasoningOutput {
  id: string;
  type: 'reasoning';
  summary?: ReasoningSummary[];
  content?: ReasoningContent[];
  encrypted_content?: string | null;
  status?: 'in_progress' | 'completed' | 'incomplete';
}

export interface ReasoningSummary {
  type: 'summary_text';
  text: string;
}

export interface ReasoningContent {
  type: 'reasoning_text';
  text: string;
}

// Union type for all streaming events
export type StreamingEvent = 
  | ResponseCreatedEvent
  | ResponseInProgressEvent
  | ResponseCompletedEvent
  | ResponseFailedEvent
  | ResponseIncompleteEvent
  | ResponseOutputItemAddedEvent
  | ResponseOutputItemDoneEvent
  | ResponseContentPartAddedEvent
  | ResponseContentPartDoneEvent
  | ResponseOutputTextDeltaEvent
  | ResponseOutputTextDoneEvent
  | ResponseFunctionCallArgumentsDeltaEvent
  | ResponseFunctionCallArgumentsDoneEvent
  | ErrorEvent;

// Helper type guards
export const isResponseCreatedEvent = (event: StreamingEvent): event is ResponseCreatedEvent => 
  event.type === 'response.created';

export const isResponseCompletedEvent = (event: StreamingEvent): event is ResponseCompletedEvent => 
  event.type === 'response.completed';

export const isResponseOutputTextDeltaEvent = (event: StreamingEvent): event is ResponseOutputTextDeltaEvent => 
  event.type === 'response.output_text.delta';

export const isErrorEvent = (event: StreamingEvent): event is ErrorEvent => 
  event.type === 'error';
