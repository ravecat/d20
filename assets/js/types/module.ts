export interface ModuleConnection {
  endpoint: string;
  topic: string;
  token: string;
}

export interface ModuleEntry {
  embedUrl: string;
  allowedOrigins: string[];
  sandbox: string[];
}
